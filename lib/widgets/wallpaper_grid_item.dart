import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/wallpaper_model.dart';

class WallpaperGridItem extends StatelessWidget {
  const WallpaperGridItem({
    super.key,
    required this.wallpaper,
    required this.index,
    required this.onTap,
  });

  final WallpaperModel wallpaper;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final height = index.isEven ? 250.0 : 320.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.38),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: wallpaper.thumbnailUrl,
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 260),
                placeholder: (context, url) => const _ImageSkeleton(),
                errorWidget: (context, url, error) => const _ImageError(),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.56),
                      ],
                      stops: const [0.55, 1],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Text(
                    //   _formatName(wallpaper.name),
                    //   maxLines: 1,
                    //   overflow: TextOverflow.ellipsis,
                    //   style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    //     color: Colors.white,
                    //     fontWeight: FontWeight.w700,
                    //     shadows: const [
                    //       Shadow(
                    //         color: Colors.black54,
                    //         blurRadius: 8,
                    //       ),
                    //     ],
                    //   ),
                    // ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.play_circle_outline_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Live',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            fontSize: 16
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageSkeleton extends StatelessWidget {
  const _ImageSkeleton();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1B1F2A),
            const Color(0xFF252B38).withValues(alpha: 0.9),
          ],
        ),
      ),
    );
  }
}

class _ImageError extends StatelessWidget {
  const _ImageError();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF181C24),
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: Color(0xFF8892A6),
        ),
      ),
    );
  }
}
