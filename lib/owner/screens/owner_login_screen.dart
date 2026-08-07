import 'package:flutter/material.dart';
import '../../core/models/user_model.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/customer_store_service.dart';
import '../../core/services/remember_me_service.dart';
import '../../core/widgets/custom_app_bar.dart';

class OwnerLoginScreen extends StatefulWidget {
  const OwnerLoginScreen({super.key});

  @override
  State<OwnerLoginScreen> createState() => _OwnerLoginScreenState();
}

class _OwnerLoginScreenState extends State<OwnerLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRememberedCredentials();
  }

  Future<void> _loadRememberedCredentials() async {
    final data = await RememberMeService.getRememberedUser();
    if (data['rememberMe'] == true && mounted) {
      setState(() {
        _rememberMe = true;
        _emailController.text = data['email'] ?? '';
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleOwnerLogin() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your business email and password.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await CustomerStoreService.loginCustomer(
      email: _emailController.text,
      password: _passwordController.text,
      rememberMe: _rememberMe,
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (result.success) {
        // Enforce owner role override for business portal access
        CustomerStoreService.updateOwnerRole(UserRole.owner);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Welcome to Restaurant Owner Portal!'),
            backgroundColor: Colors.amber,
          ),
        );
        Navigator.pushReplacementNamed(context, AppRoutes.ownerDashboard);
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
      appBar: const CustomAppBar(title: 'Business Portal Login'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ownerColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.storefront, size: 64, color: ownerColor),
            ),
            const SizedBox(height: 16),
            const Text(
              'Restaurant Owner Portal',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Manage hygiene inspection compliance, notices & reports',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Business Email',
                prefixIcon: Icon(Icons.business_center_outlined),
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
            const SizedBox(height: 10),

            Row(
              children: [
                Checkbox(
                  value: _rememberMe,
                  activeColor: ownerColor,
                  onChanged: (val) => setState(() => _rememberMe = val ?? false),
                ),
                const Text('Remember me', style: TextStyle(fontSize: 14)),
              ],
            ),
            const SizedBox(height: 16),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleOwnerLogin,
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
                    : const Text('Log In to Business Portal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Need a Business Account?'),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.ownerRegister),
                  child: const Text('Register Business', style: TextStyle(color: ownerColor, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
