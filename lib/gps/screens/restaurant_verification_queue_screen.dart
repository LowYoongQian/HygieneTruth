import 'package:flutter/material.dart';
import '../../core/models/restaurant_model.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/restaurant_store_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/shimmer_skeletons.dart';
import '../../core/widgets/status_badge.dart';

class RestaurantVerificationQueueScreen extends StatefulWidget {
  const RestaurantVerificationQueueScreen({super.key});

  @override
  State<RestaurantVerificationQueueScreen> createState() => _RestaurantVerificationQueueScreenState();
}

class _RestaurantVerificationQueueScreenState extends State<RestaurantVerificationQueueScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<RestaurantModel> _pendingOutlets = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 0;
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _loadInitialPage();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore && !_isLoading) {
        _loadMoreOutlets();
      }
    }
  }

  Future<void> _loadInitialPage() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _currentPage = 0;
        _hasMore = true;
        _pendingOutlets.clear();
      });
    }

    final newOutlets = await RestaurantStoreService.fetchPendingRestaurantsPaginated(
      page: 0,
      pageSize: _pageSize,
    );

    if (mounted) {
      setState(() {
        _pendingOutlets.addAll(newOutlets);
        _isLoading = false;
        if (newOutlets.length < _pageSize) {
          _hasMore = false;
        }
      });
    }
  }

  Future<void> _loadMoreOutlets() async {
    if (_isLoadingMore || !_hasMore) return;

    if (mounted) {
      setState(() => _isLoadingMore = true);
    }

    final nextPage = _currentPage + 1;
    final newOutlets = await RestaurantStoreService.fetchPendingRestaurantsPaginated(
      page: nextPage,
      pageSize: _pageSize,
    );

    if (mounted) {
      setState(() {
        _currentPage = nextPage;
        _pendingOutlets.addAll(newOutlets);
        _isLoadingMore = false;
        if (newOutlets.length < _pageSize) {
          _hasMore = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Pending Outlets'),
      body: _isLoading
          ? const ListSkeleton(itemCount: 3)
          : RefreshIndicator(
              onRefresh: _loadInitialPage,
              child: _pendingOutlets.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 80),
                        Center(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.verified_rounded, size: 48, color: Colors.green),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'No Pending Outlet Requests',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white70 : AppTheme.navyColor,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'All restaurant applications have been reviewed!',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _pendingOutlets.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _pendingOutlets.length) {
                          if (_isLoadingMore) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFFD97706)),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Loading more pending outlets...',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          } else if (!_hasMore && _pendingOutlets.isNotEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: Text(
                                  'All pending outlets loaded (${_pendingOutlets.length})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white38 : Colors.grey.shade500,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }

                        final r = _pendingOutlets[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isDark ? Colors.white10 : Colors.amber.withValues(alpha: 0.3)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        r.imageUrl,
                                        width: 54,
                                        height: 54,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          width: 54,
                                          height: 54,
                                          color: isDark ? Colors.white10 : Colors.grey.shade200,
                                          child: const Icon(Icons.restaurant, color: Colors.grey),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            r.name,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? Colors.white : AppTheme.navyColor,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  r.category,
                                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              StatusBadge.fromStatus(r.status.name),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(Icons.location_on_outlined, size: 14, color: isDark ? Colors.white60 : Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        r.address,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey.shade600),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey.shade200),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Icon(Icons.access_time_rounded, size: 13, color: isDark ? Colors.white38 : Colors.grey.shade500),
                                    const SizedBox(width: 4),
                                    Text(
                                      r.operatingHours.isNotEmpty ? r.operatingHours : '10:00 AM - 10:00 PM',
                                      style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey.shade500),
                                    ),
                                    const Spacer(),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFD97706),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        elevation: 0,
                                      ),
                                      onPressed: () async {
                                        await Navigator.pushNamed(
                                          context,
                                          AppRoutes.restaurantVerificationDetail,
                                          arguments: r,
                                        );
                                        if (mounted) {
                                          _loadInitialPage();
                                        }
                                      },
                                      icon: const Icon(Icons.rate_review_rounded, size: 16),
                                      label: const Text('Review Application', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
