import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../domain/models/pose.dart';
import '../../application/pose_providers.dart';
import '../widgets/category_selector.dart';

/// Rename and re-categorize an existing custom pose. The built-in library
/// is read-only and never routes here.
class EditCustomPoseScreen extends ConsumerStatefulWidget {
  const EditCustomPoseScreen({super.key, required this.pose});

  final Pose pose;

  @override
  ConsumerState<EditCustomPoseScreen> createState() =>
      _EditCustomPoseScreenState();
}

class _EditCustomPoseScreenState extends ConsumerState<EditCustomPoseScreen> {
  late final _nameController = TextEditingController(text: widget.pose.title);
  late String _categoryId = widget.pose.categoryId;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _saving) return;
    setState(() => _saving = true);
    await ref
        .read(customPosesProvider.notifier)
        .update(widget.pose.copyWith(title: name, categoryId: _categoryId));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Pose')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Category', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          CategorySelector(
            selectedCategoryId: _categoryId,
            onSelected: (id) => setState(() => _categoryId = id),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Changes'),
            ),
          ),
        ],
      ),
    );
  }
}
