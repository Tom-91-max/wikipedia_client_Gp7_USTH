import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Skeleton đơn giản dùng cho list item.
class AppSkeleton extends StatelessWidget {
  final double height;
  final EdgeInsetsGeometry padding;

  const AppSkeleton({
    super.key,
    this.height = 64,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Shimmer.fromColors(
        baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        highlightColor: Theme.of(context).colorScheme.surface,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
