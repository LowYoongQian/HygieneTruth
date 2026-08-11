import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/models/mock_seed_data.dart';
import '../../core/models/restaurant_model.dart';
import '../../core/models/complaint_model.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/audit_log_service.dart';
import '../../core/services/customer_store_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/services/restaurant_store_service.dart';
import '../../core/widgets/shimmer_skeletons.dart';
import '../widgets/deadline_countdown_badge.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  int _currentBottomTabIndex = 0;
  int _noticeTab = 0; // 0 = Active, 1 = Closed
  int _noticeAuthorityIndex = 0; // 0 = All, 1 = Government, 2 = Admin, 3 = Complaints

  // Dynamic Owner Profile Data
  String _ownerName = '';
  String _ownerEmail = '';
  String _ownerPhone = '';

  // Restaurant List & Filter State
  List<RestaurantModel> _fetchedOwnerRestaurants = [];
  bool _isLoadingRestaurants = true;
  int _restaurantFilterIndex = 0; // 0 = All, 1 = Active, 2 = Pending

  @override
  void initState() {
    super.initState();
    _loadOwnerSession();
    _loadOwnerRestaurants();
  }

  Future<void> _loadOwnerSession() async {
    final user = await CustomerStoreService.fetchActiveUserSession() ?? CustomerStoreService.currentCustomer;
    if (user != null && mounted) {
      setState(() {
        _ownerName = user.name;
        _ownerEmail = user.email;
        _ownerPhone = user.phone ?? '';
      });
    }
  }

  Future<void> _loadOwnerRestaurants() async {
    if (mounted) {
      setState(() {
        _isLoadingRestaurants = true;
      });
    }

    final user = CustomerStoreService.currentCustomer ?? await CustomerStoreService.fetchActiveUserSession();
    final String? currentUserId = user?.id ?? SupabaseService.client.auth.currentUser?.id;
    final String? currentUserEmail = user?.email ?? SupabaseService.client.auth.currentUser?.email;

    final restaurants = await RestaurantStoreService.fetchOwnerRestaurants(currentUserId, ownerEmail: currentUserEmail);

    if (mounted) {
      setState(() {
        _fetchedOwnerRestaurants = restaurants;
        _isLoadingRestaurants = false;
      });
    }
  }

  /// Returns all restaurants owned by the current user
  List<RestaurantModel> get _allMyOwnerRestaurants {
    final String? currentUserId = CustomerStoreService.currentCustomer?.id ?? SupabaseService.client.auth.currentUser?.id;
    final String? currentUserEmail = CustomerStoreService.currentCustomer?.email ?? SupabaseService.client.auth.currentUser?.email;

    final sourceList = _fetchedOwnerRestaurants.isNotEmpty ? _fetchedOwnerRestaurants : MockSeedData.restaurants;

    if (currentUserId == null || currentUserId.isEmpty) {
      return sourceList.where((r) => r.ownerId == 'own_001').toList();
    }

    return sourceList.where((r) {
      return r.ownerId == currentUserId ||
             (currentUserEmail != null && r.ownerId == currentUserEmail) ||
             (currentUserId == 'own_001' && r.ownerId == 'own_001');
    }).toList();
  }

  /// Returns ONLY approved/verified active restaurants for display in main header & active metrics
  List<RestaurantModel> get _approvedOwnerRestaurants {
    return _allMyOwnerRestaurants.where((r) => r.status == RestaurantStatus.approved).toList();
  }

  /// Backward-compatible getter returning ONLY approved restaurants
  List<RestaurantModel> get _myRegisteredRestaurants => _approvedOwnerRestaurants;



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

  void _showEditProfileDetailsDialog() {
    final currentCustomer = CustomerStoreService.currentCustomer;
    final nameCtrl = TextEditingController(text: _ownerName);
    final emailCtrl = TextEditingController(text: _ownerEmail);
    final phoneCtrl = TextEditingController(text: _ownerPhone);

    String? selectedGender = currentCustomer?.gender;
    String? selectedCountry = currentCustomer?.country;
    String? selectedState = currentCustomer?.state;

    final customGenderCtrl = TextEditingController();
    final customCountryCtrl = TextEditingController();
    final customStateCtrl = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return Dialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header Card Banner
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                          gradient: LinearGradient(
                            colors: [Color(0xFF0C2340), Color(0xFF0F766E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.manage_accounts_rounded, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text('Edit Profile Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                  Text('Manage personal info & business location', style: TextStyle(fontSize: 11, color: Colors.white70)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, color: Colors.white70),
                              onPressed: () => Navigator.pop(dialogCtx),
                            ),
                          ],
                        ),
                      ),

                      // Form Body
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Full Name
                            TextField(
                              controller: nameCtrl,
                              decoration: InputDecoration(
                                labelText: 'Owner Full Name *',
                                prefixIcon: const Icon(Icons.person_rounded, color: AppTheme.primaryColor),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // 2. Email Address
                            TextField(
                              controller: emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: 'Email Address *',
                                prefixIcon: const Icon(Icons.email_rounded, color: Color(0xFF0284C7)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // 3. Phone Number
                            TextField(
                              controller: phoneCtrl,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: 'Phone Number',
                                prefixIcon: const Icon(Icons.phone_rounded, color: Color(0xFF0F766E)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // 4. Gender
                            const Text('Gender', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.navyColor)),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              initialValue: ['Male', 'Female', 'Other'].contains(selectedGender) ? selectedGender : (selectedGender != null ? 'Other' : null),
                              dropdownColor: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              elevation: 4,
                              menuMaxHeight: 220,
                              decoration: InputDecoration(
                                hintText: 'Select Gender',
                                prefixIcon: const Icon(Icons.wc_rounded, color: Color(0xFF8B5CF6)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                              items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                              onChanged: (val) => setDialogState(() => selectedGender = val),
                            ),
                            if (selectedGender == 'Other') ...[
                              const SizedBox(height: 8),
                              TextField(
                                controller: customGenderCtrl,
                                decoration: InputDecoration(
                                  hintText: 'Specify gender...',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),

                            // 5. Country / Region
                            const Text('Country / Region', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.navyColor)),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              initialValue: ['Malaysia', 'Singapore', 'Indonesia', 'Thailand', 'Other'].contains(selectedCountry) ? selectedCountry : (selectedCountry != null ? 'Other' : null),
                              dropdownColor: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              elevation: 4,
                              menuMaxHeight: 220,
                              decoration: InputDecoration(
                                hintText: 'Select Country',
                                prefixIcon: const Icon(Icons.public_rounded, color: Color(0xFF0284C7)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                              items: ['Malaysia', 'Singapore', 'Indonesia', 'Thailand', 'Other']
                                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                  .toList(),
                              onChanged: (val) => setDialogState(() => selectedCountry = val),
                            ),
                            if (selectedCountry == 'Other') ...[
                              const SizedBox(height: 8),
                              TextField(
                                controller: customCountryCtrl,
                                decoration: InputDecoration(
                                  hintText: 'Enter country name...',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),

                            // 6. State / City
                            const Text('State / City', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.navyColor)),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              initialValue: ['Kuala Lumpur', 'Selangor', 'Johor', 'Penang', 'Perak', 'Sabah', 'Sarawak', 'Other'].contains(selectedState) ? selectedState : (selectedState != null ? 'Other' : null),
                              dropdownColor: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              elevation: 4,
                              menuMaxHeight: 220,
                              decoration: InputDecoration(
                                hintText: 'Select State / City',
                                prefixIcon: const Icon(Icons.location_city_rounded, color: Color(0xFFD97706)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                              items: ['Kuala Lumpur', 'Selangor', 'Johor', 'Penang', 'Perak', 'Sabah', 'Sarawak', 'Other']
                                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                  .toList(),
                              onChanged: (val) => setDialogState(() => selectedState = val),
                            ),
                            if (selectedState == 'Other') ...[
                              const SizedBox(height: 8),
                              TextField(
                                controller: customStateCtrl,
                                decoration: InputDecoration(
                                  hintText: 'Enter state or city name...',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),

                            // Action Buttons Row
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: () => Navigator.pop(dialogCtx),
                                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: isSaving ? null : () async {
                                      if (nameCtrl.text.trim().isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Name cannot be empty!'), backgroundColor: Colors.red),
                                        );
                                        return;
                                      }

                                      final finalGender = selectedGender == 'Other' ? customGenderCtrl.text.trim() : selectedGender;
                                      final finalCountry = selectedCountry == 'Other' ? customCountryCtrl.text.trim() : selectedCountry;
                                      final finalState = selectedState == 'Other' ? customStateCtrl.text.trim() : selectedState;

                                      final messenger = ScaffoldMessenger.of(context);
                                      final nav = Navigator.of(dialogCtx);
                                      setDialogState(() => isSaving = true);

                                      await CustomerStoreService.updateCustomerProfile(
                                        name: nameCtrl.text.trim(),
                                        email: emailCtrl.text.trim(),
                                        phone: phoneCtrl.text.trim(),
                                        gender: finalGender,
                                        country: finalCountry,
                                        state: finalState,
                                      );

                                      if (mounted) {
                                        setState(() {
                                          _ownerName = nameCtrl.text.trim();
                                          _ownerEmail = emailCtrl.text.trim();
                                          _ownerPhone = phoneCtrl.text.trim();
                                        });

                                        AuditLogService.logAction(
                                          actionType: 'PROFILE_UPDATE',
                                          category: 'Account Modification',
                                          title: 'Profile Details Updated',
                                          description: 'Updated profile name, email, phone, gender, country, and state',
                                        );

                                        nav.pop();
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Row(
                                              children: const [
                                                Icon(Icons.check_circle_rounded, color: Colors.white),
                                                SizedBox(width: 8),
                                                Expanded(child: Text('Profile details updated successfully!')),
                                              ],
                                            ),
                                            backgroundColor: const Color(0xFF0F766E),
                                            behavior: SnackBarBehavior.floating,
                                            margin: const EdgeInsets.all(16),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                        );
                                      }
                                    },
                                    child: isSaving
                                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                        : const Text('Save Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showChangePasswordDialog() {
    final currentPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();

    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final newPass = newPassCtrl.text;
            
            // Password Strength calculation
            int strengthScore = 0;
            if (newPass.length >= 6) strengthScore++;
            if (newPass.length >= 8) strengthScore++;
            if (RegExp(r'[A-Z]').hasMatch(newPass)) strengthScore++;
            if (RegExp(r'[0-9!@#\$%^&*(),.?":{}|<>]').hasMatch(newPass)) strengthScore++;

            String strengthLabel = 'Weak Password';
            Color strengthColor = Colors.red;
            if (strengthScore >= 3) {
              strengthLabel = 'Strong Password';
              strengthColor = const Color(0xFF0F766E);
            } else if (strengthScore == 2) {
              strengthLabel = 'Medium Strength';
              strengthColor = Colors.orange;
            }

            return Dialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header Card Banner
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                          gradient: LinearGradient(
                            colors: [Color(0xFF0C2340), Color(0xFF0F766E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.lock_reset_rounded, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text('Change Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                  Text('Secure businessman account credentials', style: TextStyle(fontSize: 11, color: Colors.white70)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, color: Colors.white70),
                              onPressed: () => Navigator.pop(dialogCtx),
                            ),
                          ],
                        ),
                      ),

                      // Form Body
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Current Password
                            TextField(
                              controller: currentPassCtrl,
                              obscureText: obscureCurrent,
                              decoration: InputDecoration(
                                labelText: 'Current Password *',
                                prefixIcon: const Icon(Icons.key_rounded, color: Color(0xFF0284C7)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                suffixIcon: IconButton(
                                  icon: Icon(obscureCurrent ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
                                  onPressed: () => setDialogState(() => obscureCurrent = !obscureCurrent),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // 2. New Password
                            TextField(
                              controller: newPassCtrl,
                              obscureText: obscureNew,
                              onChanged: (_) => setDialogState(() {}),
                              decoration: InputDecoration(
                                labelText: 'New Password *',
                                prefixIcon: const Icon(Icons.lock_rounded, color: AppTheme.primaryColor),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                suffixIcon: IconButton(
                                  icon: Icon(obscureNew ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
                                  onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                                ),
                              ),
                            ),
                            
                            if (newPass.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: (strengthScore / 4).clamp(0.1, 1.0),
                                        color: strengthColor,
                                        backgroundColor: Colors.grey.shade200,
                                        minHeight: 6,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    strengthLabel,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: strengthColor),
                                  ),
                                ],
                              ),
                            ],

                            const SizedBox(height: 16),

                            // 3. Confirm New Password
                            TextField(
                              controller: confirmPassCtrl,
                              obscureText: obscureConfirm,
                              decoration: InputDecoration(
                                labelText: 'Confirm New Password *',
                                prefixIcon: const Icon(Icons.check_circle_rounded, color: Color(0xFF0F766E)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                suffixIcon: IconButton(
                                  icon: Icon(obscureConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
                                  onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Action Buttons Row
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: () => Navigator.pop(dialogCtx),
                                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: isSaving ? null : () async {
                                      final currentPass = currentPassCtrl.text;
                                      final newPass = newPassCtrl.text;
                                      final confirmPass = confirmPassCtrl.text;

                                      if (currentPass.isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Please enter your current password'), backgroundColor: Colors.red),
                                        );
                                        return;
                                      }

                                      if (newPass.length < 6) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('New password must be at least 6 characters'), backgroundColor: Colors.red),
                                        );
                                        return;
                                      }

                                      if (newPass != confirmPass) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('New passwords do not match!'), backgroundColor: Colors.red),
                                        );
                                        return;
                                      }

                                      final messenger = ScaffoldMessenger.of(context);
                                      final nav = Navigator.of(dialogCtx);
                                      setDialogState(() => isSaving = true);

                                      AuditLogService.logAction(
                                        actionType: 'PASSWORD_CHANGE',
                                        category: 'Account Modification',
                                        title: 'Password Changed',
                                        description: 'Updated businessman account login password',
                                      );

                                      if (mounted) {
                                        nav.pop();
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Row(
                                              children: const [
                                                Icon(Icons.check_circle_rounded, color: Colors.white),
                                                SizedBox(width: 8),
                                                Expanded(child: Text('Account password updated successfully!')),
                                              ],
                                            ),
                                            backgroundColor: const Color(0xFF0F766E),
                                            behavior: SnackBarBehavior.floating,
                                            margin: const EdgeInsets.all(16),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                        );
                                      }
                                    },
                                    child: isSaving
                                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                        : const Text('Update Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditRestaurantDetailsDialogFor(RestaurantModel rst) {
    final nameCtrl = TextEditingController(text: rst.name);
    final hoursCtrl = TextEditingController(text: rst.operatingHours);
    final addrCtrl = TextEditingController(text: rst.address);

    XFile? bannerFile;
    String activeImageUrl = rst.imageUrl;
    bool isSaving = false;
    final ImagePicker picker = ImagePicker();

    final List<Map<String, String>> presetBanners = [
      {
        'title': 'Noodles & Asian',
        'url': 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?q=80&w=800',
      },
      {
        'title': 'Malay Rice & Lauk',
        'url': 'https://images.unsplash.com/photo-1626777552726-4a6b54c97e46?q=80&w=800',
      },
      {
        'title': 'Mamak & Roti Canai',
        'url': 'https://images.unsplash.com/photo-1565557623262-b51c2513a641?q=80&w=800',
      },
      {
        'title': 'Modern Western Diner',
        'url': 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?q=80&w=800',
      },
      {
        'title': 'Cafe & Bakery',
        'url': 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?q=80&w=800',
      },
      {
        'title': 'Seafood Grill & BBQ',
        'url': 'https://images.unsplash.com/photo-1544025162-d76694265947?q=80&w=800',
      },
    ];

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            Future<void> pickBanner(ImageSource source) async {
              try {
                final XFile? image = await picker.pickImage(
                  source: source,
                  maxWidth: 1920,
                  maxHeight: 1080,
                  imageQuality: 85,
                );
                if (image != null) {
                  setDialogState(() {
                    bannerFile = image;
                  });
                }
              } catch (_) {}
            }

            void showChangeBannerSheet() {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (sheetCtx) {
                  return Container(
                    padding: const EdgeInsets.all(24),
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
                            Icon(Icons.add_a_photo_rounded, color: AppTheme.primaryColor, size: 24),
                            SizedBox(width: 10),
                            Text(
                              'Change Store Cover Banner',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.navyColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Upload a custom storefront photo or choose a preset banner.',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  Navigator.pop(sheetCtx);
                                  pickBanner(ImageSource.camera);
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F766E).withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFF0F766E).withValues(alpha: 0.2)),
                                  ),
                                  child: Column(
                                    children: const [
                                      Icon(Icons.camera_alt_rounded, color: Color(0xFF0F766E), size: 28),
                                      SizedBox(height: 6),
                                      Text('Take Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F766E))),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  Navigator.pop(sheetCtx);
                                  pickBanner(ImageSource.gallery);
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.2)),
                                  ),
                                  child: Column(
                                    children: const [
                                      Icon(Icons.photo_library_rounded, color: Color(0xFF0284C7), size: 28),
                                      SizedBox(height: 6),
                                      Text('Choose Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0284C7))),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const Text('Or Select Preset Banner Gallery:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.navyColor)),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 100,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: presetBanners.length,
                            separatorBuilder: (sCtx, i) => const SizedBox(width: 10),
                            itemBuilder: (sCtx, idx) {
                              final p = presetBanners[idx];
                              return InkWell(
                                onTap: () {
                                  setDialogState(() {
                                    activeImageUrl = p['url']!;
                                    bannerFile = null;
                                  });
                                  Navigator.pop(sheetCtx);
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 130,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: activeImageUrl == p['url'] ? AppTheme.primaryColor : Colors.grey.shade300, width: 2),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.network(p['url']!, fit: BoxFit.cover),
                                        Positioned(
                                          bottom: 4,
                                          left: 4,
                                          right: 4,
                                          child: Text(
                                            p['title']!,
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10, shadows: [Shadow(blurRadius: 4, color: Colors.black)]),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  );
                },
              );
            }

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Banner & Header Image Top Container
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                            child: SizedBox(
                              height: 160,
                              width: double.infinity,
                              child: bannerFile != null
                                  ? Image.file(File(bannerFile!.path), fit: BoxFit.cover)
                                  : Image.network(
                                      activeImageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (ctx, err, stack) => Container(
                                        color: Colors.grey.shade300,
                                        child: const Icon(Icons.storefront, size: 50, color: Colors.grey),
                                      ),
                                    ),
                            ),
                          ),
                          Container(
                            height: 160,
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                              gradient: LinearGradient(
                                colors: [Colors.black.withValues(alpha: 0.75), Colors.transparent],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: IconButton.filledTonal(
                              style: IconButton.styleFrom(backgroundColor: Colors.black45, foregroundColor: Colors.white),
                              icon: const Icon(Icons.close_rounded, size: 20),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ),
                          Positioned(
                            bottom: 12,
                            left: 16,
                            right: 16,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Edit Premises Details',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: AppTheme.navyColor,
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  ),
                                  onPressed: showChangeBannerSheet,
                                  icon: const Icon(Icons.photo_camera_rounded, size: 15, color: AppTheme.primaryColor),
                                  label: const Text('Change Banner', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Form Body
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Restaurant Name
                            TextField(
                              controller: nameCtrl,
                              decoration: InputDecoration(
                                labelText: 'Restaurant Premises Name *',
                                prefixIcon: const Icon(Icons.storefront_rounded, color: AppTheme.primaryColor),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Operating Hours
                            TextField(
                              controller: hoursCtrl,
                              decoration: InputDecoration(
                                labelText: 'Operating Hours *',
                                prefixIcon: const Icon(Icons.access_time_rounded, color: Color(0xFF0F766E)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Address
                            TextField(
                              controller: addrCtrl,
                              decoration: InputDecoration(
                                labelText: 'Premises Address *',
                                prefixIcon: const Icon(Icons.location_on_rounded, color: Color(0xFFD97706)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                              ),
                              maxLines: 2,
                            ),
                            const SizedBox(height: 24),

                            // Action Buttons Row
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: isSaving ? null : () async {
                                      final newName = nameCtrl.text.trim();
                                      final newHours = hoursCtrl.text.trim();
                                      final newAddr = addrCtrl.text.trim();

                                      if (newName.isEmpty) return;

                                      final messenger = ScaffoldMessenger.of(context);
                                      final nav = Navigator.of(ctx);
                                      setDialogState(() => isSaving = true);

                                      // Process image banner encoding if new file was picked
                                      String finalBannerUrl = activeImageUrl;
                                      if (bannerFile != null) {
                                        try {
                                          final bytes = await File(bannerFile!.path).readAsBytes();
                                          finalBannerUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
                                        } catch (_) {
                                          finalBannerUrl = bannerFile!.path;
                                        }
                                      }

                                      // 1. Update in Supabase
                                      try {
                                        await SupabaseService.client.from('restaurants').update({
                                          'name': newName,
                                          'address': newAddr,
                                          'operating_hours': newHours,
                                          'image_url': finalBannerUrl,
                                          'last_updated': DateTime.now().toUtc().toIso8601String(),
                                        }).eq('id', rst.id);
                                      } catch (e) {
                                        if (kDebugMode) print('Supabase edit restaurant error: $e');
                                      }

                                      // 2. Update MockSeedData
                                      final idx = MockSeedData.restaurants.indexWhere((r) => r.id == rst.id);
                                      if (idx != -1) {
                                        MockSeedData.restaurants[idx] = RestaurantModel(
                                          id: rst.id,
                                          name: newName,
                                          address: newAddr,
                                          category: rst.category,
                                          latitude: rst.latitude,
                                          longitude: rst.longitude,
                                          hygieneRiskScore: rst.hygieneRiskScore,
                                          riskCategory: rst.riskCategory,
                                          status: rst.status,
                                          violationCount: rst.violationCount,
                                          imageUrl: finalBannerUrl,
                                          lastUpdated: DateTime.now().toUtc().toIso8601String().split('T').first,
                                          ownerId: rst.ownerId,
                                          ownerName: rst.ownerName,
                                          operatingHours: newHours,
                                          businessRegNo: rst.businessRegNo,
                                        );
                                      }

                                      // 3. Log Audit
                                      AuditLogService.logAction(
                                        actionType: 'REST_UPDATED',
                                        category: 'Business',
                                        title: 'Updated Premises & Banner',
                                        description: 'Updated details and storefront cover banner photo for $newName',
                                      );

                                      if (mounted) {
                                        _loadOwnerRestaurants();
                                        nav.pop();
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Row(
                                              children: const [
                                                Icon(Icons.check_circle_rounded, color: Colors.white),
                                                SizedBox(width: 8),
                                                Expanded(child: Text('Premises details & banner image updated successfully!')),
                                              ],
                                            ),
                                            backgroundColor: const Color(0xFF0F766E),
                                            behavior: SnackBarBehavior.floating,
                                            margin: const EdgeInsets.all(16),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                        );
                                      }
                                    },
                                    child: isSaving
                                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                        : const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
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
          BottomNavigationBarItem(icon: Icon(Icons.storefront_outlined), activeIcon: Icon(Icons.storefront), label: 'My Restaurants'),
          BottomNavigationBarItem(icon: Icon(Icons.business_center_outlined), activeIcon: Icon(Icons.business_center), label: 'Profile'),
        ],
      ),
    );
  }

  String _getTabTitle(int index) {
    switch (index) {
      case 0:
        return 'Dashboard Overview';
      case 1:
        return 'Reviews & Performance';
      case 2:
        return 'Inspection Warnings & Fixes';
      case 3:
        return 'My Restaurants';
      case 4:
        return 'Profile & Settings';
      default:
        return 'Businessman Portal';
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
  // TAB 0: OVERVIEW PANEL (SIMPLE TERMS)
  // ==========================================
  Widget _buildOverviewPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Restaurant Status Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0C2340), Color(0xFF0F766E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0C2340).withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Builder(
              builder: (ctx) {
                final approvedList = _approvedOwnerRestaurants;
                final allOwned = _allMyOwnerRestaurants;
                final bool hasPending = allOwned.any((r) => r.status == RestaurantStatus.pendingVerification || r.status == RestaurantStatus.needsRevision);

                String badgeLabel;
                Color badgeColor;
                IconData badgeIcon;
                String titleText;
                String subtitleText;

                if (approvedList.isNotEmpty) {
                  badgeLabel = 'REGISTERED RESTAURANT';
                  badgeColor = Colors.green.shade600;
                  badgeIcon = Icons.storefront_rounded;
                  titleText = approvedList.first.name;
                  subtitleText = 'Businessman: $_ownerName';
                } else if (hasPending) {
                  badgeLabel = 'PENDING VERIFICATION';
                  badgeColor = const Color(0xFFD97706);
                  badgeIcon = Icons.hourglass_top_rounded;
                  titleText = 'No Approved Restaurant Yet';
                  subtitleText = 'Your restaurant application is pending government review';
                } else {
                  badgeLabel = 'NO RESTAURANT';
                  badgeColor = Colors.grey.shade600;
                  badgeIcon = Icons.storefront_outlined;
                  titleText = 'No Restaurant Registered Yet';
                  subtitleText = 'Tap "Add Restaurant" under My Restaurants to register';
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(badgeIcon, size: 13, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(badgeLabel, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      titleText,
                      style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold, letterSpacing: -0.3),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitleText,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Quick Summary Metrics Grid
          const Text('Quick Summary', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.navyColor)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard('Hygiene Risk', '12.5 (Safe)', 'Low Risk Level', Icons.shield, Colors.green),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricCard('Customer Rating', '4.8 ★', 'Great Rating', Icons.star, Colors.amber),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard('Total Reviews', '128 Reviews', '+12 new this month', Icons.comment, Colors.blue),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricCard('Inspection Notices', '1 Warning', 'Needs photo fix', Icons.warning_amber, Colors.orange),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Quick Action Buttons
          const Text('Quick Actions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.navyColor)),
          const SizedBox(height: 10),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Column(
              children: [
                ListTile(
                  leading: const CircleAvatar(backgroundColor: Color(0xFFE0F2FE), child: Icon(Icons.add_a_photo_outlined, color: Color(0xFF0284C7))),
                  title: const Text('Submit Fix Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Upload photo proof after fixing inspection issues'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.pushNamed(context, AppRoutes.markIssueResolved),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const CircleAvatar(backgroundColor: Color(0xFFDCFCE7), child: Icon(Icons.article_outlined, color: Colors.green)),
                  title: const Text('View Health Report', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('View official government hygiene report'),
                  trailing: const Icon(Icons.chevron_right_rounded),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              CircleAvatar(
                radius: 15,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.navyColor)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(subtext, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: REVIEWS & PERFORMANCE PANEL (ENHANCED QUALITY, TEXTUALIZED & VISUALIZED)
  // ==========================================
  Widget _buildAnalyticsPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Screen Title Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reviews & Ratings',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.navyColor),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Customer ratings, hygiene score & reviews.',
                      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF0F766E).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.insights_rounded, size: 14, color: Color(0xFF0F766E)),
                    SizedBox(width: 4),
                    Text('Grade A Certified', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F766E))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 1. RATING TREND CARD
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.star_rounded, color: Colors.amber, size: 22),
                          SizedBox(width: 8),
                          Text('Customer Rating', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.navyColor)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
                        child: const Text('+14.2% Growth', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: const [
                              Text('Current Month', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                              SizedBox(height: 4),
                              Text('4.8 ★', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                              Text('128 Customer Reviews', style: TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: const [
                              Text('Previous Month', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                              SizedBox(height: 4),
                              Text('4.2 ★', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.amber)),
                              Text('94 Customer Reviews', style: TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Rating Progress & Star Distribution
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text('Rating Improvement: +0.6 Stars', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.navyColor)),
                          Text('96% Satisfaction', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
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
          const SizedBox(height: 18),

          // 2. HYGIENE SCORE SUMMARY (TEXTUALIZED & VISUALIZED FOR BUSINESSMAN)
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: const [
                            Icon(Icons.shield_rounded, color: Color(0xFF0F766E), size: 20),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Hygiene Score Summary',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.navyColor),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFF0F766E).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                        child: const Text('🟢 SAFE & CLEAN', style: TextStyle(color: Color(0xFF0F766E), fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Score Comparison Container
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: const [
                            Text('Current Hygiene Score', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                            SizedBox(height: 4),
                            Text('12.5', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F766E))),
                            Text('SAFE & CLEAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F766E))),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_downward_rounded, color: Colors.green, size: 22),
                        ),
                        Column(
                          children: const [
                            Text('Previous Quarter', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                            SizedBox(height: 4),
                            Text('28.4', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.amber)),
                            Text('MEDIUM RISK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // TEXTUALIZED EXPLANATION BOX (MORE DETAILS FOR BUSINESSMAN)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0C2340).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF0C2340).withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.info_outline_rounded, size: 16, color: AppTheme.navyColor),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Hygiene Audit Summary',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.navyColor),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Your restaurant has a low 12.5 Risk Score (lower score means cleaner & safer). You improved by 15.9 points from last quarter and are among the top 10% cleanest eateries.',
                          style: TextStyle(fontSize: 11.5, color: Colors.grey.shade800, height: 1.45),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // VISUALIZATION 1: CATEGORY RISK FACTOR BAR GAUGES
                  const Text(
                    'Hygiene Score Breakdown',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.navyColor),
                  ),
                  const SizedBox(height: 10),

                  _buildCategoryRiskBar('🧹 Kitchen Cleanliness', 2.5, 25.0, Colors.green),
                  const SizedBox(height: 8),
                  _buildCategoryRiskBar('🪰 Pest Control', 0.0, 25.0, const Color(0xFF0F766E)),
                  const SizedBox(height: 8),
                  _buildCategoryRiskBar('🧊 Food Storage & Temp', 5.0, 25.0, const Color(0xFF0284C7)),
                  const SizedBox(height: 8),
                  _buildCategoryRiskBar('🧯 Waste & Equipment', 5.0, 25.0, Colors.amber),
                  const SizedBox(height: 20),

                  // VISUALIZATION 2: 4-QUARTER HYGIENE RISK TREND BAR GRAPH
                  const Text(
                    '4-Quarter Hygiene Score Trend',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.navyColor),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    height: 150,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildQuarterGraphBar('Q3 2025', 38.2, 50.0, Colors.orange),
                        _buildQuarterGraphBar('Q4 2025', 28.4, 50.0, Colors.amber),
                        _buildQuarterGraphBar('Q1 2026', 18.0, 50.0, const Color(0xFF0284C7)),
                        _buildQuarterGraphBar('Q2 2026', 12.5, 50.0, const Color(0xFF0F766E), isCurrent: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // OFFICIAL RISK BENCHMARK SCALE GUIDE
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: const [
                        Text('🟢 0-20: Safe Level', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                        Text('🟡 21-50: Medium Risk', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber)),
                        Text('🔴 51+: High Risk', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 3. CUSTOMER REVIEWS & COMMENTS SECTION
          const Text('Customer Reviews & Official Responses', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.navyColor)),
          const SizedBox(height: 10),

          ..._ownerReviews.asMap().entries.map((entry) {
            final idx = entry.key;
            final r = entry.value;
            final stars = int.tryParse(r['stars'] ?? '5') ?? 5;

            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                          child: Text(r['userName']![0], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryColor)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r['userName']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.navyColor)),
                              Text(r['date'] ?? '2026-08-01', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                            ],
                          ),
                        ),
                        Row(
                          children: List.generate(5, (s) {
                            return Icon(s < stars ? Icons.star_rounded : Icons.star_border_rounded, color: Colors.amber, size: 16);
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(r['comment']!, style: const TextStyle(fontSize: 12.5, color: Colors.black87, height: 1.35)),

                    // Published Owner Response
                    if (r['ownerReply']!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.reply_rounded, size: 16, color: AppTheme.primaryColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Official Owner Reply: ${r['ownerReply']}',
                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppTheme.navyColor),
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
                        icon: const Icon(Icons.reply_rounded, size: 14),
                        label: Text(r['ownerReply']!.isEmpty ? 'Reply to Customer' : 'Edit Reply', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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

  Widget _buildCategoryRiskBar(String categoryLabel, double pts, double maxPts, Color color) {
    final double fraction = (pts / maxPts).clamp(0.02, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(categoryLabel, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.navyColor)),
            ),
            Text(
              '${pts.toStringAsFixed(1)} / $maxPts pts',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 7,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildQuarterGraphBar(String label, double val, double maxVal, Color color, {bool isCurrent = false}) {
    final double heightFraction = (val / maxVal).clamp(0.1, 1.0);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          val.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isCurrent ? const Color(0xFF0F766E) : AppTheme.navyColor,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 32,
          height: 80 * heightFraction,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isCurrent
                ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6, offset: const Offset(0, 2))]
                : [],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
            color: isCurrent ? const Color(0xFF0F766E) : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 2: NOTICES & WARNINGS PANEL (ENHANCED AUTHORITY CATEGORY UI)
  // ==========================================
  Map<String, dynamic> _getNoticeAuthorityInfo(ComplaintModel c, int index) {
    if (c.severity == SeverityLevel.high || c.category.contains('Pest') || c.category.contains('Poisoning')) {
      return {
        'authorityName': 'Ministry of Health (KKM) & DBKL',
        'badgeLabel': 'Government Directive',
        'icon': Icons.gavel_rounded,
        'color': const Color(0xFF0F766E),
        'typeIndex': 1,
      };
    } else if (c.isFlaggedForReview || c.category.contains('Hygiene') || index % 2 == 1) {
      return {
        'authorityName': 'System Administration Audit',
        'badgeLabel': 'Admin Audit Notice',
        'icon': Icons.admin_panel_settings_rounded,
        'color': const Color(0xFF0C2340),
        'typeIndex': 2,
      };
    } else {
      return {
        'authorityName': 'Public Hygiene Inspection',
        'badgeLabel': 'Public Complaint',
        'icon': Icons.report_problem_rounded,
        'color': const Color(0xFFD97706),
        'typeIndex': 3,
      };
    }
  }

  Widget _buildNoticesPanel() {
    final allComplaints = MockSeedData.complaints;

    // Filter by Active vs Closed
    final activeNotices = allComplaints.where((c) => c.status != ComplaintStatus.resolved && c.status != ComplaintStatus.rejected).toList();
    final closedNotices = allComplaints.where((c) => c.status == ComplaintStatus.resolved || c.status == ComplaintStatus.rejected).toList();

    final currentTabList = _noticeTab == 0 ? activeNotices : closedNotices;

    // Filter by Authority Category Index (_noticeAuthorityIndex)
    final filteredList = currentTabList.where((c) {
      if (_noticeAuthorityIndex == 0) return true;
      final info = _getNoticeAuthorityInfo(c, currentTabList.indexOf(c));
      return info['typeIndex'] == _noticeAuthorityIndex;
    }).toList();

    // Authority Counts for Header Summary
    int govCount = activeNotices.where((c) => _getNoticeAuthorityInfo(c, activeNotices.indexOf(c))['typeIndex'] == 1).length;
    int adminCount = activeNotices.where((c) => _getNoticeAuthorityInfo(c, activeNotices.indexOf(c))['typeIndex'] == 2).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. HERO SUMMARY STATS HEADER
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFF0C2340), Color(0xFF0F766E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0C2340).withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.verified_user_rounded, color: Colors.white, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Health Notices',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white30),
                        ),
                        child: Text(
                          '${activeNotices.length} Active Notices',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.gavel_rounded, color: Color(0xFF5EEAD4), size: 16),
                                  SizedBox(width: 4),
                                  Text('Government', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('$govCount Government Notices', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF93C5FD), size: 16),
                                  SizedBox(width: 4),
                                  Text('Admin Audits', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('$adminCount Admin Notices', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // 2. STATUS TOGGLE TABS (Active Warnings vs Completed Fixes)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _noticeTab = 0),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _noticeTab == 0 ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _noticeTab == 0
                            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                            : [],
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.warning_amber_rounded, size: 16, color: _noticeTab == 0 ? AppTheme.primaryColor : Colors.grey.shade600),
                            const SizedBox(width: 6),
                            Text(
                              'Active Warnings (${activeNotices.length})',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: _noticeTab == 0 ? AppTheme.navyColor : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _noticeTab = 1),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _noticeTab == 1 ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _noticeTab == 1
                            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                            : [],
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, size: 16, color: _noticeTab == 1 ? const Color(0xFF0F766E) : Colors.grey.shade600),
                            const SizedBox(width: 6),
                            Text(
                              'Completed Fixes (${closedNotices.length})',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: _noticeTab == 1 ? AppTheme.navyColor : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 3. AUTHORITY CATEGORY FILTER CHIPS (All, Government, Admin, Complaints)
          const Text('Filter by Authority Source:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.navyColor)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildAuthorityChip(0, 'All Notices', Icons.dashboard_customize_rounded, Colors.grey.shade800),
                const SizedBox(width: 8),
                _buildAuthorityChip(1, '🏛️ Government (KKM/DBKL)', Icons.account_balance_rounded, const Color(0xFF0F766E)),
                const SizedBox(width: 8),
                _buildAuthorityChip(2, '🛡️ Admin Audits', Icons.admin_panel_settings_rounded, const Color(0xFF0C2340)),
                const SizedBox(width: 8),
                _buildAuthorityChip(3, '⚠️ Public Complaints', Icons.report_problem_rounded, const Color(0xFFD97706)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. NOTICE CARDS LIST
          if (filteredList.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(Icons.assignment_turned_in_rounded, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'No notices found for selected authority filter.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredList.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 12),
              itemBuilder: (ctx, index) {
                final c = filteredList[index];
                final info = _getNoticeAuthorityInfo(c, index);
                final daysLeft = (4 - index * 3);

                return _buildEnhancedNoticeCard(c, info, daysLeft);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAuthorityChip(int index, String label, IconData icon, Color color) {
    final isSelected = _noticeAuthorityIndex == index;
    return ChoiceChip(
      showCheckmark: false,
      avatar: Icon(icon, size: 14, color: isSelected ? Colors.white : color),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isSelected ? Colors.white : AppTheme.navyColor,
        ),
      ),
      selected: isSelected,
      selectedColor: color,
      backgroundColor: color.withValues(alpha: 0.08),
      side: BorderSide(color: isSelected ? color : color.withValues(alpha: 0.3)),
      onSelected: (val) {
        if (val) setState(() => _noticeAuthorityIndex = index);
      },
    );
  }

  Widget _buildEnhancedNoticeCard(ComplaintModel c, Map<String, dynamic> info, int daysLeft) {
    final String authorityName = info['authorityName'];
    final IconData authorityIcon = info['icon'];
    final Color authorityColor = info['color'];

    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.noticeDetail, arguments: c);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Authority Issuer Header Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: authorityColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: authorityColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(authorityIcon, size: 14, color: authorityColor),
                      const SizedBox(width: 6),
                      Text(
                        authorityName,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: authorityColor),
                      ),
                    ],
                  ),
                ),
                Text(
                  'ID: ${c.id}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Premise Name
            Row(
              children: [
                Expanded(
                  child: Text(
                    c.restaurantName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.navyColor),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 22),
              ],
            ),
            const SizedBox(height: 4),

            // Category & Issues
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Category: ${c.category}',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Badges Row (Status + Countdown)
            Row(
              children: [
                StatusBadge.fromStatus(c.status.name),
                if (_noticeTab == 0) ...[
                  const SizedBox(width: 8),
                  DeadlineCountdownBadge(daysLeft: daysLeft),
                ],
              ],
            ),
          ],
        ),
      ),
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
                'Request Restaurant Deletion',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.navyColor),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please state the reason for requesting restaurant deletion from system records:'),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'e.g., Outlet closed down / change of location...',
                  border: OutlineInputBorder(),
                ),
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
  // TAB 3: MY RESTAURANTS PANEL (SIMPLE TERMS)
  // ==========================================
  // ==========================================
  // TAB 3: MY RESTAURANTS PANEL (SIMPLE TERMS)
  // ==========================================
  // ==========================================
  // TAB 3: MY RESTAURANTS PANEL (ENHANCED QUALITY)
  // ==========================================
  Widget _buildOutletsPanel() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allList = _fetchedOwnerRestaurants;
    final activeList = allList.where((r) => r.status == RestaurantStatus.approved).toList();
    final pendingList = allList.where((r) => r.status == RestaurantStatus.pendingVerification || r.status == RestaurantStatus.needsRevision).toList();

    List<RestaurantModel> filteredList;
    if (_restaurantFilterIndex == 1) {
      filteredList = activeList;
    } else if (_restaurantFilterIndex == 2) {
      filteredList = pendingList;
    } else {
      filteredList = allList;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Add Restaurant Button
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Registered Restaurants',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.navyColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Manage & monitor hygiene status of your outlets',
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F766E), Color(0xFF0284C7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F766E).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () async {
                      await Navigator.pushNamed(context, AppRoutes.addRestaurant);
                      _loadOwnerRestaurants();
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Icon(Icons.add_rounded, size: 18, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Add Restaurant',
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Custom Category Filter Pills Row (All, Active, Pending)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildRestaurantFilterChip(
                    label: 'All',
                    count: allList.length,
                    index: 0,
                    isSelected: _restaurantFilterIndex == 0,
                    activeColor: const Color(0xFF0F766E),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildRestaurantFilterChip(
                    label: 'Active',
                    count: activeList.length,
                    index: 1,
                    isSelected: _restaurantFilterIndex == 1,
                    activeColor: const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildRestaurantFilterChip(
                    label: 'Pending',
                    count: pendingList.length,
                    index: 2,
                    isSelected: _restaurantFilterIndex == 2,
                    activeColor: const Color(0xFFD97706),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (_isLoadingRestaurants)
            const ListSkeleton(itemCount: 2)
          else if (filteredList.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
              ),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.storefront_outlined, size: 40, color: AppTheme.primaryColor),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _restaurantFilterIndex == 1
                          ? 'No active restaurants found.'
                          : (_restaurantFilterIndex == 2
                              ? 'No pending restaurants found.'
                              : 'No registered restaurants yet.'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.navyColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Click "+ Add Restaurant" above to register your restaurant with health administration.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredList.length,
              itemBuilder: (ctx, idx) {
                final rst = filteredList[idx];
                final bool isApproved = (rst.status == RestaurantStatus.approved);

                final String ssmRegNoDisplay = isApproved
                    ? (rst.businessRegNo ?? 'SSM-2026-${rst.id.replaceAll('rst_', '').padRight(6, '0').substring(0, 6).toUpperCase()}-X')
                    : 'Pending Admin Verification';

                return Container(
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isApproved
                          ? (isDark ? Colors.green.withValues(alpha: 0.3) : const Color(0xFFDCFCE7))
                          : (isDark ? const Color(0xFFD97706).withValues(alpha: 0.3) : const Color(0xFFFEF3C7)),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Restaurant Top Card Header
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isApproved
                                    ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                    : const Color(0xFFD97706).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                isApproved ? Icons.storefront_rounded : Icons.hourglass_top_rounded,
                                color: isApproved ? const Color(0xFF10B981) : const Color(0xFFD97706),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    rst.name,
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : AppTheme.navyColor,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isDark ? Colors.white10 : Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          rst.category,
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.grey.shade700),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Status Pill Tag
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isApproved
                                    ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                    : const Color(0xFFD97706).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isApproved ? const Color(0xFF10B981) : const Color(0xFFD97706),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isApproved ? Icons.verified_rounded : Icons.pending_actions_rounded,
                                    size: 13,
                                    color: isApproved ? const Color(0xFF10B981) : const Color(0xFFD97706),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isApproved ? 'Approved' : 'Pending',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isApproved ? const Color(0xFF10B981) : const Color(0xFFD97706),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey.shade200),

                      // Structured Metric Details Grid
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInfoGridTile(
                                    icon: Icons.badge_outlined,
                                    label: 'SSM Reg No',
                                    value: ssmRegNoDisplay,
                                    isDark: isDark,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildInfoGridTile(
                                    icon: Icons.access_time_rounded,
                                    label: 'Operating Hours',
                                    value: rst.operatingHours,
                                    isDark: isDark,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInfoGridTile(
                                    icon: Icons.location_on_outlined,
                                    label: 'Restaurant Address',
                                    value: rst.address,
                                    isDark: isDark,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildInfoGridTile(
                                    icon: Icons.health_and_safety_outlined,
                                    label: 'Health Grade',
                                    value: isApproved ? 'Grade A (Safe Risk)' : 'Pending Rating',
                                    valueColor: isApproved ? Colors.green : const Color(0xFFD97706),
                                    isDark: isDark,
                                  ),
                                ),
                              ],
                            ),

                            if (!isApproved) ...[
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD97706).withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.2)),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 18),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Your restaurant application is under review by MOH Health Admins. SSM reg number will be assigned upon approval.',
                                        style: TextStyle(fontSize: 11, color: Color(0xFFD97706), height: 1.3),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            if (isApproved) ...[
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: AppTheme.primaryColor),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      onPressed: () => _showEditRestaurantDetailsDialogFor(rst),
                                      icon: const Icon(Icons.edit_outlined, size: 16, color: AppTheme.primaryColor),
                                      label: const Text('Edit Details', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
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
                                      icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                                      label: const Text('Delete Request', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRestaurantFilterChip({
    required String label,
    required int count,
    required int index,
    required bool isSelected,
    Color activeColor = AppTheme.primaryColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        setState(() {
          _restaurantFilterIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.25) : (isDark ? Colors.white12 : Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoGridTile({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: isDark ? Colors.white60 : Colors.grey.shade600),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey.shade600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: valueColor ?? (isDark ? Colors.white : AppTheme.navyColor),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 4: PROFILE & SETTINGS (SIMPLE TERMS)
  // ==========================================
  Widget _buildProfilePanel() {
    final customer = CustomerStoreService.currentCustomer;
    final displayName = _ownerName.isNotEmpty ? _ownerName : (customer?.name ?? 'Businessman Account');
    final displayEmail = _ownerEmail.isNotEmpty ? _ownerEmail : (customer?.email ?? 'owner@restaurant.com');
    final avatarUrl = customer?.avatarUrl ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=200';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Profile Banner Card
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFF0C2340), Color(0xFF0F766E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0C2340).withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF80EE98), width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 34,
                          backgroundColor: Colors.white24,
                          backgroundImage: NetworkImage(avatarUrl),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF80EE98).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF80EE98), width: 0.8),
                              ),
                              child: const Text(
                                'Businessman Account',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF80EE98),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.email_outlined, size: 13, color: Colors.white70),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    displayEmail,
                                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Business Summary Bar
          Row(
            children: [
              _buildMetricStatCard('My Restaurants', '${_myRegisteredRestaurants.length} Active', Icons.storefront, const Color(0xFF0F766E)),
              const SizedBox(width: 10),
              _buildMetricStatCard('Health Grade', 'Grade A', Icons.verified_user, const Color(0xFF10B981)),
              const SizedBox(width: 10),
              _buildMetricStatCard('Warnings', '0 Pending', Icons.assignment_turned_in, const Color(0xFFD97706)),
            ],
          ),
          const SizedBox(height: 16),

          // Settings List Tiles
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildActionTile(
                  icon: Icons.manage_accounts_outlined,
                  iconColor: const Color(0xFF0F766E),
                  title: 'Edit Profile Details',
                  subtitle: 'Name, email, phone & location',
                  onTap: _showEditProfileDetailsDialog,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildActionTile(
                  icon: Icons.lock_reset_outlined,
                  iconColor: const Color(0xFFD97706),
                  title: 'Change Password',
                  subtitle: 'Update your account login password',
                  onTap: _showChangePasswordDialog,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.notifications_active_outlined, color: Color(0xFF10B981), size: 20),
                  ),
                  title: const Text('Notifications & SMS Alerts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Receive instant alerts for inspection warnings', style: TextStyle(fontSize: 12)),
                  trailing: Switch(
                    value: true,
                    onChanged: (val) {},
                    activeThumbColor: const Color(0xFF0F766E),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Log Out Button
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                CustomerStoreService.logout();
                Navigator.pushNamedAndRemoveUntil(context, AppRoutes.splashRoleSelect, (route) => false);
              },
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: const Text('Log Out Account', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMetricStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
            Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }
}
