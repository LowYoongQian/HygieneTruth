import 'package:flutter/material.dart';
import '../../core/models/complaint_model.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/restaurant_store_service.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/status_badge.dart';

class AllComplaintsScreen extends StatefulWidget {
  const AllComplaintsScreen({super.key});

  @override
  State<AllComplaintsScreen> createState() => _AllComplaintsScreenState();
}

class _AllComplaintsScreenState extends State<AllComplaintsScreen> {
  String _selectedStatus = 'All Status';
  String _selectedType = 'All Types';

  final List<String> _statusFilters = ['All Status', 'Pending', 'Investigating', 'Resolved', 'Rejected'];

  final List<Map<String, dynamic>> _typeFilters = [
    {'name': 'All Types', 'icon': Icons.all_inbox_rounded},
    {'name': 'Food Safety & Poisoning', 'icon': Icons.sick_rounded},
    {'name': 'Pest Infestation', 'icon': Icons.pest_control_rounded},
    {'name': 'Unclean Utensils', 'icon': Icons.flatware_rounded},
    {'name': 'Staff Hygiene', 'icon': Icons.clean_hands_rounded},
    {'name': 'Staff Conduct', 'icon': Icons.record_voice_over_rounded},
    {'name': 'Waste & Drainage', 'icon': Icons.delete_sweep_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }

  Future<void> _loadComplaints() async {
    await ComplaintStoreService.fetchAllComplaints(forceRefresh: true);
    if (mounted) {
      setState(() {});
    }
  }

  bool _matchesStatus(ComplaintModel c, String statusFilter) {
    if (statusFilter == 'All Status' || statusFilter == 'All') return true;
    switch (statusFilter) {
      case 'Pending':
        return c.status == ComplaintStatus.submitted ||
            c.status == ComplaintStatus.underReview ||
            c.status == ComplaintStatus.pendingInspection;
      case 'Investigating':
        return c.status == ComplaintStatus.investigating;
      case 'Resolved':
        return c.status == ComplaintStatus.resolved;
      case 'Rejected':
        return c.status == ComplaintStatus.rejected;
      default:
        return true;
    }
  }

  bool _matchesType(ComplaintModel c, String typeFilter) {
    if (typeFilter == 'All Types') return true;
    final cat = c.category.toLowerCase();
    switch (typeFilter) {
      case 'Food Safety & Poisoning':
        return cat.contains('food') || cat.contains('poison');
      case 'Pest Infestation':
        return cat.contains('pest') || cat.contains('cockroach') || cat.contains('rat');
      case 'Unclean Utensils':
        return cat.contains('utensil') || cat.contains('cutlery') || cat.contains('plate');
      case 'Staff Hygiene':
        return cat.contains('staff hygiene') || (cat.contains('hygiene') && !cat.contains('food'));
      case 'Staff Conduct':
        return cat.contains('rude') || cat.contains('conduct') || cat.contains('service') || cat.contains('employee');
      case 'Waste & Drainage':
        return cat.contains('waste') || cat.contains('drainage') || cat.contains('grease');
      default:
        return true;
    }
  }

  bool _isFoodComplaint(String cat) {
    final c = cat.toLowerCase();
    return c.contains('food') || c.contains('poison');
  }

  bool _isPestComplaint(String cat) {
    final c = cat.toLowerCase();
    return c.contains('pest') || c.contains('cockroach') || c.contains('rat');
  }

  bool _isStaffConductComplaint(String cat) {
    final c = cat.toLowerCase();
    return c.contains('rude') || c.contains('conduct') || c.contains('service') || c.contains('employee');
  }

  int _getStatusCount(String statusFilter) {
    final list = ComplaintStoreService.complaintsNotifier.value.isNotEmpty
        ? ComplaintStoreService.complaintsNotifier.value
        : RestaurantStoreService.complaintsNotifier.value;
    if (statusFilter == 'All Status' || statusFilter == 'All') return list.length;
    return list.where((c) => _matchesStatus(c, statusFilter)).length;
  }

  int _getTypeCount(String typeFilter) {
    final list = ComplaintStoreService.complaintsNotifier.value.isNotEmpty
        ? ComplaintStoreService.complaintsNotifier.value
        : RestaurantStoreService.complaintsNotifier.value;
    if (typeFilter == 'All Types') return list.length;
    return list.where((c) => _matchesType(c, typeFilter)).length;
  }

  List<ComplaintModel> _getSortedComplaints() {
    final baseList = ComplaintStoreService.complaintsNotifier.value.isNotEmpty
        ? ComplaintStoreService.complaintsNotifier.value
        : RestaurantStoreService.complaintsNotifier.value;
    List<ComplaintModel> list = baseList
        .where((c) => _matchesStatus(c, _selectedStatus) && _matchesType(c, _selectedType))
        .toList();

    list.sort((a, b) {
      if (a.isFlaggedForReview && !b.isFlaggedForReview) return -1;
      if (!a.isFlaggedForReview && b.isFlaggedForReview) return 1;
      // Food & Pest complaints get elevated priority in KKM view
      final aIsCritical = _isFoodComplaint(a.category) || _isPestComplaint(a.category);
      final bIsCritical = _isFoodComplaint(b.category) || _isPestComplaint(b.category);
      if (aIsCritical && !bIsCritical) return -1;
      if (!aIsCritical && bIsCritical) return 1;
      return a.status.index.compareTo(b.status.index);
    });

    return list;
  }

  Color _getSeverityColor(SeverityLevel level) {
    switch (level) {
      case SeverityLevel.high:
        return const Color(0xFFDC2626);
      case SeverityLevel.medium:
        return const Color(0xFFD97706);
      case SeverityLevel.low:
        return const Color(0xFF16A34A);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sortedList = _getSortedComplaints();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        title: 'All Reports',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Reports',
            onPressed: () => _loadComplaints(),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. DUAL FILTER BARS
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              border: Border(
                bottom: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // STATUS FILTER ROW
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _statusFilters.map((st) {
                        final isSelected = _selectedStatus == st;
                        final count = _getStatusCount(st);

                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            showCheckmark: false,
                            selected: isSelected,
                            onSelected: (val) {
                              if (val) setState(() => _selectedStatus = st);
                            },
                            selectedColor: const Color(0xFF0F766E),
                            backgroundColor: isDark ? const Color(0xFF282828) : const Color(0xFFF1F5F9),
                            side: BorderSide(
                              color: isSelected ? const Color(0xFF0F766E) : Colors.transparent,
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  st,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.white.withValues(alpha: 0.25) : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$count',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // CATEGORY / ISSUE TYPE FILTER ROW
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _typeFilters.map((item) {
                        final typeName = item['name'] as String;
                        final typeIcon = item['icon'] as IconData;
                        final isSelected = _selectedType == typeName;
                        final count = _getTypeCount(typeName);

                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            showCheckmark: false,
                            selected: isSelected,
                            onSelected: (val) {
                              setState(() => _selectedType = typeName);
                            },
                            selectedColor: const Color(0xFF0D9488).withValues(alpha: 0.18),
                            backgroundColor: isDark ? const Color(0xFF161616) : const Color(0xFFF8FAFC),
                            side: BorderSide(
                              color: isSelected ? const Color(0xFF0D9488) : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                              width: isSelected ? 1.4 : 1,
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            avatar: Icon(
                              typeIcon,
                              size: 14,
                              color: isSelected ? const Color(0xFF0D9488) : (isDark ? Colors.white60 : Colors.grey.shade600),
                            ),
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  typeName,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected ? const Color(0xFF0D9488) : (isDark ? Colors.white70 : const Color(0xFF475569)),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '($count)',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? const Color(0xFF0D9488) : (isDark ? Colors.white38 : Colors.grey.shade500),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. COMPLAINT LIST CARDS
          Expanded(
            child: sortedList.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_turned_in_outlined, size: 52, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'No reports found matching "$_selectedType" under "$_selectedStatus".',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedStatus = 'All Status';
                                _selectedType = 'All Types';
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F766E),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.clear_all_rounded, size: 16),
                            label: const Text('Reset Filters'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: sortedList.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final c = sortedList[index];
                      final sevColor = _getSeverityColor(c.severity);
                      final isFood = _isFoodComplaint(c.category);
                      final isPest = _isPestComplaint(c.category);
                      final isStaffConduct = _isStaffConductComplaint(c.category);

                      return Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: c.isFlaggedForReview
                                ? Colors.red.shade300
                                : (isFood || isPest
                                    ? (isDark ? const Color(0xFFE11D48).withValues(alpha: 0.3) : const Color(0xFFFECDD3))
                                    : (isDark ? Colors.white12 : const Color(0xFFE2E8F0))),
                            width: (c.isFlaggedForReview || isFood || isPest) ? 1.3 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isFood || isPest
                                  ? const Color(0xFFE11D48).withValues(alpha: isDark ? 0.12 : 0.04)
                                  : Colors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.complaintReviewDetail,
                                arguments: c,
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Flagged Header Banner if applicable
                                if (c.isFlaggedForReview && c.flaggedReason != null)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF2F2),
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                      border: Border(bottom: BorderSide(color: Colors.red.shade100)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.flag_rounded, color: Colors.red.shade700, size: 14),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'FLAGGED: ${c.flaggedReason}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.red.shade800,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                // Card Content Body
                                Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Restaurant Name + ID Pill
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              c.restaurantName,
                                              style: TextStyle(
                                                fontSize: 15.5,
                                                fontWeight: FontWeight.bold,
                                                color: isDark ? Colors.white : const Color(0xFF0C2340),
                                                letterSpacing: -0.2,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                            decoration: BoxDecoration(
                                              color: isDark ? const Color(0xFF282828) : const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              c.id,
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.bold,
                                                color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),

                                      // Category + KKM Priority Badges Row
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: [
                                          // Main Category Badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                            decoration: BoxDecoration(
                                              color: isFood
                                                  ? const Color(0xFFE11D48).withValues(alpha: 0.1)
                                                  : (isPest
                                                      ? const Color(0xFFDC2626).withValues(alpha: 0.1)
                                                      : (isStaffConduct
                                                          ? const Color(0xFFEA580C).withValues(alpha: 0.1)
                                                          : const Color(0xFF0F766E).withValues(alpha: 0.08))),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  isFood
                                                      ? Icons.sick_rounded
                                                      : (isPest
                                                          ? Icons.pest_control_rounded
                                                          : (isStaffConduct
                                                              ? Icons.record_voice_over_rounded
                                                              : Icons.report_problem_rounded)),
                                                  size: 13,
                                                  color: isFood
                                                      ? const Color(0xFFE11D48)
                                                      : (isPest
                                                          ? const Color(0xFFDC2626)
                                                          : (isStaffConduct
                                                              ? const Color(0xFFEA580C)
                                                              : const Color(0xFF0F766E))),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  c.category,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: isFood
                                                        ? const Color(0xFFE11D48)
                                                        : (isPest
                                                            ? const Color(0xFFDC2626)
                                                            : (isStaffConduct
                                                                ? const Color(0xFFEA580C)
                                                                : const Color(0xFF0F766E))),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // KKM Priority Classification Pill
                                          if (isFood)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFEF2F2),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: const Color(0xFFFECDD3)),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.warning_amber_rounded, size: 12, color: Color(0xFFDC2626)),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'KKM Food Safety Priority',
                                                    style: TextStyle(
                                                      fontSize: 10.5,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFFBE123C),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          else if (isPest)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFEF2F2),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: const Color(0xFFFECDD3)),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.pest_control_rounded, size: 12, color: Color(0xFFDC2626)),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'KKM Cleanliness Priority',
                                                    style: TextStyle(
                                                      fontSize: 10.5,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFFDC2626),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          else if (isStaffConduct)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFFF7ED),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: const Color(0xFFFFEDD5)),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.info_outline_rounded, size: 12, color: Color(0xFFEA580C)),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'Staff Conduct (Secondary Priority)',
                                                    style: TextStyle(
                                                      fontSize: 10.5,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFFC2410C),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                          // Severity Level Pill
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                            decoration: BoxDecoration(
                                              color: sevColor.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '${c.severity.name.toUpperCase()} SEVERITY',
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.bold,
                                                color: sevColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),

                                      // Reported Issues Snippet / Preview
                                      if (c.issues.isNotEmpty) ...[
                                        Wrap(
                                          spacing: 4,
                                          runSpacing: 4,
                                          children: c.issues.take(3).map((iss) {
                                            return Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                                                borderRadius: BorderRadius.circular(5),
                                              ),
                                              child: Text(
                                                '• $iss',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                        const SizedBox(height: 8),
                                      ],

                                      // Reporter and Timestamp
                                      Row(
                                        children: [
                                          Icon(Icons.person_outline_rounded, size: 13, color: Colors.grey.shade500),
                                          const SizedBox(width: 4),
                                          Text(
                                            'User: ${c.userName}',
                                            style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                                          ),
                                          const SizedBox(width: 10),
                                          Icon(Icons.access_time_rounded, size: 13, color: Colors.grey.shade500),
                                          const SizedBox(width: 4),
                                          Text(
                                            c.submittedAt,
                                            style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),

                                      // Status Badge + Quick Assign Action Button
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          StatusBadge.fromStatus(c.status.name),
                                          Row(
                                            children: [
                                              if (c.status == ComplaintStatus.submitted ||
                                                  c.status == ComplaintStatus.underReview ||
                                                  c.status == ComplaintStatus.pendingInspection)
                                                Container(
                                                  margin: const EdgeInsets.only(right: 8),
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF059669),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: const Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.assignment_ind_rounded, size: 13, color: Colors.white),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        'Assign Officer',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              Text(
                                                'Review Details',
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFF0F766E),
                                                ),
                                              ),
                                              const SizedBox(width: 2),
                                              const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF0F766E)),
                                            ],
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
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}


