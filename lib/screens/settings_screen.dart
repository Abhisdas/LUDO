import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D2B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A4E),
        foregroundColor: Colors.white,
        title: const Text('Settings',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Consumer<SettingsProvider>(
        builder: (ctx, settings, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionHeader('Audio'),
              _buildToggle(
                icon: Icons.volume_up_rounded,
                title: 'Sound Effects',
                subtitle: 'Dice rolls, moves, captures',
                value: settings.soundEnabled,
                color: const Color(0xFF6C3CE1),
                onChanged: (_) => settings.toggleSound(),
              ),
              _buildToggle(
                icon: Icons.music_note_rounded,
                title: 'Background Music',
                subtitle: 'Ambient game music',
                value: settings.musicEnabled,
                color: const Color(0xFF43A047),
                onChanged: (_) => settings.toggleMusic(),
              ),
              const SizedBox(height: 16),
              _buildSectionHeader('Gameplay'),
              _buildToggle(
                icon: Icons.vibration_rounded,
                title: 'Vibration',
                subtitle: 'Haptic feedback on moves',
                value: settings.vibrationEnabled,
                color: const Color(0xFF1E88E5),
                onChanged: (_) => settings.toggleVibration(),
              ),
              const SizedBox(height: 16),
              _buildSectionHeader('About'),
              _buildInfoTile(
                icon: Icons.info_outline_rounded,
                title: 'Version',
                value: '1.0.0',
              ),
              _buildInfoTile(
                icon: Icons.person_rounded,
                title: 'Developer',
                value: 'LudoVerse Team',
              ),
              const SizedBox(height: 30),
              Center(
                child: Text(
                  '🎲 LudoVerse — The Ultimate Board Game',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF6C3CE1),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildToggle({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Color color,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A4E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3A3A6A)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style: const TextStyle(
                        color: Color(0xFF9E9EBE), fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: color,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A4E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3A3A6A)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF9E9EBE)),
          const SizedBox(width: 14),
          Text(title,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(value, style: const TextStyle(color: Color(0xFF9E9EBE))),
        ],
      ),
    );
  }
}
