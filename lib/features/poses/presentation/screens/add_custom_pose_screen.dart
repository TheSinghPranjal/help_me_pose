import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../../../../core/theme/app_spacing.dart';
import '../../../../domain/models/pose_category.dart';
import '../../application/pose_providers.dart';
import '../widgets/category_selector.dart';

/// Import flow for a user's own reference photos ("My Poses"). Supports
/// picking a single photo (with a full metadata form) or several at once
/// for a quick batch import.
///
/// Uses the platform's modern photo picker (`image_picker`), which on
/// current Android/iOS versions requires no runtime permission at all.
class AddCustomPoseScreen extends ConsumerStatefulWidget {
  const AddCustomPoseScreen({super.key});

  @override
  ConsumerState<AddCustomPoseScreen> createState() =>
      _AddCustomPoseScreenState();
}

class _AddCustomPoseScreenState extends ConsumerState<AddCustomPoseScreen> {
  final _picker = ImagePicker();
  final _nameController = TextEditingController();
  final _tagsController = TextEditingController();
  XFile? _picked;
  String _categoryId = kUncategorizedCategoryId;
  bool _saving = false;
  bool _importingBatch = false;

  @override
  void dispose() {
    _nameController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickSingle() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
    );
    if (file == null || !mounted) return;
    setState(() {
      _picked = file;
      _nameController.text = _prettify(p.basenameWithoutExtension(file.path));
    });
  }

  Future<void> _pickMultiple() async {
    final files = await _picker.pickMultiImage(imageQuality: 95);
    if (files.isEmpty || !mounted) return;
    setState(() => _importingBatch = true);
    for (final file in files) {
      await ref
          .read(customPosesProvider.notifier)
          .importPose(
            sourceFilePath: file.path,
            title: _prettify(p.basenameWithoutExtension(file.path)),
            categoryId: kUncategorizedCategoryId,
          );
    }
    if (!mounted) return;
    setState(() => _importingBatch = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Imported ${files.length} pose${files.length == 1 ? '' : 's'}',
        ),
      ),
    );
    Navigator.of(context).pop();
  }

  String _prettify(String filename) {
    final cleaned = filename.replaceAll(RegExp(r'[_\-]+'), ' ').trim();
    if (cleaned.isEmpty) return 'My Pose';
    return cleaned[0].toUpperCase() + cleaned.substring(1);
  }

  Future<void> _save() async {
    if (_picked == null || _saving) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please give this pose a name.')),
      );
      return;
    }
    setState(() => _saving = true);
    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    try {
      await ref
          .read(customPosesProvider.notifier)
          .importPose(
            sourceFilePath: _picked!.path,
            title: name,
            categoryId: _categoryId,
            tags: tags,
          );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_picked == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Add Pose')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: _importingBatch
                ? const CircularProgressIndicator()
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_photo_alternate_outlined, size: 48),
                      const SizedBox(height: AppSpacing.lg),
                      const Text(
                        'Import a reference photo from your gallery to build your own pose collection.',
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _pickSingle,
                          child: const Text('Choose a Photo'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _pickMultiple,
                          child: const Text('Import Multiple Photos'),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('New Pose')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: AspectRatio(
              aspectRatio: 4 / 5,
              child: Image.file(File(_picked!.path), fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
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
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _tagsController,
            decoration: const InputDecoration(
              labelText: 'Tags (optional, comma separated)',
            ),
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
                  : const Text('Save to My Poses'),
            ),
          ),
        ],
      ),
    );
  }
}
