import 'package:flutter/material.dart';
import '../../core/models/complaint_model.dart';
import '../../core/models/mock_seed_data.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/status_badge.dart';

class ComplaintFullDetailScreen extends StatelessWidget {
  const ComplaintFullDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final c = args is ComplaintModel ? args : MockSeedData.complaints.first;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Case Details'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(c.id, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                StatusBadge.fromStatus(c.status.name),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(c.restaurantName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Category: ${c.category}'),
                    ),
                    const Divider(),
                    const Text('Detailed Description:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(c.description),
                    const SizedBox(height: 12),
                    const Text('Submitted Photos/Videos Evidence:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(c.photoUrls.first, height: 160, width: double.infinity, fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 12),
                    const Text('Attached GPS Location:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Latitude: ${c.latitude}, Longitude: ${c.longitude}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            CustomButton(
              label: 'Schedule Visit',
              icon: Icons.edit_calendar,
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.scheduleInspection,
                  arguments: c,
                );
              },
            ),
            const SizedBox(height: 10),
            CustomButton(
              label: 'Record Visit',
              icon: Icons.assignment_outlined,
              backgroundColor: Colors.teal.shade700,
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.conductInspection,
                  arguments: c,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
