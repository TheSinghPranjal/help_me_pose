import 'package:flutter_test/flutter_test.dart';
import 'package:help_me_pose/domain/models/overlay_settings.dart';

void main() {
  group('OverlaySettings', () {
    test(
      'defaults to 10% opacity, default scale, centered, and normal mode',
      () {
        const settings = OverlaySettings();
        expect(settings.opacity, closeTo(0.10, 0.0001));
        expect(settings.scale, 1.0);
        expect(settings.offset, Offset.zero);
        expect(settings.isAdjustMode, isFalse);
      },
    );

    test('copyWith only changes the requested fields', () {
      const settings = OverlaySettings(
        opacity: 0.3,
        scale: 1.2,
        offset: Offset(5, 5),
      );
      final updated = settings.copyWith(opacity: 0.5);
      expect(updated.opacity, 0.5);
      expect(updated.scale, 1.2);
      expect(updated.offset, const Offset(5, 5));
    });

    test(
      'resetTo returns to centered position, default scale, and the given opacity',
      () {
        const settings = OverlaySettings(
          opacity: 0.9,
          scale: 2.5,
          offset: Offset(40, -20),
          isAdjustMode: true,
        );
        final reset = settings.resetTo(0.10);
        expect(reset.opacity, 0.10);
        expect(reset.scale, 1.0);
        expect(reset.offset, Offset.zero);
        expect(reset.isAdjustMode, isFalse);
      },
    );

    test('equality is value-based', () {
      const a = OverlaySettings(opacity: 0.4, scale: 1.1, offset: Offset(1, 2));
      const b = OverlaySettings(opacity: 0.4, scale: 1.1, offset: Offset(1, 2));
      expect(a, equals(b));
    });
  });
}
