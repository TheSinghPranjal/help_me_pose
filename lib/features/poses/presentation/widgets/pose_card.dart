import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../domain/models/pose.dart';
import '../../../../shared/widgets/pose_thumbnail.dart';

class PoseCard extends StatelessWidget {
  const PoseCard({
    super.key,
    required this.pose,
    required this.isFavorite,
    required this.onTap,
    required this.onToggleFavorite,
    this.showTitle = true,
  });

  final Pose pose;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${pose.title}, ${isFavorite ? 'favorited' : 'not favorited'}',
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Stack(
            fit: StackFit.expand,
            children: [
              PoseThumbnail(pose: pose),
              Positioned(
                top: 6,
                right: 6,
                child: _FavoriteButton(
                  isFavorite: isFavorite,
                  onTap: onToggleFavorite,
                ),
              ),
              if (showTitle)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black54],
                      ),
                    ),
                    child: Text(
                      pose.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.isFavorite, required this.onTap});

  final bool isFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black45,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Icon(
            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: isFavorite ? Colors.redAccent : Colors.white,
            size: 16,
          ),
        ),
      ),
    );
  }
}
