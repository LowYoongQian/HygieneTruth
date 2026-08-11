import 'package:flutter/material.dart';
import '../../core/models/user_model.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/customer_store_service.dart';
import '../../core/services/language_manager.dart';
import '../../core/utils/translations.dart';
import '../../core/widgets/custom_app_bar.dart';
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
    return ListenableBuilder(
      listenable: languageManager,
      builder: (context, _) {
        final customer = CustomerStoreService.currentCustomer;

        final userName = (customer?.name != null && customer!.name.isNotEmpty) ? customer.name : 'User';
        final userEmail = (customer?.email != null && customer!.email.isNotEmpty) ? customer.email : 'Not set';
        final avatarUrl = customer?.avatarUrl ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=200';

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final textColor = isDark ? const Color(0xFFF3F4F6) : const Color(0xFF0F172A);
        final subtitleTextColor = isDark ? const Color(0xFF9CA3AF) : Colors.grey.shade600;

        return Scaffold(
          appBar: CustomAppBar(
            title: t('my_profile'),
            actions: [
              IconButton(
                icon: const Icon(Icons.history),
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
              : SingleChildScrollView(
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
                              Color(0xFF0284C7), // Ocean Blue accent
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
                                backgroundColor: const Color(0xFF0284C7).withValues(alpha: 0.15),
                                backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                                child: avatarUrl.isEmpty
                                    ? Text(
                                        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                                        style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0284C7),
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
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Personal Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                _buildDetailRow(context, Icons.person_outline, 'Full Name', userName, textColor, subtitleTextColor),
                                const Divider(height: 20),
                                _buildDetailRow(context, Icons.email_outlined, 'Email Address', userEmail, textColor, subtitleTextColor),
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
                                        const Icon(Icons.link, color: Color(0xFF0284C7), size: 22),
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
                                _buildDetailRow(context, Icons.phone_outlined, 'Phone Number', customer?.phone ?? 'Not set (Tap edit to set)', textColor, subtitleTextColor),
                                const Divider(height: 20),
                                _buildDetailRow(context, Icons.wc_outlined, 'Gender', customer?.gender ?? 'Not set (Tap edit to set)', textColor, subtitleTextColor),
                                const Divider(height: 20),
                                _buildDetailRow(context, Icons.public_outlined, 'Country / Region', customer?.country ?? 'Not set (Tap edit to set)', textColor, subtitleTextColor),
                                const Divider(height: 20),
                                _buildDetailRow(context, Icons.location_city_outlined, 'State / City', customer?.state ?? 'Not set (Tap edit to set)', textColor, subtitleTextColor),
                                const Divider(height: 20),
                                _buildDetailRow(context, Icons.calendar_today_outlined, 'Member Since', _formatMemberSinceDate(customer?.joinedDate), textColor, subtitleTextColor),
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
        );
      },
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

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value, Color textColor, Color subtitleTextColor) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF0284C7), size: 22),
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
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showLinkedConnectionBottomSheet(BuildContext context, bool isLinked, String email) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
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
                    Icon(Icons.link, color: Color(0xFF0284C7), size: 24),
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
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isLinked ? Colors.green.shade300 : Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isLinked ? Colors.green.shade50 : Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.g_mobiledata,
                          size: 30,
                          color: isLinked ? Colors.green.shade700 : Colors.grey,
                        ),
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
                                    borderRadius: BorderRadius.circular(12),
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
                              isLinked ? email : 'No Google account connected',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
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
                      ? '✓ Your Google email ($email) is successfully linked to this account for 1-click authentication.'
                      : 'ℹ️ No Google account is linked to this profile. You can sign in using your email and password.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      'Close',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
