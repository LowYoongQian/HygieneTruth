import 'package:flutter/material.dart';
import '../../core/models/restaurant_model.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/restaurant_store_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/empty_state_widget.dart';

class ActivityItem {
  final String id;
  final String title;
  final String description;
  final String category; // 'Recent Visit', 'Report', 'Restaurant Review'
  final String timestamp;
  final IconData icon;
  final Color iconColor;
  final dynamic targetData;

  const ActivityItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.timestamp,
    required this.icon,
    required this.iconColor,
    this.targetData,
  });
}

class ActivityHistoryScreen extends StatefulWidget {
  const ActivityHistoryScreen({super.key});

  @override
  State<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen> {
  String _selectedCategory = 'All';
  List<Map<String, dynamic>> _userReviews = [];
  List<Map<String, dynamic>> _recentVisits = [];

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    try {
      final all = await RestaurantStoreService.fetchOwnerRestaurants(null);
      for (final r in all) {
        if (r.name.isNotEmpty && !RestaurantStoreService.isRawUuid(r.name)) {
          RestaurantStoreService.cacheRestaurantName(r.id, r.name);
        }
      }
    } catch (_) {}

    final reviews = await RestaurantStoreService.fetchUserReviewActivities();
    final visits = await RestaurantStoreService.fetchRecentVisits();
    
    // Purge any legacy mock entries from state
    final cleanReviews = reviews.where((r) => !RestaurantStoreService.isLegacyMockName(r['restaurantName']?.toString())).toList();
    final cleanVisits = visits.where((v) => !RestaurantStoreService.isLegacyMockName(v['name']?.toString())).toList();

    if (mounted) {
      setState(() {
        _userReviews = cleanReviews;
        _recentVisits = cleanVisits;
      });
    }
  }

  String _formatActivityTime(String raw) {
    if (raw.isEmpty) return 'Recently';
    final dt = DateTime.tryParse(raw);
    if (dt != null) {
      final msiaDt = dt.toUtc().add(const Duration(hours: 8));
      final now = DateTime.now();
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final hour = msiaDt.hour.toString().padLeft(2, '0');
      final minute = msiaDt.minute.toString().padLeft(2, '0');

      if (now.year == msiaDt.year && now.month == msiaDt.month && now.day == msiaDt.day) {
        return 'Today, $hour:$minute';
      }
      return '${msiaDt.day} ${months[msiaDt.month - 1]} ${msiaDt.year}, $hour:$minute';
    }
    return raw;
  }

  List<ActivityItem> get _allActivities {
    final List<ActivityItem> items = [];

    // 1. Live & Cached Restaurant Review Items
    final Set<String> seenReviewKeys = {};
    for (final rev in _userReviews) {
      final stars = rev['stars'] ?? '5';
      final comment = rev['comment'] ?? '';
      final rawRName = rev['restaurantName'] ?? rev['restaurantId'] ?? 'Restaurant';
      final rName = RestaurantStoreService.resolveRestaurantName(rawRName, fallback: 'Restaurant');
      if (RestaurantStoreService.isLegacyMockName(rName)) continue;
      final rawTime = rev['timestamp'] ?? '';
      final key = '${rName}_$comment';
      seenReviewKeys.add(key);

      final ownerReply = rev['ownerReply'] ?? '';
      final desc = ownerReply.isNotEmpty
          ? 'Posted $stars ★ Review: "$comment"\n💬 Owner Replied: "$ownerReply"'
          : 'Posted $stars ★ Review: "$comment"';

      items.add(ActivityItem(
        id: rev['id'] ?? 'act_rev_${items.length}',
        title: rName,
        description: desc,
        category: 'Restaurant Review',
        timestamp: _formatActivityTime(rawTime),
        icon: Icons.rate_review_rounded,
        iconColor: const Color(0xFFD97706),
        targetData: rev,
      ));
    }

// Removed legacy mock reviews - strictly real data only

    // 2. Recent Visit Items (Live & Cached)
    final Set<String> seenVisitNames = {};
    for (final visit in _recentVisits) {
      final rawName = visit['name']?.toString() ?? visit['id']?.toString() ?? 'Premises';
      final name = RestaurantStoreService.resolveRestaurantName(rawName, fallback: 'Premises');
      if (RestaurantStoreService.isLegacyMockName(name)) continue;
      final rawTime = visit['timestamp']?.toString() ?? '';
      seenVisitNames.add(name);

      final matching = RestaurantStoreService.restaurantsNotifier.value.where((r) => r.id == visit['id'] || r.name == name).firstOrNull;

      items.add(ActivityItem(
        id: 'act_v_${visit['id'] ?? items.length}',
        title: name,
        description: 'Viewed outlet details & GPS location map.',
        category: 'Recent Visit',
        timestamp: _formatActivityTime(rawTime),
        icon: Icons.storefront_rounded,
        iconColor: const Color(0xFF00A88F),
        targetData: matching ?? RestaurantModel(
          id: visit['id']?.toString() ?? 'rest_custom',
          name: name,
          category: visit['category']?.toString() ?? 'Restaurant',
          address: visit['address']?.toString() ?? 'Location not provided',
          latitude: 3.1466,
          longitude: 101.6958,
          hygieneRiskScore: (visit['hygieneRiskScore'] as num?)?.toDouble() ?? 25.0,
          riskCategory: RiskCategory.safe,
          status: RestaurantStatus.approved,
          violationCount: (visit['violationCount'] as num?)?.toInt() ?? 0,
          imageUrl: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=600',
          lastUpdated: 'Today',
        ),
      ));
    }

    // No mock visits

    // 3. Report Items
    for (final c in RestaurantStoreService.complaintsNotifier.value) {
      items.add(ActivityItem(
        id: 'act_rep_${c.id}',
        title: 'Hygiene Report #${c.id}',
        description: '${c.restaurantName} - ${c.issues.join(", ")}',
        category: 'Report',
        timestamp: c.submittedAt,
        icon: Icons.report_problem_rounded,
        iconColor: const Color(0xFFDC2626),
        targetData: c,
      ));
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final activities = _allActivities;
    final filtered = _selectedCategory == 'All'
        ? activities
        : activities.where((a) => a.category == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const CustomAppBar(
        title: 'Activity History',
      ),
      body: Column(
        children: [
          // Category Filter Bar (Chips)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Recent Visit', 'Report', 'Restaurant Review'].map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(cat),
                      selected: isSelected,
                      selectedColor: const Color(0xFF00A88F),
                      backgroundColor: const Color(0xFFF1F5F9),
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : const Color(0xFF475569),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isSelected ? const Color(0xFF00A88F) : const Color(0xFFCBD5E1),
                        ),
                      ),
                      onSelected: (val) {
                        setState(() {
                          _selectedCategory = val ? cat : 'All';
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Activities List
          Expanded(
            child: filtered.isEmpty
                ? const EmptyStateWidget(
                    title: 'No Activity Found',
                    message: 'No activity logs recorded under this category yet.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (ctx, idx) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = filtered[index];

                      return GestureDetector(
                        onTap: () {
                          if (item.category == 'Recent Visit' && item.targetData != null) {
                            Navigator.pushNamed(context, AppRoutes.restaurantDetail, arguments: item.targetData);
                          } else if (item.category == 'Restaurant Review') {
                            final rModel = RestaurantStoreService.restaurantsNotifier.value.where((r) => r.name == item.title || r.id == item.title).firstOrNull;
                            if (rModel != null) {
                              Navigator.pushNamed(context, AppRoutes.restaurantDetail, arguments: rModel);
                            }
                          } else if (item.category == 'Report') {
                            Navigator.pushNamed(context, AppRoutes.complaintStatusDetail, arguments: item.targetData);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: item.iconColor.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(item.icon, color: item.iconColor, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.title,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.navyColor),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: item.iconColor.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: item.iconColor.withValues(alpha: 0.3)),
                                          ),
                                          child: Text(
                                            item.category,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: item.iconColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.description,
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.3),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.access_time_rounded, size: 12, color: Colors.grey.shade500),
                                        const SizedBox(width: 4),
                                        Text(
                                          item.timestamp,
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey.shade600),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
