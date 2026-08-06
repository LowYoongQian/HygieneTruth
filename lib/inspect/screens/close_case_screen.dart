import 'package:flutter/material.dart';
import '../../core/models/inspection_model.dart';
import '../../core/models/mock_seed_data.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/status_badge.dart';

class CloseCaseScreen extends StatelessWidget {
  const CloseCaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final insp = args is InspectionModel ? args : MockSeedData.inspections.first;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Close Case'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Closure Checklist', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.check_circle, color: Colors.green),
                      title: const Text('1. Report Approved'),
                      subtitle: Text('Outcome: ${insp.outcome.name.toUpperCase()}'),
                    ),
                    const Divider(),
                    ListTile(
                      leading: Icon(
                        insp.enforcementStatus == EnforcementStatus.completed ? Icons.check_circle : Icons.hourglass_top,
                        color: insp.enforcementStatus == EnforcementStatus.completed ? Colors.green : Colors.amber,
                      ),
                      title: const Text('2. Action Completed'),
                      subtitle: Text('Status: ${insp.enforcementStatus.name.toUpperCase()}'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Report Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                StatusBadge.fromStatus('Resolved'),
              ],
            ),
            const SizedBox(height: 24),
            CustomButton(
              label: 'Close Case',
              icon: Icons.folder_off,
              backgroundColor: Colors.teal.shade800,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Case closed & complaint set to "Resolved"!')),
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
