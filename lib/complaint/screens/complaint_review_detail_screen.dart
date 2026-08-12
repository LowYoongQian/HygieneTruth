import 'package:flutter/material.dart';
import '../../core/models/complaint_model.dart';
import '../../core/models/mock_seed_data.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/status_badge.dart';
import '../widgets/flagged_reason_banner.dart';

class ComplaintReviewDetailScreen extends StatelessWidget {
  const ComplaintReviewDetailScreen({super.key});

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
        appBar: const CustomAppBar(title: 'Review Report'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.description_outlined, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('No complaint details available.', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Go Back')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(title: 'Review Report'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (c.isFlaggedForReview && c.flaggedReason != null) ...[
              FlaggedReasonBanner(reason: c.flaggedReason!),
              const SizedBox(height: 16),
            ],
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(c.restaurantName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Submitted by: ${c.userName}'),
                    ),
                    const Divider(),
                    Text('Category: ${c.category}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('Severity: ${c.severity.name.toUpperCase()}'),
                    const SizedBox(height: 8),
                    const Text('Specific Issues:', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text(c.issues.join('\n')),
                    const SizedBox(height: 8),
                    const Text('Description:', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text(c.description),
                    const SizedBox(height: 8),
                    const Text('GPS Location:', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text('Lat: ${c.latitude}, Long: ${c.longitude}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            CustomButton(
              label: 'Verify Proof',
              icon: Icons.fact_check,
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.verifyEvidence,
                  arguments: c,
                );
              },
            ),
            const SizedBox(height: 10),
            CustomButton(
              label: 'Check Duplicates',
              icon: Icons.image_search,
              backgroundColor: Colors.orange.shade800,
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.duplicateFakeReview,
                  arguments: c,
                );
              },
            ),
            const SizedBox(height: 10),
            CustomButton(
              label: 'Assign Officer',
              icon: Icons.person_add,
              backgroundColor: Colors.green.shade700,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Assigned ${c?.id} to Government Officer (PIC). Status set to "Pending Inspection".')),
                );
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
