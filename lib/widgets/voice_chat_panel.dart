import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

class VoiceChatPanel extends StatefulWidget {
  const VoiceChatPanel({super.key});

  @override
  State<VoiceChatPanel> createState() => _VoiceChatPanelState();
}

class _VoiceChatPanelState extends State<VoiceChatPanel> {
  bool noiseSuppression = true;
  bool echoCancellation = true;
  final Map<PlayerColor, double> playerVolumes = {
    PlayerColor.red: 1.0,
    PlayerColor.green: 1.0,
    PlayerColor.yellow: 1.0,
    PlayerColor.blue: 1.0,
  };

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF16163F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF3A3A6A),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.spatial_audio_off_rounded, color: Color(0xFF6C3CE1), size: 24),
                        SizedBox(width: 8),
                        Text(
                          'LudoVerse Voice Lobby',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      game.voiceChatConnected
                          ? 'Connected • Room #LV-9832 • Ping: ${game.voiceChannelPing.toInt()}ms'
                          : 'Disconnected • Group Voice Channel',
                      style: TextStyle(
                        color: game.voiceChatConnected ? const Color(0xFF4CAF50) : const Color(0xFF9E9EBE),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (game.voiceChatConnected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.wifi_rounded, color: Color(0xFF4CAF50), size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Live',
                          style: TextStyle(color: Color(0xFF4CAF50), fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            // Player list
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: game.players.length,
                itemBuilder: (ctx, idx) {
                  final player = game.players[idx];
                  final playerColorVal = game.colorOf(player.color);
                  final isLocal = player.color == PlayerColor.red;
                  final isMuted = isLocal ? game.voiceChatMuted : false;
                  final isSpeaking = game.voiceChatConnected &&
                      !game.voiceChatDeafened &&
                      (game.speakingPlayers[player.color] ?? false);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D0D2B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSpeaking ? playerColorVal : const Color(0xFF2A2A5A),
                        width: isSpeaking ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Avatar with speaking wave glow
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            if (isSpeaking)
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: playerColorVal, width: 2),
                                ),
                              ),
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: playerColorVal.withOpacity(0.2),
                                border: Border.all(color: playerColorVal, width: 2),
                              ),
                              child: Center(
                                child: Text(
                                  player.name.substring(0, 1),
                                  style: TextStyle(color: playerColorVal, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        // Player name and status
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    player.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (isLocal)
                                    Container(
                                      margin: const EdgeInsets.only(left: 6),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF6C3CE1).withOpacity(0.25),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'YOU',
                                        style: TextStyle(color: Color(0xFFB39DDB), fontSize: 8, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                !game.voiceChatConnected
                                    ? 'Offline'
                                    : isMuted
                                        ? 'Muted'
                                        : isSpeaking
                                            ? 'Speaking...'
                                            : 'Connected',
                                style: TextStyle(
                                  color: !game.voiceChatConnected
                                      ? const Color(0xFF7E7EAE)
                                      : isMuted
                                          ? const Color(0xFFE53935)
                                          : isSpeaking
                                              ? playerColorVal
                                              : const Color(0xFF9E9EBE),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Voice Status Visuals
                        if (game.voiceChatConnected) ...[
                          if (isSpeaking)
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: VoiceWaveIndicator(color: playerColorVal),
                            ),
                          // Mute/Unmute Indicator
                          Icon(
                            isMuted
                                ? Icons.mic_off_rounded
                                : isSpeaking
                                    ? Icons.mic_rounded
                                    : Icons.mic_none_rounded,
                            color: isMuted ? const Color(0xFFE53935) : const Color(0xFF9E9EBE),
                            size: 20,
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // Room Settings Collapsible Details
            if (game.voiceChatConnected) ...[
              const Divider(color: Color(0xFF2A2A5A), height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Noise Suppression',
                    style: TextStyle(color: Color(0xFF9E9EBE), fontSize: 13),
                  ),
                  Switch(
                    value: noiseSuppression,
                    onChanged: (v) => setState(() => noiseSuppression = v),
                    activeColor: const Color(0xFF6C3CE1),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Echo Cancellation',
                    style: TextStyle(color: Color(0xFF9E9EBE), fontSize: 13),
                  ),
                  Switch(
                    value: echoCancellation,
                    onChanged: (v) => setState(() => echoCancellation = v),
                    activeColor: const Color(0xFF6C3CE1),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            // Call Controls Action Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Mic Button
                _buildControlButton(
                  icon: game.voiceChatMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                  color: game.voiceChatMuted ? const Color(0xFFE53935) : const Color(0xFF1E88E5),
                  enabled: game.voiceChatConnected,
                  onTap: () => game.toggleVoiceMute(),
                  tooltip: 'Mute Microphone',
                ),
                // Main Connection Button
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () => game.toggleVoiceConnection(),
                        icon: Icon(
                          game.voiceChatConnected ? Icons.call_end_rounded : Icons.call_rounded,
                          color: Colors.white,
                        ),
                        label: Text(
                          game.voiceChatConnected ? 'Leave Voice' : 'Join Voice Chat',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: game.voiceChatConnected ? const Color(0xFFE53935) : const Color(0xFF6C3CE1),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
                ),
                // Deafen Button
                _buildControlButton(
                  icon: game.voiceChatDeafened ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  color: game.voiceChatDeafened ? const Color(0xFFE53935) : const Color(0xFF1E88E5),
                  enabled: game.voiceChatConnected,
                  onTap: () => game.toggleVoiceDeafen(),
                  tooltip: 'Deafen Audio',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required bool enabled,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(14),
      child: Opacity(
        opacity: enabled ? 1.0 : 0.4,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: enabled ? color.withOpacity(0.15) : const Color(0xFF2A2A5A).withOpacity(0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: enabled ? color.withOpacity(0.4) : const Color(0xFF2A2A5A),
              width: 1,
            ),
          ),
          child: Icon(icon, color: enabled ? color : const Color(0xFF7E7EAE)),
        ),
      ),
    );
  }
}

class VoiceWaveIndicator extends StatefulWidget {
  final Color color;
  const VoiceWaveIndicator({super.key, required this.color});

  @override
  State<VoiceWaveIndicator> createState() => _VoiceWaveIndicatorState();
}

class _VoiceWaveIndicatorState extends State<VoiceWaveIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<double> _heights = [0.2, 0.5, 0.7, 0.3, 0.6];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..addListener(() {
        setState(() {});
      });
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_heights.length, (index) {
        // Compute animated bar height scale
        final phase = (index / _heights.length) * math.pi;
        final animatedVal = math.sin(_controller.value * math.pi + phase).abs();
        final height = 4.0 + 12.0 * animatedVal * _heights[index];

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          width: 2.5,
          height: height,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(1.5),
          ),
        );
      }),
    );
  }
}
