import 'package:flutter/material.dart';
import '../../core/models/user_model.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/customer_store_service.dart';
import '../../core/widgets/custom_app_bar.dart';

class AdminGovLoginScreen extends StatefulWidget {
  const AdminGovLoginScreen({super.key});

  @override
  State<AdminGovLoginScreen> createState() => _AdminGovLoginScreenState();
}

class _AdminGovLoginScreenState extends State<AdminGovLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  // Selected Official Role Portal Mode (Government or Admin)
  UserRole _selectedPortalRole = UserRole.government;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleOfficialLogin() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your official staff credentials.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await CustomerStoreService.loginCustomer(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (result.success) {
        // Apply selected official role (Government Inspector or Administrator)
        CustomerStoreService.updateOwnerRole(_selectedPortalRole);

        final targetRoute = _selectedPortalRole == UserRole.admin
            ? AppRoutes.adminDashboard
            : AppRoutes.governmentDashboard;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selectedPortalRole == UserRole.admin
                  ? 'Administrator Access Granted'
                  : 'Government Official Portal Access Granted',
            ),
            backgroundColor: _selectedPortalRole == UserRole.admin ? const Color(0xFF0F172A) : const Color(0xFF00897B),
          ),
        );
        Navigator.pushReplacementNamed(context, targetRoute);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = _selectedPortalRole == UserRole.admin;
    final primaryColor = isAdmin ? const Color(0xFF0F172A) : const Color(0xFF00897B);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Official Staff Portal'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isAdmin ? Icons.admin_panel_settings_outlined : Icons.verified_user_outlined,
                  size: 64,
                  color: primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isAdmin ? 'System Administrator Portal' : 'Government Official Portal',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              isAdmin
                  ? 'Review complaint tickets, verify restaurant submissions & log admin actions'
                  : 'Conduct inspections, issue enforcement notices & close compliance cases',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Role Segmented Switch (Government vs Admin)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedPortalRole = UserRole.government),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !isAdmin ? const Color(0xFF00897B) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Government Official',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: !isAdmin ? Colors.white : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedPortalRole = UserRole.admin),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isAdmin ? const Color(0xFF0F172A) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Administrator',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isAdmin ? Colors.white : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Official Staff ID / Email',
                prefixIcon: Icon(Icons.badge_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleOfficialLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        isAdmin ? 'Log In as Administrator' : 'Log In as Government Official',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
