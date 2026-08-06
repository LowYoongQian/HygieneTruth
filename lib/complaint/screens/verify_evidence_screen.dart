import 'package:flutter/material.dart';
import '../../core/models/complaint_model.dart';
import '../../core/models/mock_seed_data.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/custom_button.dart';

class VerifyEvidenceScreen extends StatelessWidget {
  const VerifyEvidenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final c = args is ComplaintModel ? args : MockSeedData.complaints[2];

    final isMismatched = c.isFlaggedForReview && (c.flaggedReason?.contains('GPS') ?? false);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Verify Proof'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Evidence Check Results', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Check 1: GPS Distance Check
            Card(
              color: isMismatched ? Colors.red.shade50 : Colors.green.shade50,
              child: ListTile(
                leading: Icon(
                  isMismatched ? Icons.warning : Icons.check_circle,
                  color: isMismatched ? Colors.red : Colors.green,
                ),
                title: const Text('1. GPS Distance Check'),
                subtitle: Text(
                  isMismatched
                      ? 'FAILED: Distance > 150m threshold (~2,400m).'
                      : 'PASSED: Location is within 150m of outlet premises.',
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Check 2: Timestamp
            Card(
              color: Colors.green.shade50,
              child: const ListTile(
                leading: Icon(Icons.check_circle, color: Colors.green),
                title: Text('2. Photo Timestamp Check'),
                subtitle: Text('PASSED: Photo timestamp matches submission time.'),
              ),
            ),
            const SizedBox(height: 12),

            // Check 3: Auto Severity
            Card(
              color: Colors.blue.shade50,
              child: ListTile(
                leading: const Icon(Icons.auto_graph, color: Colors.blue),
                title: const Text('3. Auto Severity Evaluation'),
                subtitle: Text('Calculated Rank: ${c.severity.name.toUpperCase()}'),
              ),
            ),
            const SizedBox(height: 24),

            CustomButton(
              label: 'Approve Evidence',
              icon: Icons.check_circle,
              backgroundColor: Colors.green.shade700,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Evidence verified genuine.')),
                );
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 10),
            CustomButton(
              label: 'Override Pass',
              icon: Icons.published_with_changes,
              backgroundColor: Colors.amber.shade800,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('GPS distance warning overridden.')),
                );
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 10),
            CustomButton(
              label: 'Reject Evidence',
              icon: Icons.cancel,
              backgroundColor: Colors.red.shade700,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Submission rejected due to invalid proof.')),
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
