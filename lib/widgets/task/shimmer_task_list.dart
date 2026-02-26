import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerTaskList extends StatelessWidget {
  final int count;

  const ShimmerTaskList({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final base = colorScheme.surfaceContainerHighest;
    final highlight = colorScheme.surface;

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (_, i) => Shimmer.fromColors(
        baseColor: base,
        highlightColor: highlight,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          height: 110,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(height: 16, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Container(
                        width: 70, height: 24, color: Colors.white),
                  ],
                ),
                const SizedBox(height: 10),
                Container(height: 12, color: Colors.white),
                const SizedBox(height: 6),
                Container(
                    width: 160, height: 12, color: Colors.white),
                const Spacer(),
                Container(width: 100, height: 12, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
