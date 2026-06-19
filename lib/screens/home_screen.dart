import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/advertisement.dart';
import '../models/artisan.dart';
import '../models/residence.dart';
import '../services/api_service.dart';
import '../widgets/ad_banner_widget.dart';
import '../widgets/artisan_card.dart';
import '../widgets/residence_card.dart';
import 'ads_screen.dart';
import 'artisan_detail_screen.dart';
import 'artisans_screen.dart';
import 'dashboard_screen.dart';
import 'favorites_screen.dart';
import 'login_screen.dart';
import 'residence_detail_screen.dart';
import 'residences_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();

  late Future<List<Residence>> _futureResidences;
  late Future<List<Artisan>> _futureArtisans;
  late Future<List<Advertisement>> _futureAds;

  static const Color _bg = Color(0xFFF6F7FB);
  static const Color _surface = Colors.white;
  static const Color _text = Color(0xFF111827);
  static const Color _subtext = Color(0xFF6B7280);
  static const Color _line = Color(0xFFE7EAF1);

  static const Color _navy = Color(0xFF0F172A);
  static const Color _primary = Color(0xFF1D4ED8);
  static const Color _primarySoft = Color(0xFFEAF1FF);
  static const Color _gold = Color(0xFFD4A94D);
  static const Color _greenSoft = Color(0xFFEAFBF3);

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  void _loadAllData() {
    _futureResidences = _apiService.getResidences();
    _futureArtisans = _apiService.getArtisans();
    _futureAds = _apiService.getAdvertisements();
  }

  Future<void> _refreshData() async {
    setState(_loadAllData);

    await Future.wait([
      _futureResidences,
      _futureArtisans,
      _futureAds,
    ]);
  }

  Future<bool> _isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_logged_in') ?? false;
  }

  Future<void> _openProfileArea() async {
    final loggedIn = await _isLoggedIn();
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => loggedIn ? const DashboardScreen() : const LoginScreen(),
      ),
    );
  }

  Future<void> _openPublish() async {
    final loggedIn = await _isLoggedIn();
    if (!mounted) return;

    if (loggedIn) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Connecte-toi pour publier une annonce'),
      ),
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _openFavorites() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FavoritesScreen()),
    );
  }

  List<T> _uniqueById<T>(
    List<T> items,
    int Function(T item) getId,
  ) {
    final Map<int, T> map = <int, T>{};

    for (final T item in items) {
      final int id = getId(item);
      if (id != 0) {
        map[id] = item;
      }
    }

    return map.values.toList();
  }

  String _safeString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  String _extractResidenceImage(Residence residence) {
    try {
      final dynamic rawResidence = residence;
      final dynamic rawImages = rawResidence.images;

      if (rawImages is List && rawImages.isNotEmpty) {
        final first = rawImages.first?.toString() ?? '';
        if (first.trim().isNotEmpty) return first.trim();
      }
    } catch (_) {}

    try {
      final dynamic rawResidence = residence;
      final dynamic rawImage = rawResidence.image;
      if (rawImage != null && rawImage.toString().trim().isNotEmpty) {
        return rawImage.toString().trim();
      }
    } catch (_) {}

    return '';
  }

  Residence? _pickFeaturedResidence(List<Residence> residences) {
    if (residences.isEmpty) return null;

    final List<Residence> sponsored =
        residences.where((Residence e) => e.isSponsored).toList();

    if (sponsored.isNotEmpty) return sponsored.first;
    return residences.first;
  }

  String _formatPrice(dynamic price) {
    final value = _safeString(price);
    if (value.isEmpty) return 'Prix sur demande';
    return '$value FCFA';
  }

  void _openResidenceDetail(Residence residence) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResidenceDetailScreen(residence: residence),
      ),
    );
  }

  void _openArtisanDetail(Artisan artisan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ArtisanDetailScreen(artisan: artisan),
      ),
    );
  }

  List<Advertisement> _extractActiveHomeAds(List<Advertisement> ads) {
    final List<Advertisement> activeAds = ads
        .where((Advertisement item) => item.actif)
        .toList();

    final List<Advertisement> homeAds = activeAds
        .where(
          (Advertisement item) =>
              item.position.toLowerCase().trim() == 'home',
        )
        .toList();

    return homeAds.isNotEmpty ? homeAds : activeAds;
  }

  Widget _buildSmartResidenceList(
    List<Residence> residences,
    List<Advertisement> ads,
  ) {
    const int adInterval = 4;

    if (residences.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: List.generate(residences.length, (index) {
        final List<Widget> children = [];

        final Residence residence = residences[index];

        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: ResidenceCard(
              residence: residence,
              onTap: () => _openResidenceDetail(residence),
            ),
          ),
        );

        final bool shouldInsertAd =
            ads.isNotEmpty &&
            (index + 1) % adInterval == 0 &&
            index != residences.length - 1;

        if (shouldInsertAd) {
          final int adIndex = ((index + 1) ~/ adInterval - 1) % ads.length;
          final Advertisement ad = ads[adIndex];

          children.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: AdBannerWidget(
                  advertisement: ad,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdsScreen()),
                    );
                  },
                ),
              ),
            ),
          );
        }

        return Column(children: children);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          const _PremiumBackground(),
          SafeArea(
            child: RefreshIndicator(
              color: _primary,
              onRefresh: _refreshData,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fadeSlide(delay: 0, child: _buildTopBar()),
                          const SizedBox(height: 16),
                          _fadeSlide(delay: 40, child: _buildHeroSection()),
                          const SizedBox(height: 22),
                          _fadeSlide(delay: 80, child: _buildQuickAccess()),
                          const SizedBox(height: 28),
                          _fadeSlide(delay: 120, child: _buildResidencesSection()),
                          const SizedBox(height: 30),
                          _fadeSlide(delay: 160, child: _buildArtisansSection()),
                          const SizedBox(height: 30),
                          _fadeSlide(delay: 200, child: _buildAdSection()),
                        ],
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

  Widget _fadeSlide({required int delay, required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        final double offsetY = (1 - value) * 18;
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, offsetY),
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildTopBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Trouvez votre prochain espace',
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.playfairDisplay(
            fontSize: 25,
            fontWeight: FontWeight.w800,
            color: _text,
            letterSpacing: -0.4,
            height: 1.12,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Résidences, artisans et bonnes offres',
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _subtext,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _headerAction({
    required IconData icon,
    required VoidCallback onTap,
    bool filled = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: filled ? _primarySoft : _surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _line),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(icon, color: _navy, size: 22),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF132238),
            Color(0xFF1D4ED8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D4ED8).withOpacity(0.10),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -20,
            child: Container(
              width: 95,
              height: 95,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -25,
            left: -16,
            child: Container(
              width: 75,
              height: 75,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _glassChip(
                    icon: Icons.location_on_outlined,
                    label: 'Côte d’Ivoire',
                  ),
                  _glassChip(
                    icon: Icons.verified_outlined,
                    label: 'Annonces visibles',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Trouvez votre espace\nsans perdre de place.',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 27,
                  height: 1.08,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Une présentation plus simple, plus jolie et mieux adaptée aux téléphones.',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.88),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _heroButton(
                      label: 'Explorer',
                      icon: Icons.arrow_outward_rounded,
                      filled: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ResidencesScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _heroButton(
                      label: 'Publier',
                      icon: Icons.add_circle_outline_rounded,
                      filled: false,
                      onTap: _openPublish,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _glassChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroButton({
    required String label,
    required IconData icon,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          height: 48,
          decoration: BoxDecoration(
            color: filled ? Colors.white : Colors.white.withOpacity(0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: filled ? Colors.white : Colors.white.withOpacity(0.16),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: filled ? _navy : Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Icon(
                icon,
                size: 17,
                color: filled ? _navy : Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionEyebrow(String text) {
    return Text(
      text.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: _primary,
        letterSpacing: 1.3,
      ),
    );
  }

  Widget _buildQuickAccess() {
    final List<Map<String, dynamic>> items = [
      {
        'icon': Icons.apartment_rounded,
        'title': 'Résidences',
        'subtitle': 'Explorer',
        'color1': const Color(0xFF315CF4),
        'color2': const Color(0xFF6D8CFF),
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ResidencesScreen()),
          );
        },
      },
      {
        'icon': Icons.handyman_rounded,
        'title': 'Artisans',
        'subtitle': 'Trouver',
        'color1': const Color(0xFF0E9F8B),
        'color2': const Color(0xFF25C5B5),
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ArtisansScreen()),
          );
        },
      },
      {
        'icon': Icons.campaign_rounded,
        'title': 'Offres',
        'subtitle': 'Voir',
        'color1': const Color(0xFFF59E0B),
        'color2': const Color(0xFFFFC24B),
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdsScreen()),
          );
        },
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionEyebrow('Navigation'),
        const SizedBox(height: 6),
        Text(
          'Accès rapide',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _text,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Une navigation simple, jolie et plus légère.',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: _subtext,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: items.map((Map<String, dynamic> item) {
            final bool isLast = item == items.last;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: isLast ? 0 : 10),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: item['onTap'] as VoidCallback,
                    child: Ink(
                      padding: const EdgeInsets.fromLTRB(10, 14, 10, 14),
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: _line),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 14,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  item['color1'] as Color,
                                  item['color2'] as Color,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (item['color1'] as Color).withOpacity(0.24),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Icon(
                              item['icon'] as IconData,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            item['title'] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: _text,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['subtitle'] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _subtext,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required String eyebrow,
    required String title,
    required String subtitle,
    required String actionText,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _line),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(icon, color: _navy, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionEyebrow(eyebrow),
              const SizedBox(height: 4),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _text,
                  height: 1.08,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: _subtext,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            actionText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: _primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResidencesSection() {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait<dynamic>([
        _futureResidences,
        _futureAds,
      ]),
      builder: (context, snapshot) {
        final List<Residence> residences = snapshot.hasData
            ? _uniqueById<Residence>(
                (snapshot.data![0] as List<Residence>),
                (Residence item) => item.id,
              )
            : <Residence>[];

        final List<Advertisement> ads = snapshot.hasData
            ? _uniqueById<Advertisement>(
                (snapshot.data![1] as List<Advertisement>),
                (Advertisement item) => item.id,
              )
            : <Advertisement>[];

        final List<Advertisement> displayedAds = _extractActiveHomeAds(ads);

        final Residence? featured = _pickFeaturedResidence(residences);
        final List<Residence> secondary = residences
            .where((Residence e) => e.id != featured?.id)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              eyebrow: 'Sélection',
              title: 'Résidences du moment',
              subtitle: 'Des biens mis en avant avec une présentation plus propre.',
              actionText: 'Voir tout',
              icon: Icons.home_work_rounded,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ResidencesScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            if (snapshot.connectionState == ConnectionState.waiting)
              _buildResidenceLoadingList()
            else if (snapshot.hasError)
              _buildMessageCard(
                title: 'Impossible de charger les résidences',
                subtitle: 'Tire vers le bas pour actualiser la page.',
                icon: Icons.wifi_off_rounded,
                accent: _primarySoft,
              )
            else if (featured == null)
              _buildLuxuryEmptyCard(
                icon: Icons.search_off_rounded,
                title: 'Aucune résidence trouvée',
                subtitle: 'Aucune résidence pour le moment.',
                actionLabel: 'Voir les annonces',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ResidencesScreen(),
                    ),
                  );
                },
              )
            else
              Column(
                children: [
                  _buildFeaturedResidenceCard(featured),
                  if (secondary.isNotEmpty) const SizedBox(height: 16),
                  _buildSmartResidenceList(secondary, displayedAds),
                ],
              ),
          ],
        );
      },
    );
  }

  Widget _buildFeaturedResidenceCard(Residence residence) {
    final String imageUrl = _extractResidenceImage(residence);
    final dynamic r = residence;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () => _openResidenceDetail(residence),
        child: Ink(
          height: 330,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 22,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                Positioned.fill(
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            return _buildResidenceFallbackImage();
                          },
                        )
                      : _buildResidenceFallbackImage(),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
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
                Positioned(
                  left: 14,
                  top: 14,
                  child: _floatingBadge(
                    label: residence.isSponsored ? 'Premium' : 'Sélection',
                    background: residence.isSponsored
                        ? _gold.withOpacity(0.95)
                        : Colors.white.withOpacity(0.92),
                    foreground: residence.isSponsored ? Colors.white : _navy,
                    icon: residence.isSponsored
                        ? Icons.workspace_premium_rounded
                        : Icons.auto_awesome_rounded,
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.14),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _safeString(r.titre).isEmpty
                              ? 'Résidence'
                              : _safeString(r.titre),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.playfairDisplay(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            height: 1.08,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 15,
                              color: Colors.white.withOpacity(0.88),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${_safeString(r.ville)} • ${_safeString(r.quartier)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: Colors.white.withOpacity(0.88),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 11,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.10),
                                  ),
                                ),
                                child: Text(
                                  _formatPrice(r.prix),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                'Voir',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: _navy,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _floatingBadge({
    required String label,
    required Color background,
    required Color foreground,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: foreground, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResidenceFallbackImage() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFEDF3FF),
            Color(0xFFD9E5FF),
            Color(0xFFBFD2FF),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.30),
              ),
            ),
          ),
          Positioned(
            bottom: -15,
            left: -15,
            child: Container(
              width: 85,
              height: 85,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.22),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.home_work_rounded,
                color: _primary,
                size: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtisansSection() {
    return FutureBuilder<List<Artisan>>(
      future: _futureArtisans,
      builder: (context, snapshot) {
        final List<Artisan> data = _uniqueById<Artisan>(
          snapshot.data ?? <Artisan>[],
          (Artisan item) => item.id,
        );

        final List<Artisan> sponsored = data
            .where((Artisan item) => item.sponsorise)
            .take(3)
            .toList();

        final List<Artisan> fallback = data.take(3).toList();
        final List<Artisan> displayed =
            sponsored.isNotEmpty ? sponsored : fallback;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              eyebrow: 'Réseau',
              title: 'Artisans de confiance',
              subtitle: 'Des profils sérieux mis en avant avec plus de clarté.',
              actionText: 'Voir tout',
              icon: Icons.handyman_rounded,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ArtisansScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            if (snapshot.connectionState == ConnectionState.waiting)
              _buildArtisanLoadingList()
            else if (snapshot.hasError)
              _buildMessageCard(
                title: 'Impossible de charger les artisans',
                subtitle: 'Réessaie dans quelques instants.',
                icon: Icons.wifi_off_rounded,
                accent: _greenSoft,
              )
            else if (displayed.isEmpty)
              _buildLuxuryEmptyCard(
                icon: Icons.search_off_rounded,
                title: 'Aucun artisan trouvé',
                subtitle: 'Aucun artisan disponible actuellement.',
                actionLabel: 'Voir les artisans',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ArtisansScreen(),
                    ),
                  );
                },
              )
            else
              Column(
                children: displayed.map((Artisan artisan) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: ArtisanCard(
                      artisan: artisan,
                      onTap: () => _openArtisanDetail(artisan),
                    ),
                  );
                }).toList(),
              ),
          ],
        );
      },
    );
  }

  Widget _buildAdSection() {
    return FutureBuilder<List<Advertisement>>(
      future: _futureAds,
      builder: (context, snapshot) {
        final List<Advertisement> data = _uniqueById<Advertisement>(
          snapshot.data ?? <Advertisement>[],
          (Advertisement item) => item.id,
        );

        final List<Advertisement> activeAds = data
            .where((Advertisement item) => item.actif)
            .toList();

        final List<Advertisement> homeAds = activeAds
            .where(
              (Advertisement item) => item.position.toLowerCase() == 'home',
            )
            .toList();

        final Advertisement? displayed = homeAds.isNotEmpty
            ? homeAds.first
            : (activeAds.isNotEmpty ? activeAds.first : null);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              eyebrow: 'Visibilité',
              title: 'À ne pas manquer',
              subtitle: 'Offres sponsorisées et campagnes mises en avant.',
              actionText: 'Voir tout',
              icon: Icons.local_fire_department_rounded,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdsScreen()),
                );
              },
            ),
            const SizedBox(height: 18),
            if (snapshot.connectionState == ConnectionState.waiting)
              _buildAdLoadingCard()
            else if (snapshot.hasError)
              _buildMessageCard(
                title: 'Impossible de charger les offres',
                subtitle: 'Réessaie plus tard.',
                icon: Icons.wifi_off_rounded,
                accent: const Color(0xFFFFF4E5),
              )
            else if (displayed == null)
              _buildLuxuryEmptyCard(
                icon: Icons.campaign_rounded,
                title: 'Aucune offre active pour le moment',
                subtitle:
                    'Les publicités premium seront visibles ici quand elles seront disponibles.',
                actionLabel: 'Voir les offres',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdsScreen()),
                  );
                },
              )
            else
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: AdBannerWidget(
                  advertisement: displayed,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdsScreen()),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMessageCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: _navy),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _text,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _subtext,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLuxuryEmptyCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEAF1FF), Color(0xFFF7FAFF)],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(icon, color: _primary, size: 34),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _subtext,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 18),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: Ink(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                decoration: BoxDecoration(
                  color: _navy,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  actionLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResidenceLoadingList() {
    return Column(
      children: [
        const _PremiumFeaturedSkeleton(),
        const SizedBox(height: 16),
        ...List.generate(
          2,
          (index) => const Padding(
            padding: EdgeInsets.only(bottom: 14),
            child: _PremiumSkeletonCard(
              height: 142,
              hasImage: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildArtisanLoadingList() {
    return Column(
      children: List.generate(
        3,
        (index) => const Padding(
          padding: EdgeInsets.only(bottom: 14),
          child: _PremiumSkeletonCard(
            height: 158,
            hasImage: true,
          ),
        ),
      ),
    );
  }

  Widget _buildAdLoadingCard() {
    return const _PremiumAdSkeleton();
  }
}

class _PremiumBackground extends StatelessWidget {
  const _PremiumBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -90,
          left: -70,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1D4ED8).withOpacity(0.04),
            ),
          ),
        ),
        Positioned(
          top: 240,
          right: -80,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFBBD0FF).withOpacity(0.14),
            ),
          ),
        ),
        Positioned(
          bottom: 140,
          left: -45,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFF0D8).withOpacity(0.26),
            ),
          ),
        ),
      ],
    );
  }
}

class _PremiumFeaturedSkeleton extends StatefulWidget {
  const _PremiumFeaturedSkeleton();

  @override
  State<_PremiumFeaturedSkeleton> createState() =>
      _PremiumFeaturedSkeletonState();
}

class _PremiumFeaturedSkeletonState extends State<_PremiumFeaturedSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  LinearGradient get _shimmerGradient {
    return LinearGradient(
      begin: const Alignment(-1.6, -0.3),
      end: const Alignment(1.6, 0.3),
      colors: const [
        Color(0xFFF2F4F7),
        Color(0xFFFAFBFF),
        Color(0xFFEDEFF5),
      ],
      stops: const [0.1, 0.45, 0.9],
      transform: _SlidingGradientTransform(_controller.value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          height: 330,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: _shimmerGradient,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _line(width: 100, height: 28),
                const Spacer(),
                _line(width: 220, height: 24),
                const SizedBox(height: 10),
                _line(width: 160, height: 12),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _line(width: double.infinity, height: 42)),
                    const SizedBox(width: 12),
                    _line(width: 88, height: 42),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _line({required double width, required double height}) {
    return Container(
      width: width == double.infinity ? double.infinity : width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.72),
        borderRadius: BorderRadius.circular(30),
      ),
    );
  }
}

class _PremiumSkeletonCard extends StatefulWidget {
  final double height;
  final bool hasImage;

  const _PremiumSkeletonCard({
    required this.height,
    this.hasImage = false,
  });

  @override
  State<_PremiumSkeletonCard> createState() => _PremiumSkeletonCardState();
}

class _PremiumSkeletonCardState extends State<_PremiumSkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  LinearGradient get _shimmerGradient {
    return LinearGradient(
      begin: const Alignment(-1.6, -0.3),
      end: const Alignment(1.6, 0.3),
      colors: const [
        Color(0xFFF2F4F7),
        Color(0xFFFAFBFF),
        Color(0xFFEDEFF5),
      ],
      stops: const [0.1, 0.45, 0.9],
      transform: _SlidingGradientTransform(_controller.value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          height: widget.height,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: _shimmerGradient,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: widget.hasImage
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 70,
                        height: widget.height - 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.60),
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: SizedBox(
                          height: widget.height - 32,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _line(width: 120, height: 14),
                              const SizedBox(height: 8),
                              _line(width: 85, height: 10),
                              const SizedBox(height: 8),
                              _line(width: double.infinity, height: 10),
                              const SizedBox(height: 8),
                              _line(width: 140, height: 10),
                              const SizedBox(height: 12),
                              _line(width: double.infinity, height: 30),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _line(width: 160, height: 18),
                      const SizedBox(height: 10),
                      _line(width: double.infinity, height: 10),
                      const SizedBox(height: 8),
                      _line(width: 190, height: 10),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _line({required double width, required double height}) {
    return Container(
      width: width == double.infinity ? double.infinity : width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.70),
        borderRadius: BorderRadius.circular(30),
      ),
    );
  }
}

class _PremiumAdSkeleton extends StatefulWidget {
  const _PremiumAdSkeleton();

  @override
  State<_PremiumAdSkeleton> createState() => _PremiumAdSkeletonState();
}

class _PremiumAdSkeletonState extends State<_PremiumAdSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  LinearGradient get _shimmerGradient {
    return LinearGradient(
      begin: const Alignment(-1.4, -0.2),
      end: const Alignment(1.4, 0.2),
      colors: const [
        Color(0xFFF2F4F7),
        Color(0xFFFAFBFF),
        Color(0xFFEDEFF5),
      ],
      stops: const [0.1, 0.45, 0.9],
      transform: _SlidingGradientTransform(_controller.value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: _shimmerGradient,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            children: [
              Container(
                height: 210,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.60),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sLine(width: 100, height: 12),
                    const SizedBox(height: 16),
                    _sLine(width: 220, height: 20),
                    const SizedBox(height: 12),
                    _sLine(width: double.infinity, height: 12),
                    const SizedBox(height: 8),
                    _sLine(width: 180, height: 12),
                    const SizedBox(height: 16),
                    _sLine(width: 110, height: 14),
                    const SizedBox(height: 18),
                    _sLine(width: double.infinity, height: 50),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sLine({required double width, required double height}) {
    return Container(
      width: width == double.infinity ? double.infinity : width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.70),
        borderRadius: BorderRadius.circular(30),
      ),
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlidingGradientTransform(this.slidePercent);

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(
      bounds.width * (slidePercent * 2 - 1),
      0,
      0,
    );
  }
}