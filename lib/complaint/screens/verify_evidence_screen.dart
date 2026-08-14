import 'package:flutter/material.dart';
import '../../core/models/complaint_model.dart';
import '../../core/models/mock_seed_data.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/wireframe_box.dart';

class VerifyEvidenceScreen extends StatelessWidget {
  const VerifyEvidenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final args = ModalRoute.of(context)?.settings.arguments;
    ComplaintModel? c;

    if (args is ComplaintModel) {
      c = args;
    } else if (MockSeedData.complaints.isNotEmpty) {
      final flagged = MockSeedData.complaints.where((item) => item.isFlaggedForReview).toList();
      c = flagged.isNotEmpty ? flagged.first : MockSeedData.complaints.first;
    }

    if (c == null) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'Verify'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.verified_user_outlined, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('No reports available for verification.', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Go Back')),
            ],
          ),
        ),
      );
    }

    final isGpsMismatched = c.isFlaggedForReview && (c.flaggedReason?.contains('GPS') ?? false);
    final isDuplicateFlagged = c.isFlaggedForReview && (c.flaggedReason?.contains('Duplicate') ?? true);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: const CustomAppBar(title: 'Verify'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. REPORT OVERVIEW HEADER CARD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0C2340), Color(0xFF0F766E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0C2340).withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          c.id,
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (c.isFlaggedForReview ? Colors.amber.shade700 : Colors.green.shade600),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          c.isFlaggedForReview ? 'NEEDS VERIFICATION' : 'VERIFIED',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    c.restaurantName,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Issues: ${c.issues.join(", ")}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. EVIDENCE & INTEGRITY CHECKS
            const Text(
              'Evidence Verification Checks',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.navyColor),
            ),
            const SizedBox(height: 10),

            // Check 1: GPS Distance
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: isGpsMismatched ? Colors.red.shade300 : Colors.green.shade200),
              ),
              color: isGpsMismatched ? Colors.red.shade50 : Colors.green.shade50,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isGpsMismatched ? Colors.red.shade100 : Colors.green.shade100,
                  child: Icon(
                    isGpsMismatched ? Icons.location_off_rounded : Icons.location_on_rounded,
                    color: isGpsMismatched ? Colors.red.shade700 : Colors.green.shade700,
                    size: 20,
                  ),
                ),
                title: const Text('1. GPS Distance Check', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text(
                  isGpsMismatched
                      ? 'WARNING: Distance > 150m threshold (~2,400m from outlet).'
                      : 'PASSED: Location is within 150m of outlet coordinates.',
                  style: TextStyle(fontSize: 12, color: isGpsMismatched ? Colors.red.shade800 : Colors.green.shade800),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Check 2: Timestamp Check
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.green.shade200),
              ),
              color: Colors.green.shade50,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.shade100,
                  child: Icon(Icons.access_time_rounded, color: Colors.green.shade700, size: 20),
                ),
                title: const Text('2. Photo Timestamp Check', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text(
                  'PASSED: Camera EXIF timestamp matches reported submission time (${c.submittedAt}).',
                  style: TextStyle(fontSize: 12, color: Colors.green.shade800),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Check 3: Auto Severity Evaluation
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.blue.shade200),
              ),
              color: Colors.blue.shade50,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Icon(Icons.auto_graph_rounded, color: Colors.blue.shade700, size: 20),
                ),
                title: const Text('3. Auto Severity Evaluation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text(
                  'Calculated Risk Grade: ${c.severity.name.toUpperCase()} Priority Level',
                  style: TextStyle(fontSize: 12, color: Colors.blue.shade800),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 3. INTEGRATED CHECK DUPLICATES & PHOTO COMPARISON
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.copy_all_rounded, color: Color(0xFFD97706), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Check Duplicates Analysis',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.navyColor),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDuplicateFlagged ? Colors.orange.shade50 : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isDuplicateFlagged ? Colors.orange.shade300 : Colors.green.shade300),
                        ),
                        child: Text(
                          isDuplicateFlagged ? '98.4% Match' : 'Unique (0% Match)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDuplicateFlagged ? Colors.orange.shade800 : Colors.green.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isDuplicateFlagged
                        ? 'Image Hash Match: High similarity detected with existing database photo (${c.flaggedReason ?? "Previous submission"}).'
                        : 'Image Hash Check: No identical or duplicate photos found across previous reports.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.3),
                  ),
                  const SizedBox(height: 14),

                  // Side-by-Side Photo Comparison
                  const Text('Photo Comparison', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.navyColor)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            const Text('Uploaded Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF0F766E))),
                            const SizedBox(height: 6),
                            WireframeBox(
                              height: 120,
                              icon: Icons.camera_alt_rounded,
                              label: c.id,
                              sublabel: c.restaurantName,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              isDuplicateFlagged ? 'Matched Database Photo' : 'Database Comparison',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: isDuplicateFlagged ? Colors.red.shade700 : Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            WireframeBox(
                              height: 120,
                              icon: isDuplicateFlagged ? Icons.copy_rounded : Icons.verified_rounded,
                              label: isDuplicateFlagged ? (c.flaggedReason ?? 'cmp_2026_002') : 'No Match',
                              sublabel: isDuplicateFlagged ? 'Visual Similarity: 98.4%' : 'Clean original image',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4. ACTION BUTTONS
            CustomButton(
              label: 'Approve & Mark Genuine',
              icon: Icons.check_circle_rounded,
              backgroundColor: const Color(0xFF059669),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 10),
                        Expanded(child: Text('Report ${c?.id} evidence verified genuine and passed.')),
                      ],
                    ),
                    backgroundColor: const Color(0xFF059669),
                  ),
                );
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 10),
            CustomButton(
              label: 'Override Pass',
              icon: Icons.published_with_changes_rounded,
              backgroundColor: const Color(0xFFD97706),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.warning_amber, color: Colors.white),
                        const SizedBox(width: 10),
                        Expanded(child: Text('GPS & duplicate warning manually overridden for ${c?.id}.')),
                      ],
                    ),
                    backgroundColor: const Color(0xFFD97706),
                  ),
                );
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 10),
            CustomButton(
              label: 'Confirm Duplicate / Reject',
              icon: Icons.cancel_rounded,
              backgroundColor: const Color(0xFFDC2626),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.cancel, color: Colors.white),
                        const SizedBox(width: 10),
                        Expanded(child: Text('Report ${c?.id} rejected due to duplicate/invalid proof.')),
                      ],
                    ),
                    backgroundColor: const Color(0xFFDC2626),
                  ),
                );
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

