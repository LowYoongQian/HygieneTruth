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

/// Form Screen Skeleton for Reset Password / Auth Forms
class FormSkeleton extends StatelessWidget {
  const FormSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Center(child: BaseSkeleton(width: 80, height: 80, borderRadius: 40)),
          const SizedBox(height: 20),
          const Center(child: BaseSkeleton(width: 200, height: 26, borderRadius: 8)),
          const SizedBox(height: 12),
          const Center(child: BaseSkeleton(width: 260, height: 16, borderRadius: 6)),
          const SizedBox(height: 32),
          const BaseSkeleton(width: double.infinity, height: 56, borderRadius: 16),
          const SizedBox(height: 20),
          const BaseSkeleton(width: double.infinity, height: 50, borderRadius: 14),
          const SizedBox(height: 32),
          const BaseSkeleton(width: double.infinity, height: 80, borderRadius: 16),
        ],
      ),
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

/// Admin Portal Dashboard Skeleton Loader
class AdminDashboardSkeleton extends StatelessWidget {
  const AdminDashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dark Header Summary Banner Shimmer
          const BaseSkeleton(
            width: double.infinity,
            height: 110,
            borderRadius: 16,
          ),
          const SizedBox(height: 24),

          // Admin Grid Title Shimmer
          const BaseSkeleton(width: 120, height: 18, borderRadius: 4),
          const SizedBox(height: 12),

          // 2x2 Grid Stat Cards Shimmer
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.25,
            children: const [
              BaseSkeleton(width: double.infinity, height: 110, borderRadius: 16),
              BaseSkeleton(width: double.infinity, height: 110, borderRadius: 16),
              BaseSkeleton(width: double.infinity, height: 110, borderRadius: 16),
              BaseSkeleton(width: double.infinity, height: 110, borderRadius: 16),
            ],
          ),
          const SizedBox(height: 24),

          // Admin Tools Title Shimmer
          const BaseSkeleton(width: 120, height: 18, borderRadius: 4),
          const SizedBox(height: 12),

          // Admin Tool Tiles Shimmer
          const BaseSkeleton(width: double.infinity, height: 60, borderRadius: 12),
          const SizedBox(height: 10),
          const BaseSkeleton(width: double.infinity, height: 60, borderRadius: 12),
          const SizedBox(height: 10),
          const BaseSkeleton(width: double.infinity, height: 60, borderRadius: 12),
          const SizedBox(height: 10),
          const BaseSkeleton(width: double.infinity, height: 60, borderRadius: 12),
        ],
      ),
    );
  }
}

/// Outlet Review / Verification Detail Screen Skeleton Loader (including Map Shimmer)
class OutletReviewSkeleton extends StatelessWidget {
  const OutletReviewSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Hero Outlet Image Card Shimmer
          const BaseSkeleton(
            width: double.infinity,
            height: 140,
            borderRadius: 20,
          ),
          const SizedBox(height: 14),
          const BaseSkeleton(width: 180, height: 24, borderRadius: 6),
          const SizedBox(height: 8),
          const BaseSkeleton(width: 120, height: 20, borderRadius: 8),
          const SizedBox(height: 24),

          // 2. Application Details Header & Card Shimmer
          const Row(
            children: [
              BaseSkeleton(width: 20, height: 20, borderRadius: 4),
              SizedBox(width: 8),
              BaseSkeleton(width: 150, height: 18, borderRadius: 4),
            ],
          ),
          const SizedBox(height: 10),
          const BaseSkeleton(width: double.infinity, height: 110, borderRadius: 16),
          const SizedBox(height: 24),

          // 3. Map Location Header & Embedded Map Canvas Shimmer
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  BaseSkeleton(width: 20, height: 20, borderRadius: 4),
                  SizedBox(width: 8),
                  BaseSkeleton(width: 120, height: 18, borderRadius: 4),
                ],
              ),
              BaseSkeleton(width: 110, height: 22, borderRadius: 6),
            ],
          ),
          const SizedBox(height: 10),
          // Embedded Map Shimmer Container
          const BaseSkeleton(
            width: double.infinity,
            height: 200,
            borderRadius: 16,
          ),
          const SizedBox(height: 24),

          // 4. Official Assessment Input Box Shimmer
          const BaseSkeleton(width: 180, height: 16, borderRadius: 4),
          const SizedBox(height: 8),
          const BaseSkeleton(width: double.infinity, height: 80, borderRadius: 14),
          const SizedBox(height: 24),

          // 5. Action Buttons Shimmer
          const BaseSkeleton(width: double.infinity, height: 50, borderRadius: 14),
          const SizedBox(height: 10),
          const BaseSkeleton(width: double.infinity, height: 50, borderRadius: 14),
          const SizedBox(height: 10),
          const BaseSkeleton(width: double.infinity, height: 50, borderRadius: 14),
        ],
      ),
    );
  }
}

/// Notification Card Skeleton for Notification Center (100% Synced with real card layout)
class NotificationCardSkeleton extends StatelessWidget {
  const NotificationCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Shimmer.fromColors(
        baseColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200,
        highlightColor: isDark ? const Color(0xFF334155) : Colors.grey.shade50,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon avatar skeleton
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Title bar
                        Container(
                          width: 150,
                          height: 14,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF334155) : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        // Date bar
                        Container(
                          width: 60,
                          height: 10,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF334155) : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Message line 1
                    Container(
                      width: double.infinity,
                      height: 11,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF334155) : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Message line 2
                    Container(
                      width: 180,
                      height: 11,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF334155) : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
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

/// Notification List Skeleton for Notification Center TabBarView
class NotificationListSkeleton extends StatelessWidget {
  final int itemCount;
  const NotificationListSkeleton({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) => const NotificationCardSkeleton(),
    );
  }
}

/// Assigned Cases List Screen Skeleton (with Stats, Search, and Cards)
class AssignedCasesSkeleton extends StatelessWidget {
  final int itemCount;
  const AssignedCasesSkeleton({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          // Top Stats Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(child: BaseSkeleton(width: double.infinity, height: 50, borderRadius: 12)),
                const SizedBox(width: 8),
                Expanded(child: BaseSkeleton(width: double.infinity, height: 50, borderRadius: 12)),
                const SizedBox(width: 8),
                Expanded(child: BaseSkeleton(width: double.infinity, height: 50, borderRadius: 12)),
              ],
            ),
          ),
          // Search Bar
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: BaseSkeleton(width: double.infinity, height: 44, borderRadius: 12),
          ),
          // Filter Chips Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: List.generate(
                4,
                (i) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: BaseSkeleton(width: 70 + (i * 10), height: 32, borderRadius: 16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // List Cards
          ...List.generate(
            itemCount,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BaseSkeleton(width: 44, height: 44, borderRadius: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const BaseSkeleton(width: 160, height: 16, borderRadius: 4),
                        const SizedBox(height: 8),
                        const BaseSkeleton(width: 220, height: 12, borderRadius: 4),
                        const SizedBox(height: 6),
                        const BaseSkeleton(width: 130, height: 11, borderRadius: 4),
                        const SizedBox(height: 8),
                        const BaseSkeleton(width: 80, height: 20, borderRadius: 6),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Case Details Screen Skeleton
class CaseDetailsSkeleton extends StatelessWidget {
  const CaseDetailsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          BaseSkeleton(width: double.infinity, height: 110, borderRadius: 18),
          SizedBox(height: 16),
          // Description Card
          BaseSkeleton(width: double.infinity, height: 120, borderRadius: 16),
          SizedBox(height: 16),
          // Evidence Photos Card
          BaseSkeleton(width: double.infinity, height: 240, borderRadius: 16),
          SizedBox(height: 16),
          // GPS Map Card
          BaseSkeleton(width: double.infinity, height: 220, borderRadius: 16),
          SizedBox(height: 24),
          // Action Buttons
          BaseSkeleton(width: double.infinity, height: 48, borderRadius: 12),
          SizedBox(height: 12),
          BaseSkeleton(width: double.infinity, height: 48, borderRadius: 12),
        ],
      ),
    );
  }
}

/// Settings & Security History Screen Skeleton
class SettingsHistorySkeleton extends StatelessWidget {
  final int itemCount;
  const SettingsHistorySkeleton({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          // Top Summary Banner
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: BaseSkeleton(width: double.infinity, height: 95, borderRadius: 16),
          ),
          // Search Input
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: BaseSkeleton(width: double.infinity, height: 42, borderRadius: 12),
          ),
          // Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: List.generate(
                4,
                (i) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: BaseSkeleton(width: 75, height: 32, borderRadius: 16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Timeline Cards
          ...List.generate(
            itemCount,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BaseSkeleton(width: 40, height: 40, borderRadius: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            BaseSkeleton(width: 140, height: 15, borderRadius: 4),
                            BaseSkeleton(width: 60, height: 16, borderRadius: 6),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const BaseSkeleton(width: double.infinity, height: 12, borderRadius: 4),
                        const SizedBox(height: 4),
                        const BaseSkeleton(width: 180, height: 12, borderRadius: 4),
                        const SizedBox(height: 8),
                        const BaseSkeleton(width: 90, height: 10, borderRadius: 4),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Enforcement Action History Screen Skeleton
class ActionHistorySkeleton extends StatelessWidget {
  final int itemCount;
  const ActionHistorySkeleton({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          // Top Summary Metrics
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(child: BaseSkeleton(width: double.infinity, height: 52, borderRadius: 12)),
                const SizedBox(width: 8),
                Expanded(child: BaseSkeleton(width: double.infinity, height: 52, borderRadius: 12)),
                const SizedBox(width: 8),
                Expanded(child: BaseSkeleton(width: double.infinity, height: 52, borderRadius: 12)),
              ],
            ),
          ),
          // Search Input
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: BaseSkeleton(width: double.infinity, height: 42, borderRadius: 12),
          ),
          // Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: List.generate(
                4,
                (i) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: BaseSkeleton(width: 70 + (i * 10), height: 32, borderRadius: 16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Cards
          ...List.generate(
            itemCount,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BaseSkeleton(width: 44, height: 44, borderRadius: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            BaseSkeleton(width: 160, height: 16, borderRadius: 4),
                            BaseSkeleton(width: 70, height: 18, borderRadius: 6),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const BaseSkeleton(width: 220, height: 12, borderRadius: 4),
                        const SizedBox(height: 6),
                        const BaseSkeleton(width: 120, height: 12, borderRadius: 4),
                        const SizedBox(height: 8),
                        const BaseSkeleton(width: 90, height: 10, borderRadius: 4),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
