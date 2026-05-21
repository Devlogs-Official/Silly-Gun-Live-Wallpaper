import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerGrid extends StatelessWidget {
  const ShimmerGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 48) {
          return const SizedBox.shrink();
        }

        return MasonryGridView.count(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          itemCount: 8,
          itemBuilder: (context, index) {
            return Shimmer.fromColors(
              baseColor: const Color(0xFF202633),
              highlightColor: const Color(0xFF323B4D),
              period: const Duration(milliseconds: 1200),
              child: Container(
                height: index.isEven ? 250 : 320,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
