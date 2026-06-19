import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/residence.dart';
import '../services/favorites_service.dart';

class ResidenceCard extends StatefulWidget {
  final Residence residence;
  final VoidCallback? onTap;

  const ResidenceCard({
    super.key,
    required this.residence,
    this.onTap,
  });

  @override
  State<ResidenceCard> createState() => _ResidenceCardState();
}

class _ResidenceCardState extends State<ResidenceCard> {
  bool _isFavorite = false;
  bool _isLoading = true;

  static const Color _surface = Colors.white;
  static const Color _text = Color(0xFF111827);
  static const Color _primary = Color(0xFF243B8F);

  @override
  void initState() {
    super.initState();
    _loadFavorite();
  }

  Future<void> _loadFavorite() async {
    final fav = await FavoritesService.isFavorite(
      widget.residence.id.toString(),
    );

    if (!mounted) return;

    setState(() {
      _isFavorite = fav;
      _isLoading = false;
    });
  }

  Future<void> _toggleFavorite() async {
    final fav = await FavoritesService.toggleFavorite(
      widget.residence.id.toString(),
    );

    if (!mounted) return;

    setState(() {
      _isFavorite = fav;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          fav ? 'Ajouté aux favoris ❤️' : 'Retiré des favoris',
        ),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatPrice(dynamic prix) {
    if (prix == null) return 'Prix indisponible';

    final cleaned = prix.toString().replaceAll(' ', '').replaceAll(',', '');
    final number = int.tryParse(cleaned);

    if (number == null) return prix.toString();

    return '${_formatNumber(number)} FCFA';
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ' ',
    );
  }

  String _safeText(String? value, {String fallback = ''}) {
    final text = (value ?? '').trim();
    return text.isEmpty ? fallback : text;
  }

  String _locationText(Residence residence) {
    final ville = _safeText(residence.ville);
    final quartier = _safeText(residence.quartier);

    if (ville.isNotEmpty && quartier.isNotEmpty) {
      return '$ville • $quartier';
    }
    if (ville.isNotEmpty) return ville;
    if (quartier.isNotEmpty) return quartier;
    return 'Localisation inconnue';
  }

  String _extractImageUrl(Residence residence) {
    if (residence.images.isNotEmpty) {
      final first = residence.images.first.trim();
      if (first.isNotEmpty) return first;
    }

    try {
      final dynamic rawResidence = residence;
      final dynamic rawImage = rawResidence.image;
      if (rawImage != null && rawImage.toString().trim().isNotEmpty) {
        return rawImage.toString().trim();
      }
    } catch (_) {}

    return '';
  }

  String get _heroTag => 'residence-image-${widget.residence.id}';

  @override
  Widget build(BuildContext context) {
    final residence = widget.residence;
    final imageUrl = _extractImageUrl(residence);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: widget.onTap,
        child: Ink(
          height: 255,
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Hero(
                    tag: _heroTag,
                    child: imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            fadeInDuration: const Duration(milliseconds: 220),
                            placeholder: (context, url) => _buildImageLoading(),
                            errorWidget: (context, url, error) =>
                                _buildFallbackImage(),
                          )
                        : _buildFallbackImage(),
                  ),
                ),

                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.03),
                            Colors.black.withOpacity(0.10),
                            Colors.black.withOpacity(0.65),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                Positioned(
                  top: 16,
                  left: 16,
                  child: IgnorePointer(
                    child: _buildSelectionBadge(),
                  ),
                ),

                Positioned(
                  top: 16,
                  right: 16,
                  child: _buildFavoriteButton(),
                ),

                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: IgnorePointer(
                    child: _buildBottomOverlay(residence),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionBadge() {
    final bool isSponsored = widget.residence.isSponsored;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isSponsored
            ? const Color(0xFFFFF4DE)
            : Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSponsored ? Icons.workspace_premium_rounded : Icons.auto_awesome,
            size: 14,
            color: const Color(0xFF111827),
          ),
          const SizedBox(width: 6),
          Text(
            isSponsored ? 'Sponsorisé' : 'Sélection',
            style: GoogleFonts.inter(
              color: const Color(0xFF111827),
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteButton() {
    if (_isLoading) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          shape: BoxShape.circle,
        ),
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return GestureDetector(
      onTap: _toggleFavorite,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          shape: BoxShape.circle,
        ),
        child: AnimatedScale(
          scale: _isFavorite ? 1.12 : 1,
          duration: const Duration(milliseconds: 180),
          child: Icon(
            _isFavorite
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            color: _isFavorite ? Colors.red : _text,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomOverlay(Residence residence) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _safeText(residence.titre, fallback: 'SANS TITRE').toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.playfairDisplay(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.location_on_rounded,
                size: 15,
                color: Colors.white70,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _locationText(residence),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildPriceCapsule(_formatPrice(residence.prix)),
              ),
              const SizedBox(width: 12),
              _buildVoirCapsule(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCapsule(String price) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.18),
            ),
          ),
          child: Text(
            price,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 14.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVoirCapsule() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Voir',
        style: GoogleFonts.inter(
          color: const Color(0xFF111827),
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildImageLoading() {
    return Container(
      color: const Color(0xFFF3F4F6),
      child: Center(
        child: Container(
          width: 40,
          height: 40,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.90),
            shape: BoxShape.circle,
          ),
          child: const CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackImage() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFEAF1FF),
            Color(0xFFDCE7FF),
            Color(0xFFC8D8FF),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -18,
            right: -18,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.26),
              ),
            ),
          ),
          Positioned(
            bottom: -12,
            left: -12,
            child: Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.18),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.home_work_rounded,
                size: 38,
                color: _primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}