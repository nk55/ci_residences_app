import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/advertisement.dart';
import '../models/artisan.dart';
import '../models/residence.dart';

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const Duration _timeout = Duration(seconds: 20);

  // =========================
  // RÉSIDENCES PUBLIQUES
  // =========================

  Future<List<Residence>> getResidences() async {
    final url = _buildUrl(AppConfig.residencesEndpoint);

    try {
      final response = await _client
          .get(
            Uri.parse(url),
            headers: _jsonHeaders,
          )
          .timeout(_timeout);

      final data = _decodeResponse(response);

      if (_isSuccess(response.statusCode)) {
        return _extractList<Residence>(
          data,
          fromJson: (item) => Residence.fromJson(item),
          errorMessage: 'Format JSON invalide pour les résidences',
        );
      }

      throw Exception(
        _extractErrorMessage(data) ??
            'Impossible de charger les résidences (${response.statusCode})',
      );
    } on SocketException {
      throw Exception('Pas de connexion Internet');
    } on HttpException {
      throw Exception('Erreur réseau lors du chargement des résidences');
    } on FormatException {
      throw Exception('Réponse serveur invalide');
    }
  }

  // =========================
  // MES RÉSIDENCES
  // =========================

  Future<List<Residence>> getMyResidences({
    required String token,
  }) async {
    final url = _buildUrl('/api/mes-residences/');

    try {
      final response = await _client
          .get(
            Uri.parse(url),
            headers: {
              ..._jsonHeaders,
              'Authorization': 'Token $token',
            },
          )
          .timeout(_timeout);

      final data = _decodeResponse(response);

      if (_isSuccess(response.statusCode)) {
        return _extractList<Residence>(
          data,
          fromJson: (item) => Residence.fromJson(item),
          errorMessage: 'Format JSON invalide pour mes résidences',
        );
      }

      throw Exception(
        _extractErrorMessage(data) ??
            'Impossible de charger mes résidences (${response.statusCode})',
      );
    } on SocketException {
      throw Exception('Pas de connexion Internet');
    } on HttpException {
      throw Exception('Erreur réseau lors du chargement de mes résidences');
    } on FormatException {
      throw Exception('Réponse serveur invalide');
    }
  }

  // =========================
  // AJOUTER UNE RÉSIDENCE
  // =========================

  Future<Map<String, dynamic>> addResidence({
    required String token,
    required String titre,
    required String description,
    required String type,
    required String prix,
    required String ville,
    required String quartier,
    required String telephone,
    required String whatsapp,
    String capacite = '',
    String adresse = '',
    bool estActif = true,
    List<File> images = const [],
  }) async {
    final url = _buildUrl(AppConfig.createResidenceEndpoint);

    try {
      final request = http.MultipartRequest('POST', Uri.parse(url));

      request.headers.addAll({
        'Authorization': 'Token $token',
        'Accept': 'application/json',
      });

      request.fields['titre'] = titre.trim();
      request.fields['description'] = description.trim();
      request.fields['type'] = type.trim();
      request.fields['prix'] = prix.trim();
      request.fields['prix_par_nuit'] = prix.trim();
      request.fields['ville'] = ville.trim();
      request.fields['quartier'] = quartier.trim();
      request.fields['est_actif'] = estActif.toString();

      if (adresse.trim().isNotEmpty) {
        request.fields['adresse'] = adresse.trim();
      }

      if (capacite.trim().isNotEmpty) {
        request.fields['capacite'] = capacite.trim();
      }

      final cleanedTelephone = telephone.trim();
      final cleanedWhatsapp = whatsapp.trim();
      final contactPrincipal =
          cleanedWhatsapp.isNotEmpty ? cleanedWhatsapp : cleanedTelephone;

      if (contactPrincipal.isNotEmpty) {
        request.fields['telephone_whatsapp'] = contactPrincipal;
      }

      if (cleanedTelephone.isNotEmpty) {
        request.fields['telephone'] = cleanedTelephone;
      }

      if (cleanedWhatsapp.isNotEmpty) {
        request.fields['whatsapp'] = cleanedWhatsapp;
      }

      for (final image in images) {
        if (await image.exists()) {
          request.files.add(
            await http.MultipartFile.fromPath('images', image.path),
          );
        }
      }

      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);
      final data = _decodeResponse(response);

      if (_isSuccess(response.statusCode)) {
        if (data is Map<String, dynamic>) {
          return data;
        }

        return {
          'success': true,
          'message': 'Résidence ajoutée avec succès',
        };
      }

      throw Exception(
        _extractErrorMessage(data) ??
            'Impossible d’ajouter la résidence (${response.statusCode})',
      );
    } on SocketException {
      throw Exception('Pas de connexion Internet');
    } on HttpException {
      throw Exception('Erreur réseau lors de l’ajout de la résidence');
    } on FormatException {
      throw Exception('Réponse serveur invalide');
    }
  }

  // =========================
  // MODIFIER UNE RÉSIDENCE
  // =========================

  Future<Map<String, dynamic>> updateResidence({
    required String token,
    required int residenceId,
    required String titre,
    required String description,
    required String type,
    required String prix,
    required String ville,
    required String quartier,
    required String telephone,
    required String whatsapp,
    String capacite = '',
    String adresse = '',
    bool estActif = true,
    List<File> images = const [],
  }) async {
    final url = _buildUrl('${AppConfig.residencesEndpoint}/$residenceId/');

    try {
      final request = http.MultipartRequest('PUT', Uri.parse(url));

      request.headers.addAll({
        'Authorization': 'Token $token',
        'Accept': 'application/json',
      });

      request.fields['titre'] = titre.trim();
      request.fields['description'] = description.trim();
      request.fields['type'] = type.trim();
      request.fields['prix'] = prix.trim();
      request.fields['prix_par_nuit'] = prix.trim();
      request.fields['ville'] = ville.trim();
      request.fields['quartier'] = quartier.trim();
      request.fields['est_actif'] = estActif.toString();

      if (adresse.trim().isNotEmpty) {
        request.fields['adresse'] = adresse.trim();
      }

      if (capacite.trim().isNotEmpty) {
        request.fields['capacite'] = capacite.trim();
      }

      final cleanedTelephone = telephone.trim();
      final cleanedWhatsapp = whatsapp.trim();
      final contactPrincipal =
          cleanedWhatsapp.isNotEmpty ? cleanedWhatsapp : cleanedTelephone;

      if (contactPrincipal.isNotEmpty) {
        request.fields['telephone_whatsapp'] = contactPrincipal;
      }

      if (cleanedTelephone.isNotEmpty) {
        request.fields['telephone'] = cleanedTelephone;
      }

      if (cleanedWhatsapp.isNotEmpty) {
        request.fields['whatsapp'] = cleanedWhatsapp;
      }

      for (final image in images) {
        if (await image.exists()) {
          request.files.add(
            await http.MultipartFile.fromPath('images', image.path),
          );
        }
      }

      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);
      final data = _decodeResponse(response);

      if (_isSuccess(response.statusCode)) {
        if (data is Map<String, dynamic>) {
          return data;
        }

        return {
          'success': true,
          'message': 'Résidence modifiée avec succès',
        };
      }

      throw Exception(
        _extractErrorMessage(data) ??
            'Impossible de modifier la résidence (${response.statusCode})',
      );
    } on SocketException {
      throw Exception('Pas de connexion Internet');
    } on HttpException {
      throw Exception('Erreur réseau lors de la modification de la résidence');
    } on FormatException {
      throw Exception('Réponse serveur invalide');
    }
  }

  // =========================
  // SUPPRIMER UNE RÉSIDENCE
  // =========================

  Future<void> deleteResidence({
    required String token,
    required int residenceId,
  }) async {
    final url = _buildUrl('${AppConfig.residencesEndpoint}/$residenceId/');

    try {
      final response = await _client
          .delete(
            Uri.parse(url),
            headers: {
              ..._jsonHeaders,
              'Authorization': 'Token $token',
            },
          )
          .timeout(_timeout);

      final data = _decodeResponse(response);

      if (_isSuccess(response.statusCode)) {
        return;
      }

      throw Exception(
        _extractErrorMessage(data) ??
            'Impossible de supprimer la résidence (${response.statusCode})',
      );
    } on SocketException {
      throw Exception('Pas de connexion Internet');
    } on HttpException {
      throw Exception('Erreur réseau lors de la suppression de la résidence');
    } on FormatException {
      throw Exception('Réponse serveur invalide');
    }
  }

  // =========================
  // ARTISANS
  // =========================

  Future<List<Artisan>> getArtisans() async {
    final url = _buildUrl(AppConfig.artisansEndpoint);

    try {
      final response = await _client
          .get(
            Uri.parse(url),
            headers: _jsonHeaders,
          )
          .timeout(_timeout);

      final data = _decodeResponse(response);

      if (_isSuccess(response.statusCode)) {
        return _extractList<Artisan>(
          data,
          fromJson: (item) => Artisan.fromJson(item),
          errorMessage: 'Format JSON invalide pour les artisans',
        );
      }

      throw Exception(
        _extractErrorMessage(data) ??
            'Impossible de charger les artisans (${response.statusCode})',
      );
    } on SocketException {
      throw Exception('Pas de connexion Internet');
    } on HttpException {
      throw Exception('Erreur réseau lors du chargement des artisans');
    } on FormatException {
      throw Exception('Réponse serveur invalide');
    }
  }

  // =========================
  // DÉTAIL ARTISAN
  // =========================

  Future<Artisan> getArtisanDetail({
    required int artisanId,
    String email = '',
  }) async {
    final cleanedEmail = email.trim();

    final endpoint = cleanedEmail.isNotEmpty
        ? '${AppConfig.artisansEndpoint}/$artisanId/?email=${Uri.encodeQueryComponent(cleanedEmail)}'
        : '${AppConfig.artisansEndpoint}/$artisanId/';

    final url = _buildUrl(endpoint);

    try {
      final response = await _client
          .get(
            Uri.parse(url),
            headers: _jsonHeaders,
          )
          .timeout(_timeout);

      final data = _decodeResponse(response);

      if (_isSuccess(response.statusCode)) {
        if (data is Map<String, dynamic>) {
          return Artisan.fromJson(data);
        }
        throw Exception('Format JSON invalide pour artisan');
      }

      throw Exception(
        _extractErrorMessage(data) ??
            'Impossible de charger l’artisan (${response.statusCode})',
      );
    } on SocketException {
      throw Exception('Pas de connexion Internet');
    } on HttpException {
      throw Exception('Erreur réseau lors du chargement artisan');
    } on FormatException {
      throw Exception('Réponse serveur invalide');
    }
  }

  // =========================
  // CHECK ACCÈS ARTISAN
  // =========================

  Future<Map<String, dynamic>> checkArtisanAccess({
    required int artisanId,
    required String email,
  }) async {
    final cleanedEmail = email.trim();

    if (cleanedEmail.isEmpty) {
      return {
        'success': true,
        'has_access': false,
        'already_paid': false,
        'can_view_phone': false,
        'payment_required': true,
        'contact_visible': false,
        'telephone': '',
        'whatsapp': '',
        'expire_le': null,
      };
    }

    final endpoint =
        '${AppConfig.artisansEndpoint}/$artisanId/check-access/?email=${Uri.encodeQueryComponent(cleanedEmail)}';
    final url = _buildUrl(endpoint);

    try {
      final response = await _client
          .get(
            Uri.parse(url),
            headers: _jsonHeaders,
          )
          .timeout(_timeout);

      final data = _decodeResponse(response);

      if (_isSuccess(response.statusCode)) {
        if (data is Map<String, dynamic>) {
          return data;
        }
        throw Exception('Réponse invalide du serveur');
      }

      throw Exception(
        _extractErrorMessage(data) ??
            'Impossible de vérifier l’accès (${response.statusCode})',
      );
    } on SocketException {
      throw Exception('Pas de connexion Internet');
    } on HttpException {
      throw Exception('Erreur réseau lors du check accès');
    } on FormatException {
      throw Exception('Réponse serveur invalide');
    }
  }

  // =========================
  // INIT PAIEMENT ARTISAN
  // =========================

  Future<Map<String, dynamic>> initArtisanPayment({
    required int artisanId,
    required String email,
    String nomClient = '',
    String telephoneClient = '',
    String source = 'app',
  }) async {
    final cleanedEmail = email.trim();
    final cleanedNom = nomClient.trim();
    final cleanedPhone = telephoneClient.trim();
    final cleanedSource = source.trim().isEmpty ? 'app' : source.trim();

    if (cleanedEmail.isEmpty) {
      throw Exception('Veuillez renseigner votre email');
    }

    final endpoint = '${AppConfig.artisansEndpoint}/$artisanId/init-payment/';
    final url = _buildUrl(endpoint);

    try {
      final response = await _client
          .post(
            Uri.parse(url),
            headers: _jsonPostHeaders,
            body: jsonEncode({
              'email': cleanedEmail,
              'nom_client': cleanedNom,
              'telephone_client': cleanedPhone,
              'source': cleanedSource,
            }),
          )
          .timeout(_timeout);

      final data = _decodeResponse(response);

      if (_isSuccess(response.statusCode)) {
        if (data is Map<String, dynamic>) {
          return data;
        }
        throw Exception('Réponse invalide du serveur');
      }

      throw Exception(
        _extractErrorMessage(data) ??
            'Impossible d’initialiser le paiement (${response.statusCode})',
      );
    } on SocketException {
      throw Exception('Pas de connexion Internet');
    } on HttpException {
      throw Exception('Erreur réseau lors de l’initialisation du paiement');
    } on FormatException {
      throw Exception('Réponse serveur invalide');
    }
  }

  // =========================
  // VERIFY PAIEMENT ARTISAN
  // =========================

  Future<Map<String, dynamic>> verifyArtisanPayment({
    required int artisanId,
    required String email,
    required String reference,
  }) async {
    final cleanedEmail = email.trim();
    final cleanedReference = reference.trim();

    if (cleanedEmail.isEmpty) {
      throw Exception('Email requis pour vérifier le paiement');
    }

    if (cleanedReference.isEmpty) {
      throw Exception('Référence de paiement requise');
    }

    final endpoint = '${AppConfig.artisansEndpoint}/$artisanId/verify-payment/';
    final url = _buildUrl(endpoint);

    try {
      final response = await _client
          .post(
            Uri.parse(url),
            headers: _jsonPostHeaders,
            body: jsonEncode({
              'email': cleanedEmail,
              'reference': cleanedReference,
            }),
          )
          .timeout(_timeout);

      final data = _decodeResponse(response);

      if (_isSuccess(response.statusCode)) {
        if (data is Map<String, dynamic>) {
          return data;
        }
        throw Exception('Réponse invalide du serveur');
      }

      throw Exception(
        _extractErrorMessage(data) ??
            'Impossible de vérifier le paiement (${response.statusCode})',
      );
    } on SocketException {
      throw Exception('Pas de connexion Internet');
    } on HttpException {
      throw Exception('Erreur réseau lors de la vérification du paiement');
    } on FormatException {
      throw Exception('Réponse serveur invalide');
    }
  }

  // =========================
  // HELPERS ACCÈS / PAIEMENT ARTISAN
  // =========================

  bool hasArtisanAccess(Map<String, dynamic> data) {
    return data['can_view_phone'] == true ||
        data['has_access'] == true ||
        data['already_paid'] == true ||
        data['contact_visible'] == true;
  }

  bool isPaymentSuccess(Map<String, dynamic> data) {
    return data['success'] == true ||
        data['status'] == 'success' ||
        data['contact_visible'] == true ||
        data['already_paid'] == true ||
        data['has_access'] == true;
  }

  // =========================
  // PUBLICITÉS
  // =========================

  Future<List<Advertisement>> getAdvertisements() async {
    final url = _buildUrl(AppConfig.adsEndpoint);

    try {
      final response = await _client
          .get(
            Uri.parse(url),
            headers: _jsonHeaders,
          )
          .timeout(_timeout);

      final data = _decodeResponse(response);

      if (_isSuccess(response.statusCode)) {
        return _extractList<Advertisement>(
          data,
          fromJson: (item) => Advertisement.fromJson(item),
          errorMessage: 'Format JSON invalide pour les publicités',
        );
      }

      throw Exception(
        _extractErrorMessage(data) ??
            'Impossible de charger les publicités (${response.statusCode})',
      );
    } on SocketException {
      throw Exception('Pas de connexion Internet');
    } on HttpException {
      throw Exception('Erreur réseau lors du chargement des publicités');
    } on FormatException {
      throw Exception('Réponse serveur invalide');
    }
  }

  // =========================
  // CONNEXION
  // =========================

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final url = _buildUrl(AppConfig.loginEndpoint);

    try {
      final response = await _client
          .post(
            Uri.parse(url),
            headers: _jsonPostHeaders,
            body: jsonEncode({
              'username': username.trim(),
              'password': password,
            }),
          )
          .timeout(_timeout);

      final data = _decodeResponse(response);

      if (_isSuccess(response.statusCode)) {
        if (data is Map<String, dynamic>) {
          return data;
        }
        throw Exception('Réponse invalide du serveur');
      }

      throw Exception(
        _extractErrorMessage(data) ??
            'Connexion impossible (${response.statusCode})',
      );
    } on SocketException {
      throw Exception('Pas de connexion Internet');
    } on HttpException {
      throw Exception('Erreur réseau lors de la connexion');
    } on FormatException {
      throw Exception('Réponse serveur invalide');
    }
  }

  // =========================
  // PROFIL CONNECTÉ
  // =========================

  Future<Map<String, dynamic>> getCurrentUser(String token) async {
    final url = _buildUrl(AppConfig.meEndpoint);

    try {
      final response = await _client
          .get(
            Uri.parse(url),
            headers: {
              ..._jsonHeaders,
              'Authorization': 'Token $token',
            },
          )
          .timeout(_timeout);

      final data = _decodeResponse(response);

      if (_isSuccess(response.statusCode)) {
        if (data is Map<String, dynamic>) {
          return data;
        }
        throw Exception('Format utilisateur invalide');
      }

      throw Exception(
        _extractErrorMessage(data) ??
            'Impossible de récupérer l’utilisateur (${response.statusCode})',
      );
    } on SocketException {
      throw Exception('Pas de connexion Internet');
    } on HttpException {
      throw Exception('Erreur réseau lors de la récupération du profil');
    } on FormatException {
      throw Exception('Réponse serveur invalide');
    }
  }

  // =========================
  // MES RÉSERVATIONS
  // =========================

  Future<List<Map<String, dynamic>>> getMyReservations(String token) async {
    final url = _buildUrl('/api/mes-reservations/');

    try {
      final response = await _client
          .get(
            Uri.parse(url),
            headers: {
              ..._jsonHeaders,
              'Authorization': 'Token $token',
            },
          )
          .timeout(_timeout);

      final data = _decodeResponse(response);

      if (_isSuccess(response.statusCode)) {
        if (data is List) {
          return data
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }

        if (data is Map<String, dynamic> && data['results'] is List) {
          return (data['results'] as List)
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }

        throw Exception('Format JSON invalide pour les réservations');
      }

      throw Exception(
        _extractErrorMessage(data) ??
            'Impossible de charger les réservations (${response.statusCode})',
      );
    } on SocketException {
      throw Exception('Pas de connexion Internet');
    } on HttpException {
      throw Exception('Erreur réseau lors du chargement des réservations');
    } on FormatException {
      throw Exception('Réponse serveur invalide');
    }
  }

  // =========================
  // RÉPONDRE À UNE RÉSERVATION
  // =========================

  Future<void> replyReservation({
    required String token,
    required int id,
    required String message,
  }) async {
    final url = _buildUrl('/api/mes-reservations/$id/repondre/');

    try {
      final response = await _client
          .post(
            Uri.parse(url),
            headers: {
              ..._jsonPostHeaders,
              'Authorization': 'Token $token',
            },
            body: jsonEncode({
              'reponse_proprio': message.trim(),
            }),
          )
          .timeout(_timeout);

      final data = _decodeResponse(response);

      if (_isSuccess(response.statusCode)) {
        return;
      }

      throw Exception(
        _extractErrorMessage(data) ?? 'Erreur réponse (${response.statusCode})',
      );
    } on SocketException {
      throw Exception('Pas de connexion Internet');
    } on HttpException {
      throw Exception('Erreur réseau lors de la réponse à la réservation');
    } on FormatException {
      throw Exception('Réponse serveur invalide');
    }
  }

  // =========================
  // CONFIRMER RÉSERVATION
  // =========================

  Future<void> confirmReservation({
    required String token,
    required int id,
  }) async {
    final url = _buildUrl('/api/mes-reservations/$id/confirmer/');

    try {
      final response = await _client
          .post(
            Uri.parse(url),
            headers: {
              ..._jsonHeaders,
              'Authorization': 'Token $token',
            },
          )
          .timeout(_timeout);

      final data = _decodeResponse(response);

      if (_isSuccess(response.statusCode)) {
        return;
      }

      throw Exception(
        _extractErrorMessage(data) ??
            'Erreur confirmation (${response.statusCode})',
      );
    } on SocketException {
      throw Exception('Pas de connexion Internet');
    } on HttpException {
      throw Exception('Erreur réseau lors de la confirmation');
    } on FormatException {
      throw Exception('Réponse serveur invalide');
    }
  }

  // =========================
  // REFUSER RÉSERVATION
  // =========================

  Future<void> refuseReservation({
    required String token,
    required int id,
  }) async {
    final url = _buildUrl('/api/mes-reservations/$id/refuser/');

    try {
      final response = await _client
          .post(
            Uri.parse(url),
            headers: {
              ..._jsonHeaders,
              'Authorization': 'Token $token',
            },
          )
          .timeout(_timeout);

      final data = _decodeResponse(response);

      if (_isSuccess(response.statusCode)) {
        return;
      }

      throw Exception(
        _extractErrorMessage(data) ?? 'Erreur refus (${response.statusCode})',
      );
    } on SocketException {
      throw Exception('Pas de connexion Internet');
    } on HttpException {
      throw Exception('Erreur réseau lors du refus');
    } on FormatException {
      throw Exception('Réponse serveur invalide');
    }
  }

  // =========================
  // HEADERS
  // =========================

  Map<String, String> get _jsonHeaders => const {
        'Accept': 'application/json',
      };

  Map<String, String> get _jsonPostHeaders => const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // =========================
  // OUTILS INTERNES
  // =========================

  bool _isSuccess(int statusCode) => statusCode >= 200 && statusCode < 300;

  String _buildUrl(String endpoint) {
    final base = AppConfig.baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final path = endpoint.trim().replaceAll(RegExp(r'^/+'), '');
    return '$base/$path';
  }

  dynamic _decodeResponse(http.Response response) {
    if (response.bodyBytes.isEmpty) {
      return null;
    }

    try {
      final decoded = utf8.decode(response.bodyBytes);
      if (decoded.trim().isEmpty) {
        return null;
      }
      return jsonDecode(decoded);
    } catch (_) {
      return null;
    }
  }

  List<T> _extractList<T>(
    dynamic data, {
    required T Function(Map<String, dynamic> json) fromJson,
    required String errorMessage,
  }) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }

    if (data is Map<String, dynamic> && data['results'] is List) {
      return (data['results'] as List)
          .whereType<Map>()
          .map((item) => fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }

    throw Exception(errorMessage);
  }

  String? _extractErrorMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data['detail'] != null) return data['detail'].toString();
      if (data['message'] != null) return data['message'].toString();
      if (data['error'] != null) return data['error'].toString();

      if (data['errors'] is List && (data['errors'] as List).isNotEmpty) {
        return (data['errors'] as List).first.toString();
      }

      if (data['non_field_errors'] is List &&
          (data['non_field_errors'] as List).isNotEmpty) {
        return (data['non_field_errors'] as List).first.toString();
      }

      for (final entry in data.entries) {
        final value = entry.value;

        if (value is List && value.isNotEmpty) {
          return value.first.toString();
        }

        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }

        if (value is Map && value.isNotEmpty) {
          final firstValue = value.values.first;
          if (firstValue is List && firstValue.isNotEmpty) {
            return firstValue.first.toString();
          }
          if (firstValue is String && firstValue.trim().isNotEmpty) {
            return firstValue.trim();
          }
        }
      }
    }

    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }

    return null;
  }

  void dispose() {
    _client.close();
  }
}