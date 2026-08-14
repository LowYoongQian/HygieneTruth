import 'package:flutter/material.dart';
import '../../core/models/user_model.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/customer_store_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/translations.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/google_sign_in_button.dart';
import '../widgets/role_badge.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoadingSession = true;

  @override
  void initState() {
    super.initState();
    _loadUserSession();
  }

  Future<void> _loadUserSession() async {
    await CustomerStoreService.fetchActiveUserSession();
    if (mounted) {
      setState(() {
        _isLoadingSession = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final customer = CustomerStoreService.currentCustomer;
    final userName = customer?.name ?? 'Guest User';
    final userEmail = customer?.email ?? 'Not Signed In';
    final avatarUrl = customer?.avatarUrl ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleTextColor = isDark ? Colors.grey.shade400 : const Color(0xFF64748B);

        return Scaffold(
          appBar: CustomAppBar(
            title: t('profile'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit Profile',
                onPressed: () async {
                  await Navigator.pushNamed(context, AppRoutes.editProfile);
                  _loadUserSession();
                },
              ),
              IconButton(
                icon: const Icon(Icons.history_toggle_off),
                tooltip: t('activity_history'),
                onPressed: () => Navigator.pushNamed(context, AppRoutes.activityHistory),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: t('settings'),
                onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
              ),
            ],
          ),
          body: _isLoadingSession
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadUserSession,
                  color: AppTheme.primaryColor,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. TOP BANNER UI BEHIND PROFILE AVATAR FRAME
                        Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.topCenter,
                          children: [
                            // Gradient Cover Banner
                            Container(
                              height: 140,
                              width: double.infinity,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF0F172A), // Deep Navy
                                    Color(0xFF1E293B),
                                    Color(0xFF00A88F), // Brand Teal/Green accent
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    right: -20,
                                    top: -20,
                                    child: Container(
                                      width: 110,
                                      height: 110,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withValues(alpha: 0.08),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: 20,
                                    bottom: 10,
                                    child: Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withValues(alpha: 0.05),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                      // Overlapping Profile Avatar Frame Icon with Gold Ring Accent
                      Positioned(
                        top: 85,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).cardColor,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 46,
                                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                                backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                                child: avatarUrl.isEmpty
                                    ? Text(
                                        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                                        style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryColor,
                                        ),
                                      )
                                    : null,
                              ),
                              // Online Status Indicator Dot
                              Positioned(
                                right: 2,
                                bottom: 2,
                                child: Container(
                                  padding: const EdgeInsets.all(2.5),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF10B981), // Active Online Green Dot
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 55),

                  // User Info Header Block
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      children: [
                        Text(
                          userName,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userEmail,
                          style: TextStyle(
                            color: subtitleTextColor,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 10),
                        RoleBadge(role: customer?.role ?? UserRole.user),
                        const SizedBox(height: 24),

                        // Section 1: Personal Details
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Personal Details',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.primaryColor,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: () async {
                                await Navigator.pushNamed(context, AppRoutes.editProfile);
                                _loadUserSession();
                              },
                              icon: const Icon(Icons.edit_outlined, size: 16),
                              label: const Text(
                                'Edit',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                _buildDetailRow(
                                  context,
                                  Icons.person_outline,
                                  'Full Name',
                                  userName,
                                  textColor,
                                  subtitleTextColor,
                                  onTap: () async {
                                    await Navigator.pushNamed(context, AppRoutes.editProfile);
                                    _loadUserSession();
                                  },
                                ),
                                const Divider(height: 20),
                                _buildDetailRow(
                                  context,
                                  Icons.email_outlined,
                                  'Email Address',
                                  userEmail,
                                  textColor,
                                  subtitleTextColor,
                                ),
                                const Divider(height: 20),
                                InkWell(
                                  onTap: () {
                                    final isGoogleLinked = CustomerStoreService.isGoogleLinked();
                                    final googleEmail = CustomerStoreService.getGoogleLinkedEmail();
                                    _showLinkedConnectionBottomSheet(context, isGoogleLinked, googleEmail.isNotEmpty ? googleEmail : userEmail);
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.link, color: AppTheme.primaryColor, size: 22),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Linked Connection',
                                                style: TextStyle(fontSize: 12, color: subtitleTextColor),
                                              ),
                                              const SizedBox(height: 2),
                                              Row(
                                                children: [
                                                  Text(
                                                    CustomerStoreService.isGoogleLinked() ? 'Google Account Linked' : 'Not Linked',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                      color: CustomerStoreService.isGoogleLinked() ? Colors.green.shade700 : textColor,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  if (CustomerStoreService.isGoogleLinked())
                                                    const Icon(Icons.check_circle, size: 16, color: Colors.green),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                                      ],
                                    ),
                                  ),
                                ),
                                const Divider(height: 20),
                                _buildDetailRow(
                                  context,
                                  Icons.phone_outlined,
                                  'Phone Number',
                                  customer?.phone ?? 'Not set (Tap edit to set)',
                                  textColor,
                                  subtitleTextColor,
                                  onTap: () async {
                                    await Navigator.pushNamed(context, AppRoutes.editProfile);
                                    _loadUserSession();
                                  },
                                ),
                                const Divider(height: 20),
                                _buildDetailRow(
                                  context,
                                  Icons.wc_outlined,
                                  'Gender',
                                  customer?.gender ?? 'Not set (Tap edit to set)',
                                  textColor,
                                  subtitleTextColor,
                                  onTap: () async {
                                    await Navigator.pushNamed(context, AppRoutes.editProfile);
                                    _loadUserSession();
                                  },
                                ),
                                const Divider(height: 20),
                                _buildDetailRow(
                                  context,
                                  Icons.public_outlined,
                                  'Country / Region',
                                  customer?.country ?? 'Not set (Tap edit to set)',
                                  textColor,
                                  subtitleTextColor,
                                  onTap: () async {
                                    await Navigator.pushNamed(context, AppRoutes.editProfile);
                                    _loadUserSession();
                                  },
                                ),
                                const Divider(height: 20),
                                _buildDetailRow(
                                  context,
                                  Icons.location_city_outlined,
                                  'State / City',
                                  customer?.state ?? 'Not set (Tap edit to set)',
                                  textColor,
                                  subtitleTextColor,
                                  onTap: () async {
                                    await Navigator.pushNamed(context, AppRoutes.editProfile);
                                    _loadUserSession();
                                  },
                                ),
                                const Divider(height: 20),
                                _buildDetailRow(
                                  context,
                                  Icons.calendar_today_outlined,
                                  'Member Since',
                                  _formatMemberSinceDate(customer?.joinedDate),
                                  textColor,
                                  subtitleTextColor,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
  }

  String _formatMemberSinceDate(String? rawDate) {
    if (rawDate != null && rawDate.trim().isNotEmpty && rawDate != 'Recently Joined') {
      if (rawDate.contains('-') && rawDate.length >= 10) {
        final dt = DateTime.tryParse(rawDate);
        if (dt != null) {
          final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
        }
      }
      return rawDate;
    }
    final nowMsia = DateTime.now().toUtc().add(const Duration(hours: 8));
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${nowMsia.day} ${months[nowMsia.month - 1]} ${nowMsia.year}';
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color textColor,
    Color subtitleTextColor, {
    VoidCallback? onTap,
  }) {
    final isClickable = (onTap != null);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 12, color: subtitleTextColor),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: value.contains('Not set') ? Colors.grey.shade500 : textColor,
                    ),
                  ),
                ],
              ),
            ),
            if (isClickable)
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showLinkedConnectionBottomSheet(BuildContext context, bool initialIsLinked, String initialEmail) {
    bool isLinked = initialIsLinked;
    String linkedEmail = initialEmail;
    bool isProcessing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: const [
                        Icon(Icons.link, color: AppTheme.primaryColor, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Linked Connection Status',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Google Connection Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isLinked ? const Color(0xFFF0FDF4) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isLinked ? const Color(0xFF86EFAC) : Colors.grey.shade300,
                          width: isLinked ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const GoogleGLogoWidget(size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Google Account',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isLinked ? Colors.green.shade100 : Colors.grey.shade200,
                                      ),
                                      child: Text(
                                        isLinked ? 'Linked' : 'Not Linked',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isLinked ? Colors.green.shade800 : Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isLinked ? linkedEmail : 'No Google account connected',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isLinked ? FontWeight.w500 : FontWeight.normal,
                                    color: isLinked ? Colors.green.shade900 : Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isLinked
                          ? '✓ Your Google account ($linkedEmail) is successfully bound to this profile for fast 1-tap authentication.'
                          : 'ℹ️ Connect your Google account to enable instant 1-tap sign-in and sync across your devices.',
                      style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600, height: 1.4),
                    ),
                    const SizedBox(height: 20),

                    // Primary Action: Link / Unlink Button
                    if (!isLinked)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 2,
                          ),
                          onPressed: isProcessing
                              ? null
                              : () async {
                                  setModalState(() => isProcessing = true);
                                  final messenger = ScaffoldMessenger.of(context);
                                  final result = await CustomerStoreService.linkGoogleAccount();

                                  if (result.success) {
                                    final newEmail = CustomerStoreService.getGoogleLinkedEmail();
                                    setModalState(() {
                                      isLinked = true;
                                      linkedEmail = newEmail;
                                      isProcessing = false;
                                    });
                                    if (mounted) setState(() {});

                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(result.message),
                                        backgroundColor: const Color(0xFF059669),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  } else {
                                    setModalState(() => isProcessing = false);
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(result.message),
                                        backgroundColor: Colors.red.shade700,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                          icon: isProcessing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const GoogleGLogoWidget(size: 16),
                                ),
                          label: Text(
                            isProcessing ? 'Connecting to Google...' : 'Link Google Account',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade700,
                            side: BorderSide(color: Colors.red.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: isProcessing
                              ? null
                              : () async {
                                  final messenger = ScaffoldMessenger.of(context);
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (dCtx) => AlertDialog(
                                      title: const Text('Unlink Google Account?'),
                                      content: const Text(
                                        'Are you sure you want to disconnect this Google account? You will still be able to log in with your email and password.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(dCtx, false),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
                                          onPressed: () => Navigator.pop(dCtx, true),
                                          child: const Text('Unlink', style: TextStyle(color: Colors.white)),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    setModalState(() => isProcessing = true);
                                    final result = await CustomerStoreService.unlinkGoogleAccount();

                                    if (result.success) {
                                      setModalState(() {
                                        isLinked = false;
                                        linkedEmail = '';
                                        isProcessing = false;
                                      });
                                      if (mounted) setState(() {});

                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(result.message),
                                          backgroundColor: Colors.grey.shade800,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    } else {
                                      setModalState(() => isProcessing = false);
                                    }
                                  }
                                },
                          icon: isProcessing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                                )
                              : const Icon(Icons.link_off_rounded, size: 20),
                          label: Text(
                            isProcessing ? 'Unlinking...' : 'Unlink Google Account',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),

                    const SizedBox(height: 10),

                    // Close Button
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text(
                          'Close',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
