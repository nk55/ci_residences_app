import 'package:flutter/material.dart';

import '../models/residence.dart';
import '../services/api_service.dart';
import '../services/favorites_service.dart';
import '../widgets/residence_card.dart';
import 'residence_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final ApiService _apiService = ApiService();

  List<Residence> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final residences = await _apiService.getResidences();
      final favoriteIds = await FavoritesService.getFavorites();

      final favs = residences
          .where((r) => favoriteIds.contains(r.id.toString()))
          .toList();

      favs.sort((a, b) {
        if (a.isSponsored && !b.isSponsored) return -1;
        if (!a.isSponsored && b.isSponsored) return 1;
        return 0;
      });

      if (!mounted) return;

      setState(() {
        _favorites = favs;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _favorites = [];
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement des favoris : $e'),
        ),
      );
    }
  }

  Future<void> _openResidenceDetail(Residence residence) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResidenceDetailScreen(
          residence: residence,
        ),
      ),
    );

    await _loadFavorites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Favoris'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _favorites.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadFavorites,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _favorites.length,
                    itemBuilder: (context, index) {
                      final residence = _favorites[index];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: ResidenceCard(
                          residence: residence,
                          onTap: () => _openResidenceDetail(residence),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 20),
            const Text(
              'Aucun favori',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Ajoute des résidences à tes favoris pour les retrouver ici.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}