import 'package:flutter/material.dart';
import '../../core/models/mock_seed_data.dart';
import '../../core/models/restaurant_model.dart';
import '../../core/services/language_manager.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/translations.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/wireframe_box.dart';
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
  bool _photoUploaded = false;

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

  @override
  void dispose() {
    _customNameController.dispose();
    _customAddressController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is RestaurantModel) {
      _selectedRestaurant = args;
    } else {
      _selectedRestaurant ??= MockSeedData.restaurants.isNotEmpty ? MockSeedData.restaurants.first : null;
    }
  }

  bool get _isOtherSelected => _selectedRestaurant?.id == 'other_new';

  // Strict Validation: Returns true only when current step requirements are met
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
        return _description.trim().isNotEmpty || _photoUploaded;
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

  void _onNextPressed() {
    if (!_canProceedCurrentStep()) return;
    if (_currentStep < _stepTitles.length - 1) {
      setState(() {
        _currentStep += 1;
      });
    } else {
      _submitReport();
    }
  }

  void _onBackPressed() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep -= 1;
      });
    } else {
      Navigator.pop(context);
    }
  }

  void _submitReport() {
    final effectiveOutlet = _isOtherSelected
        ? _customNameController.text.trim()
        : (_selectedRestaurant?.name ?? 'Selected Premises');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.check_circle, color: Color(0xFF10B981), size: 28),
              SizedBox(width: 10),
              Expanded(
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
                'Your hygiene complaint report for "$effectiveOutlet" has been logged successfully.',
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ticket ID: #REP-2026-8842', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.navyColor)),
                    const SizedBox(height: 4),
                    Text('Status: Pending Official Verification', style: TextStyle(fontSize: 12, color: Colors.amber.shade800, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('Back to Home', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // Active Step Form Controls
  Widget _buildActiveStepContent() {
    switch (_currentStep) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Restaurant / Food Stall Premises:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.navyColor),
            ),
            const SizedBox(height: 12),

            // High-Quality Custom Styled Dropdown Container
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: DropdownButtonFormField<RestaurantModel>(
                isExpanded: true,
                initialValue: _selectedRestaurant,
                borderRadius: BorderRadius.circular(16),
                dropdownColor: Colors.white,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primaryColor, size: 26),
                decoration: InputDecoration(
                  labelText: 'Choose Restaurant / Food Stall',
                  labelStyle: TextStyle(color: Colors.grey.shade700, fontSize: 14, fontWeight: FontWeight.w600),
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
                  ...MockSeedData.restaurants.map((r) {
                    return DropdownMenuItem<RestaurantModel>(
                      value: r,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              r.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.navyColor),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              r.category,
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const DropdownMenuItem<RestaurantModel>(
                    value: _otherRestaurantOption,
                    child: Row(
                      children: [
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
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.4), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.add_business_rounded, color: AppTheme.primaryColor, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'New Restaurant Premises Information',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.navyColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Enter details for the new unlisted food outlet below:',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),

                    // 1. Restaurant Name Input
                    TextField(
                      controller: _customNameController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Restaurant / Stall Name *',
                        hintText: 'e.g. Restoran Sin Huat, Stall 12',
                        prefixIcon: const Icon(Icons.store, color: AppTheme.primaryColor, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 2. Cuisine Category Selector
                    DropdownButtonFormField<String>(
                      initialValue: _customCategory,
                      decoration: InputDecoration(
                        labelText: 'Cuisine / Premises Category',
                        prefixIcon: const Icon(Icons.restaurant_menu, color: AppTheme.primaryColor, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white,
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
                          child: Text(cat, style: const TextStyle(fontSize: 13)),
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
                      decoration: InputDecoration(
                        labelText: 'Premises Address & Landmark Details *',
                        hintText: 'e.g. Lot 45, Jalan Bukit Bintang, Kuala Lumpur',
                        prefixIcon: const Icon(Icons.place, color: AppTheme.primaryColor, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white,
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
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: const [
                  Icon(Icons.gps_fixed, size: 18, color: AppTheme.primaryColor),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'GPS Location Tagged: 3.1466, 101.6958 (Kuala Lumpur)',
                      style: TextStyle(fontSize: 12, color: AppTheme.navyColor, fontWeight: FontWeight.w500),
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
            const Text(
              'Issue Category:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.navyColor),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category',
                prefixIcon: const Icon(Icons.category, color: AppTheme.primaryColor),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: _categories.map((c) {
                return DropdownMenuItem(
                  value: c,
                  child: Text(c),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedCategory = val;
                    _selectedIssues.clear();
                  });
                }
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Observed Hygiene Issues (Check all that apply):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.navyColor),
            ),
            const SizedBox(height: 8),
            ...currentChecklist.map((issue) {
              final isChecked = _selectedIssues.contains(issue);
              return CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: AppTheme.primaryColor,
                title: Text(issue, style: const TextStyle(fontSize: 13)),
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
              );
            }),
          ],
        );

      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Description Details:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.navyColor),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                hintText: 'Describe details (e.g. time of visit, table location, staff response)...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 3,
              onChanged: (val) => setState(() => _description = val),
            ),
            const SizedBox(height: 20),
            const Text(
              'Upload Photo Evidence:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.navyColor),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                setState(() => _photoUploaded = !_photoUploaded);
              },
              child: WireframeBox(
                height: 120,
                icon: _photoUploaded ? Icons.check_circle : Icons.add_a_photo,
                label: _photoUploaded ? 'Photo Evidence Uploaded' : 'Tap to Upload Photo Evidence',
                sublabel: _photoUploaded ? 'Tap to remove photo' : 'Attach photo for inspection verification',
              ),
            ),
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
            const Text(
              'Review Report Before Submission:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.navyColor),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReviewRow('Target Outlet:', effectiveOutletName),
                  _buildReviewRow('Address:', effectiveAddress),
                  if (_isOtherSelected) _buildReviewRow('Category:', _customCategory),
                  _buildReviewRow('Main Category:', _selectedCategory),
                  _buildReviewRow('Checked Violations:', '${_selectedIssues.length} items selected'),
                  _buildReviewRow('Notes Description:', _description.isEmpty ? 'None provided' : _description),
                  _buildReviewRow('Photo Proof:', _photoUploaded ? 'Attached (1 photo)' : 'None'),
                ],
              ),
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildReviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.navyColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: languageManager,
      builder: (context, _) {
        final canProceed = _canProceedCurrentStep();

        return Scaffold(
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
              color: Colors.amber.shade50,
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.amber.shade900),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getValidationHint(),
                      style: TextStyle(fontSize: 12, color: Colors.amber.shade900, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

          // Bottom Step Navigation Control Buttons
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
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
                      backgroundColor: canProceed ? AppTheme.primaryColor : Colors.grey.shade300,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: canProceed ? _onNextPressed : null,
                    child: Text(
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
