import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/mock_seed_data.dart';
import '../models/restaurant_model.dart';
import '../models/user_model.dart';
import '../routes/app_routes.dart';
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

  Widget _buildUserHomePanel(BuildContext context) {
    final safeRestaurants = MockSeedData.restaurants.where((r) => r.riskCategory == RiskCategory.safe).toList();

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

          // Cuisine Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _cuisineChip('🍜 ${t('noodles')}', context),
                _cuisineChip('🍚 ${t('rice')}', context),
                _cuisineChip('🍣 ${t('seafood')}', context),
                _cuisineChip('🍔 ${t('fast_food')}', context),
                _cuisineChip('🥗 ${t('healthy')}', context),
                _cuisineChip('🧋 ${t('drinks')}', context),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Featured Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0284C7), Color(0xFF0F766E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '⭐ Top Eat',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Sakura Sushi Bar',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'Risk Score: 5.0 (Safe)',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF0284C7),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.restaurantDetail, arguments: safeRestaurants.first),
                        child: const Text('View Details'),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.verified_user, size: 64, color: Colors.white24),
              ],
            ),
          ),
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

          // Safe Eats List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(t('top_rated_safe'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.restaurantList),
                child: const Text('View All'),
              ),
            ],
          ),
          for (final r in safeRestaurants) RestaurantCard(restaurant: r),
        ],
      ),
    );
  }

  Widget _cuisineChip(String label, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        onPressed: () => Navigator.pushNamed(context, AppRoutes.restaurantSearch),
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
            _govToolTile(context, icon: Icons.edit_calendar, title: 'Schedule Visit', route: AppRoutes.scheduleInspection),
            _govToolTile(context, icon: Icons.assignment_outlined, title: 'Record Visit', route: AppRoutes.conductInspection),
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
                _buildDrawerItem(context, icon: Icons.edit_calendar_outlined, title: 'Schedule Visit', route: AppRoutes.scheduleInspection, iconColor: const Color(0xFFD97706), iconBgColor: const Color(0xFFFEF3C7)),
                _buildDrawerItem(context, icon: Icons.assignment_turned_in_outlined, title: 'Record Visit', route: AppRoutes.conductInspection, iconColor: const Color(0xFF059669), iconBgColor: const Color(0xFFD1FAE5)),
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
