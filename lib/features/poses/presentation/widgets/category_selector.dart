import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/models/pose_category.dart';
import '../../application/pose_providers.dart';

/// Category picker used when importing or editing a custom pose. Lets the
/// user choose an existing category (built-in or custom) or create a new
/// custom one on the fly.
class CategorySelector extends ConsumerWidget {
  const CategorySelector({
    super.key,
    required this.selectedCategoryId,
    required this.onSelected,
  });

  final String selectedCategoryId;
  final ValueChanged<String> onSelected;

  Future<void> _createCategory(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. Studio'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (title == null || title.isEmpty) return;
    final id =
        'custom_${title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}';
    await ref
        .read(customCategoriesProvider.notifier)
        .add(PoseCategory(id: id, title: title, isCustom: true));
    onSelected(id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allCategories = ref.watch(allCategoriesProvider);
    return allCategories.when(
      loading: () => const SizedBox(
        height: 40,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => Text('Could not load categories: $e'),
      data: (categories) {
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Uncategorized'),
              selected: selectedCategoryId == kUncategorizedCategoryId,
              onSelected: (_) => onSelected(kUncategorizedCategoryId),
            ),
            for (final category in categories)
              ChoiceChip(
                label: Text(category.title),
                selected: selectedCategoryId == category.id,
                onSelected: (_) => onSelected(category.id),
              ),
            ActionChip(
              avatar: const Icon(Icons.add, size: 16),
              label: const Text('New'),
              onPressed: () => _createCategory(context, ref),
            ),
          ],
        );
      },
    );
  }
}
