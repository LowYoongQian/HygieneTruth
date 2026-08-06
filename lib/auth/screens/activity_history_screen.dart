import 'package:flutter/material.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/empty_state_widget.dart';

class ActivityHistoryScreen extends StatelessWidget {
  const ActivityHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy activity log entries for demo
    final activities = [
      {
        'title': 'Submitted Complaint cmp_2026_001',
        'subtitle': 'Selera Kampung Bistro - Pest Infestation',
        'time': '2026-08-04 13:20',
        'icon': Icons.report_problem_outlined,
      },
      {
        'title': 'Viewed Safe Food Recommendations',
        'subtitle': 'Checked nearby safe restaurants list',
        'time': '2026-08-05 09:10',
        'icon': Icons.recommend_outlined,
      },
      {
        'title': 'Profile Updated',
        'subtitle': 'Updated phone number',
        'time': '2026-08-01 11:00',
        'icon': Icons.person_outline,
      },
    ];

    return Scaffold(
      appBar: const CustomAppBar(title: 'Activity History'),
      body: activities.isEmpty
          ? const EmptyStateWidget(
              title: 'No Activity History',
              message: 'You have no activity history yet.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: activities.length,
              separatorBuilder: (ctx, idx) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = activities[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal.shade50,
                    child: Icon(item['icon'] as IconData, color: Colors.teal),
                  ),
                  title: Text(item['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(item['subtitle'] as String),
                  trailing: Text(
                    item['time'] as String,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                );
              },
            ),
    );
  }
}
