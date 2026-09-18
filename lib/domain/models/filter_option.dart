/// The small, tasteful set of photo filters offered after capture.
enum PhotoFilterType { original, vivid, warm, cool, mono, noir, vintage, soft }

/// Display metadata for a [PhotoFilterType].
class FilterOption {
  const FilterOption({required this.type, required this.label});

  final PhotoFilterType type;
  final String label;

  static const List<FilterOption> all = [
    FilterOption(type: PhotoFilterType.original, label: 'Original'),
    FilterOption(type: PhotoFilterType.vivid, label: 'Vivid'),
    FilterOption(type: PhotoFilterType.warm, label: 'Warm'),
    FilterOption(type: PhotoFilterType.cool, label: 'Cool'),
    FilterOption(type: PhotoFilterType.mono, label: 'Mono'),
    FilterOption(type: PhotoFilterType.noir, label: 'Noir'),
    FilterOption(type: PhotoFilterType.vintage, label: 'Vintage'),
    FilterOption(type: PhotoFilterType.soft, label: 'Soft'),
  ];
}
