class Residence {
  final int id;
  final String titre;
  final String description;
  final dynamic prix;
  final String ville;
  final String quartier;
  final String adresse;
  final String type;
  final int capacite;
  final String telephone;
  final String telephoneWhatsApp;
  final bool isSponsored;
  final bool estActif;
  final List<String> images;
  final int userId;

  const Residence({
    required this.id,
    required this.titre,
    required this.description,
    required this.prix,
    required this.ville,
    required this.quartier,
    required this.adresse,
    required this.type,
    required this.capacite,
    required this.telephone,
    required this.telephoneWhatsApp,
    required this.isSponsored,
    required this.estActif,
    required this.images,
    required this.userId,
  });

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    return int.tryParse(value.toString()) ?? 0;
  }

  static String _parseString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;

    final text = value?.toString().toLowerCase().trim() ?? '';
    return text == 'true' || text == '1' || text == 'yes';
  }

  static List<String> _parseImages(dynamic value) {
    if (value is List) {
      return value
          .map((e) => e?.toString().trim() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return <String>[];
  }

  factory Residence.fromJson(Map<String, dynamic> json) {
    return Residence(
      id: _parseInt(json['id']),
      titre: _parseString(json['titre']),
      description: _parseString(json['description']),
      prix: json['prix'] ?? json['prix_par_nuit'] ?? '',
      ville: _parseString(json['ville']),
      quartier: _parseString(json['quartier']),
      adresse: _parseString(json['adresse']),
      type: _parseString(json['type']),
      capacite: _parseInt(json['capacite']),
      telephone: _parseString(json['telephone']),
      telephoneWhatsApp: _parseString(
        json['telephone_whatsapp'] ?? json['whatsapp'],
      ),
      isSponsored: _parseBool(
        json['is_sponsored'] ?? json['sponsorise'] ?? json['sponsored'],
      ),
      estActif: _parseBool(
        json['est_actif'] ?? json['actif'] ?? true,
      ),
      images: _parseImages(json['images']),
      userId: _parseInt(
        json['user'] ??
            json['owner'] ??
            json['proprietaire'] ??
            json['user_id'],
      ),
    );
  }

  Residence copyWith({
    int? id,
    String? titre,
    String? description,
    dynamic prix,
    String? ville,
    String? quartier,
    String? adresse,
    String? type,
    int? capacite,
    String? telephone,
    String? telephoneWhatsApp,
    bool? isSponsored,
    bool? estActif,
    List<String>? images,
    int? userId,
  }) {
    return Residence(
      id: id ?? this.id,
      titre: titre ?? this.titre,
      description: description ?? this.description,
      prix: prix ?? this.prix,
      ville: ville ?? this.ville,
      quartier: quartier ?? this.quartier,
      adresse: adresse ?? this.adresse,
      type: type ?? this.type,
      capacite: capacite ?? this.capacite,
      telephone: telephone ?? this.telephone,
      telephoneWhatsApp: telephoneWhatsApp ?? this.telephoneWhatsApp,
      isSponsored: isSponsored ?? this.isSponsored,
      estActif: estActif ?? this.estActif,
      images: images ?? this.images,
      userId: userId ?? this.userId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titre': titre,
      'description': description,
      'prix': prix,
      'ville': ville,
      'quartier': quartier,
      'adresse': adresse,
      'type': type,
      'capacite': capacite,
      'telephone': telephone,
      'telephone_whatsapp': telephoneWhatsApp,
      'is_sponsored': isSponsored,
      'est_actif': estActif,
      'images': images,
      'user': userId,
    };
  }
}