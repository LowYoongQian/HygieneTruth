import 'package:flutter/material.dart';
import '../../core/models/complaint_model.dart';
import '../../core/models/mock_seed_data.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/status_badge.dart';
import '../widgets/complaint_status_tracker.dart';

class ComplaintStatusDetailScreen extends StatelessWidget {
  const ComplaintStatusDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    ComplaintModel? c;
    if (args is ComplaintModel) {
      c = args;
    } else if (MockSeedData.complaints.isNotEmpty) {
      c = MockSeedData.complaints.first;
    }

    if (c == null) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'Report Status'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.report_outlined, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('No complaint status available.', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Go Back')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(title: 'Report: ${c.id}'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ComplaintStatusTracker(status: c.status),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Report ID: ${c.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        StatusBadge.fromStatus(c.status.name),
                      ],
                    ),
                    const Divider(height: 24),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.store, color: Colors.teal),
                      title: Text(c.restaurantName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Category: ${c.category}'),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.warning, color: Colors.amber),
                      title: const Text('Issues'),
                      subtitle: Text(c.issues.join('\n')),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.description),
                      title: const Text('Description'),
                      subtitle: Text(c.description),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.access_time),
                      title: const Text('Timestamp'),
                      subtitle: Text(c.submittedAt),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
