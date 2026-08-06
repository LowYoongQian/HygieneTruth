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

  // 1 Screen, 3 Pages (Introduce, About Project App, Tell User to Proceed)
  final List<Map<String, String>> _pages = [
    {
      'title': 'Safe Dining in Your Pocket!',
      'subtitle': 'Navigate and explore every clean food spot with ease using our built-in navigator.',
      'image': 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?q=80&w=1000',
      'button': 'Next',
    },
    {
      'title': 'Monitoring & Risk Analytics',
      'subtitle': 'AI-driven risk scoring, complaint tracking, and verified inspection records for food safety.',
      'image': 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?q=80&w=1000',
      'button': 'Next',
    },
    {
      'title': 'Get Started Now!',
      'subtitle': 'Select your role to start monitoring outlets, inspecting premises, or submitting reports.',
      'image': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?q=80&w=1000',
      'button': 'Slide to Get Started',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 3 Swipeable Onboarding Pages
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
              return Stack(
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
                  // Dark Gradient Overlay at bottom for crisp text readability
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black45,
                          Colors.black87,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.3, 0.6, 1.0],
                      ),
                    ),
                  ),
                  // Headline & Subtitle Text
                  Positioned(
                    bottom: 120,
                    left: 24,
                    right: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p['title']!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            height: 1.15,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          p['subtitle']!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),

          // Top Header Indicator Dots (3 Dots) + Skip Button
          Positioned(
            top: 54,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 6),
                      width: _currentPage == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index ? const Color(0xFFD9F99D) : Colors.white38,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, AppRoutes.splashRoleSelect);
                  },
                  child: const Text(
                    'Skip',
                    style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Action Area
          // Pages 1 & 2: Clean centered pill button ("Next") without arrow icon
          // Page 3 (Last Page): Interactive Slide-to-Act Button ("Slide to Get Started")
          Positioned(
            bottom: 34,
            left: 24,
            right: 24,
            child: isLastPage
                ? SlideToActButton(
                    text: 'Slide to Get Started',
                    icon: Icons.check,
                    onSlideComplete: () {
                      Navigator.pushReplacementNamed(context, AppRoutes.splashRoleSelect);
                    },
                  )
                : GestureDetector(
                    onTap: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      height: 58,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'Next',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
