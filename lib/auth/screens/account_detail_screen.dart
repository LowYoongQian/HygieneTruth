import '../../core/services/customer_store_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/models/user_model.dart';
import '../../core/services/audit_log_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/custom_button.dart';
import '../widgets/role_badge.dart';

class AccountDetailScreen extends StatefulWidget {
  const AccountDetailScreen({super.key});

  @override
  State<AccountDetailScreen> createState() => _AccountDetailScreenState();
}

class _AccountDetailScreenState extends State<AccountDetailScreen> {
  late UserModel _selectedUser;
  late UserRole _selectedRole;
  late AccountStatus _selectedStatus;

  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;

  String? _selectedGender;
  String? _selectedCountry;
  String? _selectedState;

  final TextEditingController _customGenderCtrl = TextEditingController();
  final TextEditingController _customCountryCtrl = TextEditingController();
  final TextEditingController _customStateCtrl = TextEditingController();

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is UserModel) {
        _selectedUser = args;
      } else {
        _selectedUser = CustomerStoreService.getAllRegisteredCustomers().first;
      }

      _nameCtrl = TextEditingController(text: _selectedUser.name);
      _emailCtrl = TextEditingController(text: _selectedUser.email);
      _phoneCtrl = TextEditingController(text: _selectedUser.phone ?? '');

      _selectedRole = _selectedUser.role == UserRole.admin ? UserRole.user : _selectedUser.role;
      _selectedStatus = _selectedUser.status;

      _selectedGender = _selectedUser.gender;
      _selectedCountry = _selectedUser.country;
      _selectedState = _selectedUser.state;

      _initialized = true;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _customGenderCtrl.dispose();
    _customCountryCtrl.dispose();
    _customStateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const CustomAppBar(title: 'User Profile & Admin Controls'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Avatar Banner Header
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primaryColor, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundImage: NetworkImage(_selectedUser.avatarUrl),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _nameCtrl.text.isNotEmpty ? _nameCtrl.text : _selectedUser.name,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.navyColor),
                  ),
                  Text(
                    _emailCtrl.text.isNotEmpty ? _emailCtrl.text : _selectedUser.email,
                    style: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  RoleBadge(role: _selectedRole),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section Header: Edit User Information
            Row(
              children: [
                const Icon(Icons.edit_note_rounded, color: AppTheme.primaryColor, size: 22),
                const SizedBox(width: 8),
                Text('Modify User Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : AppTheme.navyColor)),
              ],
            ),
            const SizedBox(height: 12),

            // Profile Fields Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Full Name
                    TextField(
                      controller: _nameCtrl,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: const Icon(Icons.person_outline, size: 20),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade300)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Email Address
                    TextField(
                      controller: _emailCtrl,
                      onChanged: (_) => setState(() {}),
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: const Icon(Icons.email_outlined, size: 20),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade300)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Phone Number
                    TextField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade300)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Gender Dropdown
                    const Text('Gender', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.navyColor)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: ['Male', 'Female', 'Other'].contains(_selectedGender) ? _selectedGender : (_selectedGender != null ? 'Other' : null),
                      borderRadius: BorderRadius.circular(16),
                      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      menuMaxHeight: 280,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primaryColor),
                      decoration: InputDecoration(
                        hintText: 'Select Gender',
                        prefixIcon: const Icon(Icons.wc_rounded, size: 20),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade300)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      items: ['Male', 'Female', 'Other'].map((g) {
                        return DropdownMenuItem(
                          value: g,
                          child: Text(g, style: TextStyle(fontWeight: FontWeight.w500, color: isDark ? Colors.white : Colors.black87)),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedGender = val),
                    ),
                    if (_selectedGender == 'Other') ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: _customGenderCtrl,
                        decoration: InputDecoration(
                          hintText: 'Specify gender...',
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade300)),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Country Dropdown
                    const Text('Country / Region', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.navyColor)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: ['Malaysia', 'Singapore', 'Indonesia', 'Thailand', 'Other'].contains(_selectedCountry) ? _selectedCountry : (_selectedCountry != null ? 'Other' : null),
                      borderRadius: BorderRadius.circular(16),
                      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      menuMaxHeight: 280,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primaryColor),
                      decoration: InputDecoration(
                        hintText: 'Select Country',
                        prefixIcon: const Icon(Icons.public_rounded, size: 20),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade300)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      items: ['Malaysia', 'Singapore', 'Indonesia', 'Thailand', 'Other'].map((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Text(c, style: TextStyle(fontWeight: FontWeight.w500, color: isDark ? Colors.white : Colors.black87)),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedCountry = val),
                    ),
                    if (_selectedCountry == 'Other') ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: _customCountryCtrl,
                        decoration: InputDecoration(
                          hintText: 'Enter country name...',
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade300)),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // State Dropdown
                    const Text('State / City', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.navyColor)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: ['Kuala Lumpur', 'Selangor', 'Johor', 'Penang', 'Perak', 'Sabah', 'Sarawak', 'Other'].contains(_selectedState) ? _selectedState : (_selectedState != null ? 'Other' : null),
                      borderRadius: BorderRadius.circular(16),
                      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      menuMaxHeight: 280,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primaryColor),
                      decoration: InputDecoration(
                        hintText: 'Select State / City',
                        prefixIcon: const Icon(Icons.location_city_rounded, size: 20),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade300)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      items: ['Kuala Lumpur', 'Selangor', 'Johor', 'Penang', 'Perak', 'Sabah', 'Sarawak', 'Other'].map((s) {
                        return DropdownMenuItem(
                          value: s,
                          child: Text(s, style: TextStyle(fontWeight: FontWeight.w500, color: isDark ? Colors.white : Colors.black87)),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedState = val),
                    ),
                    if (_selectedState == 'Other') ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: _customStateCtrl,
                        decoration: InputDecoration(
                          hintText: 'Enter state or city name...',
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade300)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Section Header: Admin Role & Status Controls
            Row(
              children: [
                const Icon(Icons.admin_panel_settings_outlined, color: Color(0xFFD97706), size: 22),
                const SizedBox(width: 8),
                Text('Admin Access & Role Controls', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : AppTheme.navyColor)),
              ],
            ),
            const SizedBox(height: 12),

            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Assign User Role', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<UserRole>(
                      isExpanded: true,
                      initialValue: _selectedRole,
                      borderRadius: BorderRadius.circular(16),
                      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      menuMaxHeight: 280,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primaryColor),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade300)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      // Exclude ADMIN role from assignable options
                      items: [UserRole.user, UserRole.owner, UserRole.government].map((r) {
                        String label = 'CUSTOMER';
                        if (r == UserRole.owner) label = 'BUSINESSMAN';
                        if (r == UserRole.government) label = 'GOVERNMENT OFFICIAL';
                        return DropdownMenuItem(value: r, child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedRole = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Account Status', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<AccountStatus>(
                      isExpanded: true,
                      initialValue: _selectedStatus,
                      borderRadius: BorderRadius.circular(16),
                      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      menuMaxHeight: 280,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primaryColor),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.verified_user_outlined, size: 20),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade300)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      items: AccountStatus.values.map((s) {
                        return DropdownMenuItem(value: s, child: Text(s.name.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedStatus = val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            CustomButton(
              label: 'Save Changes',
              icon: Icons.save_rounded,
              backgroundColor: Colors.green.shade700,
              onPressed: () async {
                final name = _nameCtrl.text.trim();
                final email = _emailCtrl.text.trim();
                final phone = _phoneCtrl.text.trim();

                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Name cannot be empty!'), backgroundColor: Colors.red),
                  );
                  return;
                }

                final finalGender = _selectedGender == 'Other' ? _customGenderCtrl.text.trim() : _selectedGender;
                final finalCountry = _selectedCountry == 'Other' ? _customCountryCtrl.text.trim() : _selectedCountry;
                final finalState = _selectedState == 'Other' ? _customStateCtrl.text.trim() : _selectedState;

                final dbRole = _selectedRole == UserRole.owner
                    ? 'businessman'
                    : (_selectedRole == UserRole.government ? 'government' : 'customer');
                final dbStatus = _selectedStatus.name;

                try {
                  await SupabaseService.client
                      .from('users')
                      .update({
                        'name': name,
                        'email': email.toLowerCase(),
                        'phone': phone,
                        'gender': finalGender,
                        'country': finalCountry,
                        'state': finalState,
                        'role': dbRole,
                        'status': dbStatus,
                      })
                      .eq('id', _selectedUser.id);

                  AuditLogService.logAction(
                    actionType: 'ADMIN_USER_EDIT',
                    category: 'Admin',
                    title: 'Admin User Profile Updated',
                    description: 'Admin updated account details and role ($dbRole) for $email',
                  );
                } catch (e) {
                  if (kDebugMode) print('Error updating user in Supabase: $e');
                }

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$name profile & controls updated successfully!'), backgroundColor: Colors.green),
                  );
                  Navigator.pop(context);
                }
              },
            ),
            const SizedBox(height: 10),
            CustomButton(
              label: 'Suspend User',
              icon: Icons.block_rounded,
              backgroundColor: Colors.red.shade700,
              onPressed: () async {
                try {
                  await SupabaseService.client
                      .from('users')
                      .update({'status': 'suspended'})
                      .eq('id', _selectedUser.id);

                  AuditLogService.logAction(
                    actionType: 'ADMIN_USER_SUSPEND',
                    category: 'Admin',
                    title: 'Admin Suspended Account',
                    description: 'Admin suspended user account ${_selectedUser.email}',
                  );
                } catch (e) {
                  if (kDebugMode) print('Error suspending user in Supabase: $e');
                }

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${_selectedUser.name} suspended.'), backgroundColor: Colors.red),
                  );
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
