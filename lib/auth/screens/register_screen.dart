import 'package:flutter/material.dart';
import '../../core/models/user_model.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/customer_store_service.dart';
import '../../core/utils/input_validator.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/google_sign_in_button.dart';

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

  String? _nameError;
  String? _emailError;
  String? _passError;
  String? _confirmPassError;

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



  // --- TRADITIONAL REGISTRATION FLOW ---
  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final pass = _passController.text;
    final confirmPass = _confirmPassController.text;

    final nameErr = InputValidator.validateName(name, fieldName: 'your name');
    final emailErr = InputValidator.validateEmail(email);
    final passErr = InputValidator.validatePassword(pass);
    final confirmErr = InputValidator.validateConfirmPassword(pass, confirmPass);

    setState(() {
      _nameError = nameErr;
      _emailError = emailErr;
      _passError = passErr;
      _confirmPassError = confirmErr;
    });

    setState(() {
      _isLoading = true;
      _isTraditionalLoading = true;
    });

    final result = await CustomerStoreService.registerCustomer(
      name: name,
      email: email,
      password: pass,
      role: UserRole.user,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        _isTraditionalLoading = false;
      });

      if (result.success) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.userDashboard,
          (route) => false,
          arguments: {'showProfileSetupDialog': true},
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- GOOGLE SIGN UP FLOW ---
  Future<void> _handleGoogleRegistration() async {
    setState(() {
      _isLoading = true;
      _isGoogleLoading = true;
    });

    final result = await CustomerStoreService.signInWithGoogle();

    if (mounted) {
      setState(() {
        _isLoading = false;
        _isGoogleLoading = false;
      });

      if (result.success && CustomerStoreService.currentCustomer != null) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.userDashboard,
          (route) => false,
          arguments: {'showProfileSetupDialog': true},
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
              decoration: InputDecoration(
                labelText: 'Full Name',
                prefixIcon: const Icon(Icons.person_outline),
                border: const OutlineInputBorder(),
                errorText: _nameError,
              ),
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
            ),
            const SizedBox(height: 16),

            // Email Address
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email Address',
                prefixIcon: const Icon(Icons.email_outlined),
                border: const OutlineInputBorder(),
                errorText: _emailError,
              ),
              keyboardType: TextInputType.emailAddress,
              onChanged: (_) {
                if (_emailError != null) setState(() => _emailError = null);
              },
            ),
            const SizedBox(height: 16),

            // Password Field
            TextField(
              controller: _passController,
              obscureText: _obscurePass,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                errorText: _passError,
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
              onChanged: (_) {
                if (_passError != null) setState(() => _passError = null);
              },
            ),
            const SizedBox(height: 16),

            // Confirm Password Field
            TextField(
              controller: _confirmPassController,
              obscureText: _obscureConfirmPass,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: const Icon(Icons.lock_reset),
                errorText: _confirmPassError,
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
              onChanged: (_) {
                if (_confirmPassError != null) setState(() => _confirmPassError = null);
              },
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
                        : const Text(
                            'Register Account',
                            key: ValueKey('reg_text_row'),
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
            GoogleSignInButton(
              text: 'Register with Google',
              isLoading: _isGoogleLoading,
              width: fullButtonWidth,
              onPressed: _isLoading ? null : _handleGoogleRegistration,
            ),
          ],
        ),
      ),
    );
  }
}
