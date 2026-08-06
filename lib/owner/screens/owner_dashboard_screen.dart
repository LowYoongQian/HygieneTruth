import 'package:flutter/material.dart';
import '../../core/models/mock_seed_data.dart';
import '../../core/models/complaint_model.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/status_badge.dart';
import '../widgets/deadline_countdown_badge.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  int _selectedTab = 0; // 0 = Active, 1 = Closed

  // TODO: Implement owner notice query & live status sync

  @override
  Widget build(BuildContext context) {
    final activeNotices = MockSeedData.complaints
        .where((c) => c.status != ComplaintStatus.resolved && c.status != ComplaintStatus.rejected)
        .toList();

    final closedNotices = MockSeedData.complaints
        .where((c) => c.status == ComplaintStatus.resolved || c.status == ComplaintStatus.rejected)
        .toList();

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Notice List',
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              Navigator.pushReplacementNamed(context, AppRoutes.splashRoleSelect);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ChoiceChip(
                  label: const Text('Active Notices'),
                  selected: _selectedTab == 0,
                  onSelected: (val) {
                    if (val) setState(() => _selectedTab = 0);
                  },
                ),
                ChoiceChip(
                  label: const Text('Closed Cases'),
                  selected: _selectedTab == 1,
                  onSelected: (val) {
                    if (val) setState(() => _selectedTab = 1);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _selectedTab == 0
                ? _buildActiveList(activeNotices)
                : _buildClosedList(closedNotices),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveList(List<ComplaintModel> list) {
    if (list.isEmpty) {
      return const Center(child: Text('No active notices'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final c = list[index];
        final daysLeft = (4 - index * 3); // Demo countdown simulation
        return Card(
          child: ListTile(
            title: Text(c.restaurantName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Category: ${c.category}'),
                Text('ID: ${c.id}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    StatusBadge.fromStatus(c.status.name),
                    const SizedBox(width: 8),
                    DeadlineCountdownBadge(daysLeft: daysLeft),
                  ],
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.noticeDetail,
                arguments: c,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildClosedList(List<ComplaintModel> list) {
    if (list.isEmpty) {
      return const Center(child: Text('No closed cases'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final c = list[index];
        return Card(
          child: ListTile(
            title: Text(c.restaurantName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Category: ${c.category}'),
                Text('Resolved: ${c.submittedAt}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    StatusBadge.fromStatus(c.status.name),
                    const SizedBox(width: 8),
                    const DeadlineCountdownBadge(daysLeft: 0, isResolved: true),
                  ],
                ),
              ],
            ),
            trailing: const Icon(Icons.description_outlined, color: Colors.teal),
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.finalReport,
                arguments: c,
              );
            },
          ),
        );
      },
    );
  }
}
