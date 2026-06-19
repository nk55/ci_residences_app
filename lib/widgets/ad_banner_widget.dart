import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/advertisement.dart';

class AdBannerWidget extends StatelessWidget {
  final Advertisement advertisement;
  final VoidCallback? onTap;

  const AdBannerWidget({
    super.key,
    required this.advertisement,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFFFFF),
                Color(0xFFF8FAFF),
                Color(0xFFF3F6FF),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageSection(),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopRow(),
                    const SizedBox(height: 14),
                    Text(
                      advertisement.titre.trim().isNotEmpty
                          ? advertisement.titre
                          : 'Offre sponsorisée',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.playfairDisplay(
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        color: const Color(0xFF111827),
                        letterSpacing: -0.3,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      advertisement.description.trim().isNotEmpty
                          ? advertisement.description
                          : 'Découvrez cette offre exclusive mise en avant dans l’application.',
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF374151),
                        fontSize: 14,
                        height: 1.65,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF3FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.category_rounded,
                            size: 16,
                            color: Color(0xFF243B8F),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              advertisement.type.trim().isNotEmpty
                                  ? advertisement.type
                                  : 'Publicité',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF243B8F),
                                fontWeight: FontWeight.w700,
                                fontSize: 12.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildCtaRow(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Stack(
      children: [
        SizedBox(
          height: 210,
          width: double.infinity,
          child: advertisement.image.trim().isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: advertisement.image.trim(),
                  fit: BoxFit.cover,
                  fadeInDuration: const Duration(milliseconds: 250),
                  placeholder: (context, url) => _buildImageLoading(),
                  errorWidget: (context, url, error) => _buildImageFallback(),
                )
              : _buildImageFallback(),
        ),
        Positioned(
          top: 14,
          left: 14,
          child: _buildSponsoredBadge(),
        ),
      ],
    );
  }

  Widget _buildImageLoading() {
    return Container(
      height: 210,
      width: double.infinity,
      color: const Color(0xFFF3F4F6),
      child: Center(
        child: Container(
          width: 44,
          height: 44,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.90),
            shape: BoxShape.circle,
          ),
          child: const CircularProgressIndicator(
            strokeWidth: 2.3,
          ),
        ),
      ),
    );
  }

  Widget _buildImageFallback() {
    return Container(
      height: 210,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF243B8F),
            Color(0xFF425FD1),
            Color(0xFF6B86FF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -18,
            right: -12,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.10),
              ),
            ),
          ),
          Positioned(
            bottom: -24,
            left: -16,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.16),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.15),
                ),
              ),
              child: const Icon(
                Icons.campaign_rounded,
                size: 38,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSponsoredBadge() {
    return Container(
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
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        'Sponsorisé',
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 11.5,
        ),
      ),
    );
  }

  Widget _buildTopRow() {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFEEF3FF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: Color(0xFF243B8F),
            size: 20,
          ),
        ),
        const Spacer(),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.open_in_new_rounded,
            size: 18,
            color: Color(0xFF243B8F),
          ),
        ),
      ],
    );
  }

  Widget _buildCtaRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF243B8F),
            Color(0xFF334FC1),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33243B8F),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.touch_app_rounded,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Touchez pour découvrir cette offre',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13.8,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}