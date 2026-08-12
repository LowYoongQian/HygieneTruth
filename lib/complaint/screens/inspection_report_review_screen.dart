import 'package:flutter/material.dart';
import '../../core/models/inspection_model.dart';
import '../../core/models/mock_seed_data.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/custom_button.dart';

class InspectionReportReviewScreen extends StatelessWidget {
  const InspectionReportReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    InspectionModel? insp;

    if (args is InspectionModel) {
      insp = args;
    } else if (MockSeedData.inspections.isNotEmpty) {
      insp = MockSeedData.inspections.first;
    }

    return Scaffold(
      appBar: const CustomAppBar(title: 'Review Reports'),
      body: insp == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE0F2FE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.rate_review_outlined, size: 48, color: Color(0xFF0284C7)),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No Inspection Reports Pending Review',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'All submitted officer inspection reports have been processed.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back to Dashboard'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A88F),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Submitted by Officer: ${insp.officerName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Target Outlet: ${insp.restaurantName}'),
                  Text('Conducted On: ${insp.conductedDate.toString().split(' ')[0]}'),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Outcome: ${insp.outcome.name.toUpperCase()}',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: insp.outcome == InspectionOutcome.nonCompliant ? Colors.red : Colors.green)),
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
