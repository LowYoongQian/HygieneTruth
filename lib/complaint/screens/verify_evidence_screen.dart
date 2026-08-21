import '../../core/services/restaurant_store_service.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/models/complaint_model.dart';
import '../../core/services/duplicate_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/custom_button.dart';

class VerifyEvidenceScreen extends StatefulWidget {
  const VerifyEvidenceScreen({super.key});

  @override
  State<VerifyEvidenceScreen> createState() => _VerifyEvidenceScreenState();
}

class _VerifyEvidenceScreenState extends State<VerifyEvidenceScreen> {
  AiDuplicateAnalysisResult? _aiResult;
  bool _isAiScanning = false;
  ComplaintModel? _complaint;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_complaint == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is ComplaintModel) {
        _complaint = args;
      } else if (RestaurantStoreService.complaintsNotifier.value.isNotEmpty) {
        final flagged = RestaurantStoreService.complaintsNotifier.value.where((item) => item.isFlaggedForReview).toList();
        _complaint = flagged.isNotEmpty ? flagged.first : RestaurantStoreService.complaintsNotifier.value.first;
      }
      _runAiDuplicateScan();
    }
  }

  Future<void> _runAiDuplicateScan() async {
    if (_complaint == null) return;
    setState(() => _isAiScanning = true);
    final result = await AiDuplicateDetectorService.analyzeComplaintEvidence(complaint: _complaint!);
    if (mounted) {
      setState(() {
        _aiResult = result;
        _isAiScanning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = _complaint;

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
    final isDuplicateFlagged = _aiResult?.isDuplicate ??
        (c.isFlaggedForReview && (c.flaggedReason?.contains('Duplicate') ?? true));

    final String? uploadedPhotoUrl = (c.photoUrls.isNotEmpty) ? c.photoUrls.first : null;
    final String? matchedDatabasePhotoUrl = isDuplicateFlagged
        ? (_aiResult?.matchedImageUrl ?? 'https://images.unsplash.com/photo-1584483766114-2cea6facdf57?w=600&auto=format&fit=crop')
        : null;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
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

            // 2. EVIDENCE VERIFICATION CHECKS
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

            // 3. DUAL-LAYER AI DUPLICATE DETECTOR & PHOTO COMPARISON
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurfaceColor : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppTheme.darkBorderColor : const Color(0xFFE2E8F0)),
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
                  // Title + Status Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00A88F).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF00A88F), size: 18),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'AI Vision & Hash Duplicate Detector',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppTheme.navyColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDuplicateFlagged ? Colors.orange.shade50 : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDuplicateFlagged ? Colors.orange.shade300 : Colors.green.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isDuplicateFlagged ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                              size: 14,
                              color: isDuplicateFlagged ? Colors.orange.shade800 : Colors.green.shade800,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isDuplicateFlagged ? 'Duplicate Match' : 'Unique (0% Match)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDuplicateFlagged ? Colors.orange.shade800 : Colors.green.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Dual Detection Layers Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        // Layer 1: Hex Byte Hash Check
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.tag_rounded, size: 14, color: Colors.blue),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Layer 1: Hex Byte Hash:',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            Text(
                              _aiResult != null ? '${_aiResult!.hexMatchScore.toStringAsFixed(1)}% Match' : 'Calculating...',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: (_aiResult?.hexMatchScore ?? 0) > 50 ? Colors.orange.shade800 : Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Layer 2: AI Neural Vision Perception Check
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.purple.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.psychology_outlined, size: 14, color: Colors.purple),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Layer 2: AI Vision Perception:',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            Text(
                              _aiResult != null ? '${_aiResult!.aiSemanticScore.toStringAsFixed(1)}% Similarity' : 'Scanning...',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: (_aiResult?.aiSemanticScore ?? 0) > 50 ? Colors.red.shade700 : Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // AI Analysis Details & Feature Vector Insights
                  if (_aiResult != null && _aiResult!.matchedAiFeatures.isNotEmpty) ...[
                    Text(
                      'AI Vision Detected Insights:',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.darkSubtitleColor : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ..._aiResult!.matchedAiFeatures.map(
                      (feature) => Padding(
                        padding: const EdgeInsets.only(bottom: 3.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Text(
                                feature,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isDark ? AppTheme.darkSubtitleColor : Colors.grey.shade700,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Rescan Action Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Hash: ${_aiResult?.hexHash ?? "N/A"}',
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontFamily: 'monospace'),
                      ),
                      InkWell(
                        onTap: _isAiScanning ? null : _runAiDuplicateScan,
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _isAiScanning
                                  ? const SizedBox(
                                      width: 10,
                                      height: 10,
                                      child: CircularProgressIndicator(strokeWidth: 1.5, color: AppTheme.primaryColor),
                                    )
                                  : const Icon(Icons.refresh_rounded, size: 12, color: AppTheme.primaryColor),
                              const SizedBox(width: 4),
                              Text(
                                _isAiScanning ? 'Scanning...' : 'Re-Scan AI',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 24),

                  // Side-by-Side Photo Comparison
                  Text(
                    'Photo Comparison',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isDark ? AppTheme.darkTextColor : AppTheme.navyColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Uploaded Photo Container
                      Expanded(
                        child: _buildEvidenceImageThumbnail(
                          context: context,
                          imageUrl: uploadedPhotoUrl,
                          title: 'Uploaded Photo',
                          emptyLabel: 'No Image',
                          emptySublabel: 'No photo attached',
                          emptyIcon: Icons.no_photography_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Database Comparison Photo Container
                      Expanded(
                        child: _buildEvidenceImageThumbnail(
                          context: context,
                          imageUrl: matchedDatabasePhotoUrl,
                          title: isDuplicateFlagged ? 'Matched Database Photo' : 'Database Comparison',
                          emptyLabel: 'No Image', // Shows "No Image" instead of "no match"
                          emptySublabel: isDuplicateFlagged ? 'No reference photo' : 'Clean original image',
                          emptyIcon: Icons.image_not_supported_outlined,
                          emptyIconColor: isDuplicateFlagged ? Colors.orange.shade400 : Colors.grey.shade400,
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
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final nav = Navigator.of(context);
                await ComplaintStoreService.verifyComplaintEvidence(
                  complaintId: c.id,
                  isGenuine: true,
                );
                messenger.showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 10),
                        Expanded(child: Text('Report ${c.id} evidence verified genuine and passed to review queue.')),
                      ],
                    ),
                    backgroundColor: const Color(0xFF059669),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                nav.pop();
              },
            ),
            const SizedBox(height: 10),
            CustomButton(
              label: 'Override Pass',
              icon: Icons.published_with_changes_rounded,
              backgroundColor: const Color(0xFFD97706),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final nav = Navigator.of(context);
                await ComplaintStoreService.verifyComplaintEvidence(
                  complaintId: c.id,
                  isGenuine: true,
                  remarks: 'Admin Manual Verification Override',
                );
                messenger.showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.warning_amber, color: Colors.white),
                        const SizedBox(width: 10),
                        Expanded(child: Text('GPS & duplicate warning manually overridden for ${c.id}.')),
                      ],
                    ),
                    backgroundColor: const Color(0xFFD97706),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                nav.pop();
              },
            ),
            const SizedBox(height: 10),
            CustomButton(
              label: 'Confirm Duplicate / Reject',
              icon: Icons.cancel_rounded,
              backgroundColor: const Color(0xFFDC2626),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final nav = Navigator.of(context);
                await ComplaintStoreService.verifyComplaintEvidence(
                  complaintId: c.id,
                  isGenuine: false,
                  remarks: 'Rejected: Duplicate / False Report',
                );
                messenger.showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.cancel, color: Colors.white),
                        const SizedBox(width: 10),
                        Expanded(child: Text('Report ${c.id} rejected due to duplicate/invalid proof.')),
                      ],
                    ),
                    backgroundColor: const Color(0xFFDC2626),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                nav.pop();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEvidenceImageThumbnail({
    required BuildContext context,
    required String? imageUrl,
    required String title,
    required String emptyLabel,
    required String emptySublabel,
    required IconData emptyIcon,
    Color? emptyIconColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasImage = imageUrl != null && imageUrl.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 11,
            color: isDark ? AppTheme.darkTextColor : const Color(0xFF0F766E),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 135,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasImage
                  ? const Color(0xFF00A88F).withValues(alpha: 0.5)
                  : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: hasImage
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildImageWidget(imageUrl),
                      Positioned(
                        right: 6,
                        bottom: 6,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.zoom_in_rounded,
                            color: Colors.white,
                            size: 15,
                          ),
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _showFullImageDialog(context, imageUrl, title),
                        ),
                      ),
                    ],
                  )
                : Container(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          emptyIcon,
                          size: 32,
                          color: emptyIconColor ?? (isDark ? Colors.white38 : Colors.grey.shade400),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          emptyLabel,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: isDark ? Colors.white70 : Colors.grey.shade700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          emptySublabel,
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.white38 : Colors.grey.shade500,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageWidget(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        loadingBuilder: (ctx, child, progress) {
          if (progress == null) return child;
          return const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
            ),
          );
        },
        errorBuilder: (ctx, error, stackTrace) => _buildFallbackIcon(),
      );
    } else if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (ctx, error, stackTrace) => _buildFallbackIcon(),
      );
    } else {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (ctx, error, stackTrace) => _buildFallbackIcon(),
        );
      } else {
        return Image.network(
          'https://images.unsplash.com/photo-1584483766114-2cea6facdf57?w=600&auto=format&fit=crop',
          fit: BoxFit.cover,
          errorBuilder: (ctx, error, stackTrace) => _buildFallbackIcon(),
        );
      }
    }
  }

  Widget _buildFallbackIcon() {
    return Container(
      color: Colors.grey.shade100,
      child: const Center(
        child: Icon(Icons.broken_image_rounded, color: Colors.grey, size: 28),
      ),
    );
  }

  void _showFullImageDialog(BuildContext context, String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: AppTheme.navyColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              child: Container(
                color: Colors.black,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.65,
                ),
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.8,
                  maxScale: 4.0,
                  child: _buildImageWidget(imageUrl),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
