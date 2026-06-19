import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'main_navigation_screen.dart';

class PaymentSuccessScreen extends StatefulWidget {
  final String artisanId;
  final String paymentReference;
  final String email;

  const PaymentSuccessScreen({
    super.key,
    required this.artisanId,
    required this.paymentReference,
    required this.email,
  });

  @override
  State<PaymentSuccessScreen> createState() =>
      _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen> {
  bool _isLoading = true;
  bool _isVerified = false;
  String? _errorMessage;

  String _telephone = '';
  String _whatsapp = '';
  String _expireLe = '';
  String _artisanNom = 'Artisan';

  static const String baseUrl = 'https://ton-site.com';

  @override
  void initState() {
    super.initState();
    _verifyPaymentAndLoadAccess();
  }

  dynamic _safeDecode(http.Response response) {
    if (response.bodyBytes.isEmpty) return {};

    try {
      final decoded = utf8.decode(response.bodyBytes);
      if (decoded.trim().isEmpty) return {};
      return jsonDecode(decoded);
    } catch (_) {
      return {};
    }
  }

  Future<void> _verifyPaymentAndLoadAccess() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final uri = Uri.parse(
        '$baseUrl/api/artisans/${widget.artisanId}/verify-payment/',
      );

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'reference': widget.paymentReference,
          'email': widget.email,
        }),
      );

      final data = _safeDecode(response);

      if (response.statusCode == 200 &&
          data is Map &&
          data['success'] == true) {
        setState(() {
          _isVerified = true;
          _telephone = (data['telephone'] ?? '').toString();
          _whatsapp = (data['whatsapp'] ?? '').toString();
          _expireLe = (data['expire_le'] ?? '').toString();
          _isLoading = false;
        });
        return;
      }

      if (response.statusCode == 200 && data is Map && data.isEmpty) {
        await _reloadAccess();
        return;
      }

      setState(() {
        _isVerified = false;
        _errorMessage =
            (data['error'] ?? 'Paiement non confirmé').toString();
        _isLoading = false;
      });
    } catch (e) {
      await _reloadAccess();
    }
  }

  Future<void> _reloadAccess() async {
    try {
      final uri = Uri.parse(
        '$baseUrl/api/artisans/${widget.artisanId}/check-access/?email=${Uri.encodeQueryComponent(widget.email)}',
      );

      final response = await http.get(uri);
      final data = _safeDecode(response);

      if (response.statusCode == 200 &&
          data is Map &&
          data['has_access'] == true) {
        setState(() {
          _isVerified = true;
          _telephone = (data['telephone'] ?? '').toString();
          _whatsapp = (data['whatsapp'] ?? '').toString();
          _expireLe = (data['expire_le'] ?? '').toString();
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _isVerified = false;
        _errorMessage = 'Paiement non confirmé.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isVerified = false;
        _errorMessage = 'Erreur réseau.';
        _isLoading = false;
      });
    }
  }

  String _formatDate(String rawDate) {
    if (rawDate.trim().isEmpty) return '';

    try {
      final date = DateTime.parse(rawDate).toLocal();
      return DateFormat('dd/MM/yyyy à HH:mm').format(date);
    } catch (_) {
      return rawDate;
    }
  }

  Future<void> _launchPhone(String phone) async {
    if (phone.trim().isEmpty) return;

    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showMessage("Impossible d'ouvrir l'appel.");
    }
  }

  Future<void> _launchWhatsApp(String phone) async {
    if (phone.trim().isEmpty) return;

    final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('https://wa.me/${cleaned.replaceAll('+', '')}');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showMessage("Impossible d'ouvrir WhatsApp.");
    }
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const MainNavigationScreen(),
      ),
      (route) => false,
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildContactRow({
    required IconData icon,
    required String label,
    required String value,
    Color valueColor = const Color(0xFF111827),
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF243B8F), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF111827),
                ),
                children: [
                  TextSpan(
                    text: '$label : ',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(
                    text: value.isEmpty ? 'Non disponible' : value,
                    style: TextStyle(
                      color: valueColor,
                      fontWeight: FontWeight.w500,
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

  Widget _buildLoadingView() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 70,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Paiement non confirmé',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _errorMessage ?? 'Une erreur est survenue.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _verifyPaymentAndLoadAccess,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9F9EE),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Color(0xFF16A34A),
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Paiement réussi',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Contact débloqué',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF16A34A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 16,
                    offset: Offset(0, 8),
                    color: Color(0x11000000),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _artisanNom,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildContactRow(
                    icon: Icons.phone,
                    label: 'Téléphone',
                    value: _telephone,
                  ),
                  _buildContactRow(
                    icon: Icons.chat,
                    label: 'WhatsApp',
                    value: _whatsapp,
                  ),
                  if (_expireLe.isNotEmpty)
                    _buildContactRow(
                      icon: Icons.schedule,
                      label: 'Accès valide jusqu’à',
                      value: _formatDate(_expireLe),
                      valueColor: const Color(0xFF16A34A),
                    ),
                ],
              ),
            ),
            const Spacer(),
            if (_whatsapp.isNotEmpty)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _launchWhatsApp(_whatsapp),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'WhatsApp',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            if (_telephone.isNotEmpty)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () => _launchPhone(_telephone),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    side: const BorderSide(
                      color: Color(0xFF243B8F),
                      width: 1.4,
                    ),
                  ),
                  child: const Text(
                    'Appeler',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF243B8F),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: TextButton(
                onPressed: _goHome,
                child: const Text('Retour à l’accueil'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FB),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Paiement',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          onPressed: _goHome,
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF111827),
          ),
        ),
      ),
      body: _isLoading
          ? _buildLoadingView()
          : _isVerified
              ? _buildSuccessView()
              : _buildErrorView(),
    );
  }
}