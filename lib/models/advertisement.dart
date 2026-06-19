class Advertisement {
  final int id;
  final String titre;
  final String description;
  final String image;
  final String lien;
  final String type;
  final String position;
  final bool actif;

  const Advertisement({
    required this.id,
    required this.titre,
    required this.description,
    required this.image,
    required this.lien,
    required this.type,
    required this.position,
    required this.actif,
  });

  factory Advertisement.fromJson(Map<String, dynamic> json) {
    return Advertisement(
      id: _parseInt(json['id']),
      titre: _parseString(json['titre']),
      description: _parseString(json['description']),
      image: _buildImageUrl(json['image']),
      lien: _parseString(json['lien']),
      type: _parseString(json['type']),
      position: _parseString(json['position']),
      actif: _parseBool(json['actif']),
    );
  }

  bool get hasImage => image.trim().isNotEmpty;

  bool get hasLink => lien.trim().isNotEmpty;

  bool get isBanner => type.toLowerCase().trim() == 'banner';

  bool get isPopup => type.toLowerCase().trim() == 'popup';

  bool get isTopPosition => position.toLowerCase().trim() == 'top';

  bool get isBottomPosition => position.toLowerCase().trim() == 'bottom';

  bool get isHomePosition => position.toLowerCase().trim() == 'home';

  bool get isVisible => actif;

  String get titreAffiche =>
      titre.trim().isNotEmpty ? titre.trim() : 'Offre sponsorisée';

  String get descriptionAffiche => description.trim().isNotEmpty
      ? description.trim()
      : 'Découvrez cette publicité mise en avant dans l’application.';

  String get typeAffiche =>
      type.trim().isNotEmpty ? type.trim() : 'Publicité';

  Advertisement copyWith({
    int? id,
    String? titre,
    String? description,
    String? image,
    String? lien,
    String? type,
    String? position,
    bool? actif,
  }) {
    return Advertisement(
      id: id ?? this.id,
      titre: titre ?? this.titre,
      description: description ?? this.description,
      image: image ?? this.image,
      lien: lien ?? this.lien,
      type: type ?? this.type,
      position: position ?? this.position,
      actif: actif ?? this.actif,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titre': titre,
      'description': description,
      'image': image,
      'lien': lien,
      'type': type,
      'position': position,
      'actif': actif,
    };
  }

  @override
  String toString() {
    return 'Advertisement(id: $id, titre: $titre, type: $type, position: $position, actif: $actif)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Advertisement &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  static String _parseString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;

    if (value is String) {
      final v = value.trim().toLowerCase();
      return v == 'true' ||
          v == '1' ||
          v == 'yes' ||
          v == 'oui' ||
          v == 'on';
    }

    return false;
  }

  static String _buildImageUrl(dynamic value) {
    final raw = _parseString(value);

    if (raw.isEmpty) return '';

    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }

    if (raw.startsWith('/')) {
      return 'https://antoinekakawah.pythonanywhere.com$raw';
    }

    return 'https://antoinekakawah.pythonanywhere.com/$raw';
  }
}