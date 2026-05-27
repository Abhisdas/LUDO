import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late TextEditingController _nameController;
  late TextEditingController _codeController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: 'Player_${math.Random().nextInt(900) + 100}');
    _codeController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 800;

    // Listen to game start and navigate automatically
    if (game.isOnlineMode && game.players.isNotEmpty && !game.gameOver) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ModalRoute.of(context)?.settings.name != '/game') {
          Navigator.pushNamed(context, '/game');
        }
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D2B),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 900 : double.infinity,
            ),
            child: game.roomCode != null && game.players.isEmpty
                ? _buildOnlineLobby(game)
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildHeader(context),
                        const SizedBox(height: 20),
                        _buildMatchmakingCard(game),
                        const SizedBox(height: 30),
                        _buildFeaturesGrid(context, isDesktop),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1A4E), Color(0xFF0D0D2B)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C3CE1), Color(0xFFAA00FF)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C3CE1).withOpacity(0.5),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset('assets/logo.jpg', fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LudoVerse',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Online Multiplayer Ludo',
                        style: TextStyle(
                          color: Color(0xFF9E9EBE),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.pushNamed(context, '/settings'),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A4E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF3A3A6A)),
                  ),
                  child: const Icon(Icons.settings_rounded,
                      color: Color(0xFF9E9EBE)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          // Banner
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C3CE1), Color(0xFFAA00FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C3CE1).withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🎲 LudoVerse Live',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Connect with friends online and play with real-time voice chat!',
                        style: TextStyle(
                          color: Color(0xFFD4C5FF),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 10),
                Text('🎮', style: TextStyle(fontSize: 60)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchmakingCard(GameProvider game) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A4E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF3A3A6A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎮 Play with Friends (Online)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Player Name input
          TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Your Name',
              labelStyle: const TextStyle(color: Color(0xFF9E9EBE)),
              filled: true,
              fillColor: const Color(0xFF0D0D2B),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF3A3A6A)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF6C3CE1)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Error Message banner
          if (game.errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE53935).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE53935)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Color(0xFFE53935)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      game.errorMessage!,
                      style: const TextStyle(color: Color(0xFFE53935), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Create Lobby Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: game.isConnecting
                  ? null
                  : () => game.createOnlineRoom(_nameController.text),
              icon: game.isConnecting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.add_box_rounded),
              label: const Text('Create Online Room', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C3CE1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'OR',
              style: TextStyle(color: Color(0xFF9E9EBE), fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          // Join lobby row
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2),
                  decoration: InputDecoration(
                    labelText: 'Room Code',
                    labelStyle: const TextStyle(color: Color(0xFF9E9EBE)),
                    filled: true,
                    fillColor: const Color(0xFF0D0D2B),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF3A3A6A)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF6C3CE1)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: game.isConnecting
                        ? null
                        : () {
                            if (_codeController.text.isNotEmpty) {
                              game.joinOnlineRoom(_nameController.text, _codeController.text);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF43A047),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Join Room', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineLobby(GameProvider game) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A4E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF3A3A6A)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ludo Lobby',
            style: TextStyle(color: Color(0xFF6C3CE1), fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Waiting for Players...',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Connected to Server',
                    style: TextStyle(color: Colors.green.shade400, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: game.roomCode ?? ''));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Room code copied to clipboard!')),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D0D2B),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF6C3CE1)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        game.roomCode ?? '',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.copy_rounded, color: Color(0xFF9E9EBE), size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Color(0xFF3A3A6A), height: 1),
          const SizedBox(height: 20),
          const Text(
            'CONNECTED PLAYERS',
            style: TextStyle(color: Color(0xFF9E9EBE), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          const SizedBox(height: 12),
          
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            itemBuilder: (ctx, idx) {
              final colorNames = ['red', 'green', 'yellow', 'blue'];
              final colorVals = [
                const Color(0xFFE53935),
                const Color(0xFF43A047),
                const Color(0xFFFDD835),
                const Color(0xFF1E88E5),
              ];
              final targetColorStr = colorNames[idx];
              final playerMap = game.onlinePlayers.firstWhere(
                (p) => p['color'] == targetColorStr,
                orElse: () => {},
              );

              final isJoined = playerMap.isNotEmpty;
              final name = isJoined ? playerMap['name'] as String : 'Waiting for player...';
              final isPlayerHost = isJoined && (playerMap['isHost'] as bool);

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isJoined ? const Color(0xFF0D0D2B) : const Color(0xFF0D0D2B).withOpacity(0.4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isJoined ? colorVals[idx] : const Color(0xFF2A2A5A),
                    width: isJoined ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: colorVals[idx]),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      name,
                      style: TextStyle(
                        color: isJoined ? Colors.white : const Color(0xFF7E7EAE),
                        fontWeight: isJoined ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    if (isPlayerHost)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDD835).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFDD835), width: 0.5),
                        ),
                        child: const Text(
                          'HOST',
                          style: TextStyle(color: Color(0xFFFDD835), fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      )
                    else if (isJoined)
                      const Text('Ready ✅', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => game.leaveOnlineRoom(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF3A3A6A)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Leave Lobby'),
                ),
              ),
              const SizedBox(width: 16),
              if (game.isHost)
                Expanded(
                  child: ElevatedButton(
                    onPressed: game.onlinePlayers.length >= 2
                        ? () => game.startOnlineGame()
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C3CE1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      disabledBackgroundColor: const Color(0xFF3A3A6A),
                    ),
                    child: const Text('Start Match', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                )
              else
                Expanded(
                  child: Center(
                    child: Text(
                      'Waiting for host to start...',
                      style: TextStyle(color: Colors.amber.shade200, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesGrid(BuildContext context, bool isDesktop) {
    final features = [
      {'icon': '🎙️', 'title': 'Voice Chat', 'desc': 'Talk to friends live'},
      {'icon': '⚡', 'title': 'Lobby Rooms', 'desc': 'Create room codes'},
      {'icon': '🎲', 'title': 'Fair Play', 'desc': 'True random dice rolls'},
      {'icon': '🛡️', 'title': 'Safe Zones', 'desc': 'Protected cells'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Game Features',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isDesktop ? 4 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: isDesktop ? 1.8 : 1.6,
            children: features
                .map((f) => Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A4E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF3A3A6A)),
                      ),
                      child: Row(
                        children: [
                          Text(f['icon']!,
                              style: const TextStyle(fontSize: 30)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                  Text(
                                    f['title']!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    f['desc']!,
                                    style: const TextStyle(
                                      color: Color(0xFF9E9EBE),
                                      fontSize: 11,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
