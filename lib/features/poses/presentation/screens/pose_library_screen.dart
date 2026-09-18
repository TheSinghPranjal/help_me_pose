import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/pose_search.dart';
import '../../../../domain/models/pose_category.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../application/pose_providers.dart';
import '../widgets/pose_card.dart';
import 'add_custom_pose_screen.dart';
import 'pose_detail_screen.dart';

enum _LibraryFilter { all, favorites, recent }

class PoseLibraryScreen extends ConsumerStatefulWidget {
  const PoseLibraryScreen({super.key});

  @override
  ConsumerState<PoseLibraryScreen> createState() => _PoseLibraryScreenState();
}

class _PoseLibraryScreenState extends ConsumerState<PoseLibraryScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pose Library'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Library'),
              Tab(text: 'My Poses'),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                0,
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) =>
                    setState(() => _query = v.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search poses, categories, tags',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        ),
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _LibraryTab(query: _query),
                  _MyPosesTab(query: _query),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryTab extends ConsumerStatefulWidget {
  const _LibraryTab({required this.query});

  final String query;

  @override
  ConsumerState<_LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends ConsumerState<_LibraryTab>
    with AutomaticKeepAliveClientMixin {
  String? _selectedCategoryId;
  _LibraryFilter _filter = _LibraryFilter.all;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final posesAsync = ref.watch(builtInPosesProvider);
    final categoriesAsync = ref.watch(builtInCategoriesProvider);
    final favorites = ref.watch(favoritePoseIdsProvider);
    final recentIds = ref.watch(recentPoseIdsProvider);

    return categoriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(
        icon: Icons.error_outline,
        title: 'Could not load pose library',
        message: '$e',
      ),
      data: (categories) {
        final categoryTitles = {for (final c in categories) c.id: c.title};
        return posesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => EmptyState(
            icon: Icons.error_outline,
            title: 'Could not load poses',
            message: '$e',
          ),
          data: (poses) {
            var filtered = poses.where(
              (p) => matchesPoseQuery(p, widget.query, categoryTitles),
            );
            if (_selectedCategoryId != null) {
              filtered = filtered.where(
                (p) => p.categoryId == _selectedCategoryId,
              );
            }
            switch (_filter) {
              case _LibraryFilter.favorites:
                filtered = filtered.where((p) => favorites.contains(p.id));
              case _LibraryFilter.recent:
                filtered = filtered.where((p) => recentIds.contains(p.id));
              case _LibraryFilter.all:
                break;
            }
            final list = filtered.toList();
            if (_filter == _LibraryFilter.recent) {
              list.sort(
                (a, b) =>
                    recentIds.indexOf(a.id).compareTo(recentIds.indexOf(b.id)),
              );
            }

            return Column(
              children: [
                _buildChipsRow(categories),
                Expanded(
                  child: list.isEmpty
                      ? EmptyState(
                          icon: Icons.search_off_rounded,
                          title: 'No poses found',
                          message: 'Try a different search term or category.',
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: AppSpacing.sm,
                                mainAxisSpacing: AppSpacing.sm,
                                childAspectRatio: 0.72,
                              ),
                          itemCount: list.length,
                          itemBuilder: (context, i) {
                            final pose = list[i];
                            return PoseCard(
                              pose: pose,
                              isFavorite: favorites.contains(pose.id),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => PoseDetailScreen(pose: pose),
                                ),
                              ),
                              onToggleFavorite: () => ref
                                  .read(favoritePoseIdsProvider.notifier)
                                  .toggle(pose.id),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildChipsRow(List<PoseCategory> categories) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 4,
        ),
        children: [
          _FilterChip(
            label: 'All',
            selected:
                _filter == _LibraryFilter.all && _selectedCategoryId == null,
            onTap: () {
              setState(() {
                _filter = _LibraryFilter.all;
                _selectedCategoryId = null;
              });
            },
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Favorites',
            selected: _filter == _LibraryFilter.favorites,
            onTap: () => setState(() => _filter = _LibraryFilter.favorites),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Recent',
            selected: _filter == _LibraryFilter.recent,
            onTap: () => setState(() => _filter = _LibraryFilter.recent),
          ),
          const SizedBox(width: 16),
          for (final category in categories) ...[
            _FilterChip(
              label: category.title,
              selected: _selectedCategoryId == category.id,
              onTap: () => setState(() {
                _filter = _LibraryFilter.all;
                _selectedCategoryId = _selectedCategoryId == category.id
                    ? null
                    : category.id;
              }),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _MyPosesTab extends ConsumerStatefulWidget {
  const _MyPosesTab({required this.query});

  final String query;

  @override
  ConsumerState<_MyPosesTab> createState() => _MyPosesTabState();
}

class _MyPosesTabState extends ConsumerState<_MyPosesTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final customPoses = ref.watch(customPosesProvider);
    final favorites = ref.watch(favoritePoseIdsProvider);
    final customCategories = ref.watch(customCategoriesProvider);
    final categoryTitles = {
      for (final c in customCategories) c.id: c.title,
      kUncategorizedCategoryId: 'Uncategorized',
    };

    final filtered =
        customPoses
            .where((p) => matchesPoseQuery(p, widget.query, categoryTitles))
            .toList()
          ..sort(
            (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
              a.createdAt ?? DateTime(0),
            ),
          );

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const AddCustomPoseScreen())),
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text('Add Pose'),
      ),
      body: filtered.isEmpty
          ? EmptyState(
              icon: Icons.collections_outlined,
              title: widget.query.isEmpty
                  ? 'No custom poses yet'
                  : 'No poses found',
              message: widget.query.isEmpty
                  ? 'Import reference photos from your gallery to build your own pose collection.'
                  : 'Try a different search term.',
              actionLabel: widget.query.isEmpty ? 'Add Pose' : null,
              onAction: widget.query.isEmpty
                  ? () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AddCustomPoseScreen(),
                      ),
                    )
                  : null,
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                96,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                childAspectRatio: 0.72,
              ),
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final pose = filtered[i];
                return PoseCard(
                  pose: pose,
                  isFavorite: favorites.contains(pose.id),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PoseDetailScreen(pose: pose),
                    ),
                  ),
                  onToggleFavorite: () => ref
                      .read(favoritePoseIdsProvider.notifier)
                      .toggle(pose.id),
                );
              },
            ),
    );
  }
}
