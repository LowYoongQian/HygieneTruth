import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/custom_app_bar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'user@example.com');
  final _passwordController = TextEditingController(text: 'password123');

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isTraditionalLoading = false;
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _isGoogleLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google Sign-In successful! (Demo)')),
      );
      setState(() {
        _isLoading = false;
        _isGoogleLoading = false;
      });
      Navigator.pushReplacementNamed(context, AppRoutes.userDashboard);
    }
  }

  Future<void> _handleLogin() async {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final targetRoute = args?['targetRoute'] as String? ?? AppRoutes.userDashboard;

    setState(() {
      _isLoading = true;
      _isTraditionalLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      setState(() {
        _isLoading = false;
        _isTraditionalLoading = false;
      });
      Navigator.pushReplacementNamed(context, targetRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final fullButtonWidth = MediaQuery.of(context).size.width - 48;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Log In'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.storefront,
              size: 72,
              color: primaryColor,
            ),
            const SizedBox(height: 12),
            const Text(
              'Hygiene Portal',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Sign in to track hygiene updates & reports',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            // Email Field
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

            // Password Field with Visibility Toggle
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
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                border: const OutlineInputBorder(),
              ),
            ),

            // Forgot Password Link
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.resetPassword);
                },
                child: Text(
                  'Forgot password?',
                  style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Animated Log In Button (Styled in Brand Theme Color)
            Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: _isTraditionalLoading ? 54 : fullButtonWidth,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
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
                            key: ValueKey('login_spinner'),
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : SingleChildScrollView(
                            key: const ValueKey('login_text_row'),
                            scrollDirection: Axis.horizontal,
                            physics: const NeverScrollableScrollPhysics(),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.login, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Log In',
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

            // Register Account Link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Don't have an account? ",
                  style: TextStyle(color: Colors.grey),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.register);
                  },
                  child: Text(
                    'Register',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // "OR" Divider Line
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey.shade400, thickness: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'OR',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey.shade400, thickness: 1)),
              ],
            ),
            const SizedBox(height: 24),

            // Animated Google Sign-In Button
            Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: _isGoogleLoading ? 54 : fullButtonWidth,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(_isGoogleLoading ? 27 : 10),
                  border: Border.all(color: Colors.grey.shade400, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: _isLoading ? null : _handleGoogleSignIn,
                  borderRadius: BorderRadius.circular(_isGoogleLoading ? 27 : 10),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _isGoogleLoading
                          ? SizedBox(
                              key: const ValueKey('google_spinner'),
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: primaryColor,
                              ),
                            )
                          : SingleChildScrollView(
                              key: const ValueKey('google_text_row'),
                              scrollDirection: Axis.horizontal,
                              physics: const NeverScrollableScrollPhysics(),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(width: 16),
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'G',
                                        style: TextStyle(
                                          color: Color(0xFF4285F4),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Sign in with Google',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
