import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/complaint_model.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/restaurant_store_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/shimmer_skeletons.dart';
import '../../core/widgets/status_badge.dart';

class VerifiedComplaintsListScreen extends StatefulWidget {
  const VerifiedComplaintsListScreen({super.key});

  @override
  State<VerifiedComplaintsListScreen> createState() => _VerifiedComplaintsListScreenState();
}

class _VerifiedComplaintsListScreenState extends State<VerifiedComplaintsListScreen> {
  final ScrollController _scrollController = ScrollController();
  RealtimeChannel? _realtimeChannel;
  List<ComplaintModel> _realCases = [];
  String _selectedStatus = 'All Assigned';
  String _searchQuery = '';
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _displayedCount = 4;
  final int _pageSize = 4;

  final List<String> _statusFilters = [
    'All Assigned',
    'Investigating',
    'Scheduled',
    'Resolved',
  ];

  @override
  void initState() {
    super.initState();
    _loadRealData();
    _setupRealtimeSubscription();
    ComplaintStoreService.complaintsNotifier.addListener(_onNotifierUpdate);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    ComplaintStoreService.complaintsNotifier.removeListener(_onNotifierUpdate);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onNotifierUpdate() {
    if (mounted) {
      setState(() {
        _realCases = List.from(ComplaintStoreService.complaintsNotifier.value);
      });
    }
  }

  Future<void> _loadRealData({bool isRefresh = false}) async {
    if (!isRefresh && _realCases.isEmpty) {
      setState(() => _isLoading = true);
    }

    try {
      final fetched = await ComplaintStoreService.fetchAllComplaints(forceRefresh: true);
      if (mounted) {
        setState(() {
          _realCases = fetched;
          _displayedCount = _pageSize;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching real complaints from Supabase: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _setupRealtimeSubscription() {
    try {
      _realtimeChannel = SupabaseService.client
          .channel('public:complaints:live_sync')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'complaints',
            callback: (payload) async {
              if (kDebugMode) {
                print('⚡ Realtime Complaint DB Event received: ${payload.eventType}');
              }
              final freshList = await ComplaintStoreService.fetchAllComplaints(forceRefresh: true);
              if (mounted) {
                setState(() {
                  _realCases = freshList;
                });
              }
            },
          )
          .subscribe();
    } catch (e) {
      if (kDebugMode) print('Supabase realtime channel error: $e');
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 150 &&
        !_isLoadingMore &&
        !_isLoading) {
      _loadMoreCases();
    }
  }

  Future<void> _loadMoreCases() async {
    final filtered = _getFilteredCases();
    if (_displayedCount >= filtered.length) return;

    setState(() => _isLoadingMore = true);
    await Future.delayed(const Duration(milliseconds: 400));

    if (mounted) {
      setState(() {
        _displayedCount = (_displayedCount + _pageSize).clamp(0, filtered.length);
        _isLoadingMore = false;
      });
    }
  }

  String _formatCaseId(String rawId) {
    if (rawId.startsWith('CMP-') || rawId.startsWith('cmp_')) {
      return rawId.toUpperCase();
    }
    final short = rawId.length > 8 ? rawId.substring(0, 8) : rawId;
    return 'CMP-${short.toUpperCase()}';
  }

  List<ComplaintModel> _getFilteredCases() {
    return _realCases.where((c) {
      final restName = RestaurantStoreService.resolveRestaurantName(c.restaurantName, fallback: c.restaurantName).toLowerCase();
      final caseId = _formatCaseId(c.id).toLowerCase();
      final category = c.category.toLowerCase();

      // Only include cases that are assigned to officer pipeline
      if (_selectedStatus == 'All' || _selectedStatus == 'All Assigned') {
        if (c.status != ComplaintStatus.investigating &&
            c.status != ComplaintStatus.pendingInspection &&
            c.status != ComplaintStatus.resolved) {
          return false;
        }
      } else if (_selectedStatus == 'Investigating') {
        if (c.status != ComplaintStatus.investigating) return false;
      } else if (_selectedStatus == 'Scheduled' || _selectedStatus == 'Pending') {
        if (c.status != ComplaintStatus.pendingInspection) return false;
      } else if (_selectedStatus == 'Resolved') {
        if (c.status != ComplaintStatus.resolved) return false;
      }

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return restName.contains(query) || caseId.contains(query) || category.contains(query);
      }

      return true;
    }).toList();
  }

  Map<String, dynamic> _getCategoryIconInfo(String category) {
    final low = category.toLowerCase();
    if (low.contains('pest') || low.contains('rat') || low.contains('cockroach')) {
      return {
        'icon': Icons.pest_control_rounded,
        'color': const Color(0xFFDC2626),
        'bg': const Color(0xFFFEE2E2),
      };
    } else if (low.contains('poison') || low.contains('vomit') || low.contains('diarrhea')) {
      return {
        'icon': Icons.medical_services_outlined,
        'color': const Color(0xFF7C3AED),
        'bg': const Color(0xFFF3E8FF),
      };
    } else if (low.contains('hygiene') || low.contains('staff') || low.contains('clean')) {
      return {
        'icon': Icons.cleaning_services_rounded,
        'color': const Color(0xFF0F766E),
        'bg': const Color(0xFFCCFBF1),
      };
    } else {
      return {
        'icon': Icons.verified_user_rounded,
        'color': const Color(0xFF0284C7),
        'bg': const Color(0xFFE0F2FE),
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allCases = _realCases;
    final filteredCases = _getFilteredCases();
    final paginatedCases = filteredCases.take(_displayedCount).toList();
    final bool hasMore = _displayedCount < filteredCases.length;

    final pendingCount = allCases.where((c) {
      final s = c.status.name.toLowerCase();
      return s == 'pending' || s == 'pendinginspection' || s == 'pending_inspection';
    }).length;

    final activeInspectCount = allCases.where((c) {
      final s = c.status.name.toLowerCase();
      return s == 'investigating' || s == 'underreview' || s == 'under_review' || s == 'submitted';
    }).length;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        title: 'Assigned Cases',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Live Sync Supabase',
            onPressed: () => _loadRealData(isRefresh: true),
          ),
        ],
      ),
      body: _isLoading
          ? const AssignedCasesSkeleton()
          : RefreshIndicator(
              onRefresh: () => _loadRealData(isRefresh: true),
              color: const Color(0xFF0F766E),
              child: Column(
                children: [
                  // 1. TOP SUMMARY METRICS (REAL SUPABASE COUNTS)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      border: Border(bottom: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0))),
                    ),
                    child: Row(
                      children: [
                        _buildStatPill('Total Cases', '${allCases.length}', const Color(0xFF0F766E), isDark),
                        const SizedBox(width: 8),
                        _buildStatPill('Pending Visit', '$pendingCount', const Color(0xFFD97706), isDark),
                        const SizedBox(width: 8),
                        _buildStatPill('Active Inspect', '$activeInspectCount', const Color(0xFF0284C7), isDark),
                      ],
                    ),
                  ),

                  // 2. SEARCH BAR
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                    child: TextField(
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val.trim();
                          _displayedCount = _pageSize;
                        });
                      },
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search by outlet, case ID, or category...',
                        hintStyle: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : Colors.grey),
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),
                  ),

                  // 3. STATUS FILTER CHIPS
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _statusFilters.map((st) {
                          final isSelected = (_selectedStatus == st);
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(st),
                              selected: isSelected,
                              selectedColor: const Color(0xFF0F766E),
                              backgroundColor: isDark ? const Color(0xFF282828) : const Color(0xFFF1F5F9),
                              checkmarkColor: Colors.white,
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: isSelected ? const Color(0xFF0F766E) : (isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
                                ),
                              ),
                              onSelected: (val) {
                                setState(() {
                                  _selectedStatus = val ? st : 'All';
                                  _displayedCount = _pageSize;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // 4. ASSIGNED CASES LIST WITH INFINITE SCROLL
                  Expanded(
                    child: filteredCases.isEmpty
                        ? _buildEmptyState(isDark)
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            itemCount: paginatedCases.length + (hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == paginatedCases.length) {
                                return _buildLoadingMoreIndicator(isDark);
                              }

                              final c = paginatedCases[index];
                              final formattedId = _formatCaseId(c.id);
                              final restName = RestaurantStoreService.resolveRestaurantName(c.restaurantName, fallback: c.restaurantName);
                              final iconInfo = _getCategoryIconInfo(c.category);
                              final IconData catIcon = iconInfo['icon'] as IconData;
                              final Color catColor = iconInfo['color'] as Color;
                              final Color catBg = iconInfo['bg'] as Color;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        AppRoutes.complaintFullDetail,
                                        arguments: c,
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: isDark ? catColor.withValues(alpha: 0.2) : catBg,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(catIcon, color: catColor, size: 22),
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
                                                        restName,
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 15,
                                                          color: isDark ? Colors.white : const Color(0xFF0C2340),
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Colors.grey),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'ID: $formattedId • Category: ${c.category}',
                                                  style: TextStyle(
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.w500,
                                                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF0284C7)),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'GPS: ${c.latitude.toStringAsFixed(4)}, ${c.longitude.toStringAsFixed(4)}',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                StatusBadge.fromStatus(c.status.name),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildLoadingMoreIndicator(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F766E)),
          ),
          const SizedBox(width: 10),
          Text(
            'Loading more assigned cases...',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String label, String count, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.2 : 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.assignment_turned_in_outlined,
                size: 40,
                color: isDark ? Colors.white38 : Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'No Assigned Cases Found',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDark ? Colors.white : const Color(0xFF0C2340),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'No complaint inspection cases match your selected filter or search term.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? Colors.white60 : Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
