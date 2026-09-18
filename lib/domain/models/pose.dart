/// Where a pose reference image originates from.
enum PoseSource { builtIn, custom }

/// A single pose reference: either part of the built-in library (a bundled
/// vector asset) or imported by the user from their own gallery.
class Pose {
  const Pose({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.imagePath,
    required this.source,
    this.thumbnailPath,
    this.tags = const [],
    this.attribution = '',
    this.createdAt,
    this.isSvg = false,
  });

  final String id;
  final String title;
  final String categoryId;

  /// Asset path (for built-in poses) or absolute file path (for custom poses).
  final String imagePath;
  final String? thumbnailPath;
  final PoseSource source;
  final List<String> tags;

  /// Source/license note, shown in pose details for transparency.
  final String attribution;
  final DateTime? createdAt;

  /// True when [imagePath] points to a bundled SVG asset rather than a
  /// raster image file.
  final bool isSvg;

  bool get isBuiltIn => source == PoseSource.builtIn;
  bool get isCustom => source == PoseSource.custom;

  Pose copyWith({
    String? title,
    String? categoryId,
    String? thumbnailPath,
    List<String>? tags,
  }) {
    return Pose(
      id: id,
      title: title ?? this.title,
      categoryId: categoryId ?? this.categoryId,
      imagePath: imagePath,
      source: source,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      tags: tags ?? this.tags,
      attribution: attribution,
      createdAt: createdAt,
      isSvg: isSvg,
    );
  }

  factory Pose.fromJson(Map<String, dynamic> json) {
    return Pose(
      id: json['id'] as String,
      title: json['title'] as String,
      categoryId: json['categoryId'] as String,
      imagePath: json['imagePath'] as String,
      thumbnailPath: json['thumbnailPath'] as String?,
      source: PoseSource.values.byName(json['source'] as String? ?? 'custom'),
      tags: (json['tags'] as List<dynamic>? ?? const []).cast<String>(),
      attribution: json['attribution'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      isSvg: json['isSvg'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'categoryId': categoryId,
    'imagePath': imagePath,
    'thumbnailPath': thumbnailPath,
    'source': source.name,
    'tags': tags,
    'attribution': attribution,
    'createdAt': createdAt?.toIso8601String(),
    'isSvg': isSvg,
  };

  @override
  bool operator ==(Object other) => other is Pose && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
