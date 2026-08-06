import 'package:flutter/material.dart';
import '../../core/models/mock_seed_data.dart';
import '../../core/models/restaurant_model.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/wireframe_box.dart';

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is RestaurantModel) {
      _selectedRestaurant = args;
    } else {
      _selectedRestaurant ??= MockSeedData.restaurants.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Submit Report'),
      body: Stepper(
        type: StepperType.vertical,
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 5) {
            setState(() => _currentStep += 1);
          } else {
            _onFinalSubmit();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep -= 1);
          }
        },
        onStepTapped: (step) => setState(() => _currentStep = step),
        controlsBuilder: (context, details) {
          final isLastStep = _currentStep == 5;
          return Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: CustomButton(
                    label: isLastStep ? 'Submit Report' : 'Next Step',
                    backgroundColor: isLastStep ? Colors.red.shade700 : const Color(0xFF0284C7),
                    onPressed: details.onStepContinue!,
                  ),
                ),
                if (_currentStep > 0) ...[
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Back'),
                  ),
                ]
              ],
            ),
          );
        },
        steps: [
          // Step 1: Select Restaurant
          Step(
            title: const Text('1. Select Outlet'),
            subtitle: Text(_selectedRestaurant?.name ?? 'Tap to pick', overflow: TextOverflow.ellipsis),
            isActive: _currentStep >= 0,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<RestaurantModel>(
                  isExpanded: true,
                  initialValue: _selectedRestaurant,
                  decoration: const InputDecoration(labelText: 'Choose Outlet'),
                  items: MockSeedData.restaurants.map((r) {
                    return DropdownMenuItem(
                      value: r,
                      child: Text('${r.name} (${r.category})', overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedRestaurant = val),
                ),
                const SizedBox(height: 8),
                Row(
                  children: const [
                    Icon(Icons.my_location, size: 14, color: Color(0xFF0284C7)),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'GPS Location: Lat 3.1478, Long 101.7100',
                        style: TextStyle(fontSize: 11, color: Color(0xFF0284C7)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Step 2: Category
          Step(
            title: const Text('2. Issue Category'),
            subtitle: Text(_selectedCategory),
            isActive: _currentStep >= 1,
            content: DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Select Main Issue'),
              items: _categories.map((cat) {
                return DropdownMenuItem(value: cat, child: Text(cat));
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
          ),

          // Step 3: Specific Issues Checklist
          Step(
            title: const Text('3. Specific Issues'),
            subtitle: Text('${_selectedIssues.length} items checked'),
            isActive: _currentStep >= 2,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Check all observed violations:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                ...(_issueChecklistMap[_selectedCategory] ?? []).map((issue) {
                  final isChecked = _selectedIssues.contains(issue);
                  return CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
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
            ),
          ),

          // Step 4: Text Description
          Step(
            title: const Text('4. Description'),
            subtitle: Text(_description.isEmpty ? 'Optional details' : 'Notes added'),
            isActive: _currentStep >= 3,
            content: TextField(
              decoration: const InputDecoration(
                hintText: 'Describe details (time, table number)...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (val) => setState(() => _description = val),
            ),
          ),

          // Step 5: Photo Upload
          Step(
            title: const Text('5. Photo Proof'),
            subtitle: Text(_photoUploaded ? 'Photo attached' : 'Tap to upload'),
            isActive: _currentStep >= 4,
            content: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() => _photoUploaded = !_photoUploaded);
                  },
                  child: WireframeBox(
                    height: 120,
                    icon: _photoUploaded ? Icons.check_circle : Icons.add_a_photo,
                    label: _photoUploaded ? 'Photo Evidence Uploaded' : 'Tap to Upload Photo Evidence',
                    sublabel: _photoUploaded ? 'Tap to remove' : 'Simulating image picker',
                  ),
                ),
              ],
            ),
          ),

          // Step 6: Confirmation Summary
          Step(
            title: const Text('6. Review & Submit'),
            subtitle: const Text('Verify before sending'),
            isActive: _currentStep >= 5,
            content: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Outlet: ${_selectedRestaurant?.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Category: $_selectedCategory'),
                  Text('Checked Items: ${_selectedIssues.length} issues'),
                  Text('Photo: ${_photoUploaded ? "Attached" : "None"}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onFinalSubmit() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report submitted successfully! Track status in My Reports.'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }
}
