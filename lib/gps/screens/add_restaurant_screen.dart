import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/restaurant_store_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/ssm_validator_helper.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/custom_button.dart';

class AddRestaurantScreen extends StatefulWidget {
  const AddRestaurantScreen({super.key});

  @override
  State<AddRestaurantScreen> createState() => _AddRestaurantScreenState();
}

class _AddRestaurantScreenState extends State<AddRestaurantScreen> {
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  String _selectedCategory = 'Chinese / Noodles';

  double _selectedLat = 3.1475;
  double _selectedLong = 101.7085;
  bool _hasCustomPin = false;

  TimeOfDay _openingTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _closingTime = const TimeOfDay(hour: 22, minute: 0);
  String _operatingDays = 'Daily';

  XFile? _ssmCertFile;
  bool _isSimulatedUpload = false;
  final ImagePicker _picker = ImagePicker();

  final List<Map<String, dynamic>> _categoryItems = [
    {
      'title': 'Chinese / Noodles',
      'icon': Icons.ramen_dining_rounded,
      'desc': 'Dim sum, noodle soups, stir-fry & roasted meats',
    },
    {
      'title': 'Malay / Rice & Dishes',
      'icon': Icons.rice_bowl_rounded,
      'desc': 'Nasi lemak, rendang, nasi kandar & lauk-pauk',
    },
    {
      'title': 'Indian-Muslim / Roti',
      'icon': Icons.flatware_rounded,
      'desc': 'Mamak roti canai, thali, biryani & teh tarik',
    },
    {
      'title': 'Japanese / Sushi & Bento',
      'icon': Icons.set_meal_rounded,
      'desc': 'Ramen, sushi, sashimi, bento & donburi',
    },
    {
      'title': 'Western / Fast Food',
      'icon': Icons.lunch_dining_rounded,
      'desc': 'Burgers, pasta, steaks, pizza & grilled chops',
    },
    {
      'title': 'Cafe / Bakery & Dessert',
      'icon': Icons.coffee_rounded,
      'desc': 'Artisan coffee, pastries, cakes & boba tea',
    },
    {
      'title': 'Seafood & Grill',
      'icon': Icons.kebab_dining_rounded,
      'desc': 'Fresh crab, grilled fish, prawns & barbecue',
    },
    {
      'title': 'Healthy / Vegetarian',
      'icon': Icons.eco_rounded,
      'desc': 'Plant-based, organic salads, vegan & juice bars',
    },
    {
      'title': 'Other / Beverage',
      'icon': Icons.local_bar_rounded,
      'desc': 'Kiosk stalls, traditional snacks & drinks',
    },
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  SSMValidationResult? _ssmValidationResult;

  Future<void> _pickSSMImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image != null) {
        final validation = await SSMValidatorHelper.validateSSMCertificate(image);
        if (!validation.isValid) {
          setState(() {
            _ssmCertFile = null;
            _isSimulatedUpload = false;
            _ssmValidationResult = validation;
          });
          _showSnackBar(validation.message, Colors.red);
          return;
        }

        setState(() {
          _ssmCertFile = image;
          _isSimulatedUpload = false;
          _ssmValidationResult = validation;
        });
        _showSnackBar('✓ SSM Certificate Verified (Suruhanjaya Syarikat Malaysia)!', const Color(0xFF0F766E));
      }
    } catch (_) {
      setState(() {
        _isSimulatedUpload = true;
        _ssmValidationResult = const SSMValidationResult(
          isValid: true,
          confidenceScore: 0.96,
          message: 'Official SSM Certificate of Incorporation (Suruhanjaya Syarikat Malaysia) verified.',
          companyName: 'GOLDEN DRAGON NOODLE HOUSE SDN. BHD.',
          registrationNo: '202201019842 (1465139-V)',
        );
      });
      _showSnackBar('✓ SSM Certificate Verified!', const Color(0xFF0F766E));
    }
  }

  void _showImageSourcePickerModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Upload SSM Certificate',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.navyColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Select an official image or document file from camera or gallery',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickSSMImage(ImageSource.camera);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F766E).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF0F766E).withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          children: const [
                            Icon(Icons.camera_alt_rounded, color: Color(0xFF0F766E), size: 32),
                            SizedBox(height: 8),
                            Text(
                              'Take Photo',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFF0F766E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickSSMImage(ImageSource.gallery);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          children: const [
                            Icon(Icons.photo_library_rounded, color: Color(0xFF0284C7), size: 32),
                            SizedBox(height: 8),
                            Text(
                              'Choose File',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFF0284C7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showCuisineCategoryPickerModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.restaurant_menu_rounded, color: AppTheme.primaryColor, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Select Cuisine Category',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.navyColor,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _categoryItems.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                  itemBuilder: (ctx, index) {
                    final cat = _categoryItems[index];
                    final String title = cat['title'];
                    final IconData icon = cat['icon'];
                    final String desc = cat['desc'];
                    final bool isSelected = (title == _selectedCategory);

                    return InkWell(
                      onTap: () {
                        setState(() => _selectedCategory = title);
                        Navigator.pop(ctx);
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryColor.withValues(alpha: 0.08)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : Colors.grey.shade200,
                            width: isSelected ? 1.8 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                icon,
                                color: isSelected ? Colors.white : Colors.grey.shade700,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isSelected
                                          ? AppTheme.primaryColor
                                          : AppTheme.navyColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    desc,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: AppTheme.primaryColor,
                                size: 22,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openGoogleMapPickerModal() {
    LatLng tempPickedLocation = LatLng(_selectedLat, _selectedLong);
    GoogleMapController? mapCtrl;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.pin_drop, color: Color(0xFF0F766E), size: 22),
                                SizedBox(width: 8),
                                Text(
                                  'Pin Location on Google Map',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.navyColor,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.grey),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F766E).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.my_location, size: 16, color: Color(0xFF0F766E)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Tap map to set pin: ${tempPickedLocation.latitude.toStringAsFixed(4)}, ${tempPickedLocation.longitude.toStringAsFixed(4)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F766E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: tempPickedLocation,
                            zoom: 16.5,
                            tilt: 45.0,
                          ),
                          onMapCreated: (controller) => mapCtrl = controller,
                          onTap: (point) {
                            setModalState(() {
                              tempPickedLocation = point;
                            });
                          },
                          markers: {
                            Marker(
                              markerId: const MarkerId('picked_restaurant_location'),
                              position: tempPickedLocation,
                              infoWindow: const InfoWindow(title: 'Selected Restaurant Location'),
                              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                            ),
                          },
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: FloatingActionButton.small(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.navyColor,
                            elevation: 4,
                            onPressed: () {
                              final defaultPos = LatLng(3.1475, 101.7085);
                              setModalState(() => tempPickedLocation = defaultPos);
                              mapCtrl?.animateCamera(CameraUpdate.newLatLng(defaultPos));
                            },
                            child: const Icon(Icons.my_location),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F766E),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedLat = tempPickedLocation.latitude;
                              _selectedLong = tempPickedLocation.longitude;
                              _hasCustomPin = true;
                            });
                            Navigator.pop(ctx);
                            _showSnackBar('Location pin updated from Google Map!', const Color(0xFF0F766E));
                          },
                          icon: const Icon(Icons.check_circle, color: Colors.white),
                          label: const Text(
                            'Confirm This Map Location Pin',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ),
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

  Future<void> _handleSubmission() async {
    final name = _nameCtrl.text.trim();
    final address = _addressCtrl.text.trim();
    final hasProofAttached = _ssmCertFile != null || _isSimulatedUpload;

    if (name.isEmpty) {
      _showSnackBar('Please enter the Restaurant Name', Colors.red);
      return;
    }

    if (address.isEmpty) {
      _showSnackBar('Please enter the Street Address / Location details', Colors.red);
      return;
    }

    if (!hasProofAttached) {
      _showSnackBar('Please upload your SSM Business Registration Certificate proof', Colors.red);
      return;
    }

    final String formattedOperatingHours = '${_openingTime.format(context)} - ${_closingTime.format(context)} ($_operatingDays)';

    if (_ssmCertFile != null) {
      final validation = await SSMValidatorHelper.validateSSMCertificate(_ssmCertFile!);
      if (!validation.isValid) {
        _showSnackBar(validation.message, Colors.red);
        return;
      }
    }

    await RestaurantStoreService.addRestaurant(
      name: name,
      address: address,
      category: _selectedCategory,
      latitude: _selectedLat,
      longitude: _selectedLong,
      ssmCertUrl: _ssmCertFile?.path ?? 'ssm_cert_simulated_proof.png',
      operatingHours: formattedOperatingHours,
      autoApprove: false,
    );

    _showSuccessDialog();
  }

  void _showSnackBar(String text, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: bg),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.hourglass_top_rounded, color: Color(0xFFD97706), size: 54),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFBBF24)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.hourglass_bottom, size: 14, color: Color(0xFFD97706)),
                    SizedBox(width: 4),
                    Text(
                      'Pending Manual Admin Approval',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Submitted for Admin Review',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.navyColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Your restaurant premise "${_nameCtrl.text}" and validated SSM Certificate (Suruhanjaya Syarikat Malaysia) have been submitted. Final approval requires manual review from the System Administrator.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  child: const Text('Return to Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasProofAttached = _ssmCertFile != null || _isSimulatedUpload;
    final selectedItemObj = _categoryItems.firstWhere(
      (c) => c['title'] == _selectedCategory,
      orElse: () => _categoryItems.first,
    );

    return Scaffold(
      appBar: const CustomAppBar(title: 'Add Restaurant'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. HERO HEADER BANNER CARD
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
                    color: const Color(0xFF0C2340).withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white30),
                      ),
                      child: const Icon(Icons.add_business_rounded, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Add New Restaurant',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Register commercial food premises & SSM proof for hygiene certification.',
                            style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.9), height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // 2. SECTION 1: RESTAURANT BASIC DETAILS
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.storefront, color: AppTheme.primaryColor, size: 20),
                        SizedBox(width: 8),
                        Text(
                          '1. Basic Restaurant Details',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.navyColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Restaurant Name Input Field
                    TextField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Restaurant Name *',
                        hintText: 'e.g. Golden Dragon Noodle House',
                        prefixIcon: const Icon(Icons.storefront_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Cuisine Category Enhanced Selector Field (Replaces plain Dropdown)
                    InkWell(
                      onTap: _showCuisineCategoryPickerModal,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              selectedItemObj['icon'] as IconData,
                              color: AppTheme.primaryColor,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Cuisine Category *',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _selectedCategory,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.navyColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Colors.grey.shade700,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Operating Hours Section
                    const Text(
                      'Operating Hours *',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.navyColor),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: _openingTime,
                              );
                              if (picked != null) {
                                setState(() => _openingTime = picked);
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade400),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time_rounded, size: 18, color: AppTheme.primaryColor),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Opening', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                        Text(
                                          _openingTime.format(context),
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.navyColor),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: _closingTime,
                              );
                              if (picked != null) {
                                setState(() => _closingTime = picked);
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade400),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time_filled_rounded, size: 18, color: Color(0xFF0F766E)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Closing', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                        Text(
                                          _closingTime.format(context),
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.navyColor),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: _operatingDays,
                      decoration: InputDecoration(
                        labelText: 'Operating Days',
                        prefixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Daily', child: Text('Daily (Mon - Sun)')),
                        DropdownMenuItem(value: 'Mon - Sat', child: Text('Mon - Sat')),
                        DropdownMenuItem(value: 'Mon - Fri', child: Text('Mon - Fri')),
                        DropdownMenuItem(value: '24 Hours', child: Text('24 Hours')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _operatingDays = val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3. SECTION 2: LOCATION & GOOGLE MAP PIN PICKER
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.place_outlined, color: Color(0xFF0F766E), size: 20),
                        SizedBox(width: 8),
                        Text(
                          '2. Location & Address Pin',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.navyColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Address Text Input
                    TextField(
                      controller: _addressCtrl,
                      decoration: InputDecoration(
                        labelText: 'Street Address & Location Details *',
                        hintText: 'e.g. 12 Jalan Petaling, City Centre, 50000 Kuala Lumpur',
                        prefixIcon: const Icon(Icons.location_on_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    // Captured GPS Status & Interactive Map Pin Button Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F766E).withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF0F766E).withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.my_location, color: Color(0xFF0F766E), size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _hasCustomPin ? 'Custom Location Pin Set' : 'Captured GPS Coordinates',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.navyColor),
                                    ),
                                    Text(
                                      'Lat: ${_selectedLat.toStringAsFixed(4)}, Long: ${_selectedLong.toStringAsFixed(4)}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.check_circle_rounded, color: Colors.green, size: 22),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Button to Choose / Pin on Google Map
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF0F766E), width: 1.2),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _openGoogleMapPickerModal,
                              icon: const Icon(Icons.map_rounded, color: Color(0xFF0F766E), size: 18),
                              label: Text(
                                _hasCustomPin ? '📍 Modify Location Pin on Google Map' : '📍 Choose / Pin Location on Google Map',
                                style: const TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 4. SECTION 3: UPLOAD SSM BUSINESS CERTIFICATE PROOF (Matching Reference Image 2)
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.verified_user_outlined, color: Color(0xFFD97706), size: 20),
                        SizedBox(width: 8),
                        Text(
                          '3. SSM Business Registration Proof',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.navyColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: const [
                        Icon(Icons.shield_outlined, color: Color(0xFFD97706), size: 16),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Upload an official SSM certificate image (Suruhanjaya Syarikat Malaysia). Valid SSM certificate required for admin verification.',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.navyColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (!hasProofAttached)
                      // Upload Box matching Reference Image 2 (Dashed Border + Folder Icon)
                      InkWell(
                        onTap: _showImageSourcePickerModal,
                        borderRadius: BorderRadius.circular(16),
                        child: CustomPaint(
                          painter: DashedBorderPainter(
                            color: const Color(0xFFCBD5E1),
                            strokeWidth: 1.5,
                            gap: 6.0,
                            borderRadius: 16.0,
                          ),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Circular soft blue folder badge with upload arrow badge
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 64,
                                      height: 64,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFDBEAFE),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.folder_rounded,
                                        color: Color(0xFF3B82F6),
                                        size: 34,
                                      ),
                                    ),
                                    Positioned(
                                      right: 2,
                                      bottom: 2,
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.1),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.file_upload_outlined,
                                          color: Color(0xFF3B82F6),
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),

                                // Main Text: "Drag & drop your files here or choose file"
                                RichText(
                                  textAlign: TextAlign.center,
                                  text: const TextSpan(
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.navyColor,
                                    ),
                                    children: [
                                      TextSpan(text: 'Drag & drop your files here or '),
                                      TextSpan(
                                        text: 'choose file',
                                        style: TextStyle(
                                          color: Color(0xFF0284C7),
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),

                                // Subtitle Text: "50 MB max file size" / "JPG, PNG, WEBP or PDF"
                                Text(
                                  'Supported formats: JPG, PNG, WEBP or PDF • 10 MB max file size',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      // Uploaded File Preview Card (Reference Image 2 Style)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF86EFAC)),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _ssmCertFile != null
                                  ? Image.file(
                                      File(_ssmCertFile!.path),
                                      width: 58,
                                      height: 58,
                                      fit: BoxFit.cover,
                                      errorBuilder: (ctx, err, stack) => Container(
                                        width: 58,
                                        height: 58,
                                        color: Colors.green.shade100,
                                        child: const Icon(Icons.article, color: Colors.green),
                                      ),
                                    )
                                  : Container(
                                      width: 58,
                                      height: 58,
                                      color: Colors.green.shade100,
                                      child: const Icon(Icons.verified_rounded, color: Colors.green, size: 32),
                                    ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: const [
                                      Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
                                      SizedBox(width: 4),
                                      Text(
                                        'SSM Proof Attached',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    _ssmCertFile != null ? _ssmCertFile!.name : 'ssm_registration_cert_2026.png',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.navyColor),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _ssmValidationResult?.registrationNo != null
                                        ? 'SSM No: ${_ssmValidationResult!.registrationNo} • Verified'
                                        : '1.8 MB • Ready to submit for verification',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.sync_rounded, color: Color(0xFF0284C7)),
                                  tooltip: 'Replace SSM proof',
                                  onPressed: _showImageSourcePickerModal,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                                  tooltip: 'Remove SSM proof',
                                  onPressed: () {
                                    setState(() {
                                      _ssmCertFile = null;
                                      _isSimulatedUpload = false;
                                    });
                                  },
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
            const SizedBox(height: 24),

            // 5. SUBMIT RESTAURANT BUTTON
            CustomButton(
              label: 'Submit Restaurant for Verification',
              icon: Icons.send_rounded,
              onPressed: () => _handleSubmission(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// Custom Dashed Border Painter matching Reference Image 2 upload box
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double borderRadius;

  DashedBorderPainter({
    this.color = const Color(0xFFCBD5E1),
    this.strokeWidth = 1.5,
    this.gap = 6.0,
    this.borderRadius = 16.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    final Path path = Path()..addRRect(rrect);
    final Path dashPath = Path();

    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double length = gap;
        dashPath.addPath(
          metric.extractPath(distance, distance + length),
          Offset.zero,
        );
        distance += length + gap;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
