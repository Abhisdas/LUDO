import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  final SharedPreferences _prefs;

  late bool _soundEnabled;
  late bool _vibrationEnabled;
  late bool _musicEnabled;
  late bool _onboardingDone;

  SettingsProvider(this._prefs) {
    _soundEnabled = _prefs.getBool('sound') ?? true;
    _vibrationEnabled = _prefs.getBool('vibration') ?? true;
    _musicEnabled = _prefs.getBool('music') ?? true;
    _onboardingDone = _prefs.getBool('onboarding_done') ?? false;
  }

  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  bool get musicEnabled => _musicEnabled;
  bool get onboardingDone => _onboardingDone;

  Future<void> toggleSound() async {
    _soundEnabled = !_soundEnabled;
    await _prefs.setBool('sound', _soundEnabled);
    notifyListeners();
  }

  Future<void> toggleVibration() async {
    _vibrationEnabled = !_vibrationEnabled;
    await _prefs.setBool('vibration', _vibrationEnabled);
    notifyListeners();
  }

  Future<void> toggleMusic() async {
    _musicEnabled = !_musicEnabled;
    await _prefs.setBool('music', _musicEnabled);
    notifyListeners();
  }

  Future<void> markOnboardingDone() async {
    _onboardingDone = true;
    await _prefs.setBool('onboarding_done', true);
    notifyListeners();
  }
}
