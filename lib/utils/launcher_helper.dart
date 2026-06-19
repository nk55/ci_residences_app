import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LauncherHelper {
  LauncherHelper._();

  // =========================
  // APPEL
  // =========================

  static Future<void> callPhone(String phoneNumber) async {
    final cleaned = _cleanPhone(phoneNumber);

    if (cleaned.isEmpty) {
      throw Exception('Numéro vide');
    }

    final uri = Uri(
      scheme: 'tel',
      path: cleaned,
    );

    await _launch(
      uri,
      errorMessage: 'Impossible d’appeler ce numéro',
    );
  }

  // =========================
  // WHATSAPP
  // =========================

  static Future<void> openWhatsApp(
    String phoneNumber, {
    String? message,
  }) async {
    final cleaned = _cleanPhone(phoneNumber);

    if (cleaned.isEmpty) {
      throw Exception('Numéro WhatsApp vide');
    }

    final phoneWithoutPlus = cleaned.replaceAll('+', '');
    final text = Uri.encodeComponent(
      (message ?? 'Bonjour, je vous contacte depuis CI Résidences.').trim(),
    );

    final waUri = Uri.parse(
      'https://wa.me/$phoneWithoutPlus?text=$text',
    );

    await _launch(
      waUri,
      errorMessage: 'Impossible d’ouvrir WhatsApp',
    );
  }

  // =========================
  // LIEN WEB / PAIEMENT
  // =========================

  static Future<void> openWebsite(String url) async {
    final normalizedUrl = _normalizeUrl(url);
    final uri = Uri.tryParse(normalizedUrl);

    if (uri == null || !_isWebScheme(uri.scheme)) {
      throw Exception('Lien invalide');
    }

    await _launch(
      uri,
      errorMessage: 'Impossible d’ouvrir le lien',
    );
  }

  // =========================
  // EMAIL
  // =========================

  static Future<void> openEmail(String email) async {
    final trimmed = email.trim();

    if (trimmed.isEmpty) {
      throw Exception('Adresse email vide');
    }

    final uri = Uri(
      scheme: 'mailto',
      path: trimmed,
    );

    await _launch(
      uri,
      errorMessage: 'Impossible d’ouvrir l’email',
    );
  }

  // =========================
  // SMS
  // =========================

  static Future<void> openSms(
    String phoneNumber, {
    String? message,
  }) async {
    final cleaned = _cleanPhone(phoneNumber);

    if (cleaned.isEmpty) {
      throw Exception('Numéro invalide');
    }

    final uri = Uri(
      scheme: 'sms',
      path: cleaned,
      queryParameters: (message != null && message.trim().isNotEmpty)
          ? {'body': message.trim()}
          : null,
    );

    await _launch(
      uri,
      errorMessage: 'Impossible d’ouvrir les SMS',
    );
  }

  // =========================
  // AFFICHER ERREUR
  // =========================

  static void showError(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // =========================
  // LANCEMENT
  // =========================

  static Future<void> _launch(
    Uri uri, {
    required String errorMessage,
  }) async {
    final canLaunch = await canLaunchUrl(uri);
    if (!canLaunch) {
      throw Exception(errorMessage);
    }

    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched) {
      throw Exception(errorMessage);
    }
  }

  // =========================
  // OUTILS
  // =========================

  static String _cleanPhone(String phone) {
    var cleaned = phone.trim();

    if (cleaned.isEmpty) {
      return '';
    }

    cleaned = cleaned.replaceAll(RegExp(r'[^\d+]'), '');

    if (cleaned.startsWith('00')) {
      cleaned = '+${cleaned.substring(2)}';
    }

    if (cleaned.contains('+')) {
      if (!cleaned.startsWith('+')) {
        cleaned = cleaned.replaceAll('+', '');
      } else {
        final rest = cleaned.substring(1).replaceAll('+', '');
        cleaned = '+$rest';
      }
    }

    return cleaned;
  }

  static String _normalizeUrl(String url) {
    final trimmed = url.trim();

    if (trimmed.isEmpty) {
      throw Exception('Lien vide');
    }

    final lower = trimmed.toLowerCase();

    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return trimmed;
    }

    return 'https://$trimmed';
  }

  static bool _isWebScheme(String scheme) {
    final s = scheme.toLowerCase();
    return s == 'http' || s == 'https';
  }
}