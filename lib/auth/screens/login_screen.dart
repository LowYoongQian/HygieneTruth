import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/customer_store_service.dart';
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
  bool _rememberMe = false; // State for Remember Me Checkbox
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

    await CustomerStoreService.loginCustomer(
      email: 'google_user@example.com',
      password: 'google_oauth_pass',
      rememberMe: _rememberMe,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google Sign-In successful! Customer data synced.')),
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

    // Authenticate with Supabase & CustomerStoreService
    final result = await CustomerStoreService.loginCustomer(
      email: _emailController.text,
      password: _passwordController.text,
      rememberMe: _rememberMe,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        _isTraditionalLoading = false;
      });

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, targetRoute);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.red,
          ),
        );
      }
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
            const SizedBox(height: 6),

            // Remember Me Checkbox on Far Left & Forgot Password Link on Far Right
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Far Left: Remember Me Checkbox & Label
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      activeColor: primaryColor,
                      visualDensity: VisualDensity.compact,
                      onChanged: (val) {
                        setState(() {
                          _rememberMe = val ?? false;
                        });
                      },
                    ),
                    const Text(
                      'Remember me',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),

                // Far Right: Forgot Password Link
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.resetPassword);
                  },
                  child: Text(
                    'Forgot password?',
                    style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
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
                const Text("Don't have an account?"),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.register);
                  },
                  child: Text(
                    'Register',
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
                    'OR CONTINUING WITH',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey.shade300)),
              ],
            ),
            const SizedBox(height: 20),

            // Google Sign-In Button
            Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: _isGoogleLoading ? 54 : fullButtonWidth,
                height: 52,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
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
                            key: ValueKey('google_spinner'),
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : SingleChildScrollView(
                            key: const ValueKey('google_text_row'),
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
                                  'Sign in with Google',
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
