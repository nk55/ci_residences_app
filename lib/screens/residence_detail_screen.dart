import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/residence.dart';
import '../services/favorites_service.dart';
import '../utils/launcher_helper.dart';

class ResidenceDetailScreen extends StatefulWidget {
  final Residence residence;

  const ResidenceDetailScreen({
    super.key,
    required this.residence,
  });

  @override
  State<ResidenceDetailScreen> createState() => _ResidenceDetailScreenState();
}

class _ResidenceDetailScreenState extends State<ResidenceDetailScreen> {
  int _currentImageIndex = 0;
  bool _isFavorite = false;

  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadFavorite();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorite() async {
    final fav = await FavoritesService.isFavorite(
      widget.residence.id.toString(),
    );

    if (!mounted) return;

    setState(() {
      _isFavorite = fav;
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
          fav
              ? 'Résidence ajoutée aux favoris'
              : 'Résidence retirée des favoris',
        ),
      ),
    );
  }

  String _formatPrice(dynamic prix) {
    if (prix == null) return 'Prix indisponible';

    final cleaned = prix
        .toString()
        .replaceAll(' ', '')
        .replaceAll(',', '')
        .trim();

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

  String _cleanPhone(String? phone) {
    if (phone == null) return '';
    return phone.trim().replaceAll(' ', '');
  }

  String _buildWhatsAppMessage(Residence residence) {
    return 'Bonjour, je suis intéressé par la résidence ${residence.titre} située à ${residence.quartier}, ${residence.ville}. Est-elle toujours disponible ?';
  }

  String get _heroTag => 'residence-image-${widget.residence.id}';

  void _openGallery(List<String> images, int initialIndex) {
    if (images.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenGallery(
          images: images,
          initialIndex: initialIndex,
          heroTagPrefix: _heroTag,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final residence = widget.residence;
    final images = residence.images;

    final phoneNumber = _cleanPhone(residence.telephone);

    final whatsappNumber = _cleanPhone(
      residence.telephoneWhatsApp.isNotEmpty
          ? residence.telephoneWhatsApp
          : residence.telephone,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 18,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Contacter le propriétaire',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () async {
                        if (whatsappNumber.isEmpty) {
                          _showError(context, 'Numéro WhatsApp non disponible');
                          return;
                        }

                        try {
                          await LauncherHelper.openWhatsApp(
                            whatsappNumber,
                            message: _buildWhatsAppMessage(residence),
                          );
                        } catch (e) {
                          _showError(context, 'Impossible d’ouvrir WhatsApp');
                        }
                      },
                      icon: const Icon(Icons.chat_bubble_outline_rounded),
                      label: const Text(
                        'WhatsApp',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF243B8F),
                        side: const BorderSide(color: Color(0xFF243B8F)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () async {
                        if (phoneNumber.isEmpty) {
                          _showError(context, 'Numéro d’appel non disponible');
                          return;
                        }

                        try {
                          await LauncherHelper.callPhone(phoneNumber);
                        } catch (e) {
                          _showError(context, 'Impossible de lancer l’appel');
                        }
                      },
                      icon: const Icon(Icons.call_outlined),
                      label: const Text(
                        'Appeler',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.black,
            expandedHeight: 360,
            pinned: true,
            elevation: 0,
            automaticallyImplyLeading: false,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.90),
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
                  backgroundColor: Colors.white.withOpacity(0.90),
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
                  backgroundColor: Colors.white.withOpacity(0.90),
                  child: IconButton(
                    onPressed: () {
                      Share.share(
                        'Découvrez cette résidence : ${residence.titre}\n'
                        '${residence.ville} - ${residence.quartier}\n'
                        'Prix : ${_formatPrice(residence.prix)}',
                      );
                    },
                    icon: const Icon(
                      Icons.share_outlined,
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
                  if (images.isNotEmpty)
                    PageView.builder(
                      controller: _pageController,
                      itemCount: images.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentImageIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => _openGallery(images, index),
                          child: Hero(
                            tag: '${_heroTag}_$index',
                            child: Image.network(
                              images[index],
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: 54,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  else
                    Hero(
                      tag: '${_heroTag}_empty',
                      child: Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(Icons.home, size: 54),
                        ),
                      ),
                    ),

                  // IMPORTANT :
                  // IgnorePointer empêche cette couche de bloquer le swipe du PageView
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.15),
                              Colors.black.withOpacity(0.10),
                              Colors.black.withOpacity(0.60),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  if (residence.isSponsored)
                    Positioned(
                      left: 16,
                      top: 110,
                      child: IgnorePointer(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF9A1F), Color(0xFFFF6A00)],
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
                    ),

                  Positioned(
                    right: 16,
                    top: 110,
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.48),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          images.isEmpty
                              ? '0/0'
                              : '${_currentImageIndex + 1}/${images.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),

                  if (images.length > 1)
                    Positioned(
                      bottom: 92,
                      left: 0,
                      right: 0,
                      child: IgnorePointer(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(images.length, (index) {
                            final isActive = _currentImageIndex == index;

                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 280),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: isActive ? 18 : 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color:
                                    isActive ? Colors.white : Colors.white54,
                                borderRadius: BorderRadius.circular(20),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),

                  Positioned(
                    left: 18,
                    right: 18,
                    bottom: 18,
                    child: IgnorePointer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            residence.titre,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${residence.type} • ${residence.ville} • ${residence.quartier}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14.5,
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
                              _formatPrice(residence.prix),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuickInfos(residence),
                  const SizedBox(height: 18),
                  _buildBookingCard(residence),
                  const SizedBox(height: 18),
                  _buildHighlightCard(
                    title: 'Ce logement vous rassure',
                    items: const [
                      DetailHighlight(
                        icon: Icons.chat_bubble_outline_rounded,
                        iconBg: Color(0xFFDDF7E8),
                        iconColor: Color(0xFF129B52),
                        title: 'Contact direct',
                        subtitle: 'Réservez rapidement avec WhatsApp.',
                      ),
                      DetailHighlight(
                        icon: Icons.flash_on_outlined,
                        iconBg: Color(0xFFE4ECFF),
                        iconColor: Color(0xFF315EFB),
                        title: 'Réponse rapide',
                        subtitle: 'Une prise de contact simple et efficace.',
                      ),
                      DetailHighlight(
                        icon: Icons.workspace_premium_outlined,
                        iconBg: Color(0xFFFFF0CC),
                        iconColor: Color(0xFFCC8A00),
                        title: 'Présentation premium',
                        subtitle:
                            'Un bien valorisé avec un style plus haut de gamme.',
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _buildBlock(
                    title: 'À propos de ce logement',
                    child: Text(
                      residence.description.isNotEmpty
                          ? residence.description
                          : 'Résidence meublée, cadre agréable, réservation rapide, contact direct sur WhatsApp et par appel.',
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.7,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildSleepCard(images),
                  const SizedBox(height: 18),
                  _buildEquipmentsCard(residence),
                  const SizedBox(height: 18),
                  _buildBlock(
                    title: 'Adresse',
                    child: Text(
                      residence.adresse.isNotEmpty
                          ? residence.adresse
                          : '${residence.quartier}, ${residence.ville}',
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInfos(Residence residence) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${residence.type} • ${residence.quartier}, ${residence.ville}',
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${residence.capacite} personnes • Hébergement premium • Réservation rapide',
            style: const TextStyle(
              fontSize: 14.5,
              color: Color(0xFF475569),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          const Divider(height: 1),
          const SizedBox(height: 18),
          const _FeatureRow(
            icon: Icons.workspace_premium_outlined,
            iconBg: Color(0xFFE8EEFF),
            iconColor: Color(0xFF315EFB),
            title: 'Coup de cœur voyageurs',
            subtitle:
                'Une résidence présentée dans un style plus rassurant, plus élégant et plus premium.',
          ),
          const SizedBox(height: 16),
          const _FeatureRow(
            icon: Icons.chat_bubble_outline_rounded,
            iconBg: Color(0xFFDDF7E8),
            iconColor: Color(0xFF129B52),
            title: 'Réservation simple',
            subtitle:
                'Contact direct sur WhatsApp pour aller vite et réserver sans complication.',
          ),
          const SizedBox(height: 16),
          const _FeatureRow(
            icon: Icons.location_on_outlined,
            iconBg: Color(0xFFE8EEFF),
            iconColor: Color(0xFF315EFB),
            title: 'Bon emplacement',
            subtitle:
                'Un logement situé dans une zone agréable, pratique et rassurante.',
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Residence residence) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                _formatPrice(residence.prix),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              const Text(
                ' / nuit',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
              const Spacer(),
              Row(
                children: const [
                  Icon(Icons.star_rounded, size: 18, color: Color(0xFFF4B400)),
                  SizedBox(width: 4),
                  Text(
                    '5,0',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF374151),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFD1D5DB)),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildBookingCell(
                          title: 'ARRIVÉE',
                          value: 'À convenir',
                        ),
                      ),
                      const VerticalDivider(width: 1, thickness: 1),
                      Expanded(
                        child: _buildBookingCell(
                          title: 'DÉPART',
                          value: 'À convenir',
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1),
                _buildBookingCell(
                  title: 'VOYAGEURS',
                  value: '${residence.capacite} personnes',
                  fullWidth: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE11D74),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () async {
                final whatsappNumber = _cleanPhone(
                  residence.telephoneWhatsApp.isNotEmpty
                      ? residence.telephoneWhatsApp
                      : residence.telephone,
                );

                if (whatsappNumber.isEmpty) {
                  _showError(context, 'Numéro WhatsApp non disponible');
                  return;
                }

                try {
                  await LauncherHelper.openWhatsApp(
                    whatsappNumber,
                    message: _buildWhatsAppMessage(residence),
                  );
                } catch (e) {
                  _showError(context, 'Impossible d’ouvrir WhatsApp');
                }
              },
              child: const Text(
                'Réserver',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Aucun paiement n’est encaissé maintenant.',
            style: TextStyle(
              fontSize: 12.5,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 16),
          _buildPriceLine(
            left: '${_formatPrice(residence.prix)} x 1 nuit',
            right: _formatPrice(residence.prix),
          ),
          const SizedBox(height: 10),
          _buildPriceLine(
            left: 'Frais de service',
            right: 'Inclus',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1),
          ),
          _buildPriceLine(
            left: 'Total',
            right: _formatPrice(residence.prix),
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCell({
    required String title,
    required String value,
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceLine({
    required String left,
    required String right,
    bool bold = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            left,
            style: TextStyle(
              fontSize: 14.5,
              color: const Color(0xFF374151),
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          right,
          style: TextStyle(
            fontSize: 14.5,
            color: const Color(0xFF111827),
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSleepCard(List<String> images) {
    return _buildBlock(
      title: 'Où vous dormirez',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: images.isNotEmpty ? () => _openGallery(images, 0) : null,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 10,
                    child: images.isNotEmpty
                        ? Hero(
                            tag: '${_heroTag}_0',
                            child: Image.network(
                              images.first,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: Icon(Icons.image_not_supported),
                                ),
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Icon(Icons.home_outlined, size: 40),
                            ),
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Espace de vie',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Un cadre confortable pensé pour un séjour agréable.',
                          style: TextStyle(
                            fontSize: 14.5,
                            color: Color(0xFF4B5563),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentsCard(Residence residence) {
    return _buildBlock(
      title: 'Ce que propose ce logement',
      child: Column(
        children: [
          Row(
            children: const [
              Expanded(
                child: _EquipmentItem(
                  icon: Icons.weekend_outlined,
                  text: 'Espace détente',
                ),
              ),
              Expanded(
                child: _EquipmentItem(
                  icon: Icons.bed_outlined,
                  text: 'Chambre',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _EquipmentItem(
                  icon: Icons.people_outline_rounded,
                  text: '${residence.capacite} personnes',
                ),
              ),
              Expanded(
                child: _EquipmentItem(
                  icon: Icons.location_on_outlined,
                  text: residence.ville,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: const [
              Expanded(
                child: _EquipmentItem(
                  icon: Icons.shield_outlined,
                  text: 'Cadre rassurant',
                ),
              ),
              Expanded(
                child: _EquipmentItem(
                  icon: Icons.wifi_outlined,
                  text: 'Connexion et confort',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF111827),
                side: const BorderSide(color: Color(0xFFD1D5DB)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  builder: (_) {
                    return SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Équipements',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _buildInfoChip(
                                  icon: Icons.tv_outlined,
                                  text: 'TV',
                                ),
                                _buildInfoChip(
                                  icon: Icons.kitchen_outlined,
                                  text: 'Cuisine équipée',
                                ),
                                _buildInfoChip(
                                  icon: Icons.ac_unit_outlined,
                                  text: 'Climatisation',
                                ),
                                _buildInfoChip(
                                  icon: Icons.wifi_outlined,
                                  text: 'Internet',
                                ),
                                _buildInfoChip(
                                  icon: Icons.local_parking_outlined,
                                  text: 'Stationnement',
                                ),
                                _buildInfoChip(
                                  icon: Icons.bathtub_outlined,
                                  text: 'Salle de bain',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              child: const Text(
                'Afficher plus d’équipements',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightCard({
    required String title,
    required List<DetailHighlight> items,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: item.iconBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(item.icon, size: 18, color: item.iconColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.subtitle,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF4B5563),
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlock({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF3FF),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: const Color(0xFF243B8F)),
          const SizedBox(width: 7),
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF243B8F),
            ),
          ),
        ],
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _FeatureRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14.5,
                  color: Color(0xFF4B5563),
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EquipmentItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _EquipmentItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF374151)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14.5,
              color: Color(0xFF374151),
            ),
          ),
        ),
      ],
    );
  }
}

class DetailHighlight {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;

  const DetailHighlight({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });
}

class FullScreenGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final String heroTagPrefix;

  const FullScreenGallery({
    super.key,
    required this.images,
    required this.initialIndex,
    required this.heroTagPrefix,
  });

  @override
  State<FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<FullScreenGallery> {
  late final PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: Hero(
                    tag: '${widget.heroTagPrefix}_$index',
                    child: Image.network(
                      widget.images[index],
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.black.withOpacity(0.45),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      '${_currentIndex + 1}/${widget.images.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.images.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 34,
              child: IgnorePointer(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.images.length, (index) {
                    final active = index == _currentIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 18 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: active ? Colors.white : Colors.white54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    );
                  }),
                ),
              ),
            ),
        ],
      ),
    );
  }
}