import 'package:flutter/material.dart';
import '../../core/models/complaint_model.dart';
import '../../core/models/mock_seed_data.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/wireframe_box.dart';
import '../widgets/deadline_countdown_badge.dart';

class NoticeDetailScreen extends StatelessWidget {
  const NoticeDetailScreen({super.key});

  Map<String, dynamic> _getAuthorityInfo(ComplaintModel c) {
    if (c.severity == SeverityLevel.high || c.category.contains('Pest') || c.category.contains('Poisoning')) {
      return {
        'authorityName': 'Ministry of Health (KKM) & DBKL Enforcement',
        'badgeLabel': 'Official Government Directive',
        'icon': Icons.gavel_rounded,
        'color': const Color(0xFF0F766E),
      };
    } else if (c.isFlaggedForReview || c.category.contains('Hygiene')) {
      return {
        'authorityName': 'System Administration Audit Division',
        'badgeLabel': 'Admin Audit Compliance Notice',
        'icon': Icons.admin_panel_settings_rounded,
        'color': const Color(0xFF0C2340),
      };
    } else {
      return {
        'authorityName': 'Public Hygiene Inspection Bureau',
        'badgeLabel': 'Verified Public Complaint Directive',
        'icon': Icons.report_problem_rounded,
        'color': const Color(0xFFD97706),
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final c = args is ComplaintModel ? args : MockSeedData.complaints.first;
    final authInfo = _getAuthorityInfo(c);
    final Color authColor = authInfo['color'];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const CustomAppBar(title: 'Notice & Directive Details'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. ISSUING AUTHORITY BANNER CARD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: authColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: authColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: authColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(authInfo['icon'], color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authInfo['badgeLabel'],
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: authColor),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          authInfo['authorityName'],
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.navyColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. PREMISE NAME & DEADLINE
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    c.restaurantName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.navyColor),
                  ),
                ),
                const DeadlineCountdownBadge(daysLeft: 4),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                StatusBadge.fromStatus(c.status.name),
                const SizedBox(width: 8),
                Text('Directive ID: ${c.id}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 16),

            // 3. DETAILS CARD
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.category_rounded, size: 16, color: AppTheme.primaryColor),
                        const SizedBox(width: 6),
                        Text('Category: ${c.category}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.navyColor)),
                      ],
                    ),
                    const Divider(height: 20),
                    const Text('Violation Description:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.navyColor)),
                    const SizedBox(height: 4),
                    Text(c.description, style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.4)),
                    const SizedBox(height: 12),
                    const Text('Specific Issues Flagged:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.navyColor)),
                    const SizedBox(height: 6),
                    ...c.issues.map((iss) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, size: 14, color: Colors.red),
                              const SizedBox(width: 6),
                              Expanded(child: Text(iss, style: const TextStyle(fontSize: 12, color: Colors.black87))),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 4. PROOF MEDIA
            const Text('Proof Media & Inspection Logs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.navyColor)),
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
                      borderRadius: BorderRadius.circular(12),
                      child: c.photoUrls.isNotEmpty
                          ? Image.network(c.photoUrls[idx], width: 140, height: 120, fit: BoxFit.cover)
                          : const WireframeBox(width: 140, height: 120, icon: Icons.image, label: 'Photo Proof'),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // 5. GPS LOCATION
            const Text('Inspection Pin Map Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.navyColor)),
            const SizedBox(height: 8),
            WireframeBox(
              height: 110,
              icon: Icons.map_rounded,
              label: 'GPS Coordinates: ${c.latitude}, ${c.longitude}',
              sublabel: 'Verified Inspection Coordinates',
            ),
            const SizedBox(height: 24),

            // 6. ACTION BUTTON
            CustomButton(
              label: 'Upload Rectification & Mark Resolved',
              icon: Icons.check_circle_rounded,
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
