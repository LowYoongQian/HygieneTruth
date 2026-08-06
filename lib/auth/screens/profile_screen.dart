import 'package:flutter/material.dart';
import '../../core/models/mock_seed_data.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../widgets/role_badge.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = MockSeedData.users.first;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        title: 'My Account',
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Activity History',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.activityHistory),
          ),
          IconButton(
            icon: const Icon(Icons.edit_note_outlined),
            tooltip: 'Edit Profile',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.editProfile),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            tooltip: 'Logout',
            onPressed: () {
              Navigator.pushReplacementNamed(context, AppRoutes.splashRoleSelect);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Center Profile Avatar & Header Info
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFEAB308), // Vibrant yellow avatar border accent matching ref
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 46,
                      backgroundImage: NetworkImage(user.avatarUrl),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
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
                    user.email,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),
                  RoleBadge(role: user.role),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section 1: Personal Details
            const Text(
              'Personal details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 10),
            _buildDetailCard([
              _buildDetailRow('Full name:', user.name),
              _buildDetailRow('Date of Birth:', 'January 15, 1996'),
              _buildDetailRow('Gender:', 'Male'),
              _buildDetailRow('Nationality:', 'Malaysian'),
              _buildDetailRow('Address:', '🇲🇾 Kuala Lumpur - Malaysia'),
              _buildDetailRow('Phone Number:', user.phone),
              _buildDetailRow('Email:', user.email, isLast: true),
            ]),

            const SizedBox(height: 24),

            // Section 2: Account Details
            const Text(
              'Account Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 10),
            _buildDetailCard([
              _buildDetailRow('Display Name:', 'user_acc_2026'),
              _buildDetailRow('Account Created:', 'March 20, 2026'),
              _buildDetailRow('Last Login:', 'August 6, 2026'),
              _buildDetailRow('Membership Status:', 'Active Member'),
              _buildDetailRowWithWidget(
                'Account Verification:',
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Verified',
                    style: TextStyle(
                      color: Color(0xFF15803D),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              _buildDetailRow('Language Preference:', 'English', isLast: true),
            ]),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: Colors.grey.shade100),
      ],
    );
  }

  Widget _buildDetailRowWithWidget(String label, Widget widgetValue, {bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              widgetValue,
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: Colors.grey.shade100),
      ],
    );
  }
}
