import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/customer_store_service.dart';
import '../../core/widgets/custom_app_bar.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirmPass = true;

  bool _isLoading = false;
  bool _isTraditionalLoading = false;
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleRegistration() async {
    setState(() {
      _isLoading = true;
      _isGoogleLoading = true;
    });

    await CustomerStoreService.registerCustomer(
      name: 'Google Customer',
      email: 'google_user@example.com',
      password: 'google_oauth_pass',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google Registration successful! Customer account saved.')),
      );
      setState(() {
        _isLoading = false;
        _isGoogleLoading = false;
      });
      Navigator.pushReplacementNamed(context, AppRoutes.userDashboard);
    }
  }

  Future<void> _handleRegister() async {
    if (_passController.text.isEmpty || _passController.text != _confirmPassController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _isTraditionalLoading = true;
    });

    // Save Customer Data to Supabase & CustomerStoreService
    final result = await CustomerStoreService.registerCustomer(
      name: _nameController.text,
      email: _emailController.text,
      password: _passController.text,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        _isTraditionalLoading = false;
      });

      if (result.success) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Customer Registration Successful!'),
            content: Text(
              '${result.message}\nYour customer data has been stored. You can now log in to access your customer portal.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushReplacementNamed(context, AppRoutes.login);
                },
                child: const Text('OK'),
              )
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
    final primaryColor = Theme.of(context).primaryColor;
    final fullButtonWidth = MediaQuery.of(context).size.width - 48;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Create Account'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.person_add_alt_1,
              size: 72,
              color: primaryColor,
            ),
            const SizedBox(height: 12),
            const Text(
              'Register Account',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Start monitoring & reporting in seconds',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Username / Full Name
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Email Address
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            // Password Field
            TextField(
              controller: _passController,
              obscureText: _obscurePass,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePass ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePass = !_obscurePass;
                    });
                  },
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Confirm Password Field
            TextField(
              controller: _confirmPassController,
              obscureText: _obscureConfirmPass,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: const Icon(Icons.lock_reset),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPass ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPass = !_obscureConfirmPass;
                    });
                  },
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Animated Register Button
            Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: _isTraditionalLoading ? 54 : fullButtonWidth,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_isTraditionalLoading ? 27 : 12),
                    ),
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 2,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _isTraditionalLoading
                        ? const SizedBox(
                            key: ValueKey('reg_spinner'),
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : SingleChildScrollView(
                            key: const ValueKey('reg_text_row'),
                            scrollDirection: Axis.horizontal,
                            physics: const NeverScrollableScrollPhysics(),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.check_circle_outline, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Register Account',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Login Route Link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Already have an account?'),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, AppRoutes.login);
                  },
                  child: Text(
                    'Log In',
                    style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Divider Line
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey.shade300)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'OR REGISTER WITH',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey.shade300)),
              ],
            ),
            const SizedBox(height: 20),

            // Google Registration Button
            Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: _isGoogleLoading ? 54 : fullButtonWidth,
                height: 52,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _handleGoogleRegistration,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_isGoogleLoading ? 27 : 12),
                    ),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _isGoogleLoading
                        ? const SizedBox(
                            key: ValueKey('google_reg_spinner'),
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : SingleChildScrollView(
                            key: const ValueKey('google_reg_text_row'),
                            scrollDirection: Axis.horizontal,
                            physics: const NeverScrollableScrollPhysics(),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.network(
                                  'https://upload.wikimedia.org/wikipedia/commons/5/53/Google_%22G%22_Logo.svg',
                                  height: 22,
                                  width: 22,
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata, size: 28, color: Colors.red),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Register with Google',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
