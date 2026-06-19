import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/artisan.dart';
import '../services/api_service.dart';
import '../services/favorites_service.dart';

class ArtisanCard extends StatefulWidget {
  final Artisan artisan;
  final VoidCallback? onTap;
  final String? customerEmail;

  const ArtisanCard({
    super.key,
    required this.artisan,
    this.onTap,
    this.customerEmail,
  });

  @override
  State<ArtisanCard> createState() => _ArtisanCardState();
}

class _ArtisanCardState extends State<ArtisanCard>
    with WidgetsBindingObserver {
  final ApiService _apiService = ApiService();

  bool _isFavorite = false;
  bool _isUnlocked = false;

  bool _isLoadingFavorite = true;
  bool _isLoadingPayment = false;
  bool _isVerifyingPayment = false;
  bool _isCheckingExistingAccess = false;

  bool _hasPendingPaymentFlow = false;
  bool _isDisposed = false;

  String? _paymentReference;
  String? _paymentUrl;

  static const Color _surface = Colors.white;
  static const Color _text = Color(0xFF0F172A);
  static const Color _subtext = Color(0xFF6B7280);
  static const Color _primary = Color(0xFF243B8F);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadFavorite();
    _initializeAccessState();
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _apiService.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ArtisanCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.artisan.id != widget.artisan.id ||
        oldWidget.customerEmail != widget.customerEmail) {
      _hasPendingPaymentFlow = false;
      _paymentReference = null;
      _paymentUrl = null;
      _initializeAccessState();
      _loadFavorite();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _handleAppResumed();
    }
  }

  Future<void> _handleAppResumed() async {
    if (!_hasPendingPaymentFlow) return;
    if (_isVerifyingPayment || _isLoadingPayment || _isCheckingExistingAccess) {
      return;
    }

    await _refreshAccessAfterReturn();
  }

  Future<void> _initializeAccessState() async {
    if (!_canUpdateUi) return;

    setState(() {
      _isUnlocked = widget.artisan.hasActiveAccess;
    });

    await _checkExistingAccess(showLoading: true);
  }

  String _safeString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  String get _safeEmail => (widget.customerEmail ?? '').trim();

  bool get _hasCustomerEmail => _safeEmail.isNotEmpty;

  String get _displayName {
    final nom = _safeString(widget.artisan.nom);
    return nom.isNotEmpty ? nom : 'Sans nom';
  }

  String get _displayMetier {
    final metier = _safeString(widget.artisan.metier);
    return metier.isNotEmpty ? metier : 'Métier';
  }

  String get _displayLocalisation {
    final localisation = _safeString(widget.artisan.localisation);
    return localisation.isNotEmpty ? localisation : 'Localisation inconnue';
  }

  String get _displayDescription => _safeString(widget.artisan.description);

  String get _displayPhone {
    final phone = _safeString(widget.artisan.numeroPrincipal);
    return phone;
  }

  String get _displayWhatsapp {
    final phone = _safeString(widget.artisan.numeroWhatsapp);
    return phone;
  }

  String get _displayImage => _safeString(widget.artisan.imageOrPlaceholder);

  bool get _hasValidImage {
    return widget.artisan.hasImage && _displayImage.isNotEmpty;
  }

  bool get _isBusy {
    return _isLoadingPayment ||
        _isVerifyingPayment ||
        _isCheckingExistingAccess;
  }

  bool get _canUpdateUi => mounted && !_isDisposed;

  String get _heroTag => 'artisan-image-${widget.artisan.id}';

  Future<void> _loadFavorite() async {
    try {
      final fav = await FavoritesService.isFavorite(
        'artisan_${widget.artisan.id}',
      );

      if (!_canUpdateUi) return;

      setState(() {
        _isFavorite = fav;
        _isLoadingFavorite = false;
      });
    } catch (_) {
      if (!_canUpdateUi) return;

      setState(() {
        _isLoadingFavorite = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isLoadingFavorite) return;

    try {
      final fav = await FavoritesService.toggleFavorite(
        'artisan_${widget.artisan.id}',
      );

      if (!_canUpdateUi) return;

      setState(() {
        _isFavorite = fav;
      });

      _showSnack(
        fav ? 'Ajouté aux favoris ❤️' : 'Retiré des favoris',
      );
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _checkExistingAccess({bool showLoading = false}) async {
    if (!_hasCustomerEmail) {
      if (_canUpdateUi) {
        setState(() {
          _isUnlocked = widget.artisan.hasActiveAccess;
          _isCheckingExistingAccess = false;
        });
      }
      return;
    }

    if (_canUpdateUi && showLoading) {
      setState(() => _isCheckingExistingAccess = true);
    }

    try {
      final res = await _apiService.checkArtisanAccess(
        artisanId: widget.artisan.id,
        email: _safeEmail,
      );

      if (!_canUpdateUi) return;

      final hasAccess = _apiService.hasArtisanAccess(res);

      setState(() {
        _isUnlocked = hasAccess;
        if (hasAccess) {
          _hasPendingPaymentFlow = false;
        }
      });
    } catch (_) {
      // silencieux
    } finally {
      if (_canUpdateUi && showLoading) {
        setState(() => _isCheckingExistingAccess = false);
      }
    }
  }

  Future<void> _refreshAccessAfterReturn() async {
    if (!_hasCustomerEmail) return;

    await _checkExistingAccess(showLoading: true);

    if (_isUnlocked) {
      _paymentReference = null;
      _paymentUrl = null;
      _hasPendingPaymentFlow = false;
      _showSnack('Paiement retrouvé. Contact débloqué 🎉');
      return;
    }

    if ((_paymentReference ?? '').isNotEmpty) {
      await _verifyPayment(silentSuccess: true);
    }
  }

  Future<void> _call() async {
    final phone = _displayPhone;
    if (phone.isEmpty) {
      _showError('Numéro indisponible');
      return;
    }

    final uri = Uri.parse('tel:$phone');
    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened) {
      _showError('Impossible de lancer l’appel');
    }
  }

  Future<void> _whatsapp() async {
    final phone = _displayWhatsapp;
    if (phone.isEmpty) {
      _showError('WhatsApp indisponible');
      return;
    }

    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.isEmpty) {
      _showError('Numéro WhatsApp invalide');
      return;
    }

    final uri = Uri.parse('https://wa.me/$cleaned');
    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened) {
      _showError('Impossible d’ouvrir WhatsApp');
    }
  }

  Future<void> _startPayment() async {
    if (_isBusy) return;

    if (!_hasCustomerEmail) {
      _showError(
        'Connecte un compte avec une adresse email valide avant de payer',
      );
      return;
    }

    setState(() => _isLoadingPayment = true);

    try {
      final res = await _apiService.initArtisanPayment(
        artisanId: widget.artisan.id,
        email: _safeEmail,
      );

      final alreadyPaid = _apiService.hasArtisanAccess(res);

      if (alreadyPaid) {
        if (!_canUpdateUi) return;

        setState(() {
          _isUnlocked = true;
          _hasPendingPaymentFlow = false;
          final ref = (res['reference'] ?? '').toString().trim();
          if (ref.isNotEmpty) {
            _paymentReference = ref;
          }
        });

        _showSnack('Accès déjà actif pour cet artisan ✅');
        return;
      }

      final paymentUrl = (res['authorization_url'] ?? '').toString().trim();
      final reference = (res['reference'] ?? '').toString().trim();

      if (paymentUrl.isEmpty) {
        throw Exception('URL de paiement introuvable');
      }

      if (reference.isEmpty) {
        throw Exception('Référence de paiement introuvable');
      }

      _paymentUrl = paymentUrl;
      _paymentReference = reference;
      _hasPendingPaymentFlow = true;

      final opened = await launchUrl(
        Uri.parse(paymentUrl),
        mode: LaunchMode.externalApplication,
      );

      if (!opened) {
        throw Exception('Impossible d’ouvrir la page de paiement');
      }

      if (!_canUpdateUi) return;

      _showSnack(
        'Page de paiement ouverte. Reviens dans l’app après paiement.',
      );
    } catch (e) {
      _showError(e);
    } finally {
      if (_canUpdateUi) {
        setState(() => _isLoadingPayment = false);
      }
    }
  }

  Future<void> _verifyPayment({bool silentSuccess = false}) async {
    final reference = _paymentReference?.trim() ?? '';
    if (reference.isEmpty) {
      _showError('Aucune référence de paiement trouvée');
      return;
    }

    if (_isVerifyingPayment) return;

    setState(() => _isVerifyingPayment = true);

    try {
      final res = await _apiService.verifyArtisanPayment(
        artisanId: widget.artisan.id,
        email: _safeEmail,
        reference: reference,
      );

      final success =
          _apiService.hasArtisanAccess(res) || res['success'] == true;

      if (!success) {
        throw Exception(
          res['error']?.toString() ??
              res['message']?.toString() ??
              'Paiement non validé',
        );
      }

      if (!_canUpdateUi) return;

      setState(() {
        _isUnlocked = true;
        _hasPendingPaymentFlow = false;
        _paymentReference = null;
        _paymentUrl = null;
      });

      if (!silentSuccess) {
        _showSnack('Paiement confirmé. Contact débloqué 🎉');
      }
    } catch (e) {
      if (!silentSuccess) {
        _showError(e);
      }
    } finally {
      if (_canUpdateUi) {
        setState(() => _isVerifyingPayment = false);
      }
    }
  }

  void _showSnack(String message) {
    if (!_canUpdateUi) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(Object e) {
    if (!_canUpdateUi) return;

    final message = e.toString().replaceFirst('Exception: ', '').trim();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message.isEmpty ? 'Une erreur est survenue' : message,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final artisan = widget.artisan;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: widget.onTap,
        child: Ink(
          height: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            color: _surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              _buildTopImage(artisan),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderTextOverlay(),
                    const SizedBox(height: 6),
                    _buildLocationOverlay(),
                    if (_displayDescription.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildDescriptionOverlay(),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildOverlayBadge(
                            _isUnlocked
                                ? 'Contact débloqué'
                                : 'Contact protégé • 500 F CFA',
                          ),
                        ),
                        const SizedBox(width: 10),
                        _buildVoirButton(),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopImage(Artisan artisan) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: SizedBox(
            height: double.infinity,
            width: double.infinity,
            child: Hero(
              tag: _heroTag,
              child: _hasValidImage
                  ? Image.network(
                      _displayImage,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return const _ImagePlaceholder();
                      },
                    )
                  : const _ImagePlaceholder(),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.05),
                  Colors.black.withOpacity(0.18),
                  Colors.black.withOpacity(0.72),
                ],
              ),
            ),
          ),
        ),
        if (artisan.sponsorise)
          Positioned(
            top: 14,
            left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFFB347),
                    Color(0xFFFF8A00),
                  ],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33FF8A00),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                'Sponsorisé',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        Positioned(
          top: 14,
          right: 14,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _isLoadingFavorite ? null : _toggleFavorite,
              child: Ink(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.92),
                  shape: BoxShape.circle,
                ),
                child: _isLoadingFavorite
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : AnimatedScale(
                        scale: _isFavorite ? 1.12 : 1,
                        duration: const Duration(milliseconds: 180),
                        child: Icon(
                          _isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: _isFavorite ? Colors.red : _primary,
                          size: 22,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderTextOverlay() {
    return Text(
      _displayName,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.playfairDisplay(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      ),
    );
  }

  Widget _buildLocationOverlay() {
    return Row(
      children: [
        const Icon(
          Icons.location_on_rounded,
          size: 16,
          color: Colors.white70,
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            _displayLocalisation,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionOverlay() {
    return Text(
      _displayDescription,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.poppins(
        color: Colors.white.withOpacity(0.92),
        fontSize: 12.8,
        height: 1.35,
      ),
    );
  }

  Widget _buildOverlayBadge(String text) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.16),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white24),
          ),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVoirButton() {
    final busy = _isBusy;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: busy
            ? null
            : (_isUnlocked
                ? widget.onTap
                : (_hasCustomerEmail ? _startPayment : widget.onTap)),
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (busy)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF243B8F),
                  ),
                )
              else
                Icon(
                  _isUnlocked
                      ? Icons.visibility_rounded
                      : Icons.lock_open_rounded,
                  size: 16,
                  color: _primary,
                ),
              const SizedBox(width: 8),
              Text(
                busy
                    ? 'Chargement'
                    : _isUnlocked
                        ? 'Voir'
                        : !_hasCustomerEmail
                            ? 'Ouvrir'
                            : 'Débloquer',
                style: GoogleFonts.poppins(
                  color: _primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEFF3FF),
      child: const Center(
        child: Icon(
          Icons.handyman_rounded,
          size: 40,
          color: Color(0xFF8EA2E8),
        ),
      ),
    );
  }
}