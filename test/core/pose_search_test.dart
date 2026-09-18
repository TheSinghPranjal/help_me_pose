import 'package:flutter_test/flutter_test.dart';
import 'package:help_me_pose/core/utils/pose_search.dart';
import 'package:help_me_pose/domain/models/pose.dart';

Pose _pose({
  required String title,
  required String categoryId,
  List<String> tags = const [],
}) {
  return Pose(
    id: title,
    title: title,
    categoryId: categoryId,
    imagePath: 'assets/poses/$categoryId/x.svg',
    source: PoseSource.builtIn,
    tags: tags,
    isSvg: true,
  );
}

void main() {
  final categoryTitles = {'standing': 'Standing', 'sitting': 'Sitting'};

  group('matchesPoseQuery', () {
    test('empty query always matches', () {
      final pose = _pose(title: 'Standing 1', categoryId: 'standing');
      expect(matchesPoseQuery(pose, '', categoryTitles), isTrue);
    });

    test('matches by title case-insensitively', () {
      final pose = _pose(title: 'Standing 1', categoryId: 'standing');
      expect(matchesPoseQuery(pose, 'STANDING', categoryTitles), isTrue);
    });

    test('matches by resolved category title, not the raw id', () {
      final pose = _pose(title: 'Pose A', categoryId: 'sitting');
      expect(matchesPoseQuery(pose, 'sitting', categoryTitles), isTrue);
      expect(matchesPoseQuery(pose, 'sit_ting', categoryTitles), isFalse);
    });

    test('matches by tag', () {
      final pose = _pose(
        title: 'Pose A',
        categoryId: 'standing',
        tags: const ['outdoor', 'casual'],
      );
      expect(matchesPoseQuery(pose, 'casual', categoryTitles), isTrue);
    });

    test('does not match unrelated queries', () {
      final pose = _pose(
        title: 'Pose A',
        categoryId: 'standing',
        tags: const ['casual'],
      );
      expect(matchesPoseQuery(pose, 'underwater', categoryTitles), isFalse);
    });
  });
}
