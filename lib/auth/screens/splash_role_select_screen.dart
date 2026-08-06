import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/custom_button.dart';

class SplashRoleSelectScreen extends StatelessWidget {
  const SplashRoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F766E),
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
                color: Colors.white,
              ),
              const SizedBox(height: 12),
              const Text(
                'Hygiene Portal',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Complaints & Risk Monitoring',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.teal.shade100,
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
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Select Role',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    CustomButton(
                      label: 'Public User',
                      icon: Icons.person_outline,
                      backgroundColor: const Color(0xFF0284C7),
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, AppRoutes.userDashboard);
                      },
                    ),
                    const SizedBox(height: 10),
                    CustomButton(
                      label: 'Admin',
                      icon: Icons.admin_panel_settings_outlined,
                      backgroundColor: const Color(0xFF0F172A),
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
                      },
                    ),
                    const SizedBox(height: 10),
                    CustomButton(
                      label: 'Officer',
                      icon: Icons.verified_user_outlined,
                      backgroundColor: const Color(0xFF0F766E),
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, AppRoutes.governmentDashboard);
                      },
                    ),
                    const SizedBox(height: 10),
                    CustomButton(
                      label: 'Owner',
                      icon: Icons.storefront,
                      backgroundColor: const Color(0xFFD97706),
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, AppRoutes.ownerDashboard);
                      },
                    ),
                    const SizedBox(height: 14),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
                          icon: const Icon(Icons.login, size: 18),
                          label: const Text('Log In'),
                        ),
                        const Text(' | ', style: TextStyle(color: Colors.grey)),
                        TextButton.icon(
                          onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
                          icon: const Icon(Icons.person_add, size: 18),
                          label: const Text('Register'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
