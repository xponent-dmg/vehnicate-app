import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:opsin/core/constants/app_gradients.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const String _prefsOnboardingSeenKey = 'onboarding_seen';

  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<_OnboardingItem> _items = const [
    _OnboardingItem(
      icon: Icons.directions_car_filled_rounded,
      title: 'Welcome to Vehnicate',
      description:
          'Vehnicate is your connected driving companion for smarter and safer vehicle journeys.',
    ),
    _OnboardingItem(
      icon: Icons.analytics_rounded,
      title: 'Know Your Drive',
      description:
          'We analyze your trip and sensor data to help you understand ride quality, behavior, and road conditions.',
    ),
    _OnboardingItem(
      icon: Icons.emergency_share_rounded,
      title: 'Stay Informed, Stay Ready',
      description:
          'Get important driving insights and stay connected with tools designed to improve every trip.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsOnboardingSeenKey, true);

    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    Navigator.pushReplacementNamed(context, user != null ? '/home' : '/login');
  }

  void _nextPage() {
    if (_currentIndex == _items.length - 1) {
      _completeOnboarding();
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppGradients.mainBackground),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _completeOnboarding,
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _items.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return _OnboardingCard(item: item);
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_items.length, (index) {
                    final isActive = index == _currentIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: isActive ? 26 : 8,
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF2D2D44),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      _currentIndex == _items.length - 1
                          ? 'Get Started'
                          : 'Continue',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingCard extends StatelessWidget {
  const _OnboardingCard({required this.item});

  final _OnboardingItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.17),
            shape: BoxShape.circle,
          ),
          child: Icon(item.icon, size: 64, color: Colors.white),
        ),
        const SizedBox(height: 28),
        Text(
          item.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          item.description,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.92),
            fontSize: 16,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _OnboardingItem {
  const _OnboardingItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}
