import 'package:flutter/material.dart';
import '../../core/models/inspection_model.dart';
import '../../core/services/audit_log_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/restaurant_store_service.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/custom_button.dart';
import '../../notifications/models/notification_model.dart';

class IssueEnforcementScreen extends StatefulWidget {
  const IssueEnforcementScreen({super.key});

  @override
  State<IssueEnforcementScreen> createState() => _IssueEnforcementScreenState();
}

class _IssueEnforcementScreenState extends State<IssueEnforcementScreen> {
  EnforcementType _selectedAction = EnforcementType.closure;
  final TextEditingController _fineCtrl = TextEditingController(text: '2500');
  final TextEditingController _justificationCtrl = TextEditingController(
    text: 'Critical pest contamination detected near cooking area. Temporary closure issued under Section 11 Food Act 1983 for comprehensive disinfection.',
  );
  String _selectedLawClause = 'Food Act 1983 - Section 11 (Unsanitary Conditions Closure)';
  bool _isSubmitting = false;

  final EnforcementType _recommendedAction = EnforcementType.closure;

  final List<String> _lawClauses = [
    'Food Act 1983 - Section 11 (Unsanitary Conditions Closure)',
    'Food Hygiene Reg 2009 - Reg 34 (Pest Infestation)',
    'Food Act 1983 - Section 13 (Contaminated Food Selling)',
    'Food Hygiene Reg 2009 - Reg 11 (Medical Health & PPE Violation)',
  ];

  final List<int> _finePresets = [250, 500, 1000, 2500, 5000];

  @override
  void dispose() {
    _fineCtrl.dispose();
    _justificationCtrl.dispose();
    super.dispose();
  }

  String _formatCaseId(String rawId) {
    if (rawId.startsWith('CMP-') || rawId.startsWith('cmp_')) {
      return rawId.toUpperCase();
    }
    final short = rawId.length > 8 ? rawId.substring(0, 8) : rawId;
    return 'CMP-${short.toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    InspectionModel? insp;
    if (args is InspectionModel) {
      insp = args;
    } else if (RestaurantStoreService.inspectionsNotifier.value.isNotEmpty) {
      insp = RestaurantStoreService.inspectionsNotifier.value.first;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formattedId = insp != null ? _formatCaseId(insp.complaintId) : 'CMP-2026-002';
    final restName = insp != null
        ? RestaurantStoreService.resolveRestaurantName(insp.restaurantName, fallback: insp.restaurantName)
        : 'Selera Kampung Bistro';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      appBar: const CustomAppBar(title: 'Issue Action'),
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
                      ? [const Color(0xFF121212), const Color(0xFF1E1E1E)]
                      : [const Color(0xFF0C2340), const Color(0xFF991B1B)],
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.red.shade900.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.red.shade400),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.gavel_rounded, color: Colors.white, size: 12),
                            SizedBox(width: 4),
                            Text('Enforcement Decree', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    restName,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Violation: ${insp?.findings.isNotEmpty == true ? insp!.findings : "Pest Infestation & Critical Contamination Risk"}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 2. OFFICIAL RECOMMENDATION ALERT CARD
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFCD34D)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_rounded, color: Color(0xFFD97706), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'MOH Health Inspector Recommendation',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_recommendedAction.name.toUpperCase()} (RM 2,500.00 Compound)',
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF78350F)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 3. ACTION TYPE SELECTION CARDS
            Text(
              'Enforcement Action Type *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0C2340),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildActionTypeTile(
                    type: EnforcementType.closure,
                    title: 'Closure Notice',
                    subtitle: '14-Day Shutdown',
                    icon: Icons.block_rounded,
                    color: const Color(0xFFDC2626),
                    isSelected: _selectedAction == EnforcementType.closure,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildActionTypeTile(
                    type: EnforcementType.fine,
                    title: 'Compound Fine',
                    subtitle: 'Monetary Penalty',
                    icon: Icons.payments_rounded,
                    color: const Color(0xFFD97706),
                    isSelected: _selectedAction == EnforcementType.fine,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildActionTypeTile(
                    type: EnforcementType.warning,
                    title: 'Form 32 Warning',
                    subtitle: '14-Day Remediation',
                    icon: Icons.warning_amber_rounded,
                    color: const Color(0xFF0284C7),
                    isSelected: _selectedAction == EnforcementType.warning,
                    isDark: isDark,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 4. FINE AMOUNT SECTION (FOR FINES AND CLOSURES)
            if (_selectedAction == EnforcementType.fine || _selectedAction == EnforcementType.closure) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Compound Penalty Amount (MYR)',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0C2340),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _fineCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        prefixText: 'RM ',
                        prefixStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0F766E),
                        ),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: _finePresets.map((amount) {
                        return ActionChip(
                          label: Text('RM $amount'),
                          labelStyle: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: _fineCtrl.text == amount.toString() ? Colors.white : const Color(0xFF0F766E),
                          ),
                          backgroundColor: _fineCtrl.text == amount.toString()
                              ? const Color(0xFF0F766E)
                              : (isDark ? const Color(0xFF121212) : const Color(0xFFF1F5F9)),
                          onPressed: () {
                            setState(() => _fineCtrl.text = amount.toString());
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 5. LEGAL STATUTORY CLAUSE
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Statutory Legal Citation *',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0C2340),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedLawClause,
                    isExpanded: true,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 12.5),
                    dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      ),
                    ),
                    items: _lawClauses.map((clause) {
                      return DropdownMenuItem(value: clause, child: Text(clause));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedLawClause = val);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 6. OFFICER JUSTIFICATION & DIRECTIVES
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enforcement Directives & Orders *',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0C2340),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _justificationCtrl,
                    maxLines: 3,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Specify mandatory rectification orders, fine due date, or closure conditions...',
                      hintStyle: TextStyle(fontSize: 12.5, color: isDark ? Colors.white38 : Colors.grey),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 7. ISSUE ACTION BUTTON
            CustomButton(
              label: 'Issue Official Enforcement Decree',
              icon: Icons.gavel_rounded,
              backgroundColor: const Color(0xFFDC2626),
              isLoading: _isSubmitting,
              onPressed: () async {
                final double fineAmt = double.tryParse(_fineCtrl.text.trim()) ?? 0.0;
                final justText = _justificationCtrl.text.trim();

                if (justText.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter enforcement directives.')),
                  );
                  return;
                }

                setState(() => _isSubmitting = true);

                // Update in memory inspections
                final nonNullInsp = insp;
                if (nonNullInsp != null) {
                  final idx = RestaurantStoreService.inspectionsNotifier.value.indexWhere((x) => x.id == nonNullInsp.id);
                  if (idx != -1) {
                    RestaurantStoreService.inspectionsNotifier.value[idx] = InspectionModel(
                      id: nonNullInsp.id,
                      complaintId: nonNullInsp.complaintId,
                      restaurantId: nonNullInsp.restaurantId,
                      restaurantName: nonNullInsp.restaurantName,
                      scheduledDate: nonNullInsp.scheduledDate,
                      conductedDate: nonNullInsp.conductedDate ?? DateTime.now().toIso8601String().split('T').first,
                      officerName: nonNullInsp.officerName,
                      outcome: nonNullInsp.outcome,
                      findings: nonNullInsp.findings,
                      recommendedAction: nonNullInsp.recommendedAction,
                      issuedAction: _selectedAction,
                      justification: justText,
                      fineAmount: fineAmt,
                      enforcementStatus: EnforcementStatus.inProgress,
                    );
                  }
                }

                // Log audit action
                AuditLogService.logAction(
                  actionType: 'ENFORCEMENT_ISSUED',
                  category: 'Government',
                  title: 'Enforcement Action Issued',
                  description: 'Issued ${_selectedAction.name.toUpperCase()} (Fine: RM ${fineAmt.toStringAsFixed(2)}) for $restName. $_selectedLawClause',
                );

                // Notify Owner
                NotificationService.sendNotification(
                  userId: 'own_001',
                  title: '🚨 Official Enforcement Decree Issued: ${_selectedAction.name.toUpperCase()}',
                  message: 'Ministry of Health issued ${_selectedAction.name.toUpperCase()} (Fine: RM ${fineAmt.toStringAsFixed(2)}) for $restName. Legal: $_selectedLawClause',
                  type: NotificationType.hygieneAlert,
                  actionUrl: 'enforcement_notice',
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
                        Expanded(child: Text('Enforcement decree issued for $restName!')),
                      ],
                    ),
                    backgroundColor: const Color(0xFFDC2626),
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

  Widget _buildActionTypeTile({
    required EnforcementType type,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _selectedAction = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey, size: 24),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : (isDark ? Colors.white : const Color(0xFF0C2340)),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 9.5, color: isDark ? Colors.white60 : Colors.grey.shade600),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
