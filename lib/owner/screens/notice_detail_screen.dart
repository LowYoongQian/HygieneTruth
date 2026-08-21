import '../../core/services/restaurant_store_service.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/models/complaint_model.dart';
import '../../core/models/restaurant_model.dart';
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
    ComplaintModel? c;
    if (args is ComplaintModel) {
      c = args;
    } else if (RestaurantStoreService.complaintsNotifier.value.isNotEmpty) {
      c = RestaurantStoreService.complaintsNotifier.value.first;
    }

    if (c == null) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'Notice & Directive Details'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.assignment_late_outlined, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('No notice or directive details available.', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Go Back')),
            ],
          ),
        ),
      );
    }

    final complaint = c;
    final authInfo = _getAuthorityInfo(complaint);
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
                Expanded(
                  child: Text(
                    'Directive ID: ${c.id.startsWith('CMP-') ? c.id : 'CMP-${c.id.length > 8 ? c.id.substring(0, 8).toUpperCase() : c.id.toUpperCase()}'}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
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
                itemCount: complaint.photoUrls.isNotEmpty ? complaint.photoUrls.length : 2,
                itemBuilder: (context, idx) {
                  if (complaint.photoUrls.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: WireframeBox(width: 140, height: 120, icon: Icons.image, label: 'Photo Proof'),
                    );
                  }
                  final path = complaint.photoUrls[idx];
                  Widget imgWidget;
                  if (path.startsWith('http://') || path.startsWith('https://')) {
                    imgWidget = Image.network(path, width: 140, height: 120, fit: BoxFit.cover, errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image, size: 36, color: Colors.grey));
                  } else {
                    String cleanPath = path;
                    if (cleanPath.startsWith('file://')) {
                      try {
                        cleanPath = Uri.parse(cleanPath).toFilePath();
                      } catch (_) {
                        cleanPath = cleanPath.replaceFirst('file://', '');
                      }
                    }
                    final f = File(cleanPath);
                    if (f.existsSync()) {
                      imgWidget = Image.file(f, width: 140, height: 120, fit: BoxFit.cover, errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image, size: 36, color: Colors.grey));
                    } else {
                      imgWidget = Image.network('https://images.unsplash.com/photo-1584483766114-2cea6facdf57?w=600', width: 140, height: 120, fit: BoxFit.cover);
                    }
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: imgWidget,
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
            const SizedBox(height: 20),

            // 6. MOH COMPOUND PENALTY CARD (If Fine Exists)
            Builder(
              builder: (ctx) {
                final rest = RestaurantStoreService.restaurantsNotifier.value
                    .where((r) => r.id == complaint.restaurantId || r.name == complaint.restaurantName)
                    .firstOrNull;
                final insp = RestaurantStoreService.getLatestInspectionForRestaurant(complaint.restaurantId);

                final bool hasFine = (rest != null && rest.fineAmount > 0) || (insp != null && insp.fineAmount > 0);
                final bool isFinePaid = (rest?.isFinePaid ?? false) || (insp?.isFinePaid ?? false);
                final double fineAmt = rest != null && rest.fineAmount > 0 ? rest.fineAmount : (insp?.fineAmount ?? 1000.0);

                if (!hasFine) return const SizedBox.shrink();

                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isFinePaid ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isFinePaid ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isFinePaid ? Icons.check_circle_rounded : Icons.payments_rounded,
                                color: isFinePaid ? const Color(0xFF059669) : const Color(0xFFDC2626),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isFinePaid ? 'Compound Penalty Settled' : 'Statutory Compound Fine',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isFinePaid ? const Color(0xFF059669) : const Color(0xFFDC2626),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'RM ${fineAmt.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isFinePaid ? const Color(0xFF059669) : const Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isFinePaid
                            ? 'Official legal clearance confirmed. Premises remains active and compliant in customer feeds.'
                            : 'Official compound penalty issued under Food Act 1983 / Food Hygiene Regulations 2009. Settle to avoid premises suspension.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isFinePaid ? const Color(0xFF047857) : const Color(0xFFB91C1C),
                          height: 1.35,
                        ),
                      ),
                      if (!isFinePaid) ...[
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDC2626),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              _showPaymentDialog(
                                context,
                                rest ??
                                    RestaurantModel(
                                      id: complaint.restaurantId,
                                      name: complaint.restaurantName,
                                      category: 'Restaurant',
                                      address: 'Premises',
                                      latitude: complaint.latitude,
                                      longitude: complaint.longitude,
                                      hygieneRiskScore: 70.0,
                                      riskCategory: RiskCategory.high,
                                      imageUrl: '',
                                      lastUpdated: '',
                                      status: RestaurantStatus.approved,
                                      violationCount: 1,
                                      fineAmount: fineAmt,
                                    ),
                                fineAmt,
                              );
                            },
                            icon: const Icon(Icons.payment_rounded, size: 18),
                            label: Text(
                              'Settle Penalty via FPX (RM ${fineAmt.toStringAsFixed(2)})',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),

            // 7. RECTIFICATION BUTTON
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

  void _showPaymentDialog(BuildContext context, RestaurantModel rest, double fineAmt) {
    String selectedBank = 'Maybank2u';
    bool isProcessing = false;
    final String refNo = 'MOH-FPX-2026-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';

    showDialog(
      context: context,
      builder: (dlgCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: const [
                  Icon(Icons.account_balance_rounded, color: Color(0xFF0F766E)),
                  SizedBox(width: 8),
                  Text('MOH FPX Gateway', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.navyColor)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Premises: ${rest.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('Penalty Amount: RM ${fineAmt.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F766E))),
                  const SizedBox(height: 14),
                  const Text('Select Malaysian FPX Bank:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: selectedBank,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: ['Maybank2u', 'CIMB Clicks', 'Public Bank (PBe)', 'RHB Now', 'Hong Leong Connect', 'AmBank', 'Bank Islam']
                        .map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 12))))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedBank = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dlgCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: isProcessing
                      ? null
                      : () async {
                          setDialogState(() => isProcessing = true);
                          await Future.delayed(const Duration(milliseconds: 1200));

                          final settled = await RestaurantStoreService.settleCompoundFine(
                            restaurantId: rest.id,
                            paymentReference: refNo,
                            amountPaid: fineAmt,
                            paymentMethod: 'FPX ($selectedBank)',
                          );

                          if (dlgCtx.mounted) Navigator.pop(dlgCtx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(settled ? 'Penalty settled successfully! Ref: $refNo' : 'Payment failed. Please retry.'),
                                backgroundColor: settled ? const Color(0xFF059669) : Colors.red,
                              ),
                            );
                          }
                        },
                  child: isProcessing
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Pay RM ${fineAmt.toStringAsFixed(2)}'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
