import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/residence.dart';
import '../services/api_service.dart';
import '../widgets/residence_card.dart';
import 'ajouter_residence_screen.dart';
import 'residence_detail_screen.dart';

class MesResidencesScreen extends StatefulWidget {
  const MesResidencesScreen({super.key});

  @override
  State<MesResidencesScreen> createState() => _MesResidencesScreenState();
}

class _MesResidencesScreenState extends State<MesResidencesScreen> {
  final ApiService _apiService = ApiService();

  late Future<List<Residence>> _futureResidences;

  String _token = '';
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _futureResidences = Future.value(<Residence>[]);
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    if (!mounted) return;

    setState(() {
      _token = token;
      _isInitialized = true;
      _loadResidences();
    });
  }

  void _loadResidences() {
    if (_token.trim().isEmpty) {
      _futureResidences = Future.value(<Residence>[]);
      return;
    }

    _futureResidences = _apiService.getMyResidences(
      token: _token,
    );
  }

  Future<void> _refresh() async {
    if (!_isInitialized || _token.trim().isEmpty) return;

    setState(() {
      _loadResidences();
    });

    try {
      await _futureResidences;
    } catch (_) {
      // Le FutureBuilder gère déjà l'erreur.
    }
  }

  Future<void> _goToAddResidence() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AjouterResidenceScreen(),
      ),
    );

    if (!mounted) return;
    await _refresh();
  }

  String _safeString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  String _normalize(dynamic value) {
    return _safeString(value).toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  List<Residence> _dedupeResidences(List<Residence> items) {
    final seen = <String>{};
    final result = <Residence>[];

    for (final item in items) {
      final id = item.id;

      String key;
      if (id != 0) {
        key = 'id:$id';
      } else {
        key = [
          _normalize(item.titre),
          _normalize(item.ville),
          _normalize(item.quartier),
          _normalize(item.prix),
          _normalize(item.description),
        ].join('|');
      }

      if (key.trim().isEmpty) continue;

      if (seen.add(key)) {
        result.add(item);
      }
    }

    return result;
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF233A91),
            Color(0xFF3557D6),
            Color(0xFF486BEE),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33243B8F),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.home_work_rounded,
            color: Colors.white,
            size: 34,
          ),
          SizedBox(height: 14),
          Text(
            'Mes résidences',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Gère ici toutes les résidences publiées sur ton compte.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFE9EEFF),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.home_work_outlined,
              size: 34,
              color: Color(0xFF3047A5),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucune résidence trouvée',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Commence par publier ta première résidence pour la voir apparaître ici.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _goToAddResidence,
              icon: const Icon(Icons.add_home_work_outlined),
              label: const Text('Ajouter une résidence'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3047A5),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 34,
              color: Color(0xFFD92D20),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Impossible de charger les résidences',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$error',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF3047A5),
                side: const BorderSide(color: Color(0xFF3047A5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(int count) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFE9EEFF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.apartment_rounded,
              color: Color(0xFF3047A5),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total résidences',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResidencesList(List<Residence> residences) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: residences.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              children: [
                _buildHeaderCard(),
                const SizedBox(height: 18),
                _buildStatsCard(residences.length),
                const SizedBox(height: 18),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Liste des résidences',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            );
          }

          if (index == residences.length + 1) {
            return const SizedBox(height: 12);
          }

          final residence = residences[index - 1];

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: ResidenceCard(
              key: ValueKey(
                'mes_residence_${residence.id}_${_safeString(residence.titre)}',
              ),
              residence: residence,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ResidenceDetailScreen(
                      residence: residence,
                    ),
                  ),
                );

                if (!mounted) return;
                await _refresh();
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _buildHeaderCard(),
        const SizedBox(height: 24),
        const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyContent() {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          _buildHeaderCard(),
          const SizedBox(height: 18),
          _buildStatsCard(0),
          const SizedBox(height: 18),
          _buildEmptyState(),
        ],
      ),
    );
  }

  Widget _buildErrorContent(Object error) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          _buildHeaderCard(),
          const SizedBox(height: 18),
          _buildErrorState(error),
        ],
      ),
    );
  }

  Widget _buildNotConnectedState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        _buildHeaderCard(),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: const Column(
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 40,
                color: Color(0xFF3047A5),
              ),
              SizedBox(height: 14),
              Text(
                'Connexion requise',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Impossible de charger vos résidences sans compte connecté.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('Mes résidences'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF6F7FB),
        surfaceTintColor: const Color(0xFFF6F7FB),
        elevation: 0,
      ),
      body: !_isInitialized
          ? _buildLoadingState()
          : _token.trim().isEmpty
              ? _buildNotConnectedState()
              : FutureBuilder<List<Residence>>(
                  future: _futureResidences,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildLoadingState();
                    }

                    if (snapshot.hasError) {
                      return _buildErrorContent(snapshot.error!);
                    }

                    final rawResidences = snapshot.data ?? <Residence>[];
                    final residences = _dedupeResidences(rawResidences);

                    if (residences.isEmpty) {
                      return _buildEmptyContent();
                    }

                    return _buildResidencesList(residences);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF3047A5),
        onPressed: _goToAddResidence,
        child: const Icon(Icons.add),
      ),
    );
  }
}