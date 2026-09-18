/// A category used to organize pose references (e.g. "Standing", "Sitting").
class PoseCategory {
  const PoseCategory({
    required this.id,
    required this.title,
    this.description = '',
    this.isCustom = false,
  });

  final String id;
  final String title;
  final String description;

  /// Custom categories are created by the user for their own imported poses
  /// and can be removed; built-in categories cannot.
  final bool isCustom;

  factory PoseCategory.fromJson(Map<String, dynamic> json) {
    return PoseCategory(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      isCustom: json['isCustom'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'isCustom': isCustom,
  };

  @override
  bool operator ==(Object other) => other is PoseCategory && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Sentinel category id used for uncategorized custom poses.
const String kUncategorizedCategoryId = 'uncategorized';
