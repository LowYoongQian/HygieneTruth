import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/customer_store_service.dart';
import '../../core/services/notification_service.dart';
import '../models/notification_model.dart';
import '../../core/widgets/shimmer_skeletons.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _activeTabIndex = 0;
  bool _isLoading = true;
  bool _showOnlyUnread = false;

  final List<Map<String, dynamic>> _categories = [
    {'id': 'all', 'label': 'All', 'icon': Icons.all_inbox_rounded},
    {'id': 'alerts', 'label': 'Safety Alerts', 'icon': Icons.shield_outlined},
    {'id': 'reviews', 'label': 'Reviews', 'icon': Icons.rate_review_outlined},
    {'id': 'complaints', 'label': 'Complaints', 'icon': Icons.report_problem_outlined},
    {'id': 'system', 'label': 'System', 'icon': Icons.campaign_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _activeTabIndex = _tabController.index);
      }
    });
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    final user = CustomerStoreService.currentCustomer;
    await NotificationService.fetchNotifications(
      userId: user?.id,
      userEmail: user?.email,
      userRole: user?.role.name,
    );
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackgroundColor : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: isDark ? AppTheme.darkTextColor : AppTheme.navyColor,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark ? AppTheme.darkSurfaceColor : Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : AppTheme.navyColor,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert_rounded,
              color: isDark ? Colors.white : AppTheme.navyColor,
            ),
            onSelected: (val) async {
              final user = CustomerStoreService.currentCustomer;
              if (val == 'mark_all_read') {
                await NotificationService.markAllAsRead(userId: user?.id, userEmail: user?.email);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All notifications marked as read'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppTheme.primaryColor,
                    ),
                  );
                }
              } else if (val == 'clear_all') {
                await NotificationService.clearAll(userId: user?.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All notifications cleared'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: Row(
                  children: [
                    Icon(Icons.done_all_rounded, size: 18, color: AppTheme.primaryColor),
                    SizedBox(width: 10),
                    Text('Mark all as read'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep_outlined, size: 18, color: Colors.red),
                    SizedBox(width: 10),
                    Text('Clear all'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Header with "Read All" quick button (matching mobile_project)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CATEGORIES',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isDark ? AppTheme.darkSubtitleColor : Colors.grey.shade600,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() => _showOnlyUnread = !_showOnlyUnread);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _showOnlyUnread
                                ? AppTheme.primaryColor.withValues(alpha: 0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _showOnlyUnread
                                  ? AppTheme.primaryColor
                                  : (isDark ? Colors.white12 : Colors.grey.shade300),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _showOnlyUnread
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                size: 14,
                                color: _showOnlyUnread ? AppTheme.primaryColor : Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Unread',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _showOnlyUnread ? AppTheme.primaryColor : Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: () async {
                          final user = CustomerStoreService.currentCustomer;
                          await NotificationService.markAllAsRead(userId: user?.id, userEmail: user?.email);
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Read all',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Top Category Bar TabBar
            _buildCategoryBar(isDark),

            const SizedBox(height: 8),

            // Category Subheader with Vertical Pill Indicator
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getCategoryTitle(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isDark ? AppTheme.darkTextColor : AppTheme.navyColor,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),

            // Notifications TabBarView
            Expanded(
              child: _isLoading
                  ? const NotificationListSkeleton()
                  : ValueListenableBuilder<List<AppNotificationModel>>(
                      valueListenable: NotificationService.notificationsNotifier,
                      builder: (context, notifs, _) {
                        return TabBarView(
                          controller: _tabController,
                          children: _categories.map((cat) {
                            final filtered = notifs.where((n) {
                              if (_showOnlyUnread && n.isRead) return false;
                              final catId = cat['id'];
                              if (catId == 'alerts') return n.type == NotificationType.hygieneAlert;
                              if (catId == 'reviews') return n.type == NotificationType.review;
                              if (catId == 'complaints') return n.type == NotificationType.complaint;
                              if (catId == 'system') return n.type == NotificationType.system || n.type == NotificationType.outlet;
                              return true;
                            }).toList();

                            if (filtered.isEmpty) {
                              return _buildEmptyState(isDark, cat['label']);
                            }

                            return RefreshIndicator(
                              onRefresh: _loadNotifications,
                              color: AppTheme.primaryColor,
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  final item = filtered[index];
                                  return _buildNotificationCard(item, isDark);
                                },
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryTitle() {
    switch (_activeTabIndex) {
      case 0:
        return 'All Notifications';
      case 1:
        return 'Safety & Outbreak Alerts';
      case 2:
        return 'Customer Review Responses';
      case 3:
        return 'Hygiene Complaint Updates';
      case 4:
        return 'System & Inspection Notices';
      default:
        return 'Notifications';
    }
  }

  Widget _buildCategoryBar(bool isDark) {
    return Container(
      color: isDark ? AppTheme.darkSurfaceColor : Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: false,
        dividerColor: Colors.transparent,
        indicatorColor: AppTheme.primaryColor,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: isDark ? Colors.white38 : Colors.grey,
        tabs: _categories.map((cat) {
          final int index = _categories.indexOf(cat);
          final bool isSelected = _activeTabIndex == index;
          return Tab(
            height: 72,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  cat['icon'] as IconData,
                  size: 22,
                  color: isSelected
                      ? AppTheme.primaryColor
                      : (isDark ? Colors.white38 : Colors.grey),
                ),
                const SizedBox(height: 5),
                Text(
                  cat['label'] as String,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNotificationCard(AppNotificationModel item, bool isDark) {
    Color typeColor = AppTheme.primaryColor;
    IconData typeIcon = Icons.notifications_active_outlined;

    switch (item.type) {
      case NotificationType.complaint:
        typeColor = const Color(0xFFDC2626); // Crimson Red
        typeIcon = Icons.report_problem_rounded;
        break;
      case NotificationType.outlet:
        typeColor = const Color(0xFF0F766E); // Deep Teal
        typeIcon = Icons.storefront_rounded;
        break;
      case NotificationType.review:
        typeColor = const Color(0xFF9333EA); // Purple
        typeIcon = Icons.rate_review_rounded;
        break;
      case NotificationType.hygieneAlert:
        typeColor = const Color(0xFFD97706); // Amber
        typeIcon = Icons.shield_rounded;
        break;
      case NotificationType.system:
        typeColor = AppTheme.navyColor;
        typeIcon = Icons.campaign_rounded;
        break;
    }

    final timeStr = _formatDateTime(item.createdAt);

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade600,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 26),
      ),
      onDismissed: (_) {
        final user = CustomerStoreService.currentCustomer;
        NotificationService.deleteNotification(item.id, userId: user?.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification removed'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: !item.isRead
              ? (isDark ? AppTheme.primaryColor.withValues(alpha: 0.12) : const Color(0xFFEFF6FF))
              : (isDark ? AppTheme.darkSurfaceColor : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: !item.isRead
                ? (isDark ? AppTheme.primaryColor.withValues(alpha: 0.4) : const Color(0xFF93C5FD))
                : (isDark ? AppTheme.darkBorderColor : Colors.grey.shade200),
            width: !item.isRead ? 1.5 : 1.0,
          ),
          boxShadow: (isDark || !item.isRead)
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: ListTile(
          onTap: () {
            final user = CustomerStoreService.currentCustomer;
            if (!item.isRead) {
              NotificationService.markAsRead(item.id, userId: user?.id, userEmail: user?.email);
            }
            if (item.actionUrl != null && item.actionUrl!.isNotEmpty) {
              _handleNotificationNavigation(item.actionUrl!);
            }
          },
          contentPadding: const EdgeInsets.all(14),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(typeIcon, color: typeColor, size: 22),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    fontWeight: !item.isRead ? FontWeight.bold : FontWeight.w600,
                    fontSize: 14.5,
                    color: isDark ? AppTheme.darkTextColor : AppTheme.navyColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                timeStr,
                style: TextStyle(
                  fontSize: 10.5,
                  color: isDark ? AppTheme.darkSubtitleColor : Colors.grey.shade500,
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.message,
                  style: TextStyle(
                    color: isDark ? AppTheme.darkSubtitleColor : Colors.grey.shade700,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
                if (item.actionUrl != null && item.actionUrl!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Text(
                        'View details',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, size: 14, color: Color(0xFF2563EB)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final m = months[dt.month - 1];
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$m $d, $h:$min';
  }

  Widget _buildEmptyState(bool isDark, String categoryLabel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurfaceColor : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 44,
                color: isDark ? Colors.white38 : Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No $categoryLabel Found',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isDark ? AppTheme.darkTextColor : AppTheme.navyColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'You are all caught up! Realtime updates for $categoryLabel will appear here instantly.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? AppTheme.darkSubtitleColor : Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNotificationNavigation(String actionUrl) {
    if (actionUrl.contains('outlet') || actionUrl.contains('testing')) {
      Navigator.of(context).pop();
    }
  }
}
