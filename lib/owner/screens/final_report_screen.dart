import 'package:flutter/material.dart';
import '../../core/models/complaint_model.dart';
import '../../core/models/mock_seed_data.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/status_badge.dart';

class FinalReportScreen extends StatelessWidget {
  const FinalReportScreen({super.key});

  // TODO: Implement read-only final report PDF export

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    ComplaintModel? c;
    if (args is ComplaintModel) {
      c = args;
    } else if (MockSeedData.complaints.isNotEmpty) {
      c = MockSeedData.complaints.last;
    }

    if (c == null) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'Final Report'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.picture_as_pdf_outlined, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('No final report available.', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Go Back')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(title: 'Final Report'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  const Icon(Icons.verified, size: 64, color: Colors.green),
                  const SizedBox(height: 8),
                  Text(c.restaurantName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('Notice ID: ${c.id}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 8),
                  StatusBadge.fromStatus(c.status.name),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text('Case Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _reportRow('Inspection Outcome', 'Compliant (Verified)'),
                    const Divider(),
                    _reportRow('Enforcement Action', 'Warning Issued'),
                    const Divider(),
                    _reportRow('Fine Amount', 'RM 0.00'),
                    const Divider(),
                    _reportRow('Resolution Date', c.submittedAt),
                    const Divider(),
                    _reportRow('Case Status', 'Resolved & Closed'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            CustomButton(
              label: 'Back',
              icon: Icons.arrow_back,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reportRow(String key, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(key, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
