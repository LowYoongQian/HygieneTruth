import 'package:flutter/material.dart';
import '../../core/models/complaint_model.dart';
import '../../core/models/mock_seed_data.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/status_badge.dart';
import '../widgets/flagged_reason_banner.dart';

class AllComplaintsScreen extends StatefulWidget {
  const AllComplaintsScreen({super.key});

  @override
  State<AllComplaintsScreen> createState() => _AllComplaintsScreenState();
}

class _AllComplaintsScreenState extends State<AllComplaintsScreen> {
  String _statusFilter = 'All';

  List<ComplaintModel> _getSortedComplaints() {
    List<ComplaintModel> list = List.from(MockSeedData.complaints);

    if (_statusFilter != 'All') {
      list = list.where((c) => c.status.name.toLowerCase() == _statusFilter.toLowerCase()).toList();
    }

    list.sort((a, b) {
      if (a.isFlaggedForReview && !b.isFlaggedForReview) return -1;
      if (!a.isFlaggedForReview && b.isFlaggedForReview) return 1;
      return a.status.index.compareTo(b.status.index);
    });

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final sortedList = _getSortedComplaints();

    return Scaffold(
      appBar: const CustomAppBar(title: 'All Reports'),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: ['All', 'Investigating', 'PendingInspection', 'Resolved', 'Rejected'].map((st) {
                final selected = _statusFilter == st;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(st),
                    selected: selected,
                    onSelected: (val) {
                      setState(() => _statusFilter = st);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: sortedList.isEmpty
                ? const Center(child: Text('No complaints found.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: sortedList.length,
                    itemBuilder: (context, index) {
                      final c = sortedList[index];
                      return Card(
                        child: Column(
                          children: [
                            if (c.isFlaggedForReview && c.flaggedReason != null)
                              FlaggedReasonBanner(reason: c.flaggedReason!),
                            ListTile(
                              title: Text('${c.restaurantName} (${c.id})', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Category: ${c.category}'),
                                  Text('User: ${c.userName} • Severity: ${c.severity.name.toUpperCase()}'),
                                  const SizedBox(height: 4),
                                  StatusBadge.fromStatus(c.status.name),
                                ],
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.complaintReviewDetail,
                                  arguments: c,
                                );
                              },
                            ),
                          ],
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
