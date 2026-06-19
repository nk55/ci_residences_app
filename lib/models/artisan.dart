import '../config/app_config.dart';

class Artisan {
  final int id;
  final String nom;
  final String metier;
  final String description;
  final String telephone;
  final String whatsapp;
  final String telephoneWhatsapp;
  final String ville;
  final String quartier;
  final String image;
  final bool sponsorise;
  final bool contactVisible;
  final String expireLe;

  const Artisan({
    required this.id,
    required this.nom,
    required this.metier,
    required this.description,
    required this.telephone,
    required this.whatsapp,
    required this.telephoneWhatsapp,
    required this.ville,
    required this.quartier,
    required this.image,
    required this.sponsorise,
    required this.contactVisible,
    required this.expireLe,
  });

  factory Artisan.fromJson(Map<String, dynamic> json) {
    final telephone = _parseString(json['telephone']);
    final whatsapp = _parseWhatsapp(json);
    final telephoneWhatsapp = _parseTelephoneWhatsapp(
      json,
      whatsapp,
      telephone,
    );

    return Artisan(
      id: _parseInt(json['id']),
      nom: _parseString(json['nom']),
      metier: _parseString(json['metier']),
      description: _parseString(json['description']),
      telephone: telephone,
      whatsapp: whatsapp,
      telephoneWhatsapp: telephoneWhatsapp,
      ville: _parseString(json['ville']),
      quartier: _parseString(json['quartier']),
      image: _parseImage(json),
      sponsorise: _parseSponsorise(json),
      contactVisible: _parseContactVisible(json),
      expireLe: _parseString(json['expire_le']),
    );
  }

  bool get hasImage => image.trim().isNotEmpty;

  bool get hasPhone => telephone.trim().isNotEmpty;

  bool get hasWhatsapp => whatsapp.trim().isNotEmpty;

  bool get hasTelephoneWhatsapp => telephoneWhatsapp.trim().isNotEmpty;

  bool get hasContact =>
      telephone.trim().isNotEmpty ||
      whatsapp.trim().isNotEmpty ||
      telephoneWhatsapp.trim().isNotEmpty;

  bool get isPremium => sponsorise;

  bool get isLocked => !contactVisible;

  bool get hasExpiration => expireLe.trim().isNotEmpty;

  DateTime? get expirationDate {
    if (expireLe.trim().isEmpty) return null;
    return DateTime.tryParse(expireLe.trim());
  }

  bool get isExpired {
    final date = expirationDate;
    if (date == null) return false;
    return date.isBefore(DateTime.now());
  }

  bool get hasActiveAccess => contactVisible && (!hasExpiration || !isExpired);

  String get numeroWhatsapp {
    if (whatsapp.trim().isNotEmpty) return whatsapp.trim();
    if (telephoneWhatsapp.trim().isNotEmpty) return telephoneWhatsapp.trim();
    return '';
  }

  String get numeroPrincipal {
    if (telephone.trim().isNotEmpty) return telephone.trim();
    if (whatsapp.trim().isNotEmpty) return whatsapp.trim();
    if (telephoneWhatsapp.trim().isNotEmpty) return telephoneWhatsapp.trim();
    return '';
  }

  String get imageOrPlaceholder =>
      hasImage ? image : 'https://via.placeholder.com/300';

  String get localisation {
    final parts = [quartier, ville]
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return parts.isEmpty ? 'Localisation non renseignée' : parts.join(', ');
  }

  String get contactAffiche {
    if (hasActiveAccess && numeroPrincipal.isNotEmpty) {
      return numeroPrincipal;
    }
    return '🔒 Débloquer (500 FCFA)';
  }

  Artisan copyWith({
    int? id,
    String? nom,
    String? metier,
    String? description,
    String? telephone,
    String? whatsapp,
    String? telephoneWhatsapp,
    String? ville,
    String? quartier,
    String? image,
    bool? sponsorise,
    bool? contactVisible,
    String? expireLe,
  }) {
    return Artisan(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      metier: metier ?? this.metier,
      description: description ?? this.description,
      telephone: telephone ?? this.telephone,
      whatsapp: whatsapp ?? this.whatsapp,
      telephoneWhatsapp: telephoneWhatsapp ?? this.telephoneWhatsapp,
      ville: ville ?? this.ville,
      quartier: quartier ?? this.quartier,
      image: image ?? this.image,
      sponsorise: sponsorise ?? this.sponsorise,
      contactVisible: contactVisible ?? this.contactVisible,
      expireLe: expireLe ?? this.expireLe,
    );
  }

  Artisan updateFromApi(Map<String, dynamic> json) {
    final telephone = json.containsKey('telephone')
        ? _parseString(json['telephone'])
        : this.telephone;

    final whatsapp = json.containsKey('whatsapp') ||
            json.containsKey('telephone_whatsapp') ||
            json.containsKey('telephone')
        ? _parseWhatsapp({
            'whatsapp': json['whatsapp'],
            'telephone_whatsapp': json['telephone_whatsapp'],
            'telephone':
                json.containsKey('telephone') ? json['telephone'] : this.telephone,
          })
        : this.whatsapp;

    final telephoneWhatsapp = json.containsKey('telephone_whatsapp') ||
            json.containsKey('whatsapp') ||
            json.containsKey('telephone')
        ? _parseTelephoneWhatsapp(
            {
              'telephone_whatsapp': json['telephone_whatsapp'],
            },
            whatsapp,
            telephone,
          )
        : this.telephoneWhatsapp;

    return copyWith(
      nom: json.containsKey('nom') ? _parseString(json['nom']) : this.nom,
      metier: json.containsKey('metier')
          ? _parseString(json['metier'])
          : this.metier,
      description: json.containsKey('description')
          ? _parseString(json['description'])
          : this.description,
      telephone: telephone,
      whatsapp: whatsapp,
      telephoneWhatsapp: telephoneWhatsapp,
      ville: json.containsKey('ville')
          ? _parseString(json['ville'])
          : this.ville,
      quartier: json.containsKey('quartier')
          ? _parseString(json['quartier'])
          : this.quartier,
      image: (json.containsKey('image') || json.containsKey('photo'))
          ? _parseImage(json)
          : this.image,
      sponsorise: json.containsKey('sponsorise') ||
              json.containsKey('est_premium')
          ? _parseSponsorise(json)
          : this.sponsorise,
      contactVisible: _containsAny(
        json,
        const [
          'can_view_phone',
          'contact_visible',
          'has_access',
          'already_paid',
        ],
      )
          ? _parseContactVisible(json)
          : this.contactVisible,
      expireLe: json.containsKey('expire_le')
          ? _parseString(json['expire_le'])
          : this.expireLe,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'metier': metier,
      'description': description,
      'telephone': telephone,
      'whatsapp': whatsapp,
      'telephone_whatsapp': telephoneWhatsapp,
      'ville': ville,
      'quartier': quartier,
      'image': image,
      'sponsorise': sponsorise,
      'contact_visible': contactVisible,
      'can_view_phone': contactVisible,
      'has_access': contactVisible,
      'already_paid': contactVisible,
      'expire_le': expireLe,
    };
  }

  @override
  String toString() {
    return 'Artisan('
        'id: $id, '
        'nom: $nom, '
        'metier: $metier, '
        'ville: $ville, '
        'quartier: $quartier, '
        'contactVisible: $contactVisible, '
        'expireLe: $expireLe'
        ')';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Artisan && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  static bool _containsAny(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      if (json.containsKey(key)) return true;
    }
    return false;
  }

  static String _parseString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString().trim()) ?? 0;
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;

    if (value is String) {
      final v = value.toLowerCase().trim();
      return v == 'true' ||
          v == '1' ||
          v == 'yes' ||
          v == 'oui' ||
          v == 'on';
    }

    return false;
  }

  static bool _parseContactVisible(Map<String, dynamic> json) {
    return _parseBool(
      json['can_view_phone'] ??
          json['contact_visible'] ??
          json['has_access'] ??
          json['already_paid'],
    );
  }

  static String _parseWhatsapp(Map<String, dynamic> json) {
    final whatsapp = _parseString(json['whatsapp']);
    if (whatsapp.isNotEmpty) return whatsapp;

    final telephoneWhatsapp = _parseString(json['telephone_whatsapp']);
    if (telephoneWhatsapp.isNotEmpty) return telephoneWhatsapp;

    return '';
  }

  static String _parseTelephoneWhatsapp(
    Map<String, dynamic> json,
    String whatsapp,
    String telephone,
  ) {
    final telephoneWhatsapp = _parseString(json['telephone_whatsapp']);
    if (telephoneWhatsapp.isNotEmpty) return telephoneWhatsapp;
    if (whatsapp.isNotEmpty) return whatsapp;
    return telephone;
  }

  static bool _parseSponsorise(Map<String, dynamic> json) {
    if (json.containsKey('sponsorise')) {
      return _parseBool(json['sponsorise']);
    }

    if (json.containsKey('est_premium')) {
      return _parseBool(json['est_premium']);
    }

    return false;
  }

  static String _parseImage(Map<String, dynamic> json) {
    final raw = _parseString(json['image'] ?? json['photo'] ?? '');

    if (raw.isEmpty) return '';

    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }

    final base = AppConfig.baseUrl.trim().replaceAll(RegExp(r'/+$'), '');

    if (raw.startsWith('/')) {
      return '$base$raw';
    }

    return '$base/$raw';
  }
}