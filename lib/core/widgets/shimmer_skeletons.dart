import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Foundational skeleton widget with smooth shimmer animation adapted for Light/Dark mode.
class BaseSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final Widget? child;

  const BaseSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade300,
      highlightColor: isDark ? const Color(0xFF334155) : Colors.grey.shade100,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: child,
      ),
    );
  }
}

/// Card Skeleton for lists and grid items
class CardSkeleton extends StatelessWidget {
  final double height;
  const CardSkeleton({super.key, this.height = 120});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: BaseSkeleton(
        width: double.infinity,
        height: height,
        borderRadius: 16,
      ),
    );
  }
}

/// List View Skeleton
class ListSkeleton extends StatelessWidget {
  final int itemCount;
  const ListSkeleton({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      itemBuilder: (context, index) => const CardSkeleton(height: 90),
    );
  }
}

/// Profile Screen Skeleton
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const BaseSkeleton(width: double.infinity, height: 160, borderRadius: 0),
          const SizedBox(height: 20),
          const BaseSkeleton(width: 100, height: 100, borderRadius: 50),
          const SizedBox(height: 12),
          const BaseSkeleton(width: 180, height: 24),
          const SizedBox(height: 8),
          const BaseSkeleton(width: 140, height: 14),
          const SizedBox(height: 24),
          const CardSkeleton(height: 140),
          const CardSkeleton(height: 140),
        ],
      ),
    );
  }
}

/// Dashboard Screen Skeleton
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BaseSkeleton(width: double.infinity, height: 140, borderRadius: 20),
          const SizedBox(height: 24),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              BaseSkeleton(width: 140, height: 20),
              BaseSkeleton(width: 60, height: 20),
            ],
          ),
          const SizedBox(height: 16),
          const CardSkeleton(height: 100),
          const CardSkeleton(height: 100),
          const CardSkeleton(height: 100),
        ],
      ),
    );
  }
}

/// Premium Map View Skeleton Loader
class MapSkeletonLoader extends StatelessWidget {
  const MapSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // 1. Shimmering Background Map Canvas
        const BaseSkeleton(
          width: double.infinity,
          height: double.infinity,
          borderRadius: 0,
        ),

        // 2. Top Floating Search Bar & Risk Legend Shimmer
        const Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Column(
            children: [
              // Search Input Bar Shimmer
              BaseSkeleton(
                width: double.infinity,
                height: 52,
                borderRadius: 28,
              ),
              SizedBox(height: 8),
              // Risk Legend Bar Shimmer
              BaseSkeleton(
                width: double.infinity,
                height: 34,
                borderRadius: 20,
              ),
            ],
          ),
        ),

        // 3. Right Floating Map Controls FAB Shimmer
        const Positioned(
          right: 16,
          bottom: 260,
          child: Column(
            children: [
              BaseSkeleton(width: 44, height: 44, borderRadius: 22),
              SizedBox(height: 12),
              BaseSkeleton(width: 44, height: 44, borderRadius: 22),
              SizedBox(height: 12),
              BaseSkeleton(width: 44, height: 44, borderRadius: 22),
            ],
          ),
        ),

        // 4. Bottom Restaurant Card Carousel Shimmer Preview
        Positioned(
          left: 16,
          right: 16,
          bottom: 20,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BaseSkeleton(
                  width: double.infinity,
                  height: 140,
                  borderRadius: 16,
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    BaseSkeleton(width: 180, height: 20, borderRadius: 6),
                    BaseSkeleton(width: 50, height: 20, borderRadius: 10),
                  ],
                ),
                SizedBox(height: 8),
                BaseSkeleton(width: 220, height: 14, borderRadius: 4),
                SizedBox(height: 12),
                Row(
                  children: [
                    BaseSkeleton(width: 90, height: 24, borderRadius: 12),
                    SizedBox(width: 8),
                    BaseSkeleton(width: 110, height: 24, borderRadius: 12),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
