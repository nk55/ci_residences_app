import 'package:flutter/material.dart';

import '../models/artisan.dart';
import '../services/api_service.dart';
import '../widgets/artisan_card.dart';
import 'artisan_detail_screen.dart';

class ArtisansScreen extends StatefulWidget {
  const ArtisansScreen({super.key});

  @override
  State<ArtisansScreen> createState() => _ArtisansScreenState();
}

class _ArtisansScreenState extends State<ArtisansScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Artisan>> _futureArtisans;

  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _futureArtisans = _apiService.getArtisans();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _reloadArtisans() async {
    setState(() {
      _futureArtisans = _apiService.getArtisans();
    });
    await _futureArtisans;
  }

  List<Artisan> _filterArtisans(List<Artisan> artisans) {
    final query = _searchText.toLowerCase().trim();

    if (query.isEmpty) {
      return _sortArtisans(artisans);
    }

    return _sortArtisans(
      artisans.where((a) {
        return a.nom.toLowerCase().contains(query) ||
            a.metier.toLowerCase().contains(query) ||
            a.ville.toLowerCase().contains(query) ||
            a.quartier.toLowerCase().contains(query);
      }).toList(),
    );
  }

  List<Artisan> _sortArtisans(List<Artisan> artisans) {
    final sorted = List<Artisan>.from(artisans);

    sorted.sort((a, b) {
      if (a.sponsorise == b.sponsorise) {
        return a.nom.toLowerCase().compareTo(b.nom.toLowerCase());
      }
      return a.sponsorise ? -1 : 1;
    });

    return sorted;
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchText = '';
    });
  }

  void _openArtisanDetail(Artisan artisan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ArtisanDetailScreen(artisan: artisan),
      ),
    );
  }

  String _resultLabel(int count) {
    if (count <= 1) {
      return '$count artisan';
    }
    return '$count artisans';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              decoration: const BoxDecoration(
                color: Color(0xFFF5F7FB),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Artisans disponibles',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(
                              blurRadius: 12,
                              offset: Offset(0, 5),
                              color: Color(0x11000000),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: _reloadArtisans,
                          icon: const Icon(
                            Icons.refresh_rounded,
                            color: Color(0xFF243B8F),
                          ),
                          tooltip: 'Actualiser',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Trouvez rapidement un artisan par nom, métier ou localisation.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 14,
                          offset: Offset(0, 6),
                          color: Color(0x11000000),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchText = value;
                        });
                      },
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Nom, métier, ville, quartier...',
                        hintStyle: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF243B8F),
                        ),
                        suffixIcon: _searchText.isNotEmpty
                            ? IconButton(
                                onPressed: _clearSearch,
                                icon: const Icon(Icons.close_rounded),
                                tooltip: 'Effacer',
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Artisan>>(
                future: _futureArtisans,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _LoadingView();
                  }

                  if (snapshot.hasError) {
                    return _ErrorView(
                      message:
                          'Impossible de charger les artisans pour le moment.',
                      onRetry: _reloadArtisans,
                    );
                  }

                  final artisans = snapshot.data ?? [];
                  final filtered = _filterArtisans(artisans);

                  if (artisans.isEmpty) {
                    return const _EmptyView(
                      icon: Icons.home_repair_service_rounded,
                      title: 'Aucun artisan disponible',
                      message:
                          'Les artisans apparaîtront ici dès qu’ils seront publiés.',
                    );
                  }

                  if (filtered.isEmpty) {
                    return const _EmptyView(
                      icon: Icons.search_off_rounded,
                      title: 'Aucun résultat',
                      message:
                          'Essaie un autre nom, métier, quartier ou ville.',
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _reloadArtisans,
                    color: const Color(0xFF243B8F),
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
                      itemCount: filtered.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEAF0FF),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    _resultLabel(filtered.length),
                                    style: const TextStyle(
                                      color: Color(0xFF243B8F),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                if (_searchText.trim().isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Résultats pour "${_searchText.trim()}"',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF6B7280),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }

                        final artisan = filtered[index - 1];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ArtisanCard(
                            artisan: artisan,
                            onTap: () => _openArtisanDetail(artisan),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: Color(0xFF243B8F),
          ),
          SizedBox(height: 14),
          Text(
            'Chargement des artisans...',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyView({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF0FF),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                icon,
                size: 38,
                color: const Color(0xFF243B8F),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
                height: 1.5,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEEEE),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: Color(0xFFD92D20),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Une erreur est survenue',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF111827),
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
                height: 1.5,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: const Color(0xFF243B8F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              label: const Text(
                'Réessayer',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}