import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/custom_button.dart';

class SplashRoleSelectScreen extends StatelessWidget {
  const SplashRoleSelectScreen({super.key});

  void _navigateToLogin(BuildContext context, String targetRoute) {
    Navigator.pushNamed(
      context,
      AppRoutes.login,
      arguments: {'targetRoute': targetRoute},
    );
  }

  @override
  Widget build(BuildContext context) {
    const navyColor = Color(0xFF0C2340);
    const tealColor = Color(0xFF00A88F);

    return Scaffold(
      backgroundColor: navyColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(
                Icons.health_and_safety_outlined,
                size: 70,
                color: Color(0xFF80EE98), // Mint sparkle logo accent
              ),
              const SizedBox(height: 12),
              const Text(
                'Hygiene Portal',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Complaints & Risk Monitoring',
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFF80EE98).withValues(alpha: 0.9),
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Select Role to Log In',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: navyColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    CustomButton(
                      label: 'Customer',
                      icon: Icons.person_outline,
                      backgroundColor: tealColor,
                      onPressed: () => _navigateToLogin(context, AppRoutes.userDashboard),
                    ),
                    const SizedBox(height: 10),
                    CustomButton(
                      label: 'Restaurant Owner',
                      icon: Icons.storefront,
                      backgroundColor: const Color(0xFFD97706),
                      onPressed: () => _navigateToLogin(context, AppRoutes.ownerDashboard),
                    ),
                    const SizedBox(height: 10),
                    CustomButton(
                      label: 'Government',
                      icon: Icons.verified_user_outlined,
                      backgroundColor: const Color(0xFF00897B),
                      onPressed: () => _navigateToLogin(context, AppRoutes.governmentDashboard),
                    ),
                    const SizedBox(height: 10),
                    CustomButton(
                      label: 'Admin',
                      icon: Icons.admin_panel_settings_outlined,
                      backgroundColor: navyColor,
                      onPressed: () => _navigateToLogin(context, AppRoutes.adminDashboard),
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, AppRoutes.login);
                          },
                          icon: const Icon(Icons.login, size: 18, color: tealColor),
                          label: const Text(
                            'Log In',
                            style: TextStyle(color: tealColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(height: 20, width: 1, color: Colors.grey.shade300),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, AppRoutes.register);
                          },
                          icon: const Icon(Icons.person_add_alt, size: 18, color: tealColor),
                          label: const Text(
                            'Register',
                            style: TextStyle(color: tealColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
