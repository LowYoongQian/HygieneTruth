import 'package:flutter/material.dart';
import '../../core/models/user_model.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/customer_store_service.dart';
import '../../core/services/remember_me_service.dart';
import '../../core/utils/input_validator.dart';
import '../../core/widgets/custom_app_bar.dart';

class OwnerLoginScreen extends StatefulWidget {
  const OwnerLoginScreen({super.key});

  @override
  State<OwnerLoginScreen> createState() => _OwnerLoginScreenState();
}

class _OwnerLoginScreenState extends State<OwnerLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _emailError;
  String? _passwordError;

  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRememberedCredentials();
  }

  Future<void> _loadRememberedCredentials() async {
    final data = await RememberMeService.getRememberedUser(portal: PortalType.owner);
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
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final emailErr = InputValidator.validateEmail(email);
    final passErr = InputValidator.validatePassword(password);

    setState(() {
      _emailError = emailErr;
      _passwordError = passErr;
    });

    if (emailErr != null || passErr != null) {
      String msg;
      if (email.isEmpty && password.isEmpty) {
        msg = 'Please enter email and password';
      } else if (emailErr != null) {
        msg = emailErr;
      } else {
        msg = passErr!;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    await RememberMeService.saveRememberedUser(
      rememberMe: _rememberMe,
      email: email,
      portal: PortalType.owner,
    );

    final result = await CustomerStoreService.loginCustomer(
      email: email,
      password: password,
      rememberMe: _rememberMe,
      portal: PortalType.owner,
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (result.success) {
        // Enforce owner role override for business portal access
        CustomerStoreService.updateOwnerRole(UserRole.owner);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Welcome to Businessman Portal!'),
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
              'Businessman Portal',
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
              decoration: InputDecoration(
                labelText: 'Business Email',
                prefixIcon: const Icon(Icons.business_center_outlined),
                border: const OutlineInputBorder(),
                errorText: _emailError,
              ),
              onChanged: (_) {
                if (_emailError != null) setState(() => _emailError = null);
              },
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                errorText: _passwordError,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) {
                if (_passwordError != null) setState(() => _passwordError = null);
              },
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
