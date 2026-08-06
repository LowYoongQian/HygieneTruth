import 'package:flutter/material.dart';
import '../../core/models/inspection_model.dart';
import '../../core/models/mock_seed_data.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/custom_button.dart';

class InspectionReportReviewScreen extends StatelessWidget {
  const InspectionReportReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final insp = MockSeedData.inspections.first;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Review Reports'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Submitted by Officer: ${insp.officerName}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Target Outlet: ${insp.restaurantName}'),
            Text('Conducted On: ${insp.conductedDate}'),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Outcome: ${insp.outcome.name.toUpperCase()}', style: TextStyle(fontWeight: FontWeight.bold, color: insp.outcome == InspectionOutcome.nonCompliant ? Colors.red : Colors.green)),
                    const SizedBox(height: 8),
                    const Text('Findings:', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text(insp.findings),
                    const SizedBox(height: 8),
                    Text('Issued Action: ${insp.issuedAction.name.toUpperCase()}'),
                    if (insp.fineAmount > 0) Text('Fine Amount: RM ${insp.fineAmount.toStringAsFixed(2)}'),
                    const SizedBox(height: 8),
                    Text('Justification: ${insp.justification}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              label: 'Approve Report',
              icon: Icons.check_circle,
              backgroundColor: Colors.green.shade700,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Report approved.')),
                );
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 10),
            CustomButton(
              label: 'Request Revision',
              icon: Icons.replay,
              backgroundColor: Colors.amber.shade800,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Returned for revision.')),
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
