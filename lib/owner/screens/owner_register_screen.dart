import 'package:flutter/material.dart';
import '../../core/models/user_model.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/customer_store_service.dart';
import '../../core/widgets/custom_app_bar.dart';

class OwnerRegisterScreen extends StatefulWidget {
  const OwnerRegisterScreen({super.key});

  @override
  State<OwnerRegisterScreen> createState() => _OwnerRegisterScreenState();
}

class _OwnerRegisterScreenState extends State<OwnerRegisterScreen> {
  final _ownerNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirmPass = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _ownerNameController.dispose();
    _emailController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _handleOwnerRegistration() async {
    if (_emailController.text.trim().isEmpty ||
        _passController.text.isEmpty ||
        _ownerNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all business registration fields.')),
      );
      return;
    }

    if (_passController.text != _confirmPassController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await CustomerStoreService.registerCustomer(
      name: _ownerNameController.text,
      email: _emailController.text,
      password: _passController.text,
      role: UserRole.owner,
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (result.success) {
        CustomerStoreService.updateOwnerRole(UserRole.owner);

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Business Account Registered!'),
            content: const Text(
              'Your business account has been successfully created. You can now access your Restaurant Owner portal.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushReplacementNamed(context, AppRoutes.ownerDashboard);
                },
                child: const Text('Go to Owner Dashboard'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const ownerColor = Color(0xFFD97706);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Business Registration'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.add_business_outlined, size: 54, color: ownerColor),
            const SizedBox(height: 12),
            const Text(
              'Register Restaurant Account',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Register your business details to receive official inspection notices & report resolutions',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            TextField(
              controller: _ownerNameController,
              decoration: const InputDecoration(
                labelText: 'Owner / Manager Full Name',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Business Email Address',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _passController,
              obscureText: _obscurePass,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                  onPressed: () => setState(() => _obscurePass = !_obscurePass),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _confirmPassController,
              obscureText: _obscureConfirmPass,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: const Icon(Icons.lock_reset),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirmPass ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                  onPressed: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleOwnerRegistration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ownerColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Register Business Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Already registered your business?'),
                TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.ownerLogin),
                  child: const Text('Log In', style: TextStyle(color: ownerColor, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
