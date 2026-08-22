import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/places_location_service.dart';
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

  Timer? _addressDebounce;
  List<PlaceSuggestion> _addressSuggestions = [];
  bool _isSearchingAddress = false;
  final FocusNode _addressFocusNode = FocusNode();

  TimeOfDay _openingTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _closingTime = const TimeOfDay(hour: 22, minute: 0);
  String _operatingDays = 'Daily';

  XFile? _ssmCertFile;
  bool _isSimulatedUpload = false;
  final ImagePicker _picker = ImagePicker();

  XFile? _bannerImageFile;
  String? _selectedBannerUrl;

  final List<Map<String, String>> _presetBannerImages = [
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
  void initState() {
    super.initState();
    _addressCtrl.addListener(_onAddressInputChanged);
  }

  void _onAddressInputChanged() {
    final text = _addressCtrl.text.trim();
    if (text.isEmpty) {
      if (_addressSuggestions.isNotEmpty || _isSearchingAddress) {
        setState(() {
          _addressSuggestions = [];
          _isSearchingAddress = false;
        });
      }
      return;
    }

    _addressDebounce?.cancel();
    _addressDebounce = Timer(const Duration(milliseconds: 250), () async {
      setState(() => _isSearchingAddress = true);
      try {
        final results = await PlacesLocationService.searchPlaces(
          text,
          userLat: _selectedLat,
          userLng: _selectedLong,
        );
        if (mounted) {
          setState(() {
            _addressSuggestions = results;
            _isSearchingAddress = false;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() => _isSearchingAddress = false);
        }
      }
    });
  }

  @override
  void dispose() {
    _addressDebounce?.cancel();
    _addressCtrl.removeListener(_onAddressInputChanged);
    _addressFocusNode.dispose();
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  SSMValidationResult? _ssmValidationResult;
  bool _isOcrScanning = false;
  double _ocrScanProgress = 0.0;
  String _ocrScanStepText = '';

  Future<void> _pickSSMImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _ssmCertFile = image;
          _isSimulatedUpload = false;
          _isOcrScanning = true;
          _ocrScanProgress = 0.15;
          _ocrScanStepText = 'Scanning Document Layout & Image Structure...';
        });

        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;
        setState(() {
          _ocrScanProgress = 0.55;
          _ocrScanStepText = 'Extracting OCR Text, Seals & SSM Registration Number...';
        });

        final validation = await SSMValidatorHelper.validateSSMCertificate(image);

        if (!mounted) return;
        setState(() {
          _ocrScanProgress = 1.0;
          _ocrScanStepText = 'AI OCR Scan Complete';
          _isOcrScanning = false;
          _ssmValidationResult = validation;
        });

        if (!validation.isValid) {
          _showSnackBar('❌ AI OCR Rejected: Invalid SSM Document!', Colors.red);
        } else {
          _showSnackBar('✓ AI OCR Verified: Official SSM Certificate Authenticated!', const Color(0xFF0F766E));
        }
      }
    } catch (e) {
      setState(() {
        _isOcrScanning = false;
        _ssmValidationResult = SSMValidationResult(
          isValid: false,
          confidenceScore: 0.0,
          message: 'AI OCR Image Picker Error: Could not read uploaded file ($e). Please upload an official SSM Certificate document.',
          detectedOcrKeywords: ['IMAGE_PICKER_ERROR'],
        );
      });
      _showSnackBar('❌ AI OCR Scan Failed: Could not process uploaded file!', Colors.red);
    }
  }

  void _showImageSourcePickerModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Drag Handle Bar
                  Center(
                    child: Container(
                      width: 44,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header with Icon & Close Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppTheme.primaryColor, Color(0xFF14B8A6)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Upload SSM Certificate',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : AppTheme.navyColor,
                                ),
                              ),
                              Text(
                                'AI OCR verification enabled',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: isDark ? Colors.white70 : Colors.grey.shade700),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Select an official SSM business registration certificate for automatic OCR recognition and official verification.',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Option 1: Camera Card
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickSSMImage(ImageSource.camera);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF282828) : const Color(0xFFF0FDFA),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? const Color(0xFF0F766E).withValues(alpha: 0.4) : const Color(0xFF0F766E).withValues(alpha: 0.25),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0F766E).withValues(alpha: 0.25),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Capture with Camera',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: isDark ? Colors.white : AppTheme.navyColor,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'Scan',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0F766E),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Take a clear photo of the physical SSM document',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF0F766E), size: 15),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Option 2: Gallery / Files Card
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickSSMImage(ImageSource.gallery);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF282828) : const Color(0xFFF0F9FF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? const Color(0xFF0284C7).withValues(alpha: 0.4) : const Color(0xFF0284C7).withValues(alpha: 0.25),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.photo_library_rounded, color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Choose from Gallery / Files',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: isDark ? Colors.white : AppTheme.navyColor,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'Upload',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0284C7),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Select PDF screenshot or saved SSM certificate image',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF0284C7), size: 15),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickBannerImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _bannerImageFile = image;
          _selectedBannerUrl = null;
        });
        _showSnackBar('✓ Restaurant Banner Photo Uploaded!', const Color(0xFF0F766E));
      }
    } catch (_) {
      _showSnackBar('Error selecting banner photo.', Colors.red);
    }
  }

  void _showBannerSourcePickerModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Drag Handle Bar
                  Center(
                    child: Container(
                      width: 44,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header with Icon & Close Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppTheme.primaryColor, Color(0xFF14B8A6)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.image_rounded, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Upload Restaurant Banner',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : AppTheme.navyColor,
                                ),
                              ),
                              Text(
                                'Storefront cover photo (16:9)',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: isDark ? Colors.white70 : Colors.grey.shade700),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Upload your custom restaurant storefront photo or pick a high-quality preset banner.',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Action 1: Camera Card
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickBannerImage(ImageSource.camera);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF282828) : const Color(0xFFF0FDFA),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? const Color(0xFF0F766E).withValues(alpha: 0.4) : const Color(0xFF0F766E).withValues(alpha: 0.25),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0F766E).withValues(alpha: 0.25),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Take Photo with Camera',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: isDark ? Colors.white : AppTheme.navyColor,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'Instant',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0F766E),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Capture a live photo of your restaurant storefront',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF0F766E), size: 15),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Action 2: Gallery Card
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickBannerImage(ImageSource.gallery);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF282828) : const Color(0xFFF0F9FF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? const Color(0xFF0284C7).withValues(alpha: 0.4) : const Color(0xFF0284C7).withValues(alpha: 0.25),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.photo_library_rounded, color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Choose from Device Gallery',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: isDark ? Colors.white : AppTheme.navyColor,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'Albums',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0284C7),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Select an existing high-res storefront photo from gallery',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF0284C7), size: 15),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Horizontal Preset Gallery Carousel
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Or Select Curated Preset Banner:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppTheme.navyColor,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF282828) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${_presetBannerImages.length} Presets',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white60 : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 115,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _presetBannerImages.length,
                      separatorBuilder: (ctx, i) => const SizedBox(width: 12),
                      itemBuilder: (ctx, idx) {
                        final item = _presetBannerImages[idx];
                        final String title = item['title']!;
                        final String url = item['url']!;
                        final bool isSelected = _selectedBannerUrl == url && _bannerImageFile == null;

                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedBannerUrl = url;
                              _bannerImageFile = null;
                            });
                            Navigator.pop(ctx);
                            _showSnackBar('✓ Preset Banner Selected: $title', const Color(0xFF0F766E));
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: 145,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? AppTheme.primaryColor : (isDark ? Colors.white24 : Colors.grey.shade300),
                                width: isSelected ? 2.5 : 1.0,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(13),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(url, fit: BoxFit.cover),
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Colors.black.withValues(alpha: 0.75), Colors.transparent],
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: const BoxDecoration(
                                          color: AppTheme.primaryColor,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
                                      ),
                                    ),
                                  Positioned(
                                    bottom: 8,
                                    left: 8,
                                    right: 8,
                                    child: Text(
                                      title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                        shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                                      ),
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
                ],
              ),
            ),
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
    final searchCtrl = TextEditingController();
    List<PlaceSuggestion> modalSuggestions = [];
    bool isSearchingModal = false;
    bool isMapDragging = false;
    String currentReverseAddress = PlacesLocationService.reverseGeocode(tempPickedLocation.latitude, tempPickedLocation.longitude);
    Timer? modalDebounce;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.90,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Column(
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
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.pin_drop_rounded, color: Color(0xFF0F766E), size: 22),
                                SizedBox(width: 8),
                                Text(
                                  'Google Map Location Finder',
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
                              onPressed: () {
                                modalDebounce?.cancel();
                                Navigator.pop(ctx);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Real-Time Google Maps Style Search Bar inside Modal
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: TextField(
                            controller: searchCtrl,
                            onChanged: (val) {
                              modalDebounce?.cancel();
                              if (val.trim().isEmpty) {
                                setModalState(() {
                                  modalSuggestions = [];
                                  isSearchingModal = false;
                                });
                                return;
                              }
                              setModalState(() => isSearchingModal = true);
                              modalDebounce = Timer(const Duration(milliseconds: 250), () async {
                                final res = await PlacesLocationService.searchPlaces(
                                  val,
                                  userLat: tempPickedLocation.latitude,
                                  userLng: tempPickedLocation.longitude,
                                );
                                setModalState(() {
                                  modalSuggestions = res;
                                  isSearchingModal = false;
                                });
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Search city, street or landmark (e.g. Melaka, Jonker, KLCC)...',
                              hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0F766E), size: 20),
                              suffixIcon: isSearchingModal
                                  ? const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F766E)),
                                      ),
                                    )
                                  : searchCtrl.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                                          onPressed: () {
                                            searchCtrl.clear();
                                            setModalState(() {
                                              modalSuggestions = [];
                                              isSearchingModal = false;
                                            });
                                          },
                                        )
                                      : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Area Quick Shortcut Chips
                  Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildModalAreaPill('📍 Melaka', 2.1953, 102.2482, mapCtrl, setModalState, (pos) {
                          tempPickedLocation = pos;
                          currentReverseAddress = PlacesLocationService.reverseGeocode(pos.latitude, pos.longitude);
                        }),
                        _buildModalAreaPill('📍 Jonker Walk', 2.1953, 102.2482, mapCtrl, setModalState, (pos) {
                          tempPickedLocation = pos;
                          currentReverseAddress = PlacesLocationService.reverseGeocode(pos.latitude, pos.longitude);
                        }),
                        _buildModalAreaPill('📍 KLCC & Pavilion', 3.1579, 101.7116, mapCtrl, setModalState, (pos) {
                          tempPickedLocation = pos;
                          currentReverseAddress = PlacesLocationService.reverseGeocode(pos.latitude, pos.longitude);
                        }),
                        _buildModalAreaPill('📍 Petaling Jaya SS2', 3.1189, 101.6214, mapCtrl, setModalState, (pos) {
                          tempPickedLocation = pos;
                          currentReverseAddress = PlacesLocationService.reverseGeocode(pos.latitude, pos.longitude);
                        }),
                        _buildModalAreaPill('📍 Penang Gurney', 5.4375, 100.3098, mapCtrl, setModalState, (pos) {
                          tempPickedLocation = pos;
                          currentReverseAddress = PlacesLocationService.reverseGeocode(pos.latitude, pos.longitude);
                        }),
                        _buildModalAreaPill('📍 Johor Bahru', 1.4623, 103.7638, mapCtrl, setModalState, (pos) {
                          tempPickedLocation = pos;
                          currentReverseAddress = PlacesLocationService.reverseGeocode(pos.latitude, pos.longitude);
                        }),
                        _buildModalAreaPill('📍 Ipoh Old Town', 4.5968, 101.0778, mapCtrl, setModalState, (pos) {
                          tempPickedLocation = pos;
                          currentReverseAddress = PlacesLocationService.reverseGeocode(pos.latitude, pos.longitude);
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),

                  Expanded(
                    child: Stack(
                      children: [
                        GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: tempPickedLocation,
                            zoom: 16.5,
                            tilt: 35.0,
                          ),
                          onMapCreated: (controller) => mapCtrl = controller,
                          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                            Factory<OneSequenceGestureRecognizer>(
                              () => EagerGestureRecognizer(),
                            ),
                          },
                          scrollGesturesEnabled: true,
                          zoomGesturesEnabled: true,
                          tiltGesturesEnabled: true,
                          rotateGesturesEnabled: true,
                          onCameraMove: (position) {
                            tempPickedLocation = position.target;
                            if (!isMapDragging) {
                              setModalState(() => isMapDragging = true);
                            }
                          },
                          onCameraIdle: () {
                            final addr = PlacesLocationService.reverseGeocode(
                              tempPickedLocation.latitude,
                              tempPickedLocation.longitude,
                            );
                            setModalState(() {
                              isMapDragging = false;
                              currentReverseAddress = addr;
                            });
                          },
                          onTap: (point) {
                            setModalState(() {
                              tempPickedLocation = point;
                              modalSuggestions = [];
                            });
                            mapCtrl?.animateCamera(CameraUpdate.newLatLng(point));
                          },
                          myLocationEnabled: true,
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: false,
                        ),

                        // Center Interactive Drag Pin with Lift & Shadow (Google Maps Style)
                        Center(
                          child: IgnorePointer(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 38), // Tip points directly to map center
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                curve: Curves.easeOut,
                                transform: Matrix4.translationValues(0, isMapDragging ? -16 : 0, 0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Live Status Tooltip Pill
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isMapDragging ? const Color(0xFFD97706) : const Color(0xFF0F766E),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.25),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isMapDragging ? Icons.open_with_rounded : Icons.place_rounded,
                                            color: Colors.white,
                                            size: 13,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            isMapDragging ? 'Release to pin here' : 'Drag map to move pin',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    // Pin Icon
                                    Stack(
                                      alignment: Alignment.center,
                                      children: const [
                                        Icon(Icons.location_on, size: 48, color: Color(0xFF0F766E)),
                                        Positioned(
                                          top: 10,
                                          child: Icon(Icons.circle, size: 14, color: Colors.white),
                                        ),
                                      ],
                                    ),
                                    // Ground Shadow that shrinks when lifted
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      width: isMapDragging ? 8 : 16,
                                      height: isMapDragging ? 3 : 5,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: isMapDragging ? 0.18 : 0.35),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Suggestions Dropdown Overlay inside Map
                        if (modalSuggestions.isNotEmpty)
                          Positioned(
                            top: 8,
                            left: 12,
                            right: 12,
                            child: Container(
                              constraints: const BoxConstraints(maxHeight: 250),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ListView.separated(
                                shrinkWrap: true,
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                itemCount: modalSuggestions.length,
                                separatorBuilder: (ctx, i) => const Divider(height: 1),
                                itemBuilder: (itemCtx, i) {
                                  final item = modalSuggestions[i];
                                  return ListTile(
                                    dense: true,
                                    leading: const Icon(Icons.place_rounded, color: Color(0xFF0F766E), size: 20),
                                    title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.navyColor)),
                                    subtitle: Text(item.address, style: TextStyle(fontSize: 11, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    trailing: item.distanceKm != null
                                        ? Text('${item.distanceKm!.toStringAsFixed(1)} km', style: const TextStyle(fontSize: 11, color: Color(0xFF0F766E), fontWeight: FontWeight.w600))
                                        : null,
                                    onTap: () {
                                      final newPos = LatLng(item.latitude, item.longitude);
                                      setModalState(() {
                                        tempPickedLocation = newPos;
                                        modalSuggestions = [];
                                        searchCtrl.text = item.title;
                                        currentReverseAddress = PlacesLocationService.reverseGeocode(newPos.latitude, newPos.longitude);
                                      });
                                      mapCtrl?.animateCamera(CameraUpdate.newLatLngZoom(newPos, 16.5));
                                    },
                                  );
                                },
                              ),
                            ),
                          ),

                        // Floating Recenter Button
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: FloatingActionButton.small(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.navyColor,
                            elevation: 4,
                            onPressed: () {
                              final defaultPos = LatLng(_selectedLat, _selectedLong);
                              setModalState(() {
                                tempPickedLocation = defaultPos;
                                currentReverseAddress = PlacesLocationService.reverseGeocode(defaultPos.latitude, defaultPos.longitude);
                              });
                              mapCtrl?.animateCamera(CameraUpdate.newLatLng(defaultPos));
                            },
                            child: const Icon(Icons.my_location),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom Confirmation Action Bar
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F766E).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF0F766E).withValues(alpha: 0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.pin_drop_rounded, size: 18, color: Color(0xFF0F766E)),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        currentReverseAddress,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F766E),
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.grey.shade300),
                                      ),
                                      child: Text(
                                        'GPS: ${tempPickedLocation.latitude.toStringAsFixed(4)}, ${tempPickedLocation.longitude.toStringAsFixed(4)}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontFamily: 'monospace',
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isMapDragging ? '📍 Moving map...' : '✓ Drag map to fine-tune',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                        color: isMapDragging ? Colors.amber.shade800 : Colors.teal.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
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
                                  _addressCtrl.text = currentReverseAddress;
                                  _addressSuggestions = [];
                                });
                                modalDebounce?.cancel();
                                Navigator.pop(ctx);
                                _showSnackBar('✓ Map pin updated & address auto-filled!', const Color(0xFF0F766E));
                              },
                              icon: const Icon(Icons.check_circle, color: Colors.white),
                              label: const Text(
                                'Confirm This Map Location Pin',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildModalAreaPill(
    String label,
    double lat,
    double lng,
    GoogleMapController? mapCtrl,
    StateSetter setModalState,
    void Function(LatLng pos) onSelect,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        backgroundColor: const Color(0xFFF1F5F9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        label: Text(
          label,
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF0F766E)),
        ),
        onPressed: () {
          final pos = LatLng(lat, lng);
          setModalState(() => onSelect(pos));
          mapCtrl?.animateCamera(CameraUpdate.newLatLngZoom(pos, 16.0));
        },
      ),
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
      _showSnackBar('Please upload your official SSM Business Registration Certificate', Colors.red);
      return;
    }

    // Strict AI OCR Document Validation Enforcement
    if (_ssmValidationResult == null || !_ssmValidationResult!.isValid) {
      _showSnackBar(
        _ssmValidationResult?.message ?? 'AI OCR Scan Rejected: You must upload a valid official SSM Business Certificate before submitting to admin!',
        Colors.red,
      );
      return;
    }

    final String formattedOperatingHours = '${_openingTime.format(context)} - ${_closingTime.format(context)} ($_operatingDays)';

    String chosenImageUrl;
    if (_bannerImageFile != null) {
      try {
        final bytes = await File(_bannerImageFile!.path).readAsBytes();
        chosenImageUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      } catch (_) {
        chosenImageUrl = _bannerImageFile!.path;
      }
    } else if (_selectedBannerUrl != null && _selectedBannerUrl!.isNotEmpty) {
      chosenImageUrl = _selectedBannerUrl!;
    } else {
      chosenImageUrl = 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?q=80&w=800';
    }

    await RestaurantStoreService.addRestaurant(
      name: name,
      address: address,
      category: _selectedCategory,
      latitude: _selectedLat,
      longitude: _selectedLong,
      ssmCertUrl: _ssmCertFile?.path ?? 'ssm_cert_simulated_proof.png',
      operatingHours: formattedOperatingHours,
      imageUrl: chosenImageUrl,
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

            // 2. SECTION 2: RESTAURANT COVER BANNER PHOTO
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: const [
                              Icon(Icons.add_a_photo_rounded, color: AppTheme.primaryColor, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '2. Restaurant Cover Banner Photo',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.navyColor),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_bannerImageFile != null || _selectedBannerUrl != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF0F766E)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF0F766E)),
                                SizedBox(width: 4),
                                Text(
                                  'Banner Set',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Upload your custom restaurant storefront photo (Camera / Gallery) or pick from curated preset banners.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 14),

                    // Banner Preview Card
                    Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: Colors.grey.shade100,
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (_bannerImageFile != null)
                              Image.file(
                                File(_bannerImageFile!.path),
                                fit: BoxFit.cover,
                              )
                            else if (_selectedBannerUrl != null)
                              Image.network(
                                _selectedBannerUrl!,
                                fit: BoxFit.cover,
                              )
                            else
                              Image.network(
                                'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?q=80&w=800',
                                fit: BoxFit.cover,
                              ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.black.withValues(alpha: 0.65), Colors.transparent],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 12,
                              left: 12,
                              right: 12,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _bannerImageFile != null
                                          ? '✓ Custom Photo Attached'
                                          : (_selectedBannerUrl != null ? '✓ Preset Banner Selected' : 'Default Storefront Preview'),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                                      ),
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: AppTheme.navyColor,
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    onPressed: _showBannerSourcePickerModal,
                                    icon: const Icon(Icons.photo_camera_rounded, size: 16, color: AppTheme.primaryColor),
                                    label: Text(
                                      _bannerImageFile != null || _selectedBannerUrl != null ? 'Change Banner' : 'Upload Banner',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3. SECTION 3: LOCATION & GOOGLE MAP PIN PICKER
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
                          '3. Location & Address Pin',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.navyColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Address Text Input with Live Autocomplete
                    TextField(
                      controller: _addressCtrl,
                      focusNode: _addressFocusNode,
                      decoration: InputDecoration(
                        labelText: 'Street Address & Location Details *',
                        hintText: 'e.g. Jonker Street, Melaka or 12 Jalan Petaling, KL',
                        prefixIcon: const Icon(Icons.location_on_outlined, color: Color(0xFF0F766E)),
                        suffixIcon: _isSearchingAddress
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F766E)),
                                ),
                              )
                            : _addressCtrl.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                                    onPressed: () {
                                      _addressCtrl.clear();
                                      setState(() => _addressSuggestions = []);
                                    },
                                  )
                                : null,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.8),
                        ),
                      ),
                      maxLines: 2,
                    ),

                    // Location Autocomplete Dropdown Overlay Card (Google Maps Style)
                    if (_addressSuggestions.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 250),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF0F766E).withValues(alpha: 0.3)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          itemCount: _addressSuggestions.length,
                          separatorBuilder: (ctx, i) => const Divider(height: 1, indent: 12, endIndent: 12),
                          itemBuilder: (ctx, idx) {
                            final item = _addressSuggestions[idx];
                            final String title = item.title;
                            final String address = item.address;
                            final double lat = item.latitude;
                            final double lng = item.longitude;
                            final String category = item.category;
                            final double? dist = item.distanceKm;

                            return ListTile(
                              dense: true,
                              leading: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(item.icon, color: const Color(0xFF0F766E), size: 18),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.navyColor),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F766E).withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      category,
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF0F766E)),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        address,
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (dist != null) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        '${dist.toStringAsFixed(1)} km',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              onTap: () {
                                _addressCtrl.text = address;
                                setState(() {
                                  _selectedLat = lat;
                                  _selectedLong = lng;
                                  _hasCustomPin = true;
                                  _addressSuggestions = [];
                                });
                                _addressFocusNode.unfocus();
                                _showSnackBar('✓ Selected: $title (Lat: ${lat.toStringAsFixed(4)}, Long: ${lng.toStringAsFixed(4)})', const Color(0xFF0F766E));
                              },
                            );
                          },
                        ),
                      ),
                    ],
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

            // 4. SECTION 4: UPLOAD SSM BUSINESS CERTIFICATE PROOF
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
                        Expanded(
                          child: Text(
                            '4. SSM Business Registration Proof',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.navyColor),
                            overflow: TextOverflow.ellipsis,
                          ),
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
                    else if (_isOcrScanning)
                      // 1. AI OCR SCANNING ANIMATED PROGRESS CARD
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F766E).withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF0F766E).withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(color: Color(0xFF0F766E), strokeWidth: 2.2),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    '🤖 Real AI Document OCR Scanner Active...',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F766E)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: _ocrScanProgress,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0F766E)),
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _ocrScanStepText,
                              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      )
                    else if (_ssmValidationResult != null && !_ssmValidationResult!.isValid)
                      // 2. AI REJECTION WARNING CARD (REJECTED DOCUMENT)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(color: Color(0xFFDC2626), shape: BoxShape.circle),
                                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'AI OCR REJECTED: INVALID SSM DOCUMENT',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF991B1B)),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Confidence: ${(_ssmValidationResult!.confidenceScore * 100).toStringAsFixed(0)}%',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red.shade800),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _ssmValidationResult!.message,
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF7F1D1D), height: 1.35),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFFDC2626)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                                onPressed: _showImageSourcePickerModal,
                                icon: const Icon(Icons.upload_file_rounded, color: Color(0xFFDC2626), size: 18),
                                label: const Text('Re-upload Official SSM Certificate', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      // 3. AI VERIFIED DOCUMENT CARD (AUTHENTICATED SSM CERTIFICATE)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF86EFAC)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: 52,
                                  height: 52,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: _ssmCertFile != null && !_ssmCertFile!.path.toLowerCase().endsWith('.pdf')
                                        ? Image.file(
                                            File(_ssmCertFile!.path),
                                            width: 52,
                                            height: 52,
                                            fit: BoxFit.cover,
                                            errorBuilder: (ctx, err, stack) => Container(
                                              width: 52,
                                              height: 52,
                                              color: Colors.green.shade100,
                                              child: const Icon(Icons.description_rounded, color: Color(0xFF166534), size: 28),
                                            ),
                                          )
                                        : Container(
                                            width: 52,
                                            height: 52,
                                            color: const Color(0xFFDCFCE7),
                                            child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF166534), size: 28),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: const [
                                          Icon(Icons.check_circle_rounded, color: Colors.green, size: 15),
                                          SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              'VERIFIED BY AI OCR ENGINE',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _ssmCertFile != null ? _ssmCertFile!.name : 'ssm_registration_cert_2026.png',
                                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.navyColor),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _ssmValidationResult?.registrationNo != null
                                            ? 'SSM No: ${_ssmValidationResult!.registrationNo}'
                                            : 'Official SSM Registration Certificate Authenticated',
                                        style: TextStyle(fontSize: 10.5, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      visualDensity: VisualDensity.compact,
                                      icon: const Icon(Icons.sync_rounded, color: Color(0xFF0284C7), size: 22),
                                      tooltip: 'Replace SSM proof',
                                      onPressed: _showImageSourcePickerModal,
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      visualDensity: VisualDensity.compact,
                                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 22),
                                      tooltip: 'Remove SSM proof',
                                      onPressed: () {
                                        setState(() {
                                          _ssmCertFile = null;
                                          _isSimulatedUpload = false;
                                          _ssmValidationResult = null;
                                        });
                                      },
                                    ),
                                  ],
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
