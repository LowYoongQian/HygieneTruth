import 'package:flutter/material.dart';
import '../../core/widgets/custom_app_bar.dart';

class AdminActionLogScreen extends StatelessWidget {
  const AdminActionLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final logs = [
      {
        'action': 'Approved Report cmp_2026_001',
        'details': 'Set status to "Investigating". Notice sent.',
        'admin': 'System Admin',
        'time': '2026-08-04 14:00',
      },
      {
        'action': 'Flagged Duplicate Photo',
        'details': 'Flagged cmp_2026_004 for image hash match.',
        'admin': 'System Auto-Check',
        'time': '2026-08-06 11:05',
      },
      {
        'action': 'Role Assigned: Officer',
        'details': 'Changed Health Officer account role.',
        'admin': 'System Admin',
        'time': '2026-08-01 09:30',
      },
    ];

    return Scaffold(
      appBar: const CustomAppBar(title: 'Audit Logs'),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: logs.length,
        separatorBuilder: (ctx, idx) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final log = logs[index];
          return ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.purple,
              child: Icon(Icons.history_edu, color: Colors.white, size: 20),
            ),
            title: Text(log['action']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log['details']!, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 2),
                Text('Logged by: ${log['admin']} • ${log['time']}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          );
        },
      ),
    );
  }
}
