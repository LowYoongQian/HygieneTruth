import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/models/complaint_model.dart';
import '../../core/models/restaurant_model.dart';
import '../../core/services/language_manager.dart';
import '../../core/services/restaurant_store_service.dart';
import '../../core/services/customer_store_service.dart';
import '../../core/services/notification_service.dart';
import '../../notifications/models/notification_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/translations.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../widgets/complaint_step_tracker.dart';

class SubmitComplaintScreen extends StatefulWidget {
  const SubmitComplaintScreen({super.key});

  @override
  State<SubmitComplaintScreen> createState() => _SubmitComplaintScreenState();
}

class _SubmitComplaintScreenState extends State<SubmitComplaintScreen> {
  int _currentStep = 0;

  RestaurantModel? _selectedRestaurant;
  String _selectedCategory = 'Pest Infestation';
  final List<String> _selectedIssues = [];
  String _description = '';
  
  final List<File> _attachedPhotoFiles = [];
  final List<String> _attachedPhotoUrls = [];
  final ImagePicker _picker = ImagePicker();

  final _customNameController = TextEditingController();
  final _customAddressController = TextEditingController();
  String _customCategory = 'Malay Local';

  static const _otherRestaurantOption = RestaurantModel(
    id: 'other_new',
    name: 'Other (Add New Premises)',
    address: 'Custom Location',
    category: 'Other',
    latitude: 3.1466,
    longitude: 101.6958,
    hygieneRiskScore: 0,
    riskCategory: RiskCategory.safe,
    status: RestaurantStatus.approved,
    violationCount: 0,
    imageUrl: '',
    lastUpdated: '',
  );

  final List<String> _stepTitles = [
    'Choose Outlet',
    'Hygiene Issues',
    'Report Details',
    'Review Check',
  ];

  final List<String> _categories = [
    'Pest Infestation',
    'Unclean Utensils',
    'Food Poisoning',
    'Poor Staff Hygiene',
    'Waste & Drainage',
    'Other Issue',
  ];

  final Map<String, IconData> _categoryIcons = {
    'Pest Infestation': Icons.bug_report_outlined,
    'Unclean Utensils': Icons.flatware_rounded,
    'Food Poisoning': Icons.sick_outlined,
    'Poor Staff Hygiene': Icons.clean_hands_outlined,
    'Waste & Drainage': Icons.delete_sweep_outlined,
    'Other Issue': Icons.report_problem_outlined,
  };

  final Map<String, List<String>> _issueChecklistMap = {
    'Pest Infestation': [
      'Cockroaches near food prep',
      'Rats / Mice droppings',
      'Flies on ready-to-eat food',
      'Uncovered open trash bins',
    ],
    'Unclean Utensils': [
      'Oily cups and glasses',
      'Dirty cutlery with residue',
      'Moldy ice machine / dispenser',
    ],
    'Food Poisoning': [
      'Undercooked raw meat served',
      'Foul odor from kitchen/dishes',
      'Expired fridge ingredients',
    ],
    'Poor Staff Hygiene': [
      'No gloves or hairnets worn',
      'Staff coughing over food',
      'Bare hands touching food',
    ],
    'Waste & Drainage': [
      'Overflowing grease trap',
      'Foul wastewater on floor',
    ],
    'Other Issue': [
      'Unspecified hygiene issue',
    ]
  };

  final List<String> _sampleEvidencePresets = [
    'https://images.unsplash.com/photo-1584820927498-cfe5211fd8bf?q=80&w=400',
    'https://images.unsplash.com/photo-1583863788434-e58a36330cf0?q=80&w=400',
    'https://images.unsplash.com/photo-1594998893017-36147cbcae05?q=80&w=400',
  ];

  @override
  void dispose() {
    _customNameController.dispose();
    _customAddressController.dispose();
    super.dispose();
  }

  List<RestaurantModel> get _availableRestaurants {
    final List<RestaurantModel> list = [];
    final Set<String> seenIds = {};

    if (_selectedRestaurant != null && _selectedRestaurant!.id != 'other_new') {
      seenIds.add(_selectedRestaurant!.id);
      list.add(_selectedRestaurant!);
    }

    for (final r in RestaurantStoreService.restaurantsNotifier.value) {
      if (!seenIds.contains(r.id)) {
        seenIds.add(r.id);
        list.add(r);
      }
    }

    return list;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is RestaurantModel) {
      final existingIndex = RestaurantStoreService.restaurantsNotifier.value.indexWhere((r) => r.id == args.id);
      if (existingIndex != -1) {
        _selectedRestaurant = RestaurantStoreService.restaurantsNotifier.value[existingIndex];
      } else {
        _selectedRestaurant = args;
      }
    } else {
      _selectedRestaurant ??= RestaurantStoreService.restaurantsNotifier.value.isNotEmpty ? RestaurantStoreService.restaurantsNotifier.value.first : null;
    }
  }

  bool get _isOtherSelected => _selectedRestaurant?.id == 'other_new';

  bool get _hasPhotoAttached => _attachedPhotoFiles.isNotEmpty || _attachedPhotoUrls.isNotEmpty;

  int get _totalPhotoCount => _attachedPhotoFiles.length + _attachedPhotoUrls.length;

  bool _canProceedCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (_isOtherSelected) {
          return _customNameController.text.trim().isNotEmpty && _customAddressController.text.trim().isNotEmpty;
        }
        return _selectedRestaurant != null;
      case 1:
        return _selectedIssues.isNotEmpty;
      case 2:
        return _description.trim().isNotEmpty || _hasPhotoAttached;
      case 3:
        return true;
      default:
        return false;
    }
  }

  // Validation Warning Message shown when Next button is disabled
  String _getValidationHint() {
    switch (_currentStep) {
      case 0:
        if (_isOtherSelected) {
          return 'Please fill in both the new restaurant name and address.';
        }
        return 'Please select an outlet premises to proceed.';
      case 1:
        return 'Please check at least 1 observed hygiene issue to proceed.';
      case 2:
        return 'Please add a brief description or attach photo evidence to proceed.';
      default:
        return '';
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          if (_totalPhotoCount < 4) {
            _attachedPhotoFiles.add(File(pickedFile.path));
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not access image: $e')),
        );
      }
    }
  }

  void _showPhotoPickerOptionsModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
                      'Attach Photo Evidence',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.navyColor),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Clear photos of food, utensils, or premises help health inspectors investigate quickly.',
                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: AppTheme.primaryColor),
                  ),
                  title: const Text('Take Photo with Camera', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Capture live evidence using device camera', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera);
                  },
                ),
                const Divider(height: 12),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.photo_library_rounded, color: Color(0xFF0284C7)),
                  ),
                  title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Select existing photos from device gallery', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                const Divider(height: 12),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.science_outlined, color: Colors.amber.shade800),
                  ),
                  title: const Text('Use Sample Evidence Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Add inspection sample photo for quick demo', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      if (_totalPhotoCount < 4) {
                        final nextPreset = _sampleEvidencePresets[_attachedPhotoUrls.length % _sampleEvidencePresets.length];
                        _attachedPhotoUrls.add(nextPreset);
                      }
                    });
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isSubmitting = false;

  void _onNextPressed() {
    if (!_canProceedCurrentStep() || _isSubmitting) return;
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      _submitReport();
    }
  }

  void _onBackPressed() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _submitReport() async {
    final effectiveOutlet = _isOtherSelected
        ? _customNameController.text.trim()
        : (_selectedRestaurant?.name ?? 'Selected Premises');

    final effectiveAddress = _isOtherSelected
        ? _customAddressController.text.trim()
        : (_selectedRestaurant?.address ?? 'Location not provided');

    setState(() => _isSubmitting = true);

    final List<String> allPhotos = [
      ..._attachedPhotoFiles.map((f) => f.path),
      ..._attachedPhotoUrls,
    ];

    ComplaintModel? createdComplaint;
    try {
      createdComplaint = await ComplaintStoreService.submitComplaint(
        restaurantId: _isOtherSelected ? 'custom_${DateTime.now().millisecondsSinceEpoch}' : (_selectedRestaurant?.id ?? 'rest_001'),
        restaurantName: effectiveOutlet,
        restaurantAddress: effectiveAddress,
        category: _selectedCategory,
        issues: _selectedIssues,
        description: _description.trim(),
        photoUrls: allPhotos,
        latitude: _selectedRestaurant?.latitude ?? 3.1466,
        longitude: _selectedRestaurant?.longitude ?? 101.6958,
      );
    } catch (_) {}

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    final displayTicketId = createdComplaint != null && createdComplaint.id.length >= 8
        ? '#CMP-${createdComplaint.id.substring(0, 8).toUpperCase()}'
        : '#CMP-2026-8842';

    final currentUser = CustomerStoreService.currentCustomer;
    NotificationService.sendNotification(
      userId: currentUser?.id ?? 'usr_current',
      userEmail: currentUser?.email,
      title: '📋 Complaint Submitted: $displayTicketId',
      message: 'Your report for "$effectiveOutlet" has been received and queued for review.',
      type: NotificationType.complaint,
      actionUrl: createdComplaint?.id,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 26),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Report Submitted!',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.navyColor),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your hygiene complaint for "$effectiveOutlet" has been dispatched to health authorities for verification.',
                style: TextStyle(fontSize: 13.5, color: Colors.grey.shade700, height: 1.4),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tracking Ticket ID',
                          style: TextStyle(fontSize: 11.5, color: Colors.grey, fontWeight: FontWeight.w600),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            displayTicketId,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.amber.shade700,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Status: Pending Inspection Review',
                            style: TextStyle(fontSize: 12, color: Colors.amber.shade900, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 1,
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  child: const Text('Back to Home', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Active Step Form Controls
  Widget _buildActiveStepContent() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (_currentStep) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Restaurant / Food Stall Premises:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : AppTheme.navyColor),
            ),
            const SizedBox(height: 12),

            // High-Quality Custom Styled Dropdown Container
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: DropdownButtonFormField<RestaurantModel>(
                isExpanded: true,
                initialValue: _selectedRestaurant,
                borderRadius: BorderRadius.circular(16),
                dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primaryColor, size: 26),
                decoration: InputDecoration(
                  labelText: 'Choose Restaurant / Food Stall',
                  labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade700, fontSize: 14, fontWeight: FontWeight.w600),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.storefront, color: AppTheme.primaryColor, size: 20),
                    ),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: [
                  ..._availableRestaurants.map((r) {
                    return DropdownMenuItem<RestaurantModel>(
                      value: r,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              r.name,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : AppTheme.navyColor),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF282828) : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              r.category,
                              style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.grey.shade700),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  DropdownMenuItem<RestaurantModel>(
                    value: _otherRestaurantOption,
                    child: Row(
                      children: const [
                        Icon(Icons.add_circle_outline, color: AppTheme.primaryColor, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Other (Add New Premises)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryColor),
                        ),
                      ],
                    ),
                  ),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedRestaurant = val;
                  });
                },
              ),
            ),

            // Dynamic Custom Fields Container if "Other" is chosen
            if (_isOtherSelected) ...[
              const SizedBox(height: 16),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.6 : 0.4), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.add_business_rounded, color: AppTheme.primaryColor, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'New Restaurant Premises Information',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white : AppTheme.navyColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Enter details for the new unlisted food outlet below:',
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),

                    // 1. Restaurant Name Input
                    TextField(
                      controller: _customNameController,
                      onChanged: (_) => setState(() {}),
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13.5),
                      decoration: InputDecoration(
                        labelText: 'Restaurant / Stall Name *',
                        labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade700),
                        hintText: 'e.g. Restoran Sin Huat, Stall 12',
                        hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
                        prefixIcon: const Icon(Icons.store, color: AppTheme.primaryColor, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300),
                        ),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF121212) : Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 2. Cuisine Category Selector
                    DropdownButtonFormField<String>(
                      initialValue: _customCategory,
                      dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        labelText: 'Cuisine / Premises Category',
                        labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade700),
                        prefixIcon: const Icon(Icons.restaurant_menu, color: AppTheme.primaryColor, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300),
                        ),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF121212) : Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      items: [
                        'Malay Local',
                        'Chinese Noodle',
                        'Indian Mamak',
                        'Dim Sum',
                        'Western Fast Food',
                        'Cafe & Bakery',
                        'Hawker Stall / Food Court',
                        'Other Cuisine',
                      ].map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Text(cat, style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black87)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _customCategory = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // 3. Address / Landmark Input
                    TextField(
                      controller: _customAddressController,
                      onChanged: (_) => setState(() {}),
                      maxLines: 2,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13.5),
                      decoration: InputDecoration(
                        labelText: 'Premises Address & Landmark Details *',
                        labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade700),
                        hintText: 'e.g. Lot 45, Jalan Bukit Bintang, Kuala Lumpur',
                        hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
                        prefixIcon: const Icon(Icons.place, color: AppTheme.primaryColor, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300),
                        ),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF121212) : Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0C4A6E).withValues(alpha: 0.3) : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.gps_fixed, size: 18, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'GPS Location Tagged: 3.1466, 101.6958 (Kuala Lumpur)',
                      style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF7DD3FC) : AppTheme.navyColor, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

      case 1:
        final currentChecklist = _issueChecklistMap[_selectedCategory] ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Main Issue Category:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : AppTheme.navyColor),
            ),
            const SizedBox(height: 10),
            
            // Category Quick Grid Selector
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((c) {
                final isSelected = (_selectedCategory == c);
                final icon = _categoryIcons[c] ?? Icons.report_problem_outlined;

                return ChoiceChip(
                  avatar: Icon(
                    icon,
                    size: 17,
                    color: isSelected ? Colors.white : AppTheme.primaryColor,
                  ),
                  label: Text(
                    c,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? Colors.white : (isDark ? Colors.white : AppTheme.navyColor),
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppTheme.primaryColor,
                  backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  side: BorderSide(
                    color: isSelected ? AppTheme.primaryColor : (isDark ? Colors.white24 : Colors.grey.shade300),
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedCategory = c;
                        _selectedIssues.clear();
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Observed Hygiene Issues:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : AppTheme.navyColor),
                ),
                Text(
                  '${_selectedIssues.length} selected',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Check all violations observed at the premises:',
              style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey.shade600),
            ),
            const SizedBox(height: 12),

            // Checklist Items Card List
            ...currentChecklist.map((issue) {
              final isChecked = _selectedIssues.contains(issue);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isChecked
                      ? (isDark ? AppTheme.primaryColor.withValues(alpha: 0.15) : AppTheme.primaryColor.withValues(alpha: 0.06))
                      : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isChecked ? AppTheme.primaryColor : (isDark ? Colors.white12 : Colors.grey.shade200),
                    width: isChecked ? 1.4 : 1,
                  ),
                ),
                child: CheckboxListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  activeColor: AppTheme.primaryColor,
                  dense: true,
                  title: Text(
                    issue,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: isChecked ? FontWeight.bold : FontWeight.normal,
                      color: isChecked ? (isDark ? Colors.white : AppTheme.navyColor) : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                  value: isChecked,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedIssues.add(issue);
                      } else {
                        _selectedIssues.remove(issue);
                      }
                    });
                  },
                ),
              );
            }),
          ],
        );

      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Description & Location Notes:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : AppTheme.navyColor),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                maxLines: 3,
                minLines: 2,
                style: TextStyle(fontSize: 13.5, color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Describe observations (e.g. time of visit, table area, kitchen counter cleanliness, staff response)...',
                  hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontSize: 12.5),
                  contentPadding: const EdgeInsets.all(14),
                  border: InputBorder.none,
                ),
                onChanged: (val) => setState(() => _description = val),
              ),
            ),
            const SizedBox(height: 10),

            // Quick Tag Chips
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _quickTagChip('#CockroachSpotted'),
                _quickTagChip('#DirtyUtensils'),
                _quickTagChip('#FoulOdor'),
                _quickTagChip('#UncoveredFood'),
                _quickTagChip('#GreasyFloor'),
              ],
            ),
            const SizedBox(height: 24),

            // Photo Evidence Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Upload Photo Evidence:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : AppTheme.navyColor),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _hasPhotoAttached ? AppTheme.primaryColor.withValues(alpha: 0.12) : (isDark ? const Color(0xFF282828) : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$_totalPhotoCount / 4 Attached',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: _hasPhotoAttached ? AppTheme.primaryColor : (isDark ? Colors.white70 : Colors.grey.shade700),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Attach photos of food, utensils, or premises for inspection validation.',
              style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey.shade600),
            ),
            const SizedBox(height: 12),

            // Photo Grid / Upload Trigger
            _buildPhotoEvidenceGrid(),
          ],
        );

      case 3:
        final effectiveOutletName = _isOtherSelected
            ? '${_customNameController.text.trim()} (New Unlisted Outlet)'
            : (_selectedRestaurant?.name ?? 'None');

        final effectiveAddress = _isOtherSelected
            ? _customAddressController.text.trim()
            : (_selectedRestaurant?.address ?? 'None');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Review Report Before Submission:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : AppTheme.navyColor),
            ),
            const SizedBox(height: 4),
            Text(
              'Please confirm that all details are accurate before lodging formal complaint.',
              style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey.shade600),
            ),
            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReviewRow('Target Outlet:', effectiveOutletName),
                  _buildReviewRow('Address:', effectiveAddress),
                  if (_isOtherSelected) _buildReviewRow('Category:', _customCategory),
                  _buildReviewRow('Main Category:', _selectedCategory),
                  _buildReviewRow('Violations Checked:', '${_selectedIssues.length} items selected'),
                  if (_selectedIssues.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 120, bottom: 10),
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: _selectedIssues.map((issue) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.35) : const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: isDark ? const Color(0xFFDC2626).withValues(alpha: 0.5) : const Color(0xFFFECACA)),
                            ),
                            child: Text(
                              '• $issue',
                              style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626), fontWeight: FontWeight.w600),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                  _buildReviewRow('Notes Details:', _description.isEmpty ? 'None provided' : _description),
                  _buildReviewRow('Photo Evidence:', _hasPhotoAttached ? 'Attached ($_totalPhotoCount photos)' : 'No photos attached'),
                  
                  // Photo Evidence Thumbnails Preview in Review Step
                  if (_hasPhotoAttached) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 70,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          ..._attachedPhotoFiles.map((file) {
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
                                image: DecorationImage(image: FileImage(file), fit: BoxFit.cover),
                              ),
                            );
                          }),
                          ..._attachedPhotoUrls.map((url) {
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
                                image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Official Guarantee Notice Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.35) : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? const Color(0xFF059669).withValues(alpha: 0.5) : const Color(0xFF86EFAC)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_outlined, color: Color(0xFF16A34A), size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your report will be securely dispatched to authorized municipal health inspectors for investigation.',
                      style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFFA7F3D0) : Colors.green.shade900, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _quickTagChip(String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        setState(() {
          _description = _description.isEmpty ? label : '$_description $label';
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF282828) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : const Color(0xFF475569), fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildPhotoEvidenceGrid() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!_hasPhotoAttached) {
      return InkWell(
        onTap: _showPhotoPickerOptionsModal,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.5 : 0.35), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_a_photo_rounded, size: 30, color: AppTheme.primaryColor),
              ),
              const SizedBox(height: 12),
              Text(
                'Tap to Upload Photo Evidence',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: isDark ? Colors.white : AppTheme.navyColor),
              ),
              const SizedBox(height: 4),
              Text(
                'Camera • Gallery • Sample Photos (Max 4)',
                style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              // 1. Files Picked
              ..._attachedPhotoFiles.asMap().entries.map((entry) {
                final idx = entry.key;
                final file = entry.value;
                return Stack(
                  children: [
                    Container(
                      width: 95,
                      height: 95,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
                        image: DecorationImage(image: FileImage(file), fit: BoxFit.cover),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _attachedPhotoFiles.removeAt(idx);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 12, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              }),

              // 2. Preset URLs Added
              ..._attachedPhotoUrls.asMap().entries.map((entry) {
                final idx = entry.key;
                final url = entry.value;
                return Stack(
                  children: [
                    Container(
                      width: 95,
                      height: 95,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
                        image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _attachedPhotoUrls.removeAt(idx);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 12, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              }),

              // 3. Add More Tile
              if (_totalPhotoCount < 4)
                InkWell(
                  onTap: _showPhotoPickerOptionsModal,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 95,
                    height: 95,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.4), style: BorderStyle.solid),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.add_photo_alternate_outlined, color: AppTheme.primaryColor, size: 26),
                        SizedBox(height: 4),
                        Text(
                          'Add More',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '✓ Evidence attached for health officer review',
                style: TextStyle(fontSize: 11.5, color: isDark ? const Color(0xFF6EE7B7) : Colors.green.shade800, fontWeight: FontWeight.w600),
              ),
              TextButton(
                onPressed: _showPhotoPickerOptionsModal,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('Change', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewRow(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white54 : Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : AppTheme.navyColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: languageManager,
      builder: (context, _) {
        final canProceed = _canProceedCurrentStep();

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
          appBar: CustomAppBar(
            title: t('submit_hygiene_report'),
          ),
      body: Column(
        children: [
          // Horizontal Step Process Header Tracker
          HorizontalStepTracker(
            currentStep: _currentStep,
            stepTitles: _stepTitles,
          ),

          // Main Step Form Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: _buildActiveStepContent(),
            ),
          ),

          // Validation Warning Message Banner
          if (!canProceed)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: isDark ? const Color(0xFF78350F).withValues(alpha: 0.3) : Colors.amber.shade50,
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: isDark ? Colors.amber.shade300 : Colors.amber.shade900),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getValidationHint(),
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.amber.shade200 : Colors.amber.shade900, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

          // Bottom Step Navigation Control Buttons
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              border: Border(top: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_currentStep > 0) ...[
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        foregroundColor: isDark ? Colors.white : AppTheme.navyColor,
                        side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _onBackPressed,
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canProceed && !_isSubmitting ? AppTheme.primaryColor : (isDark ? const Color(0xFF282828) : Colors.grey.shade300),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: (canProceed && !_isSubmitting) ? _onNextPressed : null,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                          )
                        : Text(
                            _currentStep == _stepTitles.length - 1 ? 'Submit Report' : 'Next Step',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  },
);
}
}
