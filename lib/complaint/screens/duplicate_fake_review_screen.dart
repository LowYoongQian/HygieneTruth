import 'package:flutter/material.dart';
import '../../core/models/complaint_model.dart';
import '../../core/models/mock_seed_data.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/wireframe_box.dart';

class DuplicateFakeReviewScreen extends StatelessWidget {
  const DuplicateFakeReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    ComplaintModel? c;

    if (args is ComplaintModel) {
      c = args;
    } else if (MockSeedData.complaints.isNotEmpty) {
      final flaggedList = MockSeedData.complaints.where((item) => item.isFlaggedForReview).toList();
      c = flaggedList.isNotEmpty ? flaggedList.first : MockSeedData.complaints.first;
    }

    return Scaffold(
      appBar: const CustomAppBar(title: 'Check Duplicates'),
      body: c == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFEF3C7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.copy_outlined, size: 48, color: Color(0xFFD97706)),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No Duplicate Reports Found',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'There are currently no reports flagged for duplicate or fake review.',
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade300),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.image_search, color: Colors.orange),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Image Hash Match Found! High similarity detected with existing photo.',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Photo Comparison', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            const Text('New Upload Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(height: 6),
                            WireframeBox(
                              height: 130,
                              icon: Icons.camera_alt,
                              label: c.id,
                              sublabel: 'Target: ${c.restaurantName}',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          children: [
                            const Text('Matched Existing Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(height: 6),
                            WireframeBox(
                              height: 130,
                              icon: Icons.copy,
                              label: c.flaggedReason ?? 'cmp_2026_002',
                              sublabel: 'Match Similarity: 98.4%',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    label: 'Confirm Fake / Duplicate',
                    icon: Icons.block,
                    backgroundColor: Colors.red.shade700,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Report ${c?.id} marked as duplicate/fake and rejected.')),
                      );
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 10),
                  CustomButton(
                    label: 'Mark Genuine',
                    icon: Icons.check_circle,
                    isOutlined: true,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Report ${c?.id} confirmed genuine.')),
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
