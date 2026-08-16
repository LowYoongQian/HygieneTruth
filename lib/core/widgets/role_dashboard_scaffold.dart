import 'package:geolocator/geolocator.dart';
import 'top_eat_carousel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/mock_seed_data.dart';
import '../models/restaurant_model.dart';
import '../models/user_model.dart';
import '../routes/app_routes.dart';
import '../services/gps_service.dart';
import '../services/customer_store_service.dart';
import '../services/language_manager.dart';
import '../services/restaurant_store_service.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart';
import '../utils/translations.dart';
import '../../gps/widgets/restaurant_card.dart';
import 'shimmer_skeletons.dart';
import 'stat_card.dart';
import 'notification_bell.dart';

import '../../owner/screens/owner_dashboard_screen.dart';
import '../../gps/screens/restaurant_map_screen.dart';
import '../../risk/screens/recommendation_home_screen.dart';

import 'profile_setup_focus_dialog.dart';

class RoleDashboardScaffold extends StatefulWidget {
  final UserRole initialRole;
  final int initialTabIndex;

  const RoleDashboardScaffold({
    super.key,
    required this.initialRole,
    this.initialTabIndex = 0,
  });

  @override
  State<RoleDashboardScaffold> createState() => _RoleDashboardScaffoldState();
}

class _RoleDashboardScaffoldState extends State<RoleDashboardScaffold> {
  late UserRole _currentRole;
  late int _selectedBottomTabIndex;
  bool _hasCheckedProfileSetup = false;
  double _userLat = 3.1466;
  double _userLng = 101.6958;
  bool _hasUserLocation = false;
  bool _isCategoryListExpanded = false;

  int _adminPendingCount = 0;
  int _adminUsersCount = 0;
  int _adminLogsCount = 0;
  int _adminComplaintsCount = 0;
  bool _isLoadingAdminStats = true;

  @override
  void initState() {
    super.initState();
    _currentRole = widget.initialRole;
    _selectedBottomTabIndex = widget.initialTabIndex;
    BookmarkService.init();
    _fetchUserGpsLocation();
    RestaurantStoreService.fetchAllRestaurants(forceRefresh: true);
    final currentUser = CustomerStoreService.currentCustomer;
    NotificationService.fetchNotifications(
      userId: currentUser?.id,
      userEmail: currentUser?.email,
      userRole: currentUser?.role.name,
    );
    if (_currentRole == UserRole.admin) {
      _loadAdminRealStats();
    }
  }

  Future<void> _fetchUserGpsLocation() async {
    try {
      final position = await GpsService.getCurrentLocation();
      if (position != null && mounted) {
        setState(() {
          _userLat = position.latitude;
          _userLng = position.longitude;
          _hasUserLocation = true;
        });
      }
    } catch (_) {
      // Graceful fallback to default KL location
    }
  }

  Future<void> _loadAdminRealStats() async {
    try {
      final supabase = SupabaseService.client;

      // 1. Fetch real pending outlets count
      int pending = 0;
      try {
        final pendingRes = await supabase
            .from('restaurants')
            .select()
            .eq('status', 'pendingVerification');
        pending = (pendingRes as List<dynamic>).length;
      } catch (_) {
        final pendingList = MockSeedData.restaurants.where((r) => r.status == RestaurantStatus.pendingVerification).toList();
        pending = pendingList.length;
      }

      // 2. Fetch real users count
      int usersCount = 0;
      try {
        final usersRes = await supabase.from('users').select();
        usersCount = (usersRes as List<dynamic>).length;
      } catch (_) {
        usersCount = MockSeedData.users.length;
      }

      // 3. Fetch real audit logs count
      int logsCount = 0;
      try {
        final logsRes = await supabase.from('audit_logs').select();
        logsCount = (logsRes as List<dynamic>).length;
      } catch (_) {
        logsCount = 24;
      }

      // 4. Fetch real complaints count
      int complaintsCount = 0;
      try {
        final compRes = await supabase.from('complaints').select();
        complaintsCount = (compRes as List<dynamic>).length;
      } catch (_) {
        complaintsCount = 12;
      }

      if (mounted) {
        setState(() {
          _adminPendingCount = pending;
          _adminUsersCount = usersCount;
          _adminLogsCount = logsCount;
          _adminComplaintsCount = complaintsCount;
          _isLoadingAdminStats = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading admin real stats: $e');
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasCheckedProfileSetup) {
      _hasCheckedProfileSetup = true;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['showProfileSetupDialog'] == true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ProfileSetupFocusDialog.show(context);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: languageManager,
      builder: (context, _) {
        if (_currentRole == UserRole.user) {
          return _buildUserShell(context);
        } else if (_currentRole == UserRole.admin) {
          return _buildAdminShell(context);
        } else if (_currentRole == UserRole.owner) {
          return const OwnerDashboardScreen();
        } else {
          return _buildGovernmentShell(context);
        }
      },
    );
  }

  // ==========================================
  // 1. USER / CLIENT DASHBOARD (Short 1-2 Word Terms)
  // ==========================================
  Widget _buildUserShell(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getUserTabTitle(_selectedBottomTabIndex)),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border_rounded),
            tooltip: 'Saved Wishlist',
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.savedRestaurants);
            },
          ),
          const NotificationBell(),
        ],
      ),
      body: _buildUserTabContent(_selectedBottomTabIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedBottomTabIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF0284C7),
        unselectedItemColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600,
        backgroundColor: Theme.of(context).cardColor,
        elevation: 8,
        onTap: (index) {
          setState(() {
            _selectedBottomTabIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home_outlined), label: t('home')),
          BottomNavigationBarItem(icon: const Icon(Icons.map_outlined), label: t('map')),
          BottomNavigationBarItem(icon: const Icon(Icons.recommend_outlined), label: t('safe_food')),
          BottomNavigationBarItem(icon: const Icon(Icons.person_outline), label: t('my_profile')),
        ],
      ),
    );
  }

  String _getUserTabTitle(int index) {
    switch (index) {
      case 0:
        return t('home');
      case 1:
        return t('map');
      case 2:
        return t('safe_food');
      case 3:
        return t('my_profile');
      default:
        return t('app_title');
    }
  }

  Widget _buildUserTabContent(int index) {
    switch (index) {
      case 0:
        return _buildUserHomePanel(context);
      case 1:
        return _buildUserMapPanel(context);
      case 2:
        return _buildUserSafeFoodPanel(context);
      case 3:
        return _buildUserProfilePanel(context);
      default:
        return Container();
    }
  }

  List<RestaurantModel> _getTopRankedRestaurants(List<RestaurantModel> allRestaurants) {
    final safeList = allRestaurants
        .where((r) => r.status == RestaurantStatus.approved && r.riskCategory == RiskCategory.safe)
        .toList();

    safeList.sort((a, b) {
      final ratingA = RestaurantStoreService.getRatingSync(a.id, restaurantName: a.name);
      final ratingB = RestaurantStoreService.getRatingSync(b.id, restaurantName: b.name);

      final distA = Geolocator.distanceBetween(_userLat, _userLng, a.latitude, a.longitude) / 1000.0;
      final distB = Geolocator.distanceBetween(_userLat, _userLng, b.latitude, b.longitude) / 1000.0;

      // Effective rating score (real review stars or high safety default)
      final effectiveRatingA = ratingA.hasReviews ? ratingA.averageRating : (5.0 - (a.hygieneRiskScore * 0.04));
      final effectiveRatingB = ratingB.hasReviews ? ratingB.averageRating : (5.0 - (b.hygieneRiskScore * 0.04));

      // Composite proximity score: High Star Rating + Nearby Proximity
      // Score formula gives strong weight to high stars, while prioritizing closer outlets
      final scoreA = (effectiveRatingA * 10.0) + (ratingA.totalReviews * 0.1) - (distA * 0.35) - (a.violationCount * 2.0) - (a.hygieneRiskScore * 0.05);
      final scoreB = (effectiveRatingB * 10.0) + (ratingB.totalReviews * 0.1) - (distB * 0.35) - (b.violationCount * 2.0) - (b.hygieneRiskScore * 0.05);

      return scoreB.compareTo(scoreA);
    });

    if (safeList.isEmpty) {
      return allRestaurants.take(3).toList();
    }
    return safeList.take(3).toList();
  }

  Widget _buildUserHomePanel(BuildContext context) {

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Trigger
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.restaurantSearch),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFCBD5E1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Color(0xFF0284C7)),
                  const SizedBox(width: 10),
                  Text(
                    t('search_outlets'),
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Dynamic Registered Cuisine Categories
          _buildDynamicCuisineChips(context),
          const SizedBox(height: 20),

          // Featured Top Eat Swipable Carousel
          TopEatCarousel(restaurants: MockSeedData.restaurants, userLat: _userLat, userLng: _userLng),
          const SizedBox(height: 20),

          // Quick Action Round Buttons Grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _roundActionBtn(
                icon: Icons.search,
                color: const Color(0xFF0284C7),
                label: t('search_outlets').split(' ').first,
                onTap: () => Navigator.pushNamed(context, AppRoutes.restaurantSearch),
              ),
              _roundActionBtn(
                icon: Icons.pin_drop,
                color: const Color(0xFF10B981),
                label: t('map'),
                onTap: () => Navigator.pushNamed(context, AppRoutes.restaurantMap),
              ),
              _roundActionBtn(
                icon: Icons.report_problem,
                color: const Color(0xFFEF4444),
                label: t('report'),
                onTap: () => Navigator.pushNamed(context, AppRoutes.submitComplaint),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Top Rated Safe Restaurants Leaderboard (Top 3 in Sequence)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('⭐', style: TextStyle(fontSize: 15)),
                  const SizedBox(width: 6),
                  Text(
                    t('top_rated_safe'),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  if (_hasUserLocation) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.near_me_rounded, size: 10, color: Color(0xFF0284C7)),
                          SizedBox(width: 2),
                          Text(
                            'Nearby',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0284C7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.restaurantList),
                child: const Text('View All ›', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 6),

          Builder(
            builder: (context) {
              final top3 = _getTopRankedRestaurants(MockSeedData.restaurants);
              return Column(
                children: [
                  for (int i = 0; i < top3.length; i++)
                    RestaurantCard(
                      restaurant: top3[i],
                      rankIndex: i,
                      userLat: _userLat,
                      userLng: _userLng,
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatCategoryLabel(String cat) {
    final lower = cat.toLowerCase();
    if (lower.contains('noodle')) return '🍜 $cat';
    if (lower.contains('rice') || lower.contains('kandar') || lower.contains('malay')) return '🍚 $cat';
    if (lower.contains('seafood') || lower.contains('fish')) return '🍣 $cat';
    if (lower.contains('japanese') || lower.contains('sushi')) return '🍱 $cat';
    if (lower.contains('burger') || lower.contains('fast')) return '🍔 $cat';
    if (lower.contains('chinese') || lower.contains('dim sum')) return '🥟 $cat';
    if (lower.contains('western') || lower.contains('steak') || lower.contains('grill')) return '🥩 $cat';
    if (lower.contains('cafe') || lower.contains('coffee') || lower.contains('bakery')) return '☕ $cat';
    if (lower.contains('healthy') || lower.contains('salad')) return '🥗 $cat';
    if (lower.contains('drink') || lower.contains('tea') || lower.contains('boba')) return '🧋 $cat';
    if (lower.contains('hawker') || lower.contains('local')) return '🍢 $cat';
    if (lower.contains('indian') || lower.contains('mamak') || lower.contains('curry')) return '🍛 $cat';
    return '🍽️ $cat';
  }

  Widget _buildDynamicCuisineChips(BuildContext context) {
    return ValueListenableBuilder<List<RestaurantModel>>(
      valueListenable: RestaurantStoreService.restaurantsNotifier,
      builder: (context, allRestaurants, _) {
        // Collect all distinct categories from real registered restaurants in Supabase
        final activeCategories = allRestaurants
            .map((r) => r.category.trim())
            .where((c) => c.isNotEmpty && c.toLowerCase() != 'general')
            .toSet()
            .toList();

        if (activeCategories.isEmpty) {
          return const SizedBox.shrink();
        }

        // If categories <= 2, show all directly in swipe row
        if (activeCategories.length <= 2) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: activeCategories.map((category) {
                return _cuisineChip(
                  category: category,
                  displayLabel: _formatCategoryLabel(category),
                  context: context,
                );
              }).toList(),
            ),
          );
        }

        // Collapsed mode: shows first 2 + "More (N)"
        // Expanded mode: shows all categories with smooth left & right horizontal scroll + "Less"
        final displayedCategories = _isCategoryListExpanded
            ? activeCategories
            : activeCategories.take(2).toList();
        final remainingCount = activeCategories.length - 2;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              for (final category in displayedCategories)
                _cuisineChip(
                  category: category,
                  displayLabel: _formatCategoryLabel(category),
                  context: context,
                ),
              if (!_isCategoryListExpanded && remainingCount > 0)
                _moreChip(
                  count: remainingCount,
                  onTap: () {
                    setState(() {
                      _isCategoryListExpanded = true;
                    });
                  },
                )
              else if (_isCategoryListExpanded)
                _lessChip(
                  onTap: () {
                    setState(() {
                      _isCategoryListExpanded = false;
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _moreChip({required int count, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: const Icon(Icons.apps_rounded, size: 14, color: Color(0xFF0284C7)),
        label: Text(
          'More (+$count)',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0284C7),
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF0C4A6E).withValues(alpha: 0.3) : const Color(0xFFE0F2FE),
        side: BorderSide(color: const Color(0xFF0284C7).withValues(alpha: 0.4)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onPressed: onTap,
      ),
    );
  }

  Widget _lessChip({required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: Icon(Icons.arrow_back_ios_new_rounded, size: 11, color: isDark ? Colors.white70 : Colors.grey.shade600),
        label: Text(
          'Less',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.grey.shade700,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        side: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onPressed: onTap,
      ),
    );
  }

  Widget _cuisineChip({
    required String category,
    required String displayLabel,
    required BuildContext context,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(
          displayLabel,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        side: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onPressed: () {
          Navigator.pushNamed(
            context,
            AppRoutes.restaurantSearch,
            arguments: category,
          );
        },
      ),
    );
  }

  Widget _roundActionBtn({required IconData icon, required Color color, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildUserMapPanel(BuildContext context) {
    return const RestaurantMapScreen(showAppBar: false);
  }

  Widget _buildUserSafeFoodPanel(BuildContext context) {
    return const RecommendationHomeScreen(showAppBar: false);
  }

  Widget _buildUserProfilePanel(BuildContext context) {
    final customer = CustomerStoreService.currentCustomer;
    final userName = customer?.name ?? 'Guest User';
    final userEmail = customer?.email ?? 'Not Signed In';
    final avatarUrl = customer?.avatarUrl ?? '';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // 1. TOP QUALITY BANNER FRAME WITH OVERLAPPING AVATAR
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              // Rich Aesthetic Gradient Banner Container
              Container(
                height: 140,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF0F172A), // Deep Navy
                      Color(0xFF1E293B),
                      Color(0xFF0284C7), // Ocean Blue accent
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // Subtle background decorative circles
                    Positioned(
                      right: -20,
                      top: -20,
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 20,
                      bottom: 10,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Overlapping Profile Avatar Frame Icon with Gold Ring Accent
              Positioned(
                top: 85,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 46,
                        backgroundColor: const Color(0xFF0284C7).withValues(alpha: 0.15),
                        backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl.isEmpty
                            ? Text(
                                userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0284C7),
                                ),
                              )
                            : null,
                      ),
                      // Online Indicator Status Dot
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981), // Emerald green online indicator
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Spacing below overlapping banner avatar
          const SizedBox(height: 55),

          // 2. USER INFORMATION & STATUS BADGE
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Text(
                  userName,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userEmail,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF9CA3AF) : Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_outlined, size: 14, color: Color(0xFF0284C7)),
                      SizedBox(width: 6),
                      Text(
                        'Verified Customer',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 3. ENHANCED PROFILE OPTIONS CARDS
                Card(
                  elevation: 1.5,
                  shadowColor: Colors.black.withValues(alpha: 0.06),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.person_outline, color: Color(0xFF0284C7), size: 22),
                    ),
                    title: Text(
                      t('my_profile'),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A)),
                    ),
                    subtitle: const Text('Manage personal details & contact info', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                    onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
                  ),
                ),
                const SizedBox(height: 10),

                Card(
                  elevation: 1.5,
                  shadowColor: Colors.black.withValues(alpha: 0.06),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.history, color: Colors.amber, size: 22),
                    ),
                    title: Text(
                      t('activity_history'),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A)),
                    ),
                    subtitle: const Text('View recent visits, submitted reports & reviews', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                    onTap: () => Navigator.pushNamed(context, AppRoutes.activityHistory),
                  ),
                ),
                const SizedBox(height: 24),

                // 4. ENHANCED RED LOGOUT BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626), // Premium vibrant red
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      CustomerStoreService.logout();
                      Navigator.pushReplacementNamed(context, AppRoutes.splashRoleSelect);
                    },
                    icon: const Icon(Icons.logout, size: 20),
                    label: Text(
                      t('logout'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 2. ADMIN DASHBOARD (Short 1-2 Word Terms)
  // ==========================================
  Widget _buildAdminShell(BuildContext context) {
    if (_isLoadingAdminStats) {
      _loadAdminRealStats();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Portal'),
        actions: const [],
      ),
      drawer: _buildAdminDrawer(context),
      body: _isLoadingAdminStats
          ? const AdminDashboardSkeleton()
          : RefreshIndicator(
              onRefresh: _loadAdminRealStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dark Header Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.admin_panel_settings, color: Color(0xFF0284C7), size: 22),
                            SizedBox(width: 8),
                            Text('System Admin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green.shade800,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('ONLINE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _adminMetricText('$_adminPendingCount', 'Pending'),
                        _adminMetricText('$_adminUsersCount', 'Users'),
                        _adminMetricText('$_adminLogsCount', 'Logs'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const Text('Admin Grid', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              // 2x2 Admin Tools
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.25,
                children: [
                  StatCard(
                    title: 'Manage Users',
                    value: 'Accounts ($_adminUsersCount)',
                    icon: Icons.people,
                    iconColor: const Color(0xFF0284C7),
                  ),
                  StatCard(
                    title: 'Approve Outlets',
                    value: 'Queue ($_adminPendingCount)',
                    icon: Icons.approval,
                    iconColor: const Color(0xFFF59E0B),
                  ),
                  StatCard(
                    title: 'All Reports',
                    value: 'Complaints ($_adminComplaintsCount)',
                    icon: Icons.assignment,
                    iconColor: const Color(0xFFEF4444),
                  ),
                  StatCard(
                    title: 'Audit Logs',
                    value: 'Logs ($_adminLogsCount)',
                    icon: Icons.receipt_long,
                    iconColor: const Color(0xFF10B981),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              const Text('Admin Tools', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              _adminToolTile(context, icon: Icons.people_outline, title: 'Manage Users', route: AppRoutes.manageUserAccounts),
              _adminToolTile(context, icon: Icons.verified_user_outlined, title: 'Approve Outlets', route: AppRoutes.restaurantVerificationQueue),
              _adminToolTile(context, icon: Icons.checklist_rtl, title: 'All Reports', route: AppRoutes.allComplaints),
              _adminToolTile(context, icon: Icons.gavel, title: 'Review Reports', route: AppRoutes.inspectionReportReview),
              _adminToolTile(context, icon: Icons.history_edu, title: 'Audit Logs', route: AppRoutes.adminActionLog),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _adminMetricText(String val, String label) {
    return Column(
      children: [
        Text(val, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  Widget _adminToolTile(BuildContext context, {required IconData icon, required String title, required String route}) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF0284C7)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () => Navigator.pushNamed(context, route),
      ),
    );
  }

  Widget _buildAdminDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          _buildDrawerHeader(
            name: 'System Admin',
            email: 'admin@hygiene.gov.my',
            roleBadge: 'Admin',
            avatarUrl: 'https://i.pravatar.cc/150?img=33',
            badgeColor: const Color(0xFF38BDF8),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerSectionHeader('Administration Tools'),
                _buildDrawerItem(context, icon: Icons.people_alt_outlined, title: 'Manage Users', route: AppRoutes.manageUserAccounts, iconColor: const Color(0xFF0284C7), iconBgColor: const Color(0xFFE0F2FE)),
                _buildDrawerItem(context, icon: Icons.verified_outlined, title: 'Approve Outlets', route: AppRoutes.restaurantVerificationQueue, iconColor: const Color(0xFF0D9488), iconBgColor: const Color(0xFFCCFBF1)),
                _buildDrawerItem(context, icon: Icons.assignment_outlined, title: 'All Reports', route: AppRoutes.allComplaints, iconColor: const Color(0xFF8B5CF6), iconBgColor: const Color(0xFFF3E8FF)),
                _buildDrawerItem(context, icon: Icons.gavel_outlined, title: 'Review Reports', route: AppRoutes.inspectionReportReview, iconColor: const Color(0xFF059669), iconBgColor: const Color(0xFFD1FAE5)),
                _buildDrawerItem(context, icon: Icons.receipt_long_outlined, title: 'Audit Logs', route: AppRoutes.adminActionLog, iconColor: const Color(0xFF6366F1), iconBgColor: const Color(0xFFEEF2FF)),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          _buildDrawerLogoutTile(context),
        ],
      ),
    );
  }

  // ==========================================
  // 3. GOVERNMENT / PIC DASHBOARD (Short 1-2 Word Terms)
  // ==========================================
  Widget _buildGovernmentShell(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Officer Portal'),
        actions: const [],
      ),
      drawer: _buildGovernmentDrawer(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pipeline Step Tracker
            const Text('Pipeline Status', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _pipelineStep('5', 'Assigned', Colors.blue),
                  const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                  _pipelineStep('2', 'Scheduled', Colors.amber),
                  const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                  _pipelineStep('3', 'Inspected', Colors.purple),
                  const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                  _pipelineStep('12', 'Closed', Colors.green),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Today's Priority Action Alert Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.priority_high, color: Colors.red, size: 20),
                      const SizedBox(width: 6),
                      const Text('Urgent Visit', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                      const Spacer(),
                      Text('CMP-2026-002', style: TextStyle(fontSize: 11, color: Colors.red.shade800, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text('Selera Kampung Bistro • Pest Infestation', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () => Navigator.pushNamed(context, AppRoutes.scheduleInspection),
                          child: const Text('Schedule Visit'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () => Navigator.pushNamed(context, AppRoutes.conductInspection),
                          child: const Text('Inspect Now'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text('Officer Tools', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            _govToolTile(context, icon: Icons.list_alt, title: 'Assigned Cases', route: AppRoutes.verifiedComplaintsList),
            _govToolTile(context, icon: Icons.history_edu_rounded, title: 'Government Audit Log', route: AppRoutes.governmentAuditLog),
            _govToolTile(context, icon: Icons.gavel_outlined, title: 'Issue Action', route: AppRoutes.issueEnforcement),
            _govToolTile(context, icon: Icons.inventory, title: 'Action History', route: AppRoutes.enforcementHistory),
            _govToolTile(context, icon: Icons.folder_off, title: 'Close Case', route: AppRoutes.closeCase),
          ],
        ),
      ),
    );
  }

  Widget _pipelineStep(String count, String label, Color color) {
    return Column(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: color.withValues(alpha: 0.15),
          child: Text(count, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _govToolTile(BuildContext context, {required IconData icon, required String title, required String route}) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF0284C7)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () => Navigator.pushNamed(context, route),
      ),
    );
  }

  Widget _buildGovernmentDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          _buildDrawerHeader(
            name: 'Health Officer (PIC)',
            email: 'officer.pic@hygiene.gov.my',
            roleBadge: 'Officer (PIC)',
            avatarUrl: 'https://i.pravatar.cc/150?img=12',
            badgeColor: const Color(0xFF34D399),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerSectionHeader('Field Operations'),
                _buildDrawerItem(context, icon: Icons.verified_outlined, title: 'Assigned Cases', route: AppRoutes.verifiedComplaintsList, iconColor: const Color(0xFF0284C7), iconBgColor: const Color(0xFFE0F2FE)),
                _buildDrawerItem(context, icon: Icons.history_edu_rounded, title: 'Government Audit Log', route: AppRoutes.governmentAuditLog, iconColor: const Color(0xFF0F766E), iconBgColor: const Color(0xFFCCFBF1)),
                _buildDrawerItem(context, icon: Icons.warning_amber_rounded, title: 'Issue Action', route: AppRoutes.issueEnforcement, iconColor: const Color(0xFFDC2626), iconBgColor: const Color(0xFFFEE2E2)),
                _buildDrawerItem(context, icon: Icons.history_rounded, title: 'Action History', route: AppRoutes.enforcementHistory, iconColor: const Color(0xFF8B5CF6), iconBgColor: const Color(0xFFF3E8FF)),
                _buildDrawerItem(context, icon: Icons.folder_off_outlined, title: 'Close Case', route: AppRoutes.closeCase, iconColor: const Color(0xFF475569), iconBgColor: const Color(0xFFF1F5F9)),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          _buildDrawerLogoutTile(context),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader({
    required String name,
    required String email,
    required String roleBadge,
    required String avatarUrl,
    required Color badgeColor,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0C2340), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 2),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundImage: NetworkImage(avatarUrl),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      roleBadge.toUpperCase(),
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            email,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Color(0xFF64748B),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    required Color iconColor,
    required Color iconBgColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, route);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: iconColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF94A3B8)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerLogoutTile(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.splashRoleSelect),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFCA5A5).withValues(alpha: 0.5)),
            ),
            child: const Row(
              children: [
                Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 20),
                SizedBox(width: 12),
                Text(
                  'Logout System',
                  style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
