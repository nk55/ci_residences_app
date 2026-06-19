import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AdsScreen extends StatelessWidget {
  const AdsScreen({super.key});

  // Remplace par ton vrai numéro WhatsApp
  // Format : 225XXXXXXXXXX (sans +, sans espaces)
  static const String _whatsAppNumber = '2250797472216';

  Future<void> _openWhatsApp(
    BuildContext context, {
    required String message,
  }) async {
    final encodedMessage = Uri.encodeComponent(message);

    final Uri whatsappUri = Uri.parse(
      'https://wa.me/$_whatsAppNumber?text=$encodedMessage',
    );

    try {
      final launched = await launchUrl(
        whatsappUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d’ouvrir WhatsApp.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d’ouvrir WhatsApp.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildTopCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF163A8A),
            Color(0xFF2C55D8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Icon(
                Icons.add_business_rounded,
                color: Colors.white,
                size: 22,
              ),
              SizedBox(width: 10),
              Text(
                'PUBLIER',
                style: TextStyle(
                  color: Color(0xFFDCE7FF),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'Publiez sur CI Résidences',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              height: 1.1,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Choisissez votre profil et continuez directement sur WhatsApp pour finaliser votre demande.',
            style: TextStyle(
              color: Color(0xFFE5E7EB),
              fontSize: 15,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F5FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1E7FF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF2C55D8)),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF243B8F),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required String badge,
    required String title,
    required String description,
    required IconData icon,
    required Color iconBackground,
    required Color iconColor,
    required List<String> bullets,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 28,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            badge,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2C55D8),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 25,
              height: 1.15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 16),
          ...bullets.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF22C55E),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.chat_rounded),
              label: Text(buttonText),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_user_outlined,
            color: Color(0xFFEA580C),
            size: 22,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Toutes les demandes passent d’abord par WhatsApp pour vous guider, valider les informations et finaliser la mise en ligne.',
              style: TextStyle(
                color: Color(0xFF9A3412),
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopCard(),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildInfoChip(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Réponse sur WhatsApp',
                  ),
                  _buildInfoChip(
                    icon: Icons.apartment_rounded,
                    label: 'Résidences & artisans',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildActionCard(
                context: context,
                badge: 'ARTISAN',
                title: 'Devenir artisan',
                description:
                    'Présentez votre métier, votre zone et vos services. Nous vous aidons à créer votre profil sur CI Résidences.',
                icon: Icons.handyman_rounded,
                iconBackground: const Color(0xFFE8FFF7),
                iconColor: const Color(0xFF0F9F76),
                bullets: const [
                  'Création de votre profil artisan',
                  'Ajout de votre photo, métier et description',
                  'Mise en ligne après validation',
                ],
                buttonText: 'Contacter sur WhatsApp',
                onPressed: () {
                  _openWhatsApp(
                    context,
                    message:
                        'Bonjour, je souhaite devenir artisan sur CI Résidences. Merci de m’indiquer les étapes.',
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildActionCard(
                context: context,
                badge: 'PROPRIÉTAIRE',
                title: 'Publier ma résidence',
                description:
                    'Publiez votre résidence sur CI Résidences et recevez vos identifiants après validation depuis notre plateforme Django.',
                icon: Icons.apartment_rounded,
                iconBackground: const Color(0xFFFFF4E8),
                iconColor: const Color(0xFFB45309),
                bullets: const [
                  'Offre Standard : 5 000 FCFA / mois',
                  'Offre Premium : 10 000 FCFA / mois',
                  'Création et envoi de vos identifiants de connexion',
                ],
                buttonText: 'Publier via WhatsApp',
                onPressed: () {
                  _openWhatsApp(
                    context,
                    message:
                        'Bonjour, je souhaite publier ma résidence sur CI Résidences. Merci de m’indiquer les étapes, les offres Standard et Premium, ainsi que le mode de paiement.',
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildBottomNote(),
            ],
          ),
        ),
      ),
    );
  }
}