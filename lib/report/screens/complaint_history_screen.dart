import 'package:flutter/material.dart';
import '../../core/models/mock_seed_data.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/restaurant_store_service.dart';
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
    final myComplaints = ComplaintStoreService.complaintsNotifier.value.isNotEmpty
        ? ComplaintStoreService.complaintsNotifier.value
        : MockSeedData.complaints;

    return Scaffold(
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
                child: ListTile(
                  title: Text(c.restaurantName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ID: ${c.id} • ${c.category}'),
                      Text('Submitted: ${c.submittedAt}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 6),
                      StatusBadge.fromStatus(c.status.name),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
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
