import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'top_eat_carousel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/complaint_model.dart';
import '../models/inspection_model.dart';
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
import 'user_avatar.dart';
import 'user_banner.dart';

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
  late PageController _userPageController;
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
    _userPageController = PageController(initialPage: _selectedBottomTabIndex);
    BookmarkService.init();
    _fetchUserGpsLocation();
    _loadCurrentUserSession();
    RestaurantStoreService.fetchAllRestaurants(forceRefresh: true);
    final currentUser = CustomerStoreService.currentCustomer;
    NotificationService.fetchNotifications(
      userId: currentUser?.id,
      userEmail: currentUser?.email,
      userRole: currentUser?.role.name,
    );
    if (_currentRole == UserRole.admin) {
      _loadAdminRealStats();
    } else if (_currentRole == UserRole.government) {
      ComplaintStoreService.fetchAllComplaints(forceRefresh: true);
      RestaurantStoreService.fetchInspections();
    }
  }

  @override
  void didUpdateWidget(covariant RoleDashboardScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTabIndex != oldWidget.initialTabIndex &&
        widget.initialTabIndex != _selectedBottomTabIndex) {
      _selectedBottomTabIndex = widget.initialTabIndex;
      if (_userPageController.hasClients) {
        _userPageController.jumpToPage(_selectedBottomTabIndex);
      }
    }
  }

  @override
  void dispose() {
    _userPageController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserSession() async {
    final user = await CustomerStoreService.fetchActiveUserSession();
    if (mounted && user != null) {
      setState(() {});
      NotificationService.fetchNotifications(
        userId: user.id,
        userEmail: user.email,
        userRole: user.role.name,
      );
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
        pending = RestaurantStoreService.restaurantsNotifier.value.where((r) => r.status == RestaurantStatus.pendingVerification).length;
      }

      // 2. Fetch real users count
      int usersCount = 0;
      try {
        final usersRes = await supabase.from('users').select();
        usersCount = (usersRes as List<dynamic>).length;
      } catch (_) {
        usersCount = CustomerStoreService.getAllRegisteredCustomers().length;
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
        final bool isGoogleFlow = args['isGoogleFlow'] == true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ProfileSetupFocusDialog.show(context, isGoogleFlow: isGoogleFlow);
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
        automaticallyImplyLeading: false,
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
      body: PageView(
        controller: _userPageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            _selectedBottomTabIndex = index;
          });
        },
        children: [
          _buildUserHomePanel(context),
          _buildUserMapPanel(context),
          _buildUserSafeFoodPanel(context),
          _buildUserProfilePanel(context),
        ],
      ),
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
          if (_userPageController.hasClients) {
            _userPageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
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

  List<RestaurantModel> _getTopRankedRestaurants(List<RestaurantModel> allRestaurants) {
    final safeList = allRestaurants
        .where((r) => r.isPubliclyVisible && r.riskCategory == RiskCategory.safe)
        .toList();

    safeList.sort((a, b) {
      final ratingA = RestaurantStoreService.getRatingSync(a.id, restaurantName: a.name);
      final ratingB = RestaurantStoreService.getRatingSync(b.id, restaurantName: b.name);

      final distA = Geolocator.distanceBetween(_userLat, _userLng, a.latitude, a.longitude) / 1000.0;
      final distB = Geolocator.distanceBetween(_userLat, _userLng, b.latitude, b.longitude) / 1000.0;

      // Real rating score (only positive rating weight if restaurant has verified reviews)
      final effectiveRatingA = ratingA.hasReviews ? ratingA.averageRating : 0.0;
      final effectiveRatingB = ratingB.hasReviews ? ratingB.averageRating : 0.0;

      // Composite score: Verified Ratings + Hygiene Cleanliness + Nearby Proximity
      final scoreA = (effectiveRatingA * 8.0) + (ratingA.totalReviews * 0.5) + ((100.0 - a.hygieneRiskScore) * 0.2) - (distA * 0.35) - (a.violationCount * 2.0);
      final scoreB = (effectiveRatingB * 8.0) + (ratingB.totalReviews * 0.5) + ((100.0 - b.hygieneRiskScore) * 0.2) - (distB * 0.35) - (b.violationCount * 2.0);

      return scoreB.compareTo(scoreA);
    });

    if (safeList.isEmpty) {
      return allRestaurants.where((r) => r.isPubliclyVisible).take(3).toList();
    }
    return safeList.take(3).toList();
  }

  Widget _buildUserHomePanel(BuildContext context) {
    return ValueListenableBuilder<List<RestaurantModel>>(
      valueListenable: RestaurantStoreService.restaurantsNotifier,
      builder: (context, liveRestaurants, _) {
        final publicList = liveRestaurants.where((r) => r.isPubliclyVisible).toList();
        final top3 = _getTopRankedRestaurants(liveRestaurants);

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
              if (publicList.isNotEmpty) ...[
                TopEatCarousel(restaurants: publicList, userLat: _userLat, userLng: _userLng),
                const SizedBox(height: 20),
              ],

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
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('⭐', style: TextStyle(fontSize: 15)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            t('top_rated_safe'),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
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
                  ),
                  const SizedBox(width: 4),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.restaurantList),
                    child: const Text('View All ›', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              if (top3.isNotEmpty)
                Column(
                  children: [
                    for (int i = 0; i < top3.length; i++)
                      RestaurantCard(
                        restaurant: top3[i],
                        rankIndex: i,
                        userLat: _userLat,
                        userLng: _userLng,
                      ),
                  ],
                )
              else if (liveRestaurants.isNotEmpty)
                Column(
                  children: [
                    for (int i = 0; i < liveRestaurants.length && i < 3; i++)
                      RestaurantCard(
                        restaurant: liveRestaurants[i],
                        rankIndex: i,
                        userLat: _userLat,
                        userLng: _userLng,
                      ),
                  ],
                ),
            ],
          ),
        );
      },
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
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
            color: isDark ? Colors.white : const Color(0xFF0C2340),
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      ],
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
              // Rich Aesthetic Custom / Gradient Banner Container
              UserBanner(
                bannerUrl: customer?.bannerUrl,
                height: 140,
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
                      UserAvatar(
                        avatarUrl: avatarUrl,
                        radius: 46,
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
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0C2340),
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
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0C2340)),
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
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0C2340)),
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
                  color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : const Color(0xFF0C2340),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.admin_panel_settings, color: Color(0xFF0284C7), size: 22),
                            const SizedBox(width: 8),
                            Text(
                              (CustomerStoreService.currentCustomer?.name.trim().isNotEmpty ?? false)
                                  ? CustomerStoreService.currentCustomer!.name
                                  : 'System Admin',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
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
    final user = CustomerStoreService.currentCustomer;
    final realName = (user != null && user.name.trim().isNotEmpty) ? user.name : 'System Admin';
    final realEmail = (user != null && user.email.trim().isNotEmpty)
        ? user.email
        : (SupabaseService.client.auth.currentUser?.email ?? 'admin@gmail.com');
    final realAvatar = (user != null && user.avatarUrl.isNotEmpty)
        ? user.avatarUrl
        : 'https://i.pravatar.cc/150?img=33';

    return Drawer(
      backgroundColor: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          _buildDrawerHeader(
            name: realName,
            email: realEmail,
            roleBadge: 'Admin',
            avatarUrl: realAvatar,
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
            // Pipeline Step Tracker (Dynamic Live Sync)
            const Text('Pipeline Status', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ListenableBuilder(
              listenable: Listenable.merge([
                ComplaintStoreService.complaintsNotifier,
                RestaurantStoreService.inspectionsNotifier,
              ]),
              builder: (context, _) {
                final allComplaints = ComplaintStoreService.complaintsNotifier.value;
                final allInspections = RestaurantStoreService.inspectionsNotifier.value;

                final assignedCount = allComplaints.where((c) =>
                  c.status == ComplaintStatus.investigating,
                ).length;

                final scheduledCount = allComplaints.where((c) =>
                  c.status == ComplaintStatus.pendingInspection,
                ).length + allInspections.where((i) =>
                  i.enforcementStatus == EnforcementStatus.pending && i.outcome == InspectionOutcome.pending,
                ).length;

                final inspectedCount = allInspections.where((i) =>
                  i.conductedDate != null || i.outcome != InspectionOutcome.pending,
                ).length;

                final closedCount = allComplaints.where((c) =>
                  c.status == ComplaintStatus.resolved,
                ).length + allInspections.where((i) =>
                  i.enforcementStatus == EnforcementStatus.completed,
                ).length;

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white12
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _pipelineStep('$assignedCount', 'Assigned', Colors.blue),
                      const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                      _pipelineStep('$scheduledCount', 'Scheduled', Colors.amber),
                      const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                      _pipelineStep('$inspectedCount', 'Inspected', Colors.purple),
                      const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                      _pipelineStep('$closedCount', 'Closed', Colors.green),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Dynamic Urgent Visit Carousel with Real Database Data & 5-Second Auto-Swipe (Renders only if serious/important cases exist)
            const UrgentVisitCarousel(),

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
    final user = CustomerStoreService.currentCustomer;
    final realName = (user != null && user.name.trim().isNotEmpty) ? user.name : 'Health Officer (PIC)';
    final realEmail = (user != null && user.email.trim().isNotEmpty)
        ? user.email
        : (SupabaseService.client.auth.currentUser?.email ?? 'officer@gov.my');
    final realAvatar = (user != null && user.avatarUrl.isNotEmpty)
        ? user.avatarUrl
        : 'https://i.pravatar.cc/150?img=12';

    return Drawer(
      backgroundColor: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          _buildDrawerHeader(
            name: realName,
            email: realEmail,
            roleBadge: 'Officer (PIC)',
            avatarUrl: realAvatar,
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
          colors: [Color(0xFF181818), Color(0xFF282828)],
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
              UserAvatar(
                avatarUrl: avatarUrl,
                radius: 28,
                border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 2),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4)),
                ],
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
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0C2340),
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

class UrgentVisitCarousel extends StatefulWidget {
  const UrgentVisitCarousel({super.key});

  @override
  State<UrgentVisitCarousel> createState() => _UrgentVisitCarouselState();
}

class _UrgentVisitCarouselState extends State<UrgentVisitCarousel> {
  late final PageController _pageController;
  Timer? _autoSwipeTimer;
  int _currentPageIndex = 0;
  List<ComplaintModel> _urgentComplaints = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _recalculateUrgentList();
    ComplaintStoreService.complaintsNotifier.addListener(_onDataChanged);
    RestaurantStoreService.restaurantsNotifier.addListener(_onDataChanged);
    _startAutoSwipeTimer();
  }

  @override
  void dispose() {
    _autoSwipeTimer?.cancel();
    ComplaintStoreService.complaintsNotifier.removeListener(_onDataChanged);
    RestaurantStoreService.restaurantsNotifier.removeListener(_onDataChanged);
    _pageController.dispose();
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) {
      setState(() {
        _recalculateUrgentList();
      });
      _resetTimer();
    }
  }

  void _startAutoSwipeTimer() {
    _autoSwipeTimer?.cancel();
    _autoSwipeTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_pageController.hasClients) return;
      if (_urgentComplaints.length <= 1) return;

      final nextPage = (_currentPageIndex + 1) % _urgentComplaints.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _resetTimer() {
    _autoSwipeTimer?.cancel();
    _startAutoSwipeTimer();
  }

  /// Multi-factor calculation to filter and sort assigned cases dynamically by priority/urgency
  void _recalculateUrgentList() {
    final allComplaints = ComplaintStoreService.complaintsNotifier.value;
    final allRestaurants = RestaurantStoreService.restaurantsNotifier.value;

    // STRICT FILTER: Only show cases that have been reviewed and assigned by Admin to the officer
    final assignedComplaints = allComplaints.where((c) {
      return c.status == ComplaintStatus.investigating ||
             c.status == ComplaintStatus.pendingInspection;
    }).toList();

    if (assignedComplaints.isEmpty) {
      _urgentComplaints = [];
      _currentPageIndex = 0;
      return;
    }

    final Map<String, RestaurantModel> restMap = {
      for (final r in allRestaurants) r.id: r,
    };

    final List<MapEntry<ComplaintModel, double>> scoredList = [];

    for (final c in assignedComplaints) {
      // Check if this case is SERIOUS or VERY IMPORTANT
      final bool isHighSeverity = c.severity == SeverityLevel.high;
      final bool isFlagged = c.isFlaggedForReview;

      final combinedText = '${c.category} ${c.issues.join(" ")} ${c.description}'.toLowerCase();
      const criticalKeywords = [
        'pest', 'rat', 'rats', 'cockroach', 'cockroaches', 'maggot', 'maggots',
        'poison', 'poisoning', 'vomit', 'vomiting', 'hospital', 'diarrhea',
        'raw meat', 'contamination', 'sewage', 'foul', 'bacteria', 'dead'
      ];
      final bool hasCriticalKeyword = criticalKeywords.any((kw) => combinedText.contains(kw));

      final r = restMap[c.restaurantId];
      final bool isHighRiskRest = r != null && (r.riskCategory == RiskCategory.high || r.hygieneRiskScore >= 40.0 || r.violationCount > 0);

      // ONLY include if it meets serious or very important criteria
      if (!isHighSeverity && !isFlagged && !hasCriticalKeyword && !isHighRiskRest) {
        continue;
      }

      double score = 0.0;

      // 1. Severity Level weighting
      if (c.severity == SeverityLevel.high) {
        score += 60.0;
      } else if (c.severity == SeverityLevel.medium) {
        score += 30.0;
      } else {
        score += 10.0;
      }

      // 2. Critical/High Health hazard keywords
      if (hasCriticalKeyword) {
        score += 30.0;
      }

      // 3. Restaurant Risk & Past Violations
      if (r != null) {
        if (r.riskCategory == RiskCategory.high || r.hygieneRiskScore > 40.0) {
          score += 25.0;
        } else if (r.riskCategory == RiskCategory.moderate || r.hygieneRiskScore > 20.0) {
          score += 10.0;
        }
        if (r.violationCount > 0) {
          score += (r.violationCount * 5.0).clamp(0.0, 20.0);
        }
      }

      // 4. Actionable status priority
      if (c.status == ComplaintStatus.pendingInspection) {
        score += 15.0;
      }

      scoredList.add(MapEntry(c, score));
    }

    // Sort descending by priority score
    scoredList.sort((a, b) => b.value.compareTo(a.value));

    _urgentComplaints = scoredList.map((e) => e.key).toList();
    if (_currentPageIndex >= _urgentComplaints.length && _urgentComplaints.isNotEmpty) {
      _currentPageIndex = 0;
    }
  }

  String _formatCaseId(String rawId) {
    if (rawId.startsWith('CMP-') || rawId.startsWith('cmp_') || rawId.startsWith('#CMP-')) {
      return rawId.replaceAll('#', '').toUpperCase();
    }
    final short = rawId.length > 8 ? rawId.substring(0, 8) : rawId;
    return 'CMP-${short.toUpperCase()}';
  }

  String _getIssueHighlight(ComplaintModel c) {
    if (c.issues.isNotEmpty) {
      return c.issues.first;
    }
    if (c.category.isNotEmpty) {
      return c.category;
    }
    return 'Hygiene Inspection Required';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 1. HIDE COMPLETELY: When no serious/urgent cases exist, hide the section
    if (_urgentComplaints.isEmpty) {
      return const SizedBox.shrink();
    }

    // 2. SINGLE VISIT CARD
    if (_urgentComplaints.length == 1) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: _buildUrgentCard(_urgentComplaints.first, isDark, indexBadge: null),
      );
    }

    // 3. MULTI-CARD AUTO-SWIPING CAROUSEL CONTAINER (5-Sec Rotation)
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 155,
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollStartNotification) {
                  // Pause timer while user is interacting manually
                  _autoSwipeTimer?.cancel();
                } else if (notification is ScrollEndNotification) {
                  // Resume timer once user stops dragging
                  _resetTimer();
                }
                return false;
              },
              child: PageView.builder(
                controller: _pageController,
                itemCount: _urgentComplaints.length,
                onPageChanged: (index) {
                  setState(() => _currentPageIndex = index);
                },
                itemBuilder: (context, index) {
                  final complaint = _urgentComplaints[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _buildUrgentCard(
                      complaint,
                      isDark,
                      indexBadge: '${index + 1}/${_urgentComplaints.length}',
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Smooth Page Indicator Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_urgentComplaints.length, (idx) {
              final isSelected = idx == _currentPageIndex;
              final item = _urgentComplaints[idx];
              final Color dotColor = item.severity == SeverityLevel.high
                  ? const Color(0xFFDC2626)
                  : (item.severity == SeverityLevel.medium ? const Color(0xFFD97706) : const Color(0xFF0284C7));

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isSelected ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isSelected ? dotColor : (isDark ? Colors.white24 : Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildUrgentCard(ComplaintModel complaint, bool isDark, {String? indexBadge}) {
    final caseId = _formatCaseId(complaint.id);
    final restName = RestaurantStoreService.resolveRestaurantName(
      complaint.restaurantName,
      fallback: complaint.restaurantName,
    );
    final issueText = _getIssueHighlight(complaint);

    // Dynamic Urgency & Severity Theming
    final bool isUrgent = complaint.severity == SeverityLevel.high;
    final bool isPriority = complaint.severity == SeverityLevel.medium;

    final Color badgeColor;
    final Color bgColor;
    final Color borderColor;
    final String badgeLabel;
    final IconData badgeIcon;

    if (isUrgent) {
      badgeColor = const Color(0xFFDC2626);
      bgColor = isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.25) : const Color(0xFFFEF2F2);
      borderColor = isDark ? const Color(0xFFDC2626).withValues(alpha: 0.5) : const Color(0xFFFECACA);
      badgeLabel = 'Urgent Visit';
      badgeIcon = Icons.priority_high_rounded;
    } else if (isPriority) {
      badgeColor = const Color(0xFFD97706);
      bgColor = isDark ? const Color(0xFF78350F).withValues(alpha: 0.25) : const Color(0xFFFFFBEB);
      borderColor = isDark ? const Color(0xFFD97706).withValues(alpha: 0.5) : const Color(0xFFFDE68A);
      badgeLabel = 'Priority Visit';
      badgeIcon = Icons.schedule_rounded;
    } else {
      badgeColor = const Color(0xFF0284C7);
      bgColor = isDark ? const Color(0xFF0C4A6E).withValues(alpha: 0.25) : const Color(0xFFF0F9FF);
      borderColor = isDark ? const Color(0xFF0284C7).withValues(alpha: 0.5) : const Color(0xFFBAE6FD);
      badgeLabel = 'Routine Visit';
      badgeIcon = Icons.assignment_outlined;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Row 1: Header + Priority Badge + Case ID
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(badgeIcon, color: badgeColor, size: 16),
              ),
              const SizedBox(width: 6),
              Text(
                badgeLabel,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: badgeColor,
                  letterSpacing: -0.2,
                ),
              ),
              const Spacer(),
              if (indexBadge != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white12 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    indexBadge,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                caseId,
                style: TextStyle(
                  fontSize: 11,
                  color: badgeColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          // Row 2: Restaurant Name • Issue
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              '$restName • $issueText',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0C2340),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Row 3: Action Buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: badgeColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.scheduleInspection,
                        arguments: complaint,
                      );
                    },
                    child: const Text(
                      'Schedule Visit',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? const Color(0xFF5EEAD4) : const Color(0xFF0F766E),
                      side: BorderSide(
                        color: isDark ? const Color(0xFF14B8A6) : const Color(0xFF0D9488),
                        width: 1.2,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.conductInspection,
                        arguments: complaint,
                      );
                    },
                    child: const Text(
                      'Inspect Now',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
