import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/models/complaint_model.dart';
import '../../core/models/inspection_model.dart';
import '../../core/services/audit_log_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/restaurant_store_service.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/custom_button.dart';
import '../../notifications/models/notification_model.dart';

class ConductInspectionScreen extends StatefulWidget {
  const ConductInspectionScreen({super.key});

  @override
  State<ConductInspectionScreen> createState() => _ConductInspectionScreenState();
}

class _ConductInspectionScreenState extends State<ConductInspectionScreen> {
  InspectionOutcome _outcome = InspectionOutcome.nonCompliant;
  double _hygieneScore = 45.0;
  bool _isSubmitting = false;

  final TextEditingController _findingsCtrl = TextEditingController(
    text: 'Found unhygienic food storage and active pest presence near cooking area.',
  );

  final List<String> _commonViolations = [
    'Food Storage Temp',
    'Active Pest Presence',
    'Cross-contamination',
    'Staff Hygiene & PPE',
    'Grease Trap Overflow',
    'Expired Ingredients',
  ];

  final Set<String> _selectedViolations = {
    'Food Storage Temp',
    'Active Pest Presence',
  };

  final List<String> _evidencePhotos = [
    'https://images.unsplash.com/photo-1584483766114-2cea6facdf57?w=600',
    'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=600',
  ];

  String _enforcementAction = 'Issue Compound Fine (RM 1,000)';

  final List<String> _enforcementOptions = [
    'Pass - No Enforcement Needed',
    'Issue Written Warning (Form 32)',
    'Issue Compound Fine (RM 1,000)',
    'Temporary 14-Day Premise Closure (Section 11)',
  ];

  @override
  void dispose() {
    _findingsCtrl.dispose();
    super.dispose();
  }

  String _formatCaseId(String rawId) {
    if (rawId.startsWith('CMP-') || rawId.startsWith('cmp_')) {
      return rawId.toUpperCase();
    }
    final short = rawId.length > 8 ? rawId.substring(0, 8) : rawId;
    return 'CMP-${short.toUpperCase()}';
  }

  Widget _buildEvidenceThumbnail(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(path, height: 75, width: 75, fit: BoxFit.cover, errorBuilder: (ctx, err, stack) => const Icon(Icons.image, size: 28, color: Colors.grey));
    } else {
      final f = File(path.startsWith('file://') ? Uri.parse(path).toFilePath() : path);
      if (f.existsSync()) {
        return Image.file(f, height: 75, width: 75, fit: BoxFit.cover, errorBuilder: (ctx, err, stack) => const Icon(Icons.image, size: 28, color: Colors.grey));
      }
      return Image.network('https://images.unsplash.com/photo-1584483766114-2cea6facdf57?w=600', height: 75, width: 75, fit: BoxFit.cover);
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formattedId = c != null ? _formatCaseId(c.id) : 'CMP-ACTIVE';
    final restName = c != null
        ? RestaurantStoreService.resolveRestaurantName(c.restaurantName, fallback: c.restaurantName)
        : 'Premise Inspection';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: const CustomAppBar(title: 'Record Visit'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. TOP CASE CONTEXT BANNER
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                      : [const Color(0xFF0C2340), const Color(0xFF0F766E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          formattedId,
                          style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Row(
                        children: [
                          Icon(Icons.verified_rounded, color: Color(0xFF38BDF8), size: 14),
                          SizedBox(width: 4),
                          Text('Official Inspection', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    restName,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Reported: ${c?.category ?? "Food Hygiene Violation"}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 2. VISUAL OUTCOME CARDS SELECTOR
            Text(
              'Inspection Final Outcome *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildOutcomeCard(
                    outcome: InspectionOutcome.compliant,
                    title: 'Compliant',
                    subtitle: 'Passes Grade A/B',
                    icon: Icons.check_circle_rounded,
                    color: const Color(0xFF059669),
                    isSelected: _outcome == InspectionOutcome.compliant,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildOutcomeCard(
                    outcome: InspectionOutcome.nonCompliant,
                    title: 'Non-Compliant',
                    subtitle: 'Violations Found',
                    icon: Icons.warning_rounded,
                    color: const Color(0xFFDC2626),
                    isSelected: _outcome == InspectionOutcome.nonCompliant,
                    isDark: isDark,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 3. HYGIENE SCORE RATING SLIDER
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Assigned Hygiene Score',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: _hygieneScore >= 80
                              ? Colors.green.shade50
                              : (_hygieneScore >= 60 ? Colors.orange.shade50 : Colors.red.shade50),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _hygieneScore >= 80
                                ? Colors.green.shade300
                                : (_hygieneScore >= 60 ? Colors.orange.shade300 : Colors.red.shade300),
                          ),
                        ),
                        child: Text(
                          '${_hygieneScore.toInt()} / 100 • ${_hygieneScore >= 80 ? "Grade A" : (_hygieneScore >= 60 ? "Grade B" : "Grade C")}',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: _hygieneScore >= 80
                                ? Colors.green.shade800
                                : (_hygieneScore >= 60 ? Colors.orange.shade800 : Colors.red.shade800),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_hygieneScore < 60) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 12, color: Colors.red.shade700),
                          const SizedBox(width: 4),
                          Text(
                            'Below Passing Threshold (Action Required)',
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.red.shade800),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: _hygieneScore >= 80 ? const Color(0xFF059669) : (_hygieneScore >= 60 ? const Color(0xFFD97706) : const Color(0xFFDC2626)),
                      thumbColor: const Color(0xFF0F766E),
                      overlayColor: const Color(0xFF0F766E).withValues(alpha: 0.2),
                    ),
                    child: Slider(
                      value: _hygieneScore,
                      min: 0,
                      max: 100,
                      divisions: 20,
                      label: '${_hygieneScore.toInt()}',
                      onChanged: (val) => setState(() => _hygieneScore = val),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 4. VIOLATIONS DETECTED QUICK CHIPS
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Observed Violations Checklist',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _commonViolations.map((item) {
                      final isSelected = _selectedViolations.contains(item);
                      return FilterChip(
                        label: Text(item),
                        selected: isSelected,
                        selectedColor: const Color(0xFFDC2626).withValues(alpha: 0.15),
                        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        checkmarkColor: const Color(0xFFDC2626),
                        labelStyle: TextStyle(
                          fontSize: 11.5,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? const Color(0xFFDC2626) : (isDark ? Colors.white70 : const Color(0xFF475569)),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: isSelected ? const Color(0xFFDC2626) : (isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
                          ),
                        ),
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              _selectedViolations.add(item);
                            } else {
                              _selectedViolations.remove(item);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 5. DETAILED FINDINGS TEXT FIELD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Inspector Official Findings *',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _findingsCtrl,
                    maxLines: 3,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Record detailed findings, cross-contamination risks, and corrective orders...',
                      hintStyle: TextStyle(fontSize: 12.5, color: isDark ? Colors.white38 : Colors.grey),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 6. PHOTO EVIDENCE ATTACHMENTS
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Attached Photo Evidence (${_evidencePhotos.length})',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF0F766E),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () {
                          setState(() {
                            _evidencePhotos.add('https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=600');
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Photo proof attached!'), duration: Duration(seconds: 1)),
                          );
                        },
                        icon: const Icon(Icons.add_a_photo_outlined, size: 16),
                        label: const Text('Add Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 75,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _evidencePhotos.length,
                      itemBuilder: (ctx, idx) {
                        return Stack(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: _buildEvidenceThumbnail(_evidencePhotos[idx]),
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 12,
                              child: GestureDetector(
                                onTap: () => setState(() => _evidencePhotos.removeAt(idx)),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, color: Colors.white, size: 12),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 7. RECOMMENDED ENFORCEMENT ACTION
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enforcement & Corrective Action',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: _enforcementAction,
                    isExpanded: true,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13),
                    dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      ),
                    ),
                    items: _enforcementOptions.map((opt) {
                      return DropdownMenuItem<String>(
                        value: opt,
                        child: Text(opt, style: const TextStyle(fontSize: 12.5)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _enforcementAction = val);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 8. SUBMIT ACTION BUTTON
            CustomButton(
              label: 'Submit Inspection Report',
              icon: Icons.send_rounded,
              backgroundColor: const Color(0xFF0F766E),
              isLoading: _isSubmitting,
              onPressed: () async {
                final findings = _findingsCtrl.text.trim();
                if (findings.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter official inspection findings.')),
                  );
                  return;
                }

                setState(() => _isSubmitting = true);

                // Update complaint status in memory & Supabase
                if (c != null) {
                  final nonNullC = c;
                  final idx = RestaurantStoreService.complaintsNotifier.value.indexWhere((x) => x.id == nonNullC.id);
                  if (idx != -1) {
                    RestaurantStoreService.complaintsNotifier.value[idx] = ComplaintModel(
                      id: nonNullC.id,
                      restaurantId: nonNullC.restaurantId,
                      restaurantName: nonNullC.restaurantName,
                      userId: nonNullC.userId,
                      userName: nonNullC.userName,
                      issues: nonNullC.issues,
                      description: nonNullC.description,
                      category: nonNullC.category,
                      submittedAt: nonNullC.submittedAt,
                      status: _outcome == InspectionOutcome.compliant ? ComplaintStatus.resolved : ComplaintStatus.investigating,
                      photoUrls: _evidencePhotos,
                      latitude: nonNullC.latitude,
                      longitude: nonNullC.longitude,
                      severity: nonNullC.severity,
                      isFlaggedForReview: false,
                    );
                  }
                }

                // Log audit action
                AuditLogService.logAction(
                  actionType: 'INSPECTION_CONDUCTED',
                  category: 'Government',
                  title: 'Health Inspection Report Submitted',
                  description: 'Outcome: ${_outcome.name.toUpperCase()} (Score: ${_hygieneScore.toInt()}/100) for $restName. Action: $_enforcementAction',
                );

                // Notify Owner
                NotificationService.sendNotification(
                  userId: 'own_001',
                  title: '📋 Health Inspection Outcome: ${_outcome == InspectionOutcome.compliant ? "Pass" : "Non-Compliant Notice"}',
                  message: 'Official visit completed for $restName. Outcome: ${_outcome.name.toUpperCase()}. Action: $_enforcementAction',
                  type: NotificationType.hygieneAlert,
                  actionUrl: 'inspection_result',
                );

                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);

                await Future.delayed(const Duration(milliseconds: 600));

                if (!mounted) return;
                setState(() => _isSubmitting = false);
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Colors.white),
                        const SizedBox(width: 10),
                        Expanded(child: Text('Inspection report submitted for $restName!')),
                      ],
                    ),
                    backgroundColor: const Color(0xFF0F766E),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
                navigator.pop();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOutcomeCard({
    required InspectionOutcome outcome,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _outcome = outcome;
          if (outcome == InspectionOutcome.compliant) {
            _hygieneScore = 88.0;
            _enforcementAction = 'Pass - No Enforcement Needed';
            _selectedViolations.clear();
          } else {
            _hygieneScore = 45.0;
            _enforcementAction = 'Issue Compound Fine (RM 1,000)';
            _selectedViolations.addAll(['Food Storage Temp', 'Active Pest Presence']);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? color.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : (isDark ? Colors.white : const Color(0xFF0F172A)),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
