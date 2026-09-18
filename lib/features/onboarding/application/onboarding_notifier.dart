import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';

final onboardingCompleteProvider = NotifierProvider<OnboardingNotifier, bool>(
  OnboardingNotifier.new,
);

class OnboardingNotifier extends Notifier<bool> {
  @override
  bool build() {
    return ref.read(settingsRepositoryProvider).isOnboardingComplete();
  }

  Future<void> complete() async {
    state = true;
    await ref.read(settingsRepositoryProvider).setOnboardingComplete(true);
  }

  /// Exposed for Settings > "Reset onboarding".
  Future<void> reset() async {
    state = false;
    await ref.read(settingsRepositoryProvider).setOnboardingComplete(false);
  }
}
