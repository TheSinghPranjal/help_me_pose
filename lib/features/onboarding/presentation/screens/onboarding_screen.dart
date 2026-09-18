import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/dot_page_indicator.dart';
import '../../application/onboarding_notifier.dart';

class _OnboardingStep {
  const _OnboardingStep({
    required this.title,
    required this.description,
    required this.overlayOpacity,
    required this.icon,
  });

  final String title;
  final String description;
  final double overlayOpacity;
  final IconData icon;
}

const _steps = [
  _OnboardingStep(
    title: 'Pick a pose to guide you',
    description:
        'Browse a categorized pose library or import your own reference photo from your gallery.',
    overlayOpacity: 0.9,
    icon: Icons.grid_view_rounded,
  ),
  _OnboardingStep(
    title: 'See it over your camera',
    description:
        'Your chosen pose appears as a faint, adjustable overlay on top of the live camera preview.',
    overlayOpacity: 0.10,
    icon: Icons.layers_outlined,
  ),
  _OnboardingStep(
    title: 'Line yourself up',
    description:
        'Move around until your body matches the guide. Adjust opacity, position and scale any time.',
    overlayOpacity: 0.22,
    icon: Icons.accessibility_new_rounded,
  ),
  _OnboardingStep(
    title: 'Capture the real shot',
    description:
        'The guide is never saved to your photo — only your actual camera photograph is kept, straight to your gallery.',
    overlayOpacity: 0.0,
    icon: Icons.camera_alt_rounded,
  ),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _finish() => ref.read(onboardingCompleteProvider.notifier).complete();

  void _next() {
    if (_index == _steps.length - 1) {
      _finish();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _steps.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: TextButton(
                  onPressed: isLast ? null : _finish,
                  child: Text(isLast ? '' : 'Skip'),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _steps.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => _OnboardingPage(step: _steps[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                children: [
                  DotPageIndicator(count: _steps.length, index: _index),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _next,
                      child: Text(isLast ? 'Get started' : 'Next'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.step});

  final _OnboardingStep step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: _PhoneMock(
                overlayOpacity: step.overlayOpacity,
                icon: step.icon,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            step.title,
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            step.description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PhoneMock extends StatelessWidget {
  const _PhoneMock({required this.overlayOpacity, required this.icon});

  final double overlayOpacity;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 9 / 16,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 380),
        decoration: BoxDecoration(
          color: AppColors.cameraBackdrop,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white24, width: 6),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF2A2A2E), Color(0xFF0B0B0D)],
                ),
              ),
            ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 400),
              opacity: overlayOpacity,
              child: SvgPicture.asset(
                'assets/poses/standing/standing_01.svg',
                height: 220,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: AppColors.cameraControlSurface,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
