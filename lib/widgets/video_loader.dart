import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class VideoLoader extends StatelessWidget {
  const VideoLoader({
    super.key,
    this.borderRadius = 30,
  });

  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF171B24),
      highlightColor: const Color(0xFF2B3444),
      period: const Duration(milliseconds: 1100),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}
