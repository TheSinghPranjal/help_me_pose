import '../../domain/models/pose.dart';

/// Whether [pose] matches a free-text [query] against its title, resolved
/// category title, and tags. An empty query always matches.
bool matchesPoseQuery(
  Pose pose,
  String query,
  Map<String, String> categoryTitles,
) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) return true;
  if (pose.title.toLowerCase().contains(normalized)) return true;
  if ((categoryTitles[pose.categoryId] ?? '').toLowerCase().contains(
    normalized,
  )) {
    return true;
  }
  return pose.tags.any((tag) => tag.toLowerCase().contains(normalized));
}
