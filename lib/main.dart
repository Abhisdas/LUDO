import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/game_screen.dart';
import 'screens/settings_screen.dart';
import 'providers/game_provider.dart';
import 'providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  final prefs = await SharedPreferences.getInstance();
  runApp(LudoVerseApp(prefs: prefs));
}

class LudoVerseApp extends StatelessWidget {
  final SharedPreferences prefs;
  const LudoVerseApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider(prefs)),
      ],
      child: MaterialApp(
        title: 'LudoVerse',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6C3CE1),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        initialRoute: '/splash',
        routes: {
          '/splash': (ctx) => const SplashScreen(),
          '/onboarding': (ctx) => const OnboardingScreen(),
          '/home': (ctx) => const HomeScreen(),
          '/game': (ctx) => const GameScreen(),
          '/settings': (ctx) => const SettingsScreen(),
        },
      ),
    );
  }
}
