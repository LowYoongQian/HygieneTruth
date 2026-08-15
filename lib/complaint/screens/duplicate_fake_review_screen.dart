import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/models/complaint_model.dart';
import '../../core/models/mock_seed_data.dart';
import '../../core/services/duplicate_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/custom_button.dart';

class DuplicateFakeReviewScreen extends StatefulWidget {
  const DuplicateFakeReviewScreen({super.key});

  @override
  State<DuplicateFakeReviewScreen> createState() => _DuplicateFakeReviewScreenState();
}

class _DuplicateFakeReviewScreenState extends State<DuplicateFakeReviewScreen> {
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
      } else if (MockSeedData.complaints.isNotEmpty) {
        final flaggedList = MockSeedData.complaints.where((item) => item.isFlaggedForReview).toList();
        _complaint = flaggedList.isNotEmpty ? flaggedList.first : MockSeedData.complaints.first;
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
        appBar: const CustomAppBar(title: 'Check Duplicates'),
        body: Center(
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
        ),
      );
    }

    final String? uploadedPhotoUrl = (c.photoUrls.isNotEmpty) ? c.photoUrls.first : null;
    final isDuplicateFlagged = _aiResult?.isDuplicate ?? c.isFlaggedForReview;
    final String? matchedDatabasePhotoUrl = isDuplicateFlagged
        ? (_aiResult?.matchedImageUrl ?? 'https://images.unsplash.com/photo-1584483766114-2cea6facdf57?w=600&auto=format&fit=crop')
        : null;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackgroundColor : const Color(0xFFF8FAFC),
      appBar: const CustomAppBar(title: 'Check Duplicates'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top AI Alert Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDuplicateFlagged ? Colors.orange.shade50 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDuplicateFlagged ? Colors.orange.shade300 : Colors.green.shade300,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isDuplicateFlagged ? Icons.auto_awesome_rounded : Icons.check_circle_rounded,
                    color: isDuplicateFlagged ? Colors.orange.shade800 : Colors.green.shade700,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _aiResult?.aiVerdict ?? 'Running dual-layer AI duplicate scan...',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isDuplicateFlagged ? const Color(0xFF9A3412) : Colors.green.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Dual Layer Breakdown Box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurfaceColor : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? AppTheme.darkBorderColor : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'AI & Hash Analysis Breakdown',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.navyColor),
                      ),
                      InkWell(
                        onTap: _isAiScanning ? null : _runAiDuplicateScan,
                        child: Row(
                          children: [
                            _isAiScanning
                                ? const SizedBox(
                                    width: 10,
                                    height: 10,
                                    child: CircularProgressIndicator(strokeWidth: 1.5, color: AppTheme.primaryColor),
                                  )
                                : const Icon(Icons.refresh, size: 13, color: AppTheme.primaryColor),
                            const SizedBox(width: 4),
                            Text(
                              _isAiScanning ? 'Scanning...' : 'Re-Scan AI',
                              style: const TextStyle(fontSize: 11, color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.tag_rounded, size: 14, color: Colors.blue),
                      const SizedBox(width: 6),
                      const Text('Layer 1 (Hex Hash Match):', style: TextStyle(fontSize: 12)),
                      const Spacer(),
                      Text(
                        '${_aiResult?.hexMatchScore.toStringAsFixed(1) ?? "0.0"}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: (_aiResult?.hexMatchScore ?? 0) > 50 ? Colors.orange.shade800 : Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.psychology_outlined, size: 14, color: Colors.purple),
                      const SizedBox(width: 6),
                      const Text('Layer 2 (AI Vision Perception):', style: TextStyle(fontSize: 12)),
                      const Spacer(),
                      Text(
                        '${_aiResult?.aiSemanticScore.toStringAsFixed(1) ?? "0.0"}%',
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
            const SizedBox(height: 16),

            // Photo Comparison Header
            Text(
              'Photo Comparison',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDark ? AppTheme.darkTextColor : AppTheme.navyColor,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildEvidenceImageThumbnail(
                    context: context,
                    imageUrl: uploadedPhotoUrl,
                    title: 'New Upload Photo',
                    emptyLabel: 'No Image',
                    emptySublabel: 'No photo attached',
                    emptyIcon: Icons.no_photography_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildEvidenceImageThumbnail(
                    context: context,
                    imageUrl: matchedDatabasePhotoUrl,
                    title: isDuplicateFlagged ? 'Matched Database Photo' : 'Database Comparison',
                    emptyLabel: 'No Image', // Shows "No Image" instead of "no match"
                    emptySublabel: isDuplicateFlagged ? 'No reference photo' : 'Clean original submission',
                    emptyIcon: Icons.image_not_supported_outlined,
                    emptyIconColor: isDuplicateFlagged ? Colors.orange.shade400 : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            CustomButton(
              label: 'Confirm Fake / Duplicate',
              icon: Icons.block_rounded,
              backgroundColor: Colors.red.shade700,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Report ${c.id} marked as duplicate/fake and rejected.')),
                );
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 10),
            CustomButton(
              label: 'Mark Genuine',
              icon: Icons.check_circle_rounded,
              isOutlined: true,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Report ${c.id} confirmed genuine.')),
                );
                Navigator.pop(context);
              },
            ),
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
            fontSize: 11.5,
            color: isDark ? AppTheme.darkTextColor : const Color(0xFF0F766E),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 135,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
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
