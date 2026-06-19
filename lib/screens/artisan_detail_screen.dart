import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/artisan.dart';
import '../services/api_service.dart';
import '../services/favorites_service.dart';
import '../utils/launcher_helper.dart';

class ArtisanDetailScreen extends StatefulWidget {
  final Artisan artisan;

  const ArtisanDetailScreen({
    super.key,
    required this.artisan,
  });

  @override
  State<ArtisanDetailScreen> createState() => _ArtisanDetailScreenState();
}

class _ArtisanDetailScreenState extends State<ArtisanDetailScreen> {
  final ApiService _apiService = ApiService();
  final AppLinks _appLinks = AppLinks();

  late Artisan _artisan;

  bool _isFavorite = false;
  bool _isLoadingPayment = false;
  bool _isVerifyingPayment = false;
  bool _isLoadingClientInfos = true;

  StreamSubscription<Uri>? _linkSubscription;
  Timer? _countdownTimer;

  String _userEmail = '';
  String _userName = '';
  String _userPhone = '';

  Duration? _timeLeft;

  @override
  void initState() {
    super.initState();
    _artisan = widget.artisan;
    _bootstrap();
  }

  String get _heroTag => 'artisan-image-${_artisan.id}';

  Future<void> _bootstrap() async {
    await _loadClientInfos();
    await _loadFavorite();
    await _initDeepLinks();
    await _checkAccess();
    _startCountdownIfNeeded();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadClientInfos() async {
    final prefs = await SharedPreferences.getInstance();

    _userName = (prefs.getString('client_name') ?? '').trim();
    _userEmail = (prefs.getString('client_email') ?? '').trim();
    _userPhone = (prefs.getString('client_phone') ?? '').trim();

    if (!mounted) return;
    setState(() {
      _isLoadingClientInfos = false;
    });
  }

  Future<void> _saveClientInfos() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('client_name', _userName.trim());
    await prefs.setString('client_email', _userEmail.trim());
    await prefs.setString('client_phone', _userPhone.trim());
  }

  Future<void> _initDeepLinks() async {
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri != null) {
        await _handleLink(uri);
      }
    } catch (_) {}

    _linkSubscription = _appLinks.uriLinkStream.listen((uri) async {
      await _handleLink(uri);
    });
  }

  Future<void> _handleLink(Uri uri) async {
    if (uri.scheme != 'ciresidences') return;
    if (uri.host != 'payment-return') return;

    final reference = (uri.queryParameters['reference'] ?? '').trim();
    final status = (uri.queryParameters['status'] ?? '').trim().toLowerCase();
    final emailFromLink = (uri.queryParameters['email'] ?? '').trim();

    if (emailFromLink.isNotEmpty) {
      _userEmail = emailFromLink;
      await _saveClientInfos();
    }

    if (status == 'success') {
      if (reference.isNotEmpty) {
        await _verifyPayment(reference);
      } else {
        await _checkAccess();
      }

      if (!mounted) return;
      _showMessage('Paiement confirmé ✅ Contact débloqué');
      return;
    }

    _showMessage('Paiement annulé ❌');
  }

  Future<void> _checkAccess() async {
    if (_userEmail.trim().isEmpty) return;

    try {
      final data = await _apiService.checkArtisanAccess(
        artisanId: _artisan.id,
        email: _userEmail,
      );

      if (!mounted) return;

      setState(() {
        _artisan = _artisan.copyWith(
          telephone: (data['telephone'] ?? '').toString(),
          whatsapp: (data['whatsapp'] ?? '').toString(),
          contactVisible: _apiService.hasArtisanAccess(data),
          expireLe: (data['expire_le'] ?? '').toString(),
        );
      });

      _startCountdownIfNeeded();
    } catch (e) {
      debugPrint('Erreur check access: $e');
    }
  }

  Future<void> _verifyPayment(String reference) async {
    if (_isVerifyingPayment) return;

    if (_userEmail.trim().isEmpty) {
      await _checkAccess();
      return;
    }

    setState(() {
      _isVerifyingPayment = true;
    });

    try {
      final data = await _apiService.verifyArtisanPayment(
        artisanId: _artisan.id,
        email: _userEmail,
        reference: reference,
      );

      if (!mounted) return;

      setState(() {
        _artisan = _artisan.copyWith(
          telephone: (data['telephone'] ?? '').toString(),
          whatsapp: (data['whatsapp'] ?? '').toString(),
          contactVisible: _apiService.hasArtisanAccess(data),
          expireLe: (data['expire_le'] ?? '').toString(),
        );
      });

      if (!_artisan.contactVisible) {
        await _checkAccess();
      }

      _startCountdownIfNeeded();
    } catch (_) {
      await _checkAccess();
    } finally {
      if (!mounted) return;
      setState(() {
        _isVerifyingPayment = false;
      });
    }
  }

  Future<void> _loadFavorite() async {
    final fav = await FavoritesService.isFavorite('artisan_${_artisan.id}');
    if (!mounted) return;

    setState(() {
      _isFavorite = fav;
    });
  }

  Future<void> _toggleFavorite() async {
    final fav = await FavoritesService.toggleFavorite('artisan_${_artisan.id}');
    if (!mounted) return;

    setState(() {
      _isFavorite = fav;
    });

    _showMessage(fav ? 'Ajouté aux favoris' : 'Retiré des favoris');
  }

  Future<void> _showPaymentForm() async {
    final nameController = TextEditingController(text: _userName);
    final emailController = TextEditingController(text: _userEmail);
    final phoneController = TextEditingController(text: _userPhone);

    final formKey = GlobalKey<FormState>();

    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD0D5DD),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Débloquer le contact',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Renseignez vos informations avant le paiement sécurisé.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: nameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Nom complet',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Veuillez renseigner votre nom';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.mail_outline_rounded),
                    ),
                    validator: (value) {
                      final email = (value ?? '').trim();
                      if (email.isEmpty) {
                        return 'Veuillez renseigner votre email';
                      }
                      if (!email.contains('@') || !email.contains('.')) {
                        return 'Email invalide';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Téléphone',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Veuillez renseigner votre numéro';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (!(formKey.currentState?.validate() ?? false)) return;

                        Navigator.pop(
                          context,
                          {
                            'name': nameController.text.trim(),
                            'email': emailController.text.trim(),
                            'phone': phoneController.text.trim(),
                          },
                        );
                      },
                      icon: const Icon(Icons.lock_open_rounded),
                      label: const Text(
                        'Continuer vers le paiement',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFF243B8F),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (result == null) return;

    _userName = (result['name'] ?? '').trim();
    _userEmail = (result['email'] ?? '').trim();
    _userPhone = (result['phone'] ?? '').trim();

    await _saveClientInfos();
    await _initPayment();
  }

  Future<void> _initPayment() async {
    if (_isLoadingPayment) return;

    if (_userEmail.trim().isEmpty) {
      _showMessage('Veuillez renseigner votre email');
      return;
    }

    setState(() {
      _isLoadingPayment = true;
    });

    try {
      final response = await _apiService.initArtisanPayment(
        artisanId: _artisan.id,
        email: _userEmail,
        nomClient: _userName,
        telephoneClient: _userPhone,
        source: 'app',
      );

      if (_apiService.hasArtisanAccess(response)) {
        await _checkAccess();
        _showMessage('Accès déjà actif ✅');
        return;
      }

      final url = (response['authorization_url'] ?? '').toString().trim();

      if (url.isEmpty) {
        throw Exception('Lien paiement invalide');
      }

      await LauncherHelper.openWebsite(url);
      _showMessage('Finalisez le paiement...');
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingPayment = false;
      });
    }
  }

  Future<void> _call() async {
    final phone = _artisan.numeroPrincipal;

    if (phone.isEmpty) {
      _showMessage('Numéro indisponible');
      return;
    }

    await LauncherHelper.callPhone(phone);
  }

  Future<void> _whatsapp() async {
    final phone = _artisan.numeroWhatsapp;

    if (phone.isEmpty) {
      _showMessage('Numéro indisponible');
      return;
    }

    await LauncherHelper.openWhatsApp(
      phone,
      message:
          'Bonjour ${_artisan.nom}, je viens depuis CI Résidences concernant votre service.',
    );
  }

  void _shareArtisan() {
    final text = _artisan.contactVisible
        ? 'Artisan ${_artisan.nom}\nTéléphone: ${_artisan.telephone}\nWhatsApp: ${_artisan.whatsapp}'
        : 'Découvrez ${_artisan.nom} sur CI Résidences.';
    Share.share(text);
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  DateTime? _parseExpireDate() {
    final raw = _artisan.expireLe.trim();
    if (raw.isEmpty) return null;

    try {
      return DateTime.parse(raw).toLocal();
    } catch (_) {
      return null;
    }
  }

  void _startCountdownIfNeeded() {
    _countdownTimer?.cancel();

    final expireDate = _parseExpireDate();
    if (expireDate == null || !_artisan.contactVisible) {
      if (mounted) {
        setState(() {
          _timeLeft = null;
        });
      }
      return;
    }

    void updateCountdown() {
      final now = DateTime.now();
      final diff = expireDate.difference(now);

      if (!mounted) return;

      if (diff.isNegative || diff.inSeconds <= 0) {
        _countdownTimer?.cancel();
        setState(() {
          _timeLeft = Duration.zero;
          _artisan = _artisan.copyWith(
            contactVisible: false,
            telephone: '',
            whatsapp: '',
            expireLe: '',
          );
        });
        return;
      }

      setState(() {
        _timeLeft = diff;
      });
    }

    updateCountdown();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      updateCountdown();
    });
  }

  String _formatExpireDate() {
    final expireDate = _parseExpireDate();
    if (expireDate == null) return '';
    return DateFormat('dd/MM/yyyy à HH:mm').format(expireDate);
  }

  String _formatCountdown(Duration duration) {
    final totalSeconds = duration.inSeconds;
    if (totalSeconds <= 0) return '00:00:00';

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    final h = hours.toString().padLeft(2, '0');
    final m = minutes.toString().padLeft(2, '0');
    final s = seconds.toString().padLeft(2, '0');

    return '$h:$m:$s';
  }

  Color _countdownColor() {
    if (_timeLeft == null) return const Color(0xFF16A34A);
    if (_timeLeft!.inHours < 1) return const Color(0xFFD92D20);
    if (_timeLeft!.inHours < 6) return const Color(0xFFF59E0B);
    return const Color(0xFF16A34A);
  }

  Widget _buildCountdownCard() {
    final timeLeft = _timeLeft;
    if (!_artisan.contactVisible || timeLeft == null) {
      return const SizedBox.shrink();
    }

    final color = _countdownColor();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            blurRadius: 16,
            offset: Offset(0, 8),
            color: Color(0x11000000),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.timer_rounded, color: color, size: 22),
              const SizedBox(width: 8),
              const Text(
                'Temps restant',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            _formatCountdown(timeLeft),
            style: TextStyle(
              fontSize: 34,
              height: 1,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Valide jusqu’au ${_formatExpireDate()}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(bool contactVisible) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            blurRadius: 16,
            offset: Offset(0, 8),
            color: Color(0x11000000),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Coordonnées',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 18),
          _buildInfoRow(
            icon: Icons.phone_rounded,
            label: 'Téléphone',
            value: contactVisible ? _artisan.telephone : '********',
          ),
          const SizedBox(height: 14),
          _buildInfoRow(
            icon: Icons.chat_bubble_rounded,
            label: 'WhatsApp',
            value: contactVisible ? _artisan.whatsapp : '********',
          ),
          if (!contactVisible) ...[
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.security_rounded,
                    color: Color(0xFFF97316),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Paiement sécurisé • Déblocage personnel • 500 FCFA',
                      style: TextStyle(
                        color: Color(0xFF9A3412),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF4FF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF243B8F),
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 17,
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionBar(bool contactVisible) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              offset: Offset(0, -6),
              color: Color(0x11000000),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 58,
                child: ElevatedButton.icon(
                  onPressed: (_isLoadingPayment ||
                          _isVerifyingPayment ||
                          _isLoadingClientInfos)
                      ? null
                      : () async {
                          if (!contactVisible) {
                            await _showPaymentForm();
                          } else {
                            await _whatsapp();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: contactVisible
                        ? const Color(0xFF12B76A)
                        : const Color(0xFF243B8F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: (_isLoadingPayment || _isVerifyingPayment)
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          contactVisible
                              ? Icons.chat_rounded
                              : Icons.lock_open_rounded,
                        ),
                  label: Text(
                    (_isLoadingPayment || _isVerifyingPayment)
                        ? 'Patientez...'
                        : (contactVisible ? 'WhatsApp' : 'Débloquer 500 FCFA'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 58,
              width: 128,
              child: OutlinedButton.icon(
                onPressed: contactVisible ? _call : null,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  side: BorderSide(
                    color: contactVisible
                        ? const Color(0xFF243B8F)
                        : const Color(0xFFD0D5DD),
                    width: 1.3,
                  ),
                ),
                icon: const Icon(Icons.call_rounded),
                label: const Text(
                  'Appeler',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader(bool contactVisible) {
    return SliverAppBar(
      backgroundColor: Colors.black,
      expandedHeight: 300,
      pinned: true,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: CircleAvatar(
          backgroundColor: Colors.white.withOpacity(0.88),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF111827),
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.88),
            child: IconButton(
              onPressed: _toggleFavorite,
              icon: Icon(
                _isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: _isFavorite ? Colors.red : const Color(0xFF111827),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8, right: 8, bottom: 8),
          child: CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.88),
            child: IconButton(
              onPressed: _shareArtisan,
              icon: const Icon(
                Icons.share_rounded,
                color: Color(0xFF111827),
              ),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: _heroTag,
              child: (_artisan.hasImage &&
                      _artisan.imageOrPlaceholder.trim().isNotEmpty)
                  ? Image.network(
                      _artisan.imageOrPlaceholder,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                    )
                  : _buildPlaceholderImage(),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.18),
                      Colors.black.withOpacity(0.12),
                      Colors.black.withOpacity(0.62),
                    ],
                  ),
                ),
              ),
            ),
            if (_artisan.sponsorise)
              Positioned(
                left: 16,
                top: 110,
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
                  ),
                  child: const Text(
                    'Sponsorisé',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _artisan.nom,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _artisan.metier.isNotEmpty
                        ? _artisan.metier
                        : 'Métier',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _artisan.localisation.isNotEmpty
                        ? _artisan.localisation
                        : 'Localisation inconnue',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.18),
                      ),
                    ),
                    child: Text(
                      contactVisible
                          ? 'Contact débloqué'
                          : 'Débloquer le contact • 500 FCFA',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: const Color(0xFFEFF3FF),
      child: const Center(
        child: Icon(
          Icons.handyman_rounded,
          size: 68,
          color: Color(0xFF8EA2E8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contactVisible = _artisan.contactVisible;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      bottomNavigationBar: _buildActionBar(contactVisible),
      body: _isLoadingClientInfos
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                _buildHeroHeader(contactVisible),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Column(
                      children: [
                        _buildCountdownCard(),
                        if (contactVisible && _timeLeft != null)
                          const SizedBox(height: 18),
                        _buildContactCard(contactVisible),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}