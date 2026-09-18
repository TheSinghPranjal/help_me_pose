import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/providers/navigation_providers.dart';
import 'core/routing/app_shell.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/application/onboarding_notifier.dart';
import 'features/onboarding/presentation/screens/onboarding_screen.dart';
import 'features/settings/application/settings_notifier.dart';

class HelpMePoseApp extends ConsumerWidget {
  const HelpMePoseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(
      settingsNotifierProvider.select((s) => s.themeMode),
    );
    final onboardingComplete = ref.watch(onboardingCompleteProvider);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      navigatorObservers: [appRouteObserver],
      home: onboardingComplete ? const AppShell() : const OnboardingScreen(),
    );
  }
}
