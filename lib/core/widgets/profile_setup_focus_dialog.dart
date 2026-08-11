import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/customer_store_service.dart';
import '../theme/app_theme.dart';

class ProfileSetupFocusDialog {
  /// Displays a Strong Focus Backdrop Dialog overlaying the Home Page
  static void show(BuildContext context, {bool isGoogleFlow = false}) {
    String? selectedGender;
    String? selectedCountry;
    String? selectedState;

    final customGenderCtrl = TextEditingController();
    final customCountryCtrl = TextEditingController();
    final customStateCtrl = TextEditingController();

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Profile Setup Focus',
      barrierColor: Colors.black.withValues(alpha: 0.65), // Strong Darkened Backdrop Focus
      transitionDuration: const Duration(milliseconds: 350),
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack).value,
          child: child,
        );
      },
      pageBuilder: (ctx, anim1, anim2) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            elevation: 20,
            backgroundColor: Colors.white,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                final customer = CustomerStoreService.currentCustomer;

                return Padding(
                  padding: const EdgeInsets.all(22.0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header Icon & Title
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.person_pin_outlined, color: AppTheme.primaryColor, size: 28),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    customer != null ? 'Welcome, ${customer.name}!' : 'Personal Details (Optional)',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.navyColor),
                                  ),
                                  const Text(
                                    'Select gender, country, and state or set it later',
                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // 1. GENDER DROPDOWN
                        const Text('Gender', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.navyColor)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: selectedGender,
                          decoration: InputDecoration(
                            hintText: 'Select Gender',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                        ],

                        const SizedBox(height: 14),

                        // 2. COUNTRY DROPDOWN
                        const Text('Country / Region', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.navyColor)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: selectedCountry,
                          decoration: InputDecoration(
                            hintText: 'Select Country',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                        ],

                        const SizedBox(height: 14),

                        // 3. STATE DROPDOWN
                        const Text('State / City', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.navyColor)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: selectedState,
                          decoration: InputDecoration(
                            hintText: 'Select State / City',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // ACTION BUTTONS
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () async {
                            final finalGender = selectedGender == 'Other' ? customGenderCtrl.text.trim() : selectedGender;
                            final finalCountry = selectedCountry == 'Other' ? customCountryCtrl.text.trim() : selectedCountry;
                            final finalState = selectedState == 'Other' ? customStateCtrl.text.trim() : selectedState;

                            Navigator.pop(ctx);
                            final current = CustomerStoreService.currentCustomer;
                            if (current != null) {
                              await CustomerStoreService.updateCustomerProfile(
                                name: current.name,
                                gender: finalGender,
                                country: finalCountry,
                                state: finalState,
                              );
                            }
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Profile details saved successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          },
                          child: const Text('Save & Continue to Home', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Optional profile details skipped. You can set your gender, country, and state anytime later in Profile Settings.'),
                                backgroundColor: AppTheme.primaryColor,
                                duration: Duration(seconds: 4),
                              ),
                            );
                          },
                          child: const Text('Set It Later', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
