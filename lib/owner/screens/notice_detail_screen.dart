import 'package:flutter/material.dart';
import '../../core/models/complaint_model.dart';
import '../../core/models/mock_seed_data.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/wireframe_box.dart';
import '../widgets/deadline_countdown_badge.dart';

class NoticeDetailScreen extends StatelessWidget {
  const NoticeDetailScreen({super.key});

  // TODO: Implement owner evidence response submit

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final c = args is ComplaintModel ? args : MockSeedData.complaints.first;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Notice Details'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(c.restaurantName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const DeadlineCountdownBadge(daysLeft: 4),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                StatusBadge.fromStatus(c.status.name),
                const SizedBox(width: 8),
                Text('Notice ID: ${c.id}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Category: ${c.category}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Violation Description:', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text(c.description),
                    const SizedBox(height: 8),
                    const Text('Specific Issues:', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text(c.issues.join('\n')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            const Text('Proof Media', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: c.photoUrls.isNotEmpty ? c.photoUrls.length : 2,
                itemBuilder: (context, idx) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: c.photoUrls.isNotEmpty
                          ? Image.network(c.photoUrls[idx], width: 140, height: 120, fit: BoxFit.cover)
                          : const WireframeBox(width: 140, height: 120, icon: Icons.image, label: 'Photo Proof'),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            const Text('GPS Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            WireframeBox(
              height: 110,
              icon: Icons.map,
              label: 'GPS: ${c.latitude}, ${c.longitude}',
              sublabel: 'Location Pin Map',
            ),
            const SizedBox(height: 24),

            CustomButton(
              label: 'Mark Resolved',
              icon: Icons.check_circle,
              backgroundColor: const Color(0xFF0F766E),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.markIssueResolved,
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
