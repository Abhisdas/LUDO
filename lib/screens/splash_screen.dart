import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _scaleAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );
    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      final settings = context.read<SettingsProvider>();
      Navigator.pushReplacementNamed(
        context,
        settings.onboardingDone ? '/home' : '/onboarding',
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D2B),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [Color(0xFF1A1A4E), Color(0xFF0D0D2B)],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (ctx, child) {
              return FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: child,
                ),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C3CE1), Color(0xFFAA00FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6C3CE1).withOpacity(0.6),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/logo.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF6C3CE1), Color(0xFFE040FB)],
                  ).createShader(bounds),
                  child: const Text(
                    'LudoVerse',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'The Ultimate Board Game',
                  style: TextStyle(
                    color: Color(0xFF9E9EBE),
                    fontSize: 16,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 60),
                SizedBox(
                  width: 200,
                  child: LinearProgressIndicator(
                    backgroundColor: const Color(0xFF1A1A4E),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF6C3CE1),
                    ),
                    borderRadius: BorderRadius.circular(10),
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
