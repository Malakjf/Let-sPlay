/// Field (Stadium) model
class Field {
  final String id;
  final String name;
  final String description;
  final String location;
  final double? latitude;
  final double? longitude;
  final List<String> images;
  final double pricePerHour;
  final bool isAvailable;
  final String? fieldType; // e.g., "5-a-side", "7-a-side", "11-a-side"
  final DateTime createdAt;
  final DateTime? updatedAt;

  Field({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    this.latitude,
    this.longitude,
    this.images = const [],
    this.pricePerHour = 0.0,
    this.isAvailable = true,
    this.fieldType,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create Field from Firestore document
  factory Field.fromFirestore(Map<String, dynamic> data, String id) {
    return Field(
      id: id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      location: data['location'] as String? ?? '',
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      images:
          (data['images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      pricePerHour: (data['pricePerHour'] as num?)?.toDouble() ?? 0.0,
      isAvailable: data['isAvailable'] as bool? ?? true,
      fieldType: data['fieldType'] as String?,
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as dynamic)?.toDate(),
    );
  }

  /// Convert Field to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'images': images,
      'pricePerHour': pricePerHour,
      'isAvailable': isAvailable,
      'fieldType': fieldType,
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? DateTime.now(),
    };
  }

  /// Create a copy with updated fields
  Field copyWith({
    String? id,
    String? name,
    String? description,
    String? location,
    double? latitude,
    double? longitude,
    List<String>? images,
    double? pricePerHour,
    bool? isAvailable,
    String? fieldType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Field(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      images: images ?? this.images,
      pricePerHour: pricePerHour ?? this.pricePerHour,
      isAvailable: isAvailable ?? this.isAvailable,
      fieldType: fieldType ?? this.fieldType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get the first image URL or null
  String? get primaryImage => images.isNotEmpty ? images.first : null;
}
