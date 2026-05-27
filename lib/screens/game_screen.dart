import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../widgets/ludo_board_widget.dart';
import '../widgets/dice_widget.dart';
import '../widgets/voice_chat_panel.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final leave = await _confirmExit(context);
        if (leave && context.mounted) {
          final game = context.read<GameProvider>();
          if (game.isOnlineMode) {
            game.leaveOnlineRoom();
          }
          Navigator.pop(context);
        }
      },
      child: Consumer<GameProvider>(
        builder: (ctx, game, _) {
          final isLandscape = MediaQuery.of(ctx).size.width > MediaQuery.of(ctx).size.height;
          return Scaffold(
            backgroundColor: const Color(0xFF0D0D2B),
            body: SafeArea(
              child: game.gameOver
                  ? _buildGameOver(ctx, game)
                  : _buildGamePlay(ctx, game),
            ),
            floatingActionButton: (!game.gameOver && !isLandscape)
                ? _buildVoiceFAB(ctx, game)
                : null,
          );
        },
      ),
    );
  }

  Widget _buildVoiceFAB(BuildContext context, GameProvider game) {
    final isConnected = game.voiceChatConnected;
    final isMuted = game.voiceChatMuted;

    return FloatingActionButton(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const VoiceChatPanel(),
        );
      },
      backgroundColor: isConnected
          ? (isMuted ? const Color(0xFFE53935) : const Color(0xFF43A047))
          : const Color(0xFF6C3CE1),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        isConnected
            ? (isMuted ? Icons.mic_off_rounded : Icons.mic_rounded)
            : Icons.spatial_audio_off_rounded,
      ),
    );
  }

  Widget _buildGamePlay(BuildContext context, GameProvider game) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final isLandscape = constraints.maxWidth > constraints.maxHeight;
        if (isLandscape) {
          return _buildLandscapeLayout(context, game, constraints);
        }
        return _buildPortraitLayout(context, game);
      },
    );
  }

  Widget _buildPortraitLayout(BuildContext context, GameProvider game) {
    return Column(
      children: [
        _buildTopBar(context, game),
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: LudoBoardWidget(game: game),
              ),
            ),
          ),
        ),
        _buildBottomPanel(context, game),
      ],
    );
  }

  Widget _buildLandscapeLayout(BuildContext context, GameProvider game, BoxConstraints constraints) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left Column: Ludo Board (centered)
        Expanded(
          flex: 5,
          child: Container(
            padding: const EdgeInsets.all(12),
            alignment: Alignment.center,
            child: LudoBoardWidget(game: game),
          ),
        ),
        // Right Column: Controls, Players, and Voice Chat Panel
        Expanded(
          flex: 4,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF16163F),
              borderRadius: BorderRadius.horizontal(left: Radius.circular(30)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Bar row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () async {
                          final leave = await _confirmExit(context);
                          if (leave && context.mounted) {
                            if (game.isOnlineMode) {
                              game.leaveOnlineRoom();
                            }
                            Navigator.pop(context);
                          }
                        },
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D0D2B),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 16),
                        ),
                      ),
                      Text(
                        '${game.currentPlayer.name}\'s Turn',
                        style: TextStyle(
                          color: game.colorOf(game.currentPlayer.color),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D0D2B),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${game.numberOfPlayers}P',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Dice widget section inline
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D0D2B),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        DiceWidget(
                          value: game.diceValue,
                          isRolling: game.isRolling,
                          canRoll: !game.diceRolled && !game.isRolling,
                          onRoll: () => game.rollDice(),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            game.isRolling
                                ? 'Rolling...'
                                : game.diceRolled
                                    ? game.movablePieceIds.isEmpty
                                        ? 'No moves available!'
                                        : 'Tap piece to move'
                                    : 'Tap dice to roll!',
                            style: TextStyle(
                              color: game.colorOf(game.currentPlayer.color),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Player stats grid
                  const Text(
                    'PLAYERS',
                    style: TextStyle(color: Color(0xFF6C3CE1), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: game.players.map((p) {
                      final isActive = p.color == game.currentPlayer.color;
                      final color = game.colorOf(p.color);
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isActive ? color.withOpacity(0.2) : const Color(0xFF0D0D2B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isActive ? color : const Color(0xFF2A2A5A),
                            width: isActive ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              p.name,
                              style: TextStyle(
                                color: isActive ? color : const Color(0xFF9E9EBE),
                                fontSize: 12,
                                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (p.hasWon)
                              const Text('🏆', style: TextStyle(fontSize: 11))
                            else
                              Text(
                                '${p.piecesFinished}/4',
                                style: TextStyle(
                                  color: isActive ? color : const Color(0xFF9E9EBE),
                                  fontSize: 10,
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Inline Voice Chat Controls & Lobby Info
                  const Text(
                    'VOICE CHAT CHANNEL',
                    style: TextStyle(color: Color(0xFF6C3CE1), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 8),

                  // Mini Voice Lobby Panel Inline
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D0D2B),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              game.voiceChatConnected ? Icons.spatial_audio_rounded : Icons.spatial_audio_off_rounded,
                              color: game.voiceChatConnected ? const Color(0xFF4CAF50) : const Color(0xFF9E9EBE),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    game.voiceChatConnected ? 'Connected to Lobby' : 'Voice Chat Offline',
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                  if (game.voiceChatConnected)
                                    Text(
                                      'Ping: ${game.voiceChannelPing.toInt()}ms',
                                      style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 10),
                                    ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => game.toggleVoiceConnection(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: game.voiceChatConnected ? const Color(0xFFE53935) : const Color(0xFF6C3CE1),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                minimumSize: Size.zero,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: Text(
                                game.voiceChatConnected ? 'Leave' : 'Join',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        if (game.voiceChatConnected) ...[
                          const Divider(color: Color(0xFF2A2A5A), height: 16),
                          // List of players speaking status
                          ...game.players.map((p) {
                            final isSpeaking = !game.voiceChatDeafened && (game.speakingPlayers[p.color] ?? false);
                            final isMuted = p.color == PlayerColor.red && game.voiceChatMuted;
                            final colorVal = game.colorOf(p.color);
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(shape: BoxShape.circle, color: colorVal),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    p.name,
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                  const Spacer(),
                                  if (isSpeaking) ...[
                                    Row(
                                      children: List.generate(3, (index) => Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 1),
                                        width: 2,
                                        height: 6.0 + 4.0 * (index % 2 == 0 ? 0.5 : 1.0),
                                        color: colorVal,
                                      )),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Icon(
                                    isMuted ? Icons.mic_off_rounded : isSpeaking ? Icons.mic_rounded : Icons.mic_none_rounded,
                                    color: isMuted ? const Color(0xFFE53935) : const Color(0xFF9E9EBE),
                                    size: 16,
                                  ),
                                ],
                              ),
                            );
                          }),
                          const Divider(color: Color(0xFF2A2A5A), height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                onPressed: () => game.toggleVoiceMute(),
                                icon: Icon(
                                  game.voiceChatMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                                  color: game.voiceChatMuted ? const Color(0xFFE53935) : const Color(0xFF1E88E5),
                                  size: 20,
                                ),
                              ),
                              IconButton(
                                onPressed: () => game.toggleVoiceDeafen(),
                                icon: Icon(
                                  game.voiceChatDeafened ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                                  color: game.voiceChatDeafened ? const Color(0xFFE53935) : const Color(0xFF1E88E5),
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context, GameProvider game) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () async {
              final leave = await _confirmExit(context);
              if (leave && context.mounted) {
                if (game.isOnlineMode) {
                  game.leaveOnlineRoom();
                }
                Navigator.pop(context);
              }
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A4E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
          Text(
            '${game.currentPlayer.name}\'s Turn',
            style: TextStyle(
              color: game.colorOf(game.currentPlayer.color),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A4E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${game.numberOfPlayers}P',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel(BuildContext context, GameProvider game) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A4E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          // Player status row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: game.players.map((p) {
                final isActive = p.color == game.currentPlayer.color;
                final color = game.colorOf(p.color);
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? color.withOpacity(0.25)
                        : const Color(0xFF0D0D2B),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isActive ? color : const Color(0xFF3A3A6A),
                      width: isActive ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle, color: color),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        p.name,
                        style: TextStyle(
                          color: isActive ? color : const Color(0xFF9E9EBE),
                          fontWeight: isActive
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (p.hasWon)
                        const Text('🏆', style: TextStyle(fontSize: 14))
                      else
                        Text(
                          '${p.piecesFinished}/4',
                          style: TextStyle(
                            color: isActive ? color : const Color(0xFF9E9EBE),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Dice
              DiceWidget(
                value: game.diceValue,
                isRolling: game.isRolling,
                canRoll: !game.diceRolled && !game.isRolling,
                onRoll: () => game.rollDice(),
              ),
              // Instruction
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(
                    game.isRolling
                        ? 'Rolling...'
                        : game.diceRolled
                            ? game.movablePieceIds.isEmpty
                                ? 'No moves available!'
                                : 'Tap a piece to move'
                            : 'Tap dice to roll!',
                    style: TextStyle(
                      color: game.colorOf(game.currentPlayer.color),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGameOver(BuildContext context, GameProvider game) {
    final winner = game.players.firstWhere((p) => p.rank == 1);
    final color = game.colorOf(winner.color);

    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [color.withOpacity(0.3), const Color(0xFF0D0D2B)],
          radius: 1.5,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Trophy
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.2),
                  border: Border.all(color: color, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🏆', style: TextStyle(fontSize: 70)),
                ),
              ),
              const SizedBox(height: 30),
              Text(
                '${winner.name} Wins!',
                style: TextStyle(
                  color: color,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  shadows: [
                    Shadow(color: color.withOpacity(0.5), blurRadius: 20),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Congratulations on winning the match!',
                style: TextStyle(color: Color(0xFF9E9EBE), fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              // Rankings
              ...game.players
                  .where((p) => p.rank > 0)
                  .toList()
                  .asMap()
                  .entries
                  .map((e) {
                final medals = ['🥇', '🥈', '🥉', '4️⃣'];
                final pc = game.colorOf(e.value.color);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(medals[e.value.rank - 1],
                          style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 10),
                      Text(
                        e.value.name,
                        style: TextStyle(
                            color: pc,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF3A3A6A)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Home'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        context
                            .read<GameProvider>()
                            .initGame(game.numberOfPlayers);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Play Again',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmExit(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A4E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Exit Game?',
                style: TextStyle(color: Colors.white)),
            content: const Text(
              'Are you sure you want to quit? Your progress will be lost.',
              style: TextStyle(color: Color(0xFF9E9EBE)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                ),
                child: const Text('Exit',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;
  }
}
