import 'package:flutter/material.dart';
import '../../core/services/customer_store_service.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/custom_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late String _selectedGender;
  late String _selectedCountry;
  late TextEditingController _stateCtrl;

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  final List<String> _countryOptions = ['Malaysia 🇲🇾', 'Singapore 🇸🇬', 'Indonesia 🇮🇩', 'Thailand 🇹🇭', 'United States 🇺🇸', 'Other'];

  @override
  void initState() {
    super.initState();
    final customer = CustomerStoreService.currentCustomer;
    _nameCtrl = TextEditingController(text: customer?.name ?? '');
    _phoneCtrl = TextEditingController(text: customer?.phone ?? '');
    _selectedGender = (customer?.gender != null && _genderOptions.contains(customer!.gender)) ? customer.gender! : 'Male';
    _selectedCountry = (customer?.country != null && _countryOptions.contains(customer!.country)) ? customer.country! : 'Malaysia 🇲🇾';
    _stateCtrl = TextEditingController(text: customer?.state ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _stateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Edit Profile Details'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: const Color(0xFF0284C7).withValues(alpha: 0.15),
                    backgroundImage: NetworkImage(CustomerStoreService.currentCustomer?.avatarUrl ?? 'https://i.pravatar.cc/150?img=1'),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFF00A88F),
                      child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
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
              ),
            ),
            const SizedBox(height: 28),

            CustomButton(
              label: 'Save Profile Changes',
              onPressed: () {
                CustomerStoreService.updateCustomerProfile(
                  name: _nameCtrl.text.trim(),
                  phone: _phoneCtrl.text.trim(),
                  gender: _selectedGender,
                  country: _selectedCountry,
                  state: _stateCtrl.text.trim(),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile details updated successfully!')),
                );
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
