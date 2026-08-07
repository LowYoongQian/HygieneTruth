import 'package:flutter/material.dart';
import '../../core/models/mock_seed_data.dart';
import '../../core/models/complaint_model.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/status_badge.dart';
import '../widgets/deadline_countdown_badge.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  int _currentBottomTabIndex = 0;
  int _noticeTab = 0; // 0 = Active, 1 = Closed

  // Mutable Owner Profile Data
  String _ownerName = 'Chong Wei Meng';
  final String _ownerEmail = 'owner@bistro.com';
  String _ownerPhone = '+60 12-345 6789';

  // Mutable Approved Restaurant Details Data
  String _restaurantName = 'Golden Dragon Noodle House';
  String _businessRegNo = 'SSM-2024-009481-X';
  String _operatingHours = '10:00 AM - 10:00 PM (Daily)';
  String _restaurantAddress = '12 Jalan Petaling, City Centre, 50000 Kuala Lumpur';
  final bool _isPremisesApproved = true;

  // Mock Reviews Data with Owner Responses for Analytics Monitoring
  final List<Map<String, String>> _ownerReviews = [
    {
      'userName': 'Ahmad Razak',
      'date': '2026-07-28',
      'stars': '5',
      'comment': 'Very clean dining area and kitchen! Food served hot and fresh. Staff wore hairnets and gloves properly.',
      'ownerReply': 'Thank you Ahmad! We strictly enforce daily sanitization protocols.',
    },
    {
      'userName': 'Siti Sarah',
      'date': '2026-07-22',
      'stars': '4',
      'comment': 'Great noodles! Tables were wiped clean quickly. Passed hygiene inspection well.',
      'ownerReply': '',
    },
    {
      'userName': 'Kevin Tan',
      'date': '2026-07-15',
      'stars': '3',
      'comment': 'Food was delicious, but floor near dishwashing area was slippery during peak hour.',
      'ownerReply': 'Appreciate the feedback Kevin. Our team has placed non-slip mats near dishwashing.',
    },
  ];

  void _showChangeNameDialog() {
    final nameCtrl = TextEditingController(text: _ownerName);
    final phoneCtrl = TextEditingController(text: _ownerPhone);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Edit Owner Profile', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.navyColor)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Owner Full Name',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
              onPressed: () {
                if (nameCtrl.text.trim().isNotEmpty) {
                  setState(() {
                    _ownerName = nameCtrl.text.trim();
                    _ownerPhone = phoneCtrl.text.trim();
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Owner profile updated successfully!')),
                  );
                }
              },
              child: const Text('Save Profile', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showChangePasswordDialog() {
    final currentPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.navyColor)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPassCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Current Password', prefixIcon: Icon(Icons.lock_outline)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: newPassCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password', prefixIcon: Icon(Icons.lock)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: confirmPassCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm New Password', prefixIcon: Icon(Icons.check_circle_outline)),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
              onPressed: () {
                if (newPassCtrl.text.isEmpty || newPassCtrl.text != confirmPassCtrl.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('New passwords do not match!'), backgroundColor: Colors.red),
                  );
                  return;
                }
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Business account password updated!'), backgroundColor: AppTheme.primaryColor),
                );
              },
              child: const Text('Update Password', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showEditRestaurantDetailsDialog() {
    final nameCtrl = TextEditingController(text: _restaurantName);
    final regNoCtrl = TextEditingController(text: _businessRegNo);
    final hoursCtrl = TextEditingController(text: _operatingHours);
    final addrCtrl = TextEditingController(text: _restaurantAddress);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Edit Approved Premises Details', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.navyColor)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Restaurant Premises Name', prefixIcon: Icon(Icons.storefront)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: regNoCtrl,
                  decoration: const InputDecoration(labelText: 'Business Reg No (SSM)', prefixIcon: Icon(Icons.card_membership)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: hoursCtrl,
                  decoration: const InputDecoration(labelText: 'Operating Hours', prefixIcon: Icon(Icons.access_time)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: addrCtrl,
                  decoration: const InputDecoration(labelText: 'Premises Address', prefixIcon: Icon(Icons.location_on)),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
              onPressed: () {
                if (nameCtrl.text.trim().isNotEmpty) {
                  setState(() {
                    _restaurantName = nameCtrl.text.trim();
                    _businessRegNo = regNoCtrl.text.trim();
                    _operatingHours = hoursCtrl.text.trim();
                    _restaurantAddress = addrCtrl.text.trim();
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Approved restaurant details updated!'), backgroundColor: AppTheme.primaryColor),
                  );
                }
              },
              child: const Text('Save Premises', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showOwnerReplyDialog(int index) {
    final replyCtrl = TextEditingController(text: _ownerReviews[index]['ownerReply']);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Reply to ${_ownerReviews[index]['userName']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('"${_ownerReviews[index]['comment']}"', style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 12),
              TextField(
                controller: replyCtrl,
                decoration: InputDecoration(
                  hintText: 'Write official business response...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
              onPressed: () {
                if (replyCtrl.text.trim().isNotEmpty) {
                  setState(() {
                    _ownerReviews[index]['ownerReply'] = replyCtrl.text.trim();
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Response published to review!'), backgroundColor: AppTheme.primaryColor),
                  );
                }
              },
              child: const Text('Post Response', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        title: _getTabTitle(_currentBottomTabIndex),
      ),
      body: _buildTabBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentBottomTabIndex,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey.shade500,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentBottomTabIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Overview'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), activeIcon: Icon(Icons.analytics), label: 'Analytics'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_late_outlined), activeIcon: Icon(Icons.assignment_late), label: 'Notices'),
          BottomNavigationBarItem(icon: Icon(Icons.storefront_outlined), activeIcon: Icon(Icons.storefront), label: 'Outlets'),
          BottomNavigationBarItem(icon: Icon(Icons.business_center_outlined), activeIcon: Icon(Icons.business_center), label: 'Profile'),
        ],
      ),
    );
  }

  String _getTabTitle(int index) {
    switch (index) {
      case 0:
        return 'Commercial Dashboard';
      case 1:
        return 'Self-Monitoring & Analytics';
      case 2:
        return 'Compliance Notices';
      case 3:
        return 'Approved Premises';
      case 4:
        return 'Business Profile';
      default:
        return 'Owner Portal';
    }
  }

  Widget _buildTabBody() {
    switch (_currentBottomTabIndex) {
      case 0:
        return _buildOverviewPanel();
      case 1:
        return _buildAnalyticsPanel();
      case 2:
        return _buildNoticesPanel();
      case 3:
        return _buildOutletsPanel();
      case 4:
        return _buildProfilePanel();
      default:
        return _buildOverviewPanel();
    }
  }

  // ==========================================
  // TAB 0: COMMERCIAL OVERVIEW PANEL
  // ==========================================
  Widget _buildOverviewPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Commercial Premises Status Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0C2340), Color(0xFF1E3A8A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
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
                        color: Colors.green.shade600,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.verified, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text('APPROVED PREMISES', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Text(
                      'License: MHK-KL-88241',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(_restaurantName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                Text('Owner: $_ownerName • Reg: $_businessRegNo', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Commercial KPI Metric Cards Grid
          const Text('Commercial Performance Metrics', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.navyColor)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard('Hygiene Risk', '12.5 (SAFE)', '-15.9 pts drop', Icons.shield, Colors.green),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricCard('Avg Rating', '4.8 ★', '+14% vs last mo', Icons.star, Colors.amber),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard('Total Reviews', '128 Reviews', '+12 new', Icons.comment, Colors.blue),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricCard('Active Notices', '1 Notice', '1 Pending Fix', Icons.warning_amber, Colors.orange),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Quick Action Commercial Buttons
          const Text('Commercial Actions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.navyColor)),
          const SizedBox(height: 10),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Column(
              children: [
                ListTile(
                  leading: const CircleAvatar(backgroundColor: Color(0xFFE0F2FE), child: Icon(Icons.check_circle_outline, color: Color(0xFF0284C7))),
                  title: const Text('Submit Rectification Proof', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Upload resolution photo evidence for open notices'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () => Navigator.pushNamed(context, AppRoutes.markIssueResolved),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const CircleAvatar(backgroundColor: Color(0xFFDCFCE7), child: Icon(Icons.article_outlined, color: Colors.green)),
                  title: const Text('View Official Health Certificate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Download government hygiene compliance report'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () => Navigator.pushNamed(context, AppRoutes.finalReport),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, String subtext, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.navyColor)),
          const SizedBox(height: 2),
          Text(subtext, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: SELF-MONITORING & ANALYTICS COMPARISON PANEL
  // ==========================================
  Widget _buildAnalyticsPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Self-Monitoring Performance Comparison',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.navyColor),
          ),
          Text(
            'Compare rating trends, risk score changes, and monitor customer comments.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),

          // 1. Rating Comparison Card (Current Month vs Previous Month)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Rating Comparison', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.navyColor)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                        child: const Text('+14.2% Growth', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: const [
                            Text('Current (Jul 2026)', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            SizedBox(height: 4),
                            Text('4.8 ★', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                            Text('128 Reviews', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Container(height: 40, width: 1, color: Colors.grey.shade300),
                      Expanded(
                        child: Column(
                          children: const [
                            Text('Previous (Jun 2026)', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            SizedBox(height: 4),
                            Text('4.2 ★', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.amber)),
                            Text('94 Reviews', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Comparison Progress Visual
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('30-Day Rating Improvement: +0.6 Stars', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: 0.96,
                          minHeight: 8,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2. Risk Score Trend Comparison Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Hygiene Risk Comparison', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.navyColor)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                        child: const Text('Risk Reduced', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: const [
                          Text('Current Score', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          SizedBox(height: 4),
                          Text('12.5', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                          Text('SAFE TIER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                      const Icon(Icons.arrow_forward, color: Colors.green, size: 24),
                      Column(
                        children: const [
                          Text('Previous Quarter', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          SizedBox(height: 4),
                          Text('28.4', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.amber)),
                          Text('MODERATE TIER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 3. Customer Comment & Feedback Monitor Section
          const Text('Customer Feedback & Comment Monitor', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.navyColor)),
          const SizedBox(height: 10),

          ..._ownerReviews.asMap().entries.map((entry) {
            final idx = entry.key;
            final r = entry.value;
            final stars = int.tryParse(r['stars'] ?? '5') ?? 5;

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                          child: Text(r['userName']![0], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryColor)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(r['userName']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.navyColor)),
                        ),
                        Row(
                          children: List.generate(5, (s) {
                            return Icon(s < stars ? Icons.star : Icons.star_border, color: Colors.amber, size: 14);
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(r['comment']!, style: const TextStyle(fontSize: 12, color: Colors.black87)),

                    // Published Owner Response
                    if (r['ownerReply']!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.reply, size: 14, color: AppTheme.primaryColor),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Official Owner Reply: ${r['ownerReply']}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.navyColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                        onPressed: () => _showOwnerReplyDialog(idx),
                        icon: const Icon(Icons.reply, size: 14),
                        label: Text(r['ownerReply']!.isEmpty ? 'Respond to Comment' : 'Edit Response', style: const TextStyle(fontSize: 11)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: COMPLIANCE NOTICES PANEL
  // ==========================================
  Widget _buildNoticesPanel() {
    final activeNotices = MockSeedData.complaints.where((c) => c.status != ComplaintStatus.resolved && c.status != ComplaintStatus.rejected).toList();

    final closedNotices = MockSeedData.complaints.where((c) => c.status == ComplaintStatus.resolved || c.status == ComplaintStatus.rejected).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ChoiceChip(
                label: const Text('Active Notices'),
                selected: _noticeTab == 0,
                onSelected: (val) {
                  if (val) setState(() => _noticeTab = 0);
                },
              ),
              ChoiceChip(
                label: const Text('Closed Cases'),
                selected: _noticeTab == 1,
                onSelected: (val) {
                  if (val) setState(() => _noticeTab = 1);
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: _noticeTab == 0 ? _buildActiveList(activeNotices) : _buildClosedList(closedNotices),
        ),
      ],
    );
  }

  Widget _buildActiveList(List<ComplaintModel> list) {
    if (list.isEmpty) {
      return const Center(child: Text('No active notices'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final c = list[index];
        final daysLeft = (4 - index * 3);
        return Card(
          child: ListTile(
            title: Text(c.restaurantName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Category: ${c.category}'),
                Text('ID: ${c.id}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    StatusBadge.fromStatus(c.status.name),
                    const SizedBox(width: 8),
                    DeadlineCountdownBadge(daysLeft: daysLeft),
                  ],
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.noticeDetail, arguments: c);
            },
          ),
        );
      },
    );
  }

  Widget _buildClosedList(List<ComplaintModel> list) {
    if (list.isEmpty) {
      return const Center(child: Text('No closed cases'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final c = list[index];
        return Card(
          child: ListTile(
            title: Text(c.restaurantName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Category: ${c.category}'),
                Text('ID: ${c.id}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 6),
                StatusBadge.fromStatus(c.status.name),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.noticeDetail, arguments: c);
            },
          ),
        );
      },
    );
  }

  void _showRequestDeleteRestaurantDialog() {
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text(
                'Request Premises Deletion',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.navyColor),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Submitting a request to delete your approved restaurant premises will notify government health admins for review.',
                style: TextStyle(fontSize: 12, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                decoration: InputDecoration(
                  labelText: 'Reason for Deletion Request',
                  hintText: 'e.g. Permanent closure, business sale, relocation...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                if (reasonCtrl.text.trim().isNotEmpty) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Deletion request submitted to health admins for review.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Submit Request', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // ==========================================
  // TAB 3: APPROVED PREMISES DETAILS PANEL
  // ==========================================
  Widget _buildOutletsPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Add New Premises Button & Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('My Approved Premises', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.navyColor)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, visualDensity: VisualDensity.compact),
                onPressed: () => Navigator.pushNamed(context, AppRoutes.addRestaurant),
                icon: const Icon(Icons.add_business, size: 14, color: Colors.white),
                label: const Text('+ Add New Premises', style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFFDCFCE7),
                        child: Icon(Icons.storefront, color: Colors.green),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_restaurantName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.navyColor)),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.verified, size: 14, color: Colors.green),
                                const SizedBox(width: 4),
                                Text(
                                  _isPremisesApproved ? 'Approved & Certified Premises' : 'Under Review',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 10),

                  _buildDetailRow('Business Reg No (SSM):', _businessRegNo),
                  _buildDetailRow('License Cert Number:', 'MHK-KL-88241'),
                  _buildDetailRow('Operating Hours:', _operatingHours),
                  _buildDetailRow('Premises Address:', _restaurantAddress),
                  _buildDetailRow('Seating Capacity:', '85 Seats (Indoor & Alfresco)'),
                  _buildDetailRow('Last Health Inspection:', '2026-07-15 (Grade A - 96/100)'),

                  const SizedBox(height: 14),
                  const Divider(),
                  const SizedBox(height: 10),

                  // Action Buttons Row inside Premises Card (Edit Details + Request Premises Deletion)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.primaryColor),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _showEditRestaurantDetailsDialog,
                          icon: const Icon(Icons.edit, size: 16, color: AppTheme.primaryColor),
                          label: const Text('Edit Details', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _showRequestDeleteRestaurantDialog,
                          icon: const Icon(Icons.delete_forever_outlined, size: 16, color: Colors.red),
                          label: const Text('Request Deletion', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.navyColor)),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 4: OWNER BUSINESS PROFILE & SETTINGS
  // ==========================================
  Widget _buildProfilePanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Owner Profile Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                    child: const Icon(Icons.business_center, size: 30, color: AppTheme.primaryColor),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_ownerName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.navyColor)),
                        Text('Restaurant Owner / Director', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        const SizedBox(height: 4),
                        Text(_ownerEmail, style: const TextStyle(fontSize: 11, color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Business Account Settings Menu List
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.edit_outlined, color: AppTheme.primaryColor),
                  title: const Text('Edit Owner Name & Contact Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text('Current: $_ownerName • $_ownerPhone'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: _showChangeNameDialog,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.lock_reset, color: AppTheme.primaryColor),
                  title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Update commercial account password'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: _showChangePasswordDialog,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.storefront_outlined, color: AppTheme.primaryColor),
                  title: const Text('Edit Approved Restaurant Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text('Premises: $_restaurantName'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: _showEditRestaurantDetailsDialog,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.notifications_active_outlined, color: AppTheme.primaryColor),
                  title: const Text('Commercial Alerts & Notifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Receive instant SMS/email alerts for inspection notices'),
                  trailing: Switch(
                    value: true,
                    onChanged: (val) {},
                    activeThumbColor: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Sign Out Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () {
              Navigator.pushReplacementNamed(context, AppRoutes.splashRoleSelect);
            },
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text('Sign Out Business Account', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
