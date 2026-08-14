import 'package:flutter/material.dart';
import '../../core/services/customer_store_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_app_bar.dart';

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
  late String _selectedState;

  late String _avatarUrl;
  bool _isSaving = false;

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  final List<String> _countryOptions = ['Malaysia 🇲🇾', 'Singapore 🇸🇬', 'Indonesia 🇮🇩', 'Thailand 🇹🇭', 'United States 🇺🇸', 'Other'];

  final Map<String, List<String>> _countryStatesMap = {
    'Malaysia 🇲🇾': [
      'Kuala Lumpur',
      'Selangor',
      'Penang',
      'Johor',
      'Perak',
      'Melaka',
      'Kedah',
      'Pahang',
      'Negeri Sembilan',
      'Sabah',
      'Sarawak',
      'Kelantan',
      'Terengganu',
      'Perlis',
      'Putrajaya',
      'Labuan',
    ],
    'Singapore 🇸🇬': [
      'Central Region',
      'East Region',
      'North Region',
      'North-East Region',
      'West Region',
    ],
    'Indonesia 🇮🇩': [
      'Jakarta',
      'West Java (Bandung)',
      'Central Java (Semarang)',
      'East Java (Surabaya)',
      'Bali (Denpasar)',
      'North Sumatra (Medan)',
      'Banten',
      'Yogyakarta',
      'Riau',
      'South Sulawesi',
    ],
    'Thailand 🇹🇭': [
      'Bangkok',
      'Chiang Mai',
      'Phuket',
      'Chonburi (Pattaya)',
      'Nonthaburi',
      'Surat Thani (Koh Samui)',
      'Krabi',
      'Khon Kaen',
    ],
    'United States 🇺🇸': [
      'California',
      'New York',
      'Texas',
      'Florida',
      'Washington',
      'Illinois',
      'Massachusetts',
      'Nevada',
      'Georgia',
      'Hawaii',
    ],
    'Other': [
      'Other / International',
    ],
  };

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

    final availableStates = _countryStatesMap[_selectedCountry] ?? _countryStatesMap['Malaysia 🇲🇾']!;
    final customerState = customer?.state?.trim();
    if (customerState != null && customerState.isNotEmpty && availableStates.contains(customerState)) {
      _selectedState = customerState;
    } else {
      _selectedState = availableStates.first;
    }

    _avatarUrl = customer?.avatarUrl ?? _presetAvatars.first;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
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
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      prefixIcon: const Icon(Icons.link_rounded, size: 20, color: AppTheme.primaryColor),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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

    InputDecoration buildInputDecoration({
      required String label,
      required IconData icon,
      bool isReadOnly = false,
      Widget? suffixIcon,
    }) {
      return InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: 13.5,
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
        ),
        prefixIcon: Icon(icon, color: AppTheme.primaryColor, size: 22),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isReadOnly
            ? (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade100)
            : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade50),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppTheme.primaryColor,
            width: 1.8,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(title: 'Edit Profile Details'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dynamic Interactive Profile Avatar with Camera Button
            Center(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: _showAvatarPickerModal,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.25),
                          width: 3.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 54,
                        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
                        backgroundImage: NetworkImage(_avatarUrl),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: AppTheme.primaryColor,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt_rounded, size: 17, color: Colors.white),
                          padding: EdgeInsets.zero,
                          onPressed: _showAvatarPickerModal,
                        ),
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
              decoration: buildInputDecoration(
                label: 'Full Name',
                icon: Icons.person_outline_rounded,
              ),
            ),
            const SizedBox(height: 16),

            // Email Address (Registered)
            TextField(
              controller: _emailCtrl,
              readOnly: true,
              decoration: buildInputDecoration(
                label: 'Email Address (Registered)',
                icon: Icons.email_outlined,
                isReadOnly: true,
                suffixIcon: const Icon(Icons.lock_outline_rounded, size: 18, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),

            // Phone Number
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: buildInputDecoration(
                label: 'Phone Number',
                icon: Icons.phone_outlined,
              ),
            ),
            const SizedBox(height: 16),

            // Gender Selector
            DropdownButtonFormField<String>(
              initialValue: _selectedGender,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primaryColor, size: 24),
              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              elevation: 4,
              menuMaxHeight: 260,
              isExpanded: true,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              decoration: buildInputDecoration(
                label: 'Gender',
                icon: Icons.wc_outlined,
              ),
              selectedItemBuilder: (BuildContext context) {
                return _genderOptions.map((g) {
                  IconData gIcon;
                  Color gIconColor;
                  if (g == 'Male') {
                    gIcon = Icons.male_rounded;
                    gIconColor = AppTheme.primaryColor;
                  } else if (g == 'Female') {
                    gIcon = Icons.female_rounded;
                    gIconColor = const Color(0xFFEC4899);
                  } else {
                    gIcon = Icons.transgender_rounded;
                    gIconColor = const Color(0xFF8B5CF6);
                  }
                  return Row(
                    children: [
                      Icon(gIcon, size: 20, color: gIconColor),
                      const SizedBox(width: 10),
                      Text(
                        g,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  );
                }).toList();
              },
              items: _genderOptions.map((g) {
                final isSelected = (_selectedGender == g);
                IconData gIcon;
                Color gIconColor;
                if (g == 'Male') {
                  gIcon = Icons.male_rounded;
                  gIconColor = AppTheme.primaryColor;
                } else if (g == 'Female') {
                  gIcon = Icons.female_rounded;
                  gIconColor = const Color(0xFFEC4899);
                } else {
                  gIcon = Icons.transgender_rounded;
                  gIconColor = const Color(0xFF8B5CF6);
                }

                return DropdownMenuItem(
                  value: g,
                  child: Row(
                    children: [
                      Icon(gIcon, size: 20, color: gIconColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          g,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_rounded, size: 18, color: AppTheme.primaryColor),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedGender = val);
              },
            ),
            const SizedBox(height: 16),

            // Country Selector
            DropdownButtonFormField<String>(
              initialValue: _selectedCountry,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primaryColor, size: 24),
              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              elevation: 4,
              menuMaxHeight: 280,
              isExpanded: true,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              decoration: buildInputDecoration(
                label: 'Country / Region',
                icon: Icons.public_outlined,
              ),
              selectedItemBuilder: (BuildContext context) {
                return _countryOptions.map((c) {
                  return Row(
                    children: [
                      Text(
                        c,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  );
                }).toList();
              },
              items: _countryOptions.map((c) {
                final isSelected = (_selectedCountry == c);
                return DropdownMenuItem(
                  value: c,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          c,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_rounded, size: 18, color: AppTheme.primaryColor),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedCountry = val;
                    final availableStates = _countryStatesMap[_selectedCountry] ?? ['Other / International'];
                    if (!availableStates.contains(_selectedState)) {
                      _selectedState = availableStates.first;
                    }
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // State / Region Dropdown Selector
            DropdownButtonFormField<String>(
              key: ValueKey('state_dropdown_$_selectedCountry'),
              initialValue: _selectedState,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primaryColor, size: 24),
              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              elevation: 4,
              menuMaxHeight: 280,
              isExpanded: true,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              decoration: buildInputDecoration(
                label: 'State / Region',
                icon: Icons.location_city_outlined,
              ),
              selectedItemBuilder: (BuildContext context) {
                final states = _countryStatesMap[_selectedCountry] ?? ['Other / International'];
                return states.map((s) {
                  return Row(
                    children: [
                      Text(
                        s,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  );
                }).toList();
              },
              items: (_countryStatesMap[_selectedCountry] ?? ['Other / International']).map((s) {
                final isSelected = (_selectedState == s);
                return DropdownMenuItem(
                  value: s,
                  child: Row(
                    children: [
                      const Icon(Icons.pin_drop_outlined, size: 18, color: AppTheme.primaryColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          s,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_rounded, size: 18, color: AppTheme.primaryColor),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedState = val);
              },
            ),
            const SizedBox(height: 28),

            // Primary Save Changes Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                onPressed: _isSaving
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final nav = Navigator.of(context);

                        setState(() => _isSaving = true);
                        await CustomerStoreService.updateCustomerProfile(
                          name: _nameCtrl.text.trim(),
                          phone: _phoneCtrl.text.trim(),
                          gender: _selectedGender,
                          country: _selectedCountry,
                          state: _selectedState,
                          avatarUrl: _avatarUrl,
                        );

                        if (!mounted) return;
                        setState(() => _isSaving = false);
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Profile details updated successfully!'),
                            backgroundColor: AppTheme.primaryColor,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        nav.pop();
                      },
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                      )
                    : const Text(
                        'Save Profile Changes',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
