import 'package:flutter/material.dart';
import '../../core/models/inspection_model.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/restaurant_store_service.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/shimmer_skeletons.dart';
import '../../core/widgets/status_badge.dart';

class EnforcementHistoryScreen extends StatefulWidget {
  const EnforcementHistoryScreen({super.key});

  @override
  State<EnforcementHistoryScreen> createState() => _EnforcementHistoryScreenState();
}

class _EnforcementHistoryScreenState extends State<EnforcementHistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  String _selectedFilter = 'All';
  String _searchQuery = '';
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _displayedCount = 4;
  final int _pageSize = 4;

  final List<String> _filterOptions = [
    'All',
    'In Progress',
    'Completed',
    'Closure',
    'Fine',
    'Warning',
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _displayedCount = _pageSize;
        _isLoading = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 150 &&
        !_isLoadingMore &&
        !_isLoading) {
      _loadMoreActions();
    }
  }

  Future<void> _loadMoreActions() async {
    final filtered = _getFilteredList();
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

  List<InspectionModel> _getFilteredList() {
    return RestaurantStoreService.inspectionsNotifier.value.where((insp) {
      final restName = RestaurantStoreService.resolveRestaurantName(insp.restaurantName, fallback: insp.restaurantName).toLowerCase();
      final actionStr = insp.issuedAction.name.toLowerCase();
      final statusStr = insp.enforcementStatus.name.toLowerCase();

      if (_selectedFilter != 'All') {
        if (_selectedFilter == 'In Progress' && statusStr != 'inprogress') return false;
        if (_selectedFilter == 'Completed' && statusStr != 'completed') return false;
        if (_selectedFilter == 'Closure' && actionStr != 'closure') return false;
        if (_selectedFilter == 'Fine' && actionStr != 'fine') return false;
        if (_selectedFilter == 'Warning' && actionStr != 'warning') return false;
      }

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return restName.contains(q) || actionStr.contains(q) || insp.officerName.toLowerCase().contains(q);
      }

      return true;
    }).toList();
  }

  Map<String, dynamic> _getActionVisuals(EnforcementType type) {
    switch (type) {
      case EnforcementType.closure:
        return {
          'icon': Icons.block_rounded,
          'color': const Color(0xFFDC2626),
          'bg': const Color(0xFFFEE2E2),
          'label': 'Closure Notice',
        };
      case EnforcementType.fine:
        return {
          'icon': Icons.payments_rounded,
          'color': const Color(0xFFD97706),
          'bg': const Color(0xFFFEF3C7),
          'label': 'Compound Fine',
        };
      case EnforcementType.warning:
        return {
          'icon': Icons.warning_amber_rounded,
          'color': const Color(0xFF0284C7),
          'bg': const Color(0xFFE0F2FE),
          'label': 'Warning Notice',
        };
      case EnforcementType.none:
        return {
          'icon': Icons.check_circle_outline_rounded,
          'color': const Color(0xFF059669),
          'bg': const Color(0xFFD1FAE5),
          'label': 'Compliant',
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allList = RestaurantStoreService.inspectionsNotifier.value;
    final filtered = _getFilteredList();
    final paginated = filtered.take(_displayedCount).toList();
    final hasMore = _displayedCount < filtered.length;

    final totalFines = allList.fold<double>(0, (sum, i) => sum + i.fineAmount);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: const CustomAppBar(title: 'Action History'),
      body: _isLoading
          ? const ActionHistorySkeleton()
          : RefreshIndicator(
              onRefresh: _loadInitialData,
              color: const Color(0xFF0F766E),
              child: Column(
                children: [
                  // 1. TOP STATS COUNTER PILLS
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      border: Border(bottom: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0))),
                    ),
                    child: Row(
                      children: [
                        _buildStatPill('Total Actions', '${allList.length}', const Color(0xFF0F766E), isDark),
                        const SizedBox(width: 8),
                        _buildStatPill('Total Fines', 'RM ${totalFines.toInt()}', const Color(0xFFDC2626), isDark),
                        const SizedBox(width: 8),
                        _buildStatPill('In Progress', '${allList.where((i) => i.enforcementStatus == EnforcementStatus.inProgress).length}', const Color(0xFFD97706), isDark),
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
                        hintText: 'Search actions by premise, fine, or officer...',
                        hintStyle: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : Colors.grey),
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
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

                  // 3. FILTER CHIPS ROW
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _filterOptions.map((opt) {
                          final isSelected = (_selectedFilter == opt);
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(opt),
                              selected: isSelected,
                              selectedColor: const Color(0xFF0F766E),
                              backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
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
                                  _selectedFilter = val ? opt : 'All';
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

                  // 4. ACTION HISTORY LIST WITH INFINITE SCROLL
                  Expanded(
                    child: filtered.isEmpty
                        ? _buildEmptyState(isDark)
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            itemCount: paginated.length + (hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == paginated.length) {
                                return _buildLoadingMoreIndicator(isDark);
                              }

                              final insp = paginated[index];
                              final restName = RestaurantStoreService.resolveRestaurantName(insp.restaurantName, fallback: insp.restaurantName);
                              final visuals = _getActionVisuals(insp.issuedAction);
                              final IconData icon = visuals['icon'] as IconData;
                              final Color iconColor = visuals['color'] as Color;
                              final Color iconBg = visuals['bg'] as Color;
                              final String actionLabel = visuals['label'] as String;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
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
                                      Navigator.pushNamed(context, AppRoutes.closeCase, arguments: insp);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: isDark ? iconColor.withValues(alpha: 0.2) : iconBg,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(icon, color: iconColor, size: 22),
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
                                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    StatusBadge.fromStatus(insp.enforcementStatus.name),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Decree: $actionLabel',
                                                  style: TextStyle(
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.w600,
                                                    color: iconColor,
                                                  ),
                                                ),
                                                if (insp.fineAmount > 0) ...[
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        'Compound Penalty: RM ${insp.fineAmount.toStringAsFixed(2)}',
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.bold,
                                                          color: Color(0xFFDC2626),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                                        decoration: BoxDecoration(
                                                          color: insp.isFinePaid ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
                                                          borderRadius: BorderRadius.circular(6),
                                                          border: Border.all(color: insp.isFinePaid ? const Color(0xFF10B981) : const Color(0xFFF59E0B)),
                                                        ),
                                                        child: Text(
                                                          insp.isFinePaid ? '✅ Paid' : '⏳ Unpaid',
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.bold,
                                                            color: insp.isFinePaid ? const Color(0xFF059669) : const Color(0xFFB45309),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                                const SizedBox(height: 6),
                                                Row(
                                                  children: [
                                                    Icon(Icons.badge_outlined, size: 13, color: isDark ? Colors.white38 : Colors.grey),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      insp.officerName,
                                                      style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey.shade600),
                                                    ),
                                                    const Spacer(),
                                                    Text(
                                                      'Tap to Close Case ›',
                                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0F766E)),
                                                    ),
                                                  ],
                                                ),
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
            'Loading more actions...',
            style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : const Color(0xFF64748B), fontWeight: FontWeight.w500),
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
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
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
                color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.history_toggle_off_rounded, size: 40, color: isDark ? Colors.white38 : Colors.grey.shade400),
            ),
            const SizedBox(height: 14),
            Text(
              'No Enforcement Actions Found',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : const Color(0xFF0F172A)),
            ),
            const SizedBox(height: 6),
            Text(
              'No enforcement history records match your search query or selected filter.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: isDark ? Colors.white60 : Colors.grey.shade600, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
