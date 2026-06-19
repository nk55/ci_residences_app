import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'reservation_detail_screen.dart';

class MesReservationsScreen extends StatefulWidget {
  final String token;

  const MesReservationsScreen({
    super.key,
    required this.token,
  });

  @override
  State<MesReservationsScreen> createState() => _MesReservationsScreenState();
}

class _MesReservationsScreenState extends State<MesReservationsScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Map<String, dynamic>>> _futureReservations;

  @override
  void initState() {
    super.initState();
    _futureReservations = _apiService.getMyReservations(widget.token);
  }

  Future<void> _refresh() async {
    setState(() {
      _futureReservations = _apiService.getMyReservations(widget.token);
    });

    await _futureReservations;
  }

  String _formatDates(Map<String, dynamic> reservation) {
    final dateDebut = reservation['date_debut']?.toString() ?? '';
    final dateFin = reservation['date_fin']?.toString() ?? '';

    if (dateDebut.isEmpty && dateFin.isEmpty) {
      return 'Dates non renseignées';
    }

    if (dateDebut.isNotEmpty && dateFin.isNotEmpty) {
      return '$dateDebut - $dateFin';
    }

    return dateDebut.isNotEmpty ? dateDebut : dateFin;
  }

  String _formatResidence(Map<String, dynamic> reservation) {
    final residence = reservation['residence'];

    if (residence is Map<String, dynamic>) {
      return residence['titre']?.toString() ?? 'Résidence';
    }

    return reservation['residence_nom']?.toString() ??
        reservation['residence_title']?.toString() ??
        'Résidence';
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
            Icons.calendar_month_rounded,
            color: Colors.white,
            size: 34,
          ),
          SizedBox(height: 14),
          Text(
            'Mes réservations',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Retrouve ici toutes les demandes de réservation reçues pour tes résidences.',
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

  Widget _buildStatsRow(List<Map<String, dynamic>> reservations) {
    int enAttente = 0;
    int confirmees = 0;
    int terminees = 0;

    for (final item in reservations) {
      final statut = (item['statut'] ?? '').toString().toLowerCase();

      if (statut.contains('attente')) {
        enAttente++;
      } else if (statut.contains('confirm')) {
        confirmees++;
      } else if (statut.contains('termin')) {
        terminees++;
      }
    }

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'En attente',
            value: '$enAttente',
            icon: Icons.hourglass_bottom_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Confirmées',
            value: '$confirmees',
            icon: Icons.check_circle_outline_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Terminées',
            value: '$terminees',
            icon: Icons.task_alt_rounded,
          ),
        ),
      ],
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
      child: const Column(
        children: [
          Icon(
            Icons.event_busy_outlined,
            size: 56,
            color: Color(0xFF9CA3AF),
          ),
          SizedBox(height: 12),
          Text(
            'Aucune réservation pour le moment',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Les nouvelles demandes de réservation apparaîtront ici.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              height: 1.4,
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
          const Icon(
            Icons.error_outline,
            size: 56,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 12),
          const Text(
            'Impossible de charger les réservations',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
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
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: _refresh,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('Mes réservations'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF6F7FB),
        surfaceTintColor: const Color(0xFFF6F7FB),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _futureReservations,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  _buildHeaderCard(),
                  const SizedBox(height: 40),
                  const Center(child: CircularProgressIndicator()),
                ],
              );
            }

            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  _buildHeaderCard(),
                  const SizedBox(height: 20),
                  _buildErrorState(snapshot.error!),
                ],
              );
            }

            final reservations = snapshot.data ?? [];

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _buildHeaderCard(),
                const SizedBox(height: 20),
                _buildStatsRow(reservations),
                const SizedBox(height: 20),
                const Text(
                  'Réservations reçues',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 12),
                if (reservations.isEmpty)
                  _buildEmptyState()
                else
                  ...reservations.map(
                    (reservation) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _ReservationCard(
                        token: widget.token,
                        reservationId: reservation['id'] as int? ?? 0,
                        client: reservation['nom_client']?.toString() ?? '',
                        residence: _formatResidence(reservation),
                        dates: _formatDates(reservation),
                        statut: reservation['statut']?.toString() ?? '',
                        telephone: reservation['telephone']?.toString() ?? '',
                        email: reservation['email']?.toString() ?? '',
                        nbPersonnes:
                            reservation['nb_personnes']?.toString() ?? '',
                        message: reservation['message']?.toString() ?? '',
                        reponseProprietaire:
                            reservation['reponse_proprio']?.toString() ?? '',
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  final String token;
  final int reservationId;
  final String client;
  final String residence;
  final String dates;
  final String statut;
  final String telephone;
  final String email;
  final String nbPersonnes;
  final String message;
  final String reponseProprietaire;

  const _ReservationCard({
    required this.token,
    required this.reservationId,
    required this.client,
    required this.residence,
    required this.dates,
    required this.statut,
    required this.telephone,
    required this.email,
    required this.nbPersonnes,
    required this.message,
    required this.reponseProprietaire,
  });

  Color _statusColor() {
    final value = statut.toLowerCase();
    if (value.contains('confirm')) return const Color(0xFF16A34A);
    if (value.contains('termin')) return const Color(0xFF4F46E5);
    if (value.contains('refus')) return const Color(0xFFD92D20);
    return const Color(0xFFD97706);
  }

  Color _statusBgColor() {
    final value = statut.toLowerCase();
    if (value.contains('confirm')) return const Color(0xFFECFDF3);
    if (value.contains('termin')) return const Color(0xFFEEF2FF);
    if (value.contains('refus')) return const Color(0xFFFFEDEE);
    return const Color(0xFFFFF7ED);
  }

  void _openDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReservationDetailScreen(
          reservationId: reservationId,
          token: token,
          client: client,
          residence: residence,
          dates: dates,
          statut: statut,
          telephone: telephone,
          email: email,
          nbPersonnes: nbPersonnes,
          message: message,
          reponseProprietaireInitiale: reponseProprietaire,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor();
    final statusBgColor = _statusBgColor();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundColor: Color(0xFFE9EEFF),
                child: Icon(
                  Icons.person_outline_rounded,
                  color: Color(0xFF3047A5),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  client,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statut,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InfoRow(
            icon: Icons.home_work_outlined,
            text: residence,
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.date_range_outlined,
            text: dates,
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.phone_outlined,
            text: telephone,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openDetail(context),
                  icon: const Icon(Icons.message_outlined),
                  label: const Text('Répondre'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF3047A5),
                    side: const BorderSide(color: Color(0xFF3047A5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openDetail(context),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Voir'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3047A5),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: const Color(0xFF6B7280),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14.5,
              color: Color(0xFF374151),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
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
      child: Column(
        children: [
          Icon(
            icon,
            color: const Color(0xFF3047A5),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}