import 'package:flutter/material.dart';
import '../../core/services/customer_store_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/custom_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late String _selectedGender;
  late String _selectedCountry;
  late TextEditingController _stateCtrl;

  late String _avatarUrl;
  bool _isSaving = false;

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  final List<String> _countryOptions = ['Malaysia 🇲🇾', 'Singapore 🇸🇬', 'Indonesia 🇮🇩', 'Thailand 🇹🇭', 'United States 🇺🇸', 'Other'];

  final List<String> _presetAvatars = [
    'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=200',
    'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?q=80&w=200',
    'https://images.unsplash.com/photo-1580489944761-15a19d654956?q=80&w=200',
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=200',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=200',
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=200',
  ];

  @override
  void initState() {
    super.initState();
    final customer = CustomerStoreService.currentCustomer;
    _nameCtrl = TextEditingController(text: customer?.name ?? '');
    _emailCtrl = TextEditingController(text: customer?.email ?? '');
    _phoneCtrl = TextEditingController(text: customer?.phone ?? '');
    _selectedGender = (customer?.gender != null && _genderOptions.contains(customer!.gender)) ? customer.gender! : 'Male';
    _selectedCountry = (customer?.country != null && _countryOptions.contains(customer!.country)) ? customer.country! : 'Malaysia 🇲🇾';
    _stateCtrl = TextEditingController(text: customer?.state ?? '');
    _avatarUrl = customer?.avatarUrl ?? _presetAvatars.first;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _stateCtrl.dispose();
    super.dispose();
  }

  void _showAvatarPickerModal() {
    final customUrlCtrl = TextEditingController(text: _avatarUrl);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
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
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add_a_photo_rounded, color: AppTheme.primaryColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Change Profile Picture',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.navyColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Select Curated Avatar:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 70,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _presetAvatars.length,
                      separatorBuilder: (ctx, idx) => const SizedBox(width: 12),
                      itemBuilder: (ctx, idx) {
                        final url = _presetAvatars[idx];
                        final isSelected = (_avatarUrl == url);
                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              _avatarUrl = url;
                              customUrlCtrl.text = url;
                            });
                            setState(() {
                              _avatarUrl = url;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                                width: 3,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 28,
                              backgroundImage: NetworkImage(url),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Or Enter Custom Image URL:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: customUrlCtrl,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'https://example.com/avatar.jpg',
                      prefixIcon: const Icon(Icons.link_rounded, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        if (customUrlCtrl.text.trim().isNotEmpty) {
                          setState(() {
                            _avatarUrl = customUrlCtrl.text.trim();
                          });
                        }
                        Navigator.pop(ctx);
                      },
                      child: const Text('Apply Avatar Selection', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Edit Profile Details'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dynamic Interactive Profile Avatar with Camera Button
            Center(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: _showAvatarPickerModal,
                    child: CircleAvatar(
                      radius: 54,
                      backgroundColor: const Color(0xFF0284C7).withValues(alpha: 0.15),
                      backgroundImage: NetworkImage(_avatarUrl),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppTheme.primaryColor,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                        padding: EdgeInsets.zero,
                        onPressed: _showAvatarPickerModal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Full Name
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Full Name',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 16),

            // Email Address (Registered)
            TextField(
              controller: _emailCtrl,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Email Address (Registered)',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade100,
              ),
            ),
            const SizedBox(height: 16),

            // Phone Number
            TextField(
              controller: _phoneCtrl,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: const Icon(Icons.phone_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 16),

            // Gender Selector
            DropdownButtonFormField<String>(
              initialValue: _selectedGender,
              decoration: InputDecoration(
                labelText: 'Gender',
                prefixIcon: const Icon(Icons.wc_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
              ),
              items: _genderOptions.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedGender = val);
              },
            ),
            const SizedBox(height: 16),

            // Country Selector
            DropdownButtonFormField<String>(
              initialValue: _selectedCountry,
              decoration: InputDecoration(
                labelText: 'Country / Region',
                prefixIcon: const Icon(Icons.public_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
              ),
              items: _countryOptions.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedCountry = val);
              },
            ),
            const SizedBox(height: 16),

            // State / City
            TextField(
              controller: _stateCtrl,
              decoration: InputDecoration(
                labelText: 'State / City',
                prefixIcon: const Icon(Icons.location_city_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 28),

            CustomButton(
              label: _isSaving ? 'Saving...' : 'Save Profile Changes',
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final nav = Navigator.of(context);

                setState(() => _isSaving = true);
                await CustomerStoreService.updateCustomerProfile(
                  name: _nameCtrl.text.trim(),
                  phone: _phoneCtrl.text.trim(),
                  gender: _selectedGender,
                  country: _selectedCountry,
                  state: _stateCtrl.text.trim(),
                  avatarUrl: _avatarUrl,
                );

                if (!mounted) return;
                setState(() => _isSaving = false);
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Profile details updated successfully!'),
                    backgroundColor: AppTheme.primaryColor,
                  ),
                );
                nav.pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
