class WallpaperModel {
  const WallpaperModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.thumbnailUrl,
    required this.createdAt,
  });

  final int id;
  final String name;
  final String imageUrl;
  final String thumbnailUrl;
  final DateTime? createdAt;

  factory WallpaperModel.fromJson(Map<String, dynamic> json) {
    return WallpaperModel(
      id: _parseInt(json['id']),
      name: (json['name'] as String?)?.trim() ?? '',
      imageUrl: (json['image_url'] as String?)?.trim() ?? '',
      thumbnailUrl: (json['thumbnail_url'] as String?)?.trim() ?? '',
      createdAt: DateTime.tryParse(
        ((json['created_at'] as String?) ?? '').replaceFirst(' ', 'T'),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image_url': imageUrl,
      'thumbnail_url': thumbnailUrl,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  static int _parseInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
