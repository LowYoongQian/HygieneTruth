import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../widgets/slide_to_act_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      'title': 'Safe Dining in Your Pocket!',
      'subtitle': 'Navigate and explore every clean food spot with ease using our built-in navigator.',
      'image': 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?q=80&w=1000',
    },
    {
      'title': 'Monitoring & Risk Analytics',
      'subtitle': 'AI-driven risk scoring, complaint tracking, and verified inspection records for food safety.',
      'image': 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?q=80&w=1000',
    },
    {
      'title': 'Get Started Now!',
      'subtitle': 'Select your role to start monitoring outlets, inspecting premises, or submitting reports.',
      'image': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?q=80&w=1000',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;
    final primaryColor = Theme.of(context).primaryColor;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Swipeable Onboarding Content (Half Image + Half White Body)
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              final p = _pages[index];
              return Column(
                children: [
                  // Top Half: Cover Image with Gradient Blur Blend
                  SizedBox(
                    height: screenHeight * 0.52,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          p['image']!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: const Color(0xFF0F766E),
                              child: const Icon(Icons.restaurant, size: 100, color: Colors.white24),
                            );
                          },
                        ),
                        // Soft Gradient Blur Transition blending image into white body
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: 120,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.0),
                                  Colors.white.withValues(alpha: 0.6),
                                  Colors.white,
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom Half: Clean White Body with Centered Headline & Subtitle
                  Expanded(
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          Text(
                            p['title']!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                              height: 1.25,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            p['subtitle']!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Glassmorphism Frosted Skip Button (Top Right matching reference image)
          Positioned(
            top: 54,
            right: 20,
            child: GestureDetector(
              onTap: () {
                Navigator.pushReplacementNamed(context, AppRoutes.splashRoleSelect);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ),

          // Page Indicator Dots Bar Positioned Directly On Top of the Bottom Button
          Positioned(
            bottom: 104,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (idx) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentPage == idx ? 22 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: _currentPage == idx ? primaryColor : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),

          // Fixed Bottom Action Button (Next / Slide to Get Started)
          Positioned(
            bottom: 34,
            left: 24,
            right: 24,
            child: isLastPage
                ? SlideToActButton(
                    text: 'Slide to Get Started',
                    icon: Icons.keyboard_double_arrow_right,
                    onSlideComplete: () {
                      Navigator.pushReplacementNamed(context, AppRoutes.splashRoleSelect);
                    },
                  )
                : ElevatedButton(
                    onPressed: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOut,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 3,
                    ),
                    child: const Text(
                      'Next',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
