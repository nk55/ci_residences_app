import 'package:flutter/material.dart';

import '../services/api_service.dart';

class ReservationDetailScreen extends StatefulWidget {
  final int reservationId;
  final String token;

  final String client;
  final String residence;
  final String dates;
  final String statut;
  final String telephone;
  final String email;
  final String nbPersonnes;
  final String message;
  final String reponseProprietaireInitiale;

  const ReservationDetailScreen({
    super.key,
    required this.reservationId,
    required this.token,
    required this.client,
    required this.residence,
    required this.dates,
    required this.statut,
    required this.telephone,
    required this.email,
    required this.nbPersonnes,
    required this.message,
    this.reponseProprietaireInitiale = '',
  });

  @override
  State<ReservationDetailScreen> createState() =>
      _ReservationDetailScreenState();
}

class _ReservationDetailScreenState extends State<ReservationDetailScreen> {
  final ApiService _apiService = ApiService();

  late String _statutActuel;
  late String _reponseProprietaire;

  bool _isReplying = false;
  bool _isConfirming = false;
  bool _isRefusing = false;

  @override
  void initState() {
    super.initState();
    _statutActuel = widget.statut;
    _reponseProprietaire = widget.reponseProprietaireInitiale;
  }

  Color _statusColor(String statut) {
    final value = statut.toLowerCase();

    if (value.contains('confirm')) return const Color(0xFF16A34A);
    if (value.contains('termin')) return const Color(0xFF4F46E5);
    if (value.contains('refus')) return const Color(0xFFD92D20);

    return const Color(0xFFD97706);
  }

  Color _statusBgColor(String statut) {
    final value = statut.toLowerCase();

    if (value.contains('confirm')) return const Color(0xFFECFDF3);
    if (value.contains('termin')) return const Color(0xFFEEF2FF);
    if (value.contains('refus')) return const Color(0xFFFFEDEE);

    return const Color(0xFFFFF7ED);
  }

  Future<void> _showReplyDialog() async {
    final controller = TextEditingController(text: _reponseProprietaire);

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Répondre au client'),
          content: TextField(
            controller: controller,
            maxLines: 5,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              hintText: 'Écris ta réponse ici...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, controller.text.trim());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3047A5),
                foregroundColor: Colors.white,
              ),
              child: const Text('Envoyer'),
            ),
          ],
        );
      },
    );

    if (result == null || result.trim().isEmpty) return;

    setState(() {
      _isReplying = true;
    });

    try {
      await _apiService.replyReservation(
        token: widget.token,
        id: widget.reservationId,
        message: result.trim(),
      );

      if (!mounted) return;

      setState(() {
        _reponseProprietaire = result.trim();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Réponse envoyée avec succès ✅'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur réponse : $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isReplying = false;
      });
    }
  }

  Future<void> _confirmReservation() async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmer la réservation'),
          content: const Text(
            'Veux-tu vraiment confirmer cette réservation ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirmer'),
            ),
          ],
        );
      },
    );

    if (accepted != true) return;

    setState(() {
      _isConfirming = true;
    });

    try {
      await _apiService.confirmReservation(
        token: widget.token,
        id: widget.reservationId,
      );

      if (!mounted) return;

      setState(() {
        _statutActuel = 'Confirmée';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Réservation confirmée ✅'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur confirmation : $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isConfirming = false;
      });
    }
  }

  Future<void> _refuseReservation() async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Refuser la réservation'),
          content: const Text(
            'Veux-tu vraiment refuser cette réservation ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD92D20),
                foregroundColor: Colors.white,
              ),
              child: const Text('Refuser'),
            ),
          ],
        );
      },
    );

    if (accepted != true) return;

    setState(() {
      _isRefusing = true;
    });

    try {
      await _apiService.refuseReservation(
        token: widget.token,
        id: widget.reservationId,
      );

      if (!mounted) return;

      setState(() {
        _statutActuel = 'Refusée';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Réservation refusée'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur refus : $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isRefusing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(_statutActuel);
    final statusBgColor = _statusBgColor(_statutActuel);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('Détail réservation'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF6F7FB),
        surfaceTintColor: const Color(0xFFF6F7FB),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Container(
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
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white24,
                  child: Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.client,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.residence,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14.5,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Container(
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
                const Text(
                  'Résumé',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.verified_outlined,
                      color: Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Statut',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
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
                        _statutActuel,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _DetailInfoTile(
                  icon: Icons.home_work_outlined,
                  label: 'Résidence',
                  value: widget.residence,
                ),
                const SizedBox(height: 12),
                _DetailInfoTile(
                  icon: Icons.date_range_outlined,
                  label: 'Dates',
                  value: widget.dates,
                ),
                const SizedBox(height: 12),
                _DetailInfoTile(
                  icon: Icons.groups_2_outlined,
                  label: 'Nombre de personnes',
                  value: widget.nbPersonnes,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Container(
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
              children: [
                _DetailInfoTile(
                  icon: Icons.person_outline_rounded,
                  label: 'Nom',
                  value: widget.client,
                ),
                const SizedBox(height: 12),
                _DetailInfoTile(
                  icon: Icons.phone_outlined,
                  label: 'Téléphone',
                  value: widget.telephone.isEmpty
                      ? 'Non renseigné'
                      : widget.telephone,
                ),
                const SizedBox(height: 12),
                _DetailInfoTile(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: widget.email.isEmpty ? 'Non renseigné' : widget.email,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Container(
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
                const Text(
                  'Message du client',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Text(
                    widget.message.trim().isEmpty
                        ? 'Aucun message laissé par le client.'
                        : widget.message,
                    style: const TextStyle(
                      fontSize: 14.5,
                      color: Color(0xFF374151),
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_reponseProprietaire.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
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
                  const Text(
                    'Ma réponse',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFBFDBFE),
                      ),
                    ),
                    child: Text(
                      _reponseProprietaire,
                      style: const TextStyle(
                        fontSize: 14.5,
                        color: Color(0xFF1F2937),
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: (_isReplying || _isConfirming || _isRefusing)
                      ? null
                      : _showReplyDialog,
                  icon: _isReplying
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.message_outlined),
                  label: const Text('Répondre'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF3047A5),
                    side: const BorderSide(color: Color(0xFF3047A5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    minimumSize: const Size.fromHeight(54),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (_isReplying || _isConfirming || _isRefusing)
                      ? null
                      : _confirmReservation,
                  icon: _isConfirming
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: const Text('Confirmer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3047A5),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    minimumSize: const Size.fromHeight(54),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: (_isReplying || _isConfirming || _isRefusing)
                  ? null
                  : _refuseReservation,
              icon: _isRefusing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.close_rounded),
              label: const Text('Refuser la réservation'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFD92D20),
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailInfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF3047A5)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  
}

