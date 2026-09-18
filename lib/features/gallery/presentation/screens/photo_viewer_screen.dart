import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../domain/models/captured_photo.dart';

/// Full-screen view of a single capture, with share support. This never
/// edits or re-saves the photo — it is already in the system gallery.
class PhotoViewerScreen extends StatelessWidget {
  const PhotoViewerScreen({super.key, required this.photo});

  final CapturedPhoto photo;

  @override
  Widget build(BuildContext context) {
    final file = File(photo.filePath);
    return Scaffold(
      backgroundColor: AppColors.cameraBackdrop,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(DateFormat.yMMMd().add_jm().format(photo.capturedAt)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => SharePlus.instance.share(
              ShareParams(files: [XFile(photo.filePath)]),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: file.existsSync()
                ? InteractiveViewer(
                    child: Image.file(file, fit: BoxFit.contain),
                  )
                : const Text(
                    'This photo is no longer available.',
                    style: TextStyle(color: Colors.white70),
                  ),
          ),
        ),
      ),
    );
  }
}
