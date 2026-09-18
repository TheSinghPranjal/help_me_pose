import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../onboarding/application/onboarding_notifier.dart';
import '../../application/settings_notifier.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsNotifierProvider);
    final notifier = ref.read(settingsNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionHeader('Appearance'),
          RadioGroup<ThemeMode>(
            groupValue: settings.themeMode,
            onChanged: (mode) {
              if (mode != null) notifier.setThemeMode(mode);
            },
            child: Column(
              children: const [
                RadioListTile<ThemeMode>(
                  title: Text('Match system'),
                  value: ThemeMode.system,
                ),
                RadioListTile<ThemeMode>(
                  title: Text('Light'),
                  value: ThemeMode.light,
                ),
                RadioListTile<ThemeMode>(
                  title: Text('Dark'),
                  value: ThemeMode.dark,
                ),
              ],
            ),
          ),
          const Divider(),
          const _SectionHeader('Camera & overlay'),
          ListTile(
            title: const Text('Default overlay opacity'),
            subtitle: Slider(
              value: settings.defaultOverlayOpacity,
              min: AppConstants.minOverlayOpacity,
              max: AppConstants.maxOverlayOpacity,
              divisions: 20,
              label: '${(settings.defaultOverlayOpacity * 100).round()}%',
              onChanged: notifier.setDefaultOverlayOpacity,
            ),
            trailing: Text(
              '${(settings.defaultOverlayOpacity * 100).round()}%',
            ),
          ),
          SwitchListTile(
            title: const Text('Mirror selfie photos'),
            subtitle: const Text(
              'Save front-camera photos mirrored, matching what you see in the viewfinder.',
            ),
            value: settings.mirrorFrontCamera,
            onChanged: notifier.setMirrorFrontCamera,
          ),
          SwitchListTile(
            title: const Text('Haptic feedback'),
            value: settings.hapticFeedbackEnabled,
            onChanged: notifier.setHapticFeedbackEnabled,
          ),
          SwitchListTile(
            title: const Text('Save automatically after capture'),
            subtitle: const Text(
              'Turn off to review and choose a filter before saving.',
            ),
            value: settings.autoSaveAfterCapture,
            onChanged: notifier.setAutoSaveAfterCapture,
          ),
          const Divider(),
          const _SectionHeader('General'),
          ListTile(
            title: const Text('Show onboarding again'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => ref.read(onboardingCompleteProvider.notifier).reset(),
          ),
          ListTile(
            title: const Text('About Help me Pose'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showAbout(context),
          ),
          const _AppVersionTile(),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Help me Pose'),
        content: const SingleChildScrollView(
          child: Text(
            'Help me Pose overlays a reference pose on your camera preview so you can line yourself up before '
            'taking a photo. The reference is only a visual guide — it is never included in your saved photo.\n\n'
            'Your imported pose photos and captured photographs stay on your device. Nothing is uploaded '
            'anywhere unless you explicitly choose to share it.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _AppVersionTile extends StatelessWidget {
  const _AppVersionTile();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final info = snapshot.data;
        return ListTile(
          title: const Text('Version'),
          trailing: Text(
            info == null ? '' : '${info.version} (${info.buildNumber})',
          ),
        );
      },
    );
  }
}
