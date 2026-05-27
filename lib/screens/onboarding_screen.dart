import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class _OnboardPage {
  final String title;
  final String subtitle;
  final String imagePath;
  final Color accent;

  const _OnboardPage({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.accent,
  });
}

final _pages = [
  const _OnboardPage(
    title: 'Welcome to LudoVerse',
    subtitle: 'Experience the classic board game reimagined with stunning visuals and smooth gameplay.',
    imagePath: 'assets/walkthrough/logo_gaming.jpg',
    accent: Color(0xFF6C3CE1),
  ),
  const _OnboardPage(
    title: 'Roll & Move',
    subtitle: 'Roll the dice and strategically move your pieces around the board to reach home first!',
    imagePath: 'assets/walkthrough/game.png',
    accent: Color(0xFFE53935),
  ),
  const _OnboardPage(
    title: 'Multiple Modes',
    subtitle: 'Play with 2, 3, or 4 players. Challenge your friends in exciting head-to-head battles!',
    imagePath: 'assets/walkthrough/gaming.jpeg',
    accent: Color(0xFF43A047),
  ),
  const _OnboardPage(
    title: 'Capture & Win',
    subtitle: 'Land on your opponent\'s piece to send them back to base. Be the first to get all pieces home!',
    imagePath: 'assets/walkthrough/game.png',
    accent: Color(0xFFFDD835),
  ),
  const _OnboardPage(
    title: 'Play Now!',
    subtitle: 'Your adventure starts here. Get ready for the most thrilling Ludo experience ever!',
    imagePath: 'assets/walkthrough/gaming.jpeg',
    accent: Color(0xFF1E88E5),
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _current = 0;

  void _next() {
    if (_current < _pages.length - 1) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      _finish();
    }
  }

  void _finish() {
    context.read<SettingsProvider>().markOnboardingDone();
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_current];
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D2B),
      body: Stack(
        children: [
          // Background gradient
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [page.accent.withOpacity(0.3), const Color(0xFF0D0D2B)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Skip button
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: _finish,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                          color: page.accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                  ),
                ),
                // Page view
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (i) => setState(() => _current = i),
                    itemBuilder: (ctx, i) {
                      final p = _pages[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Image with glow
                            Container(
                              width: 260,
                              height: 260,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: p.accent.withOpacity(0.4),
                                    blurRadius: 40,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: Image.asset(
                                  p.imagePath,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 50),
                            Text(
                              p.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              p.subtitle,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF9E9EBE),
                                fontSize: 16,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                // Dots + button
                Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _pages.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: i == _current ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: i == _current
                                  ? page.accent
                                  : const Color(0xFF3A3A6A),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: ElevatedButton(
                          onPressed: _next,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: page.accent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 8,
                            shadowColor: page.accent.withOpacity(0.5),
                          ),
                          child: Text(
                            _current == _pages.length - 1
                                ? 'Get Started!'
                                : 'Next',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
