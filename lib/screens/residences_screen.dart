import 'package:flutter/material.dart';

import '../models/residence.dart';
import '../services/api_service.dart';
import '../widgets/residence_card.dart';
import 'residence_detail_screen.dart';

enum FilterType { all, sponsored, nonSponsored }
enum SortType { none, priceAsc, priceDesc }

class ResidencesScreen extends StatefulWidget {
  const ResidencesScreen({super.key});

  @override
  State<ResidencesScreen> createState() => _ResidencesScreenState();
}

class _ResidencesScreenState extends State<ResidencesScreen> {
  final ApiService _apiService = ApiService();

  List<Residence> _residences = [];
  bool _isLoading = true;
  bool _hasError = false;

  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  FilterType _filter = FilterType.all;
  SortType _sort = SortType.none;

  static const Color _bg = Color(0xFFF6F7FB);
  static const Color _surface = Colors.white;
  static const Color _text = Color(0xFF111827);
  static const Color _subtext = Color(0xFF6B7280);
  static const Color _line = Color(0xFFE7EAF1);
  static const Color _primary = Color(0xFF243B8F);

  @override
  void initState() {
    super.initState();
    _loadResidences();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadResidences() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final data = await _apiService.getResidences();

      if (!mounted) return;

      setState(() {
        _residences = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  List<Residence> _applyFilters() {
    List<Residence> result = List.from(_residences);

    result.sort((a, b) {
      if (a.isSponsored && !b.isSponsored) return -1;
      if (!a.isSponsored && b.isSponsored) return 1;
      return 0;
    });

    if (_searchText.trim().isNotEmpty) {
      final query = _searchText.toLowerCase().trim();

      result = result.where((r) {
        return r.titre.toLowerCase().contains(query) ||
            r.ville.toLowerCase().contains(query) ||
            r.quartier.toLowerCase().contains(query) ||
            r.type.toLowerCase().contains(query);
      }).toList();
    }

    if (_filter == FilterType.sponsored) {
      result = result.where((r) => r.isSponsored).toList();
    } else if (_filter == FilterType.nonSponsored) {
      result = result.where((r) => !r.isSponsored).toList();
    }

    if (_sort != SortType.none) {
      result.sort((a, b) {
        final priceA = _parsePrice(a.prix);
        final priceB = _parsePrice(b.prix);

        return _sort == SortType.priceAsc
            ? priceA.compareTo(priceB)
            : priceB.compareTo(priceA);
      });
    }

    return result;
  }

  int _parsePrice(dynamic prix) {
    if (prix == null) return 0;

    final cleaned = prix
        .toString()
        .replaceAll('FCFA', '')
        .replaceAll(' ', '')
        .replaceAll(',', '');

    return int.tryParse(cleaned) ?? 0;
  }

  Future<void> _refresh() async {
    await _loadResidences();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchText = '';
    });
  }

  String _resultLabel(int count) {
    if (count <= 1) {
      return '$count résidence';
    }
    return '$count résidences';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: _primary,
                ),
              )
            : _hasError
                ? _buildError()
                : _buildContent(),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
              'Erreur de chargement',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _text,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Impossible de charger les résidences pour le moment.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _subtext,
                fontWeight: FontWeight.w500,
                height: 1.5,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _loadResidences,
              icon: const Icon(Icons.refresh_rounded),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: _primary,
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

  Widget _buildContent() {
    final filtered = _applyFilters();

    return RefreshIndicator(
      onRefresh: _refresh,
      color: _primary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Résidences meublées',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: _text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _searchText.trim().isEmpty
                        ? '${_resultLabel(filtered.length)} disponibles'
                        : '${_resultLabel(filtered.length)} pour "${_searchText.trim()}"',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _subtext,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSearch(),
                  const SizedBox(height: 12),
                  _buildFilters(),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            sliver: filtered.isEmpty
                ? SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(30),
                        child: Column(
                          children: const [
                            Icon(
                              Icons.search_off_rounded,
                              size: 44,
                              color: _subtext,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Aucune résidence trouvée',
                              style: TextStyle(
                                color: _subtext,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final residence = filtered[index];

                        return TweenAnimationBuilder<double>(
                          duration: Duration(milliseconds: 320 + (index * 60)),
                          tween: Tween<double>(begin: 0, end: 1),
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 22 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 18),
                            child: ResidenceCard(
                              residence: residence,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ResidenceDetailScreen(
                                      residence: residence,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _line),
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
          setState(() => _searchText = value);
        },
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Rechercher une résidence...',
          hintStyle: const TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 14,
          ),
          border: InputBorder.none,
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: _primary,
          ),
          suffixIcon: _searchText.trim().isNotEmpty
              ? IconButton(
                  onPressed: _clearSearch,
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Effacer',
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip(
            'Toutes',
            _filter == FilterType.all,
            () {
              setState(() => _filter = FilterType.all);
            },
          ),
          const SizedBox(width: 8),
          _chip(
            'Premium',
            _filter == FilterType.sponsored,
            () {
              setState(() => _filter = FilterType.sponsored);
            },
          ),
          const SizedBox(width: 8),
          _chip(
            'Standard',
            _filter == FilterType.nonSponsored,
            () {
              setState(() => _filter = FilterType.nonSponsored);
            },
          ),
          const SizedBox(width: 12),
          _chip(
            'Prix ↑',
            _sort == SortType.priceAsc,
            () {
              setState(() {
                _sort =
                    _sort == SortType.priceAsc ? SortType.none : SortType.priceAsc;
              });
            },
          ),
          const SizedBox(width: 8),
          _chip(
            'Prix ↓',
            _sort == SortType.priceDesc,
            () {
              setState(() {
                _sort = _sort == SortType.priceDesc
                    ? SortType.none
                    : SortType.priceDesc;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? _primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _line),
          boxShadow: active
              ? const [
                  BoxShadow(
                    blurRadius: 10,
                    offset: Offset(0, 4),
                    color: Color(0x1A243B8F),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : _text,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}