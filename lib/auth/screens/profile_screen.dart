import 'package:flutter/material.dart';
import '../../core/models/mock_seed_data.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/customer_store_service.dart';
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
    final customer = CustomerStoreService.currentCustomer;
    final fallbackUser = MockSeedData.users.first;

    final userName = customer?.name ?? fallbackUser.name;
    final userEmail = customer?.email ?? fallbackUser.email;
    final avatarUrl = customer?.avatarUrl ?? fallbackUser.avatarUrl;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFF3F4F6) : const Color(0xFF0F172A);
    final subtitleTextColor = isDark ? const Color(0xFF9CA3AF) : Colors.grey.shade600;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'My Profile',
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Activity History',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.activityHistory),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
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
                              // Verified Badge Pin Icon
                              Positioned(
                                right: 2,
                                bottom: 2,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.verified,
                                    color: Color(0xFF0284C7),
                                    size: 20,
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
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              userName,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.verified,
                              color: Color(0xFF0284C7),
                              size: 20,
                            ),
                          ],
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
                        RoleBadge(role: fallbackUser.role),
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
                                _buildDetailRow(context, Icons.phone_outlined, 'Phone Number', customer?.phone ?? 'Not set (Tap edit to set)', textColor, subtitleTextColor),
                                const Divider(height: 20),
                                _buildDetailRow(context, Icons.wc_outlined, 'Gender', customer?.gender ?? 'Not set (Tap edit to set)', textColor, subtitleTextColor),
                                const Divider(height: 20),
                                _buildDetailRow(context, Icons.public_outlined, 'Country / Region', customer?.country ?? 'Not set (Tap edit to set)', textColor, subtitleTextColor),
                                const Divider(height: 20),
                                _buildDetailRow(context, Icons.location_city_outlined, 'State / City', customer?.state ?? 'Not set (Tap edit to set)', textColor, subtitleTextColor),
                                const Divider(height: 20),
                                _buildDetailRow(context, Icons.calendar_today_outlined, 'Member Since', customer?.joinedDate ?? 'Jan 2024', textColor, subtitleTextColor),
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
}
