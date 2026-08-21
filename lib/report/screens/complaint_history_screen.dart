import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/restaurant_store_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../core/widgets/status_badge.dart';

class ComplaintHistoryScreen extends StatefulWidget {
  const ComplaintHistoryScreen({super.key});

  @override
  State<ComplaintHistoryScreen> createState() => _ComplaintHistoryScreenState();
}

class _ComplaintHistoryScreenState extends State<ComplaintHistoryScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    await ComplaintStoreService.fetchAllComplaints(forceRefresh: true);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _handleRefresh() async {
    setState(() => _isLoading = true);
    await ComplaintStoreService.fetchAllComplaints(forceRefresh: true);
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final myComplaints = ComplaintStoreService.complaintsNotifier.value.isNotEmpty
        ? ComplaintStoreService.complaintsNotifier.value
        : RestaurantStoreService.complaintsNotifier.value;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      appBar: const CustomAppBar(title: 'My Reports'),
      body: SkeletonScreenWrapper(
        isLoading: _isLoading,
        skeletonView: const SkeletonListLoader(itemCount: 4),
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: myComplaints.length,
            itemBuilder: (context, index) {
              final c = myComplaints[index];
              return Card(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200),
                ),
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text(
                    c.restaurantName,
                    style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.navyColor),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),
                      Text(
                        'ID: ${c.id.startsWith('CMP-') ? c.id : 'CMP-${c.id.length > 8 ? c.id.substring(0, 8).toUpperCase() : c.id.toUpperCase()}'} • ${c.category}',
                        style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 12.5),
                      ),
                      const SizedBox(height: 2),
                      Text('Submitted: ${c.submittedAt}', style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey)),
                      const SizedBox(height: 6),
                      StatusBadge.fromStatus(c.status.name),
                    ],
                  ),
                  trailing: Icon(Icons.arrow_forward_ios, size: 14, color: isDark ? Colors.white38 : Colors.grey),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.complaintStatusDetail,
                      arguments: c,
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
