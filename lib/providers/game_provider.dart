import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'voice_chat_helper_stub.dart' if (dart.library.html) 'voice_chat_helper_web.dart';

enum PlayerColor { red, green, yellow, blue }

enum PieceState { home, active, finished }

// All 52 main path squares (0-51), plus home column squares per colour
// Red starts at index 0, Green at 13, Yellow at 26, Blue at 39
const List<int> safeSquares = [0, 8, 13, 21, 26, 34, 39, 47];

class GamePiece {
  final int id;
  final PlayerColor color;
  PieceState state;
  int position; // -1 = in base, 0..51 = main path, 100+n = home column (n=0..5), 106 = finished

  GamePiece({
    required this.id,
    required this.color,
    this.state = PieceState.home,
    this.position = -1,
  });

  bool get isAtBase => position == -1;
  bool get isFinished => state == PieceState.finished;

  /// Absolute path index (0..51) for pieces on main track
  int get mainPathIndex => position;

  GamePiece copyWith({
    PieceState? state,
    int? position,
  }) {
    return GamePiece(
      id: id,
      color: color,
      state: state ?? this.state,
      position: position ?? this.position,
    );
  }
}

class Player {
  final PlayerColor color;
  final String name;
  List<GamePiece> pieces;
  int rank; // 0 = not finished yet

  Player({
    required this.color,
    required this.name,
    this.rank = 0,
  }) : pieces = List.generate(
          4,
          (i) => GamePiece(id: i, color: color),
        );

  bool get hasWon => pieces.every((p) => p.isFinished);

  int get piecesAtHome => pieces.where((p) => p.isAtBase).length;
  int get piecesActive => pieces.where((p) => p.state == PieceState.active).length;
  int get piecesFinished => pieces.where((p) => p.isFinished).length;
}

class GameProvider extends ChangeNotifier {
  List<Player> players = [];
  int currentPlayerIndex = 0;
  int diceValue = 1;
  bool diceRolled = false;
  bool isRolling = false;
  List<int> movablePieceIds = [];
  int rankCounter = 1;
  bool gameOver = false;
  int numberOfPlayers = 4;
  bool soundEnabled = true;

  // Voice Chat State
  bool voiceChatConnected = false;
  bool voiceChatMuted = false;
  bool voiceChatDeafened = false;
  Map<PlayerColor, bool> speakingPlayers = {};
  double voiceChannelPing = 24.0;

  // Online Multiplayer State
  WebSocketChannel? _channel;
  bool isOnlineMode = false;
  String? roomCode;
  String? myPlayerId;
  PlayerColor? myColor;
  bool isHost = false;
  List<Map<String, dynamic>> onlinePlayers = [];
  bool isConnecting = false;
  String? errorMessage;
  Uri _getServerUri() {
    // If compiled in release mode, use the production deployed server URL
    if (kReleaseMode) {
      return Uri.parse('wss://ludo-q7r8.onrender.com');
    }

    String host = 'localhost';
    if (kIsWeb) {
      final baseUri = Uri.parse(Uri.base.toString());
      if (baseUri.host.isNotEmpty) {
        host = baseUri.host;
      }
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      host = '10.0.2.2';
    }
    return Uri.parse('ws://$host:8080');
  }

  void createOnlineRoom(String playerName) {
    isConnecting = true;
    errorMessage = null;
    notifyListeners();

    myPlayerId = Random().nextInt(100000).toString();
    isOnlineMode = true;

    final uri = _getServerUri();
    try {
      _channel = WebSocketChannel.connect(uri);
      
      _channel!.stream.listen(
        (message) => _handleWSMessage(message),
        onError: (err) {
          isConnecting = false;
          errorMessage = 'Connection failed. Is the server running?';
          isOnlineMode = false;
          notifyListeners();
        },
        onDone: () {
          isConnecting = false;
          isOnlineMode = false;
          notifyListeners();
        }
      );

      _channel!.sink.add(jsonEncode({
        'action': 'create_room',
        'playerId': myPlayerId,
        'playerName': playerName,
      }));
    } catch (e) {
      isConnecting = false;
      errorMessage = 'Failed to connect: $e';
      isOnlineMode = false;
      notifyListeners();
    }
  }

  void joinOnlineRoom(String playerName, String code) {
    isConnecting = true;
    errorMessage = null;
    notifyListeners();

    myPlayerId = Random().nextInt(100000).toString();
    isOnlineMode = true;
    roomCode = code.toUpperCase();

    final uri = _getServerUri();
    try {
      _channel = WebSocketChannel.connect(uri);
      
      _channel!.stream.listen(
        (message) => _handleWSMessage(message),
        onError: (err) {
          isConnecting = false;
          errorMessage = 'Connection failed. Is the server running?';
          isOnlineMode = false;
          notifyListeners();
        },
        onDone: () {
          isConnecting = false;
          isOnlineMode = false;
          notifyListeners();
        }
      );

      _channel!.sink.add(jsonEncode({
        'action': 'join_room',
        'playerId': myPlayerId,
        'playerName': playerName,
        'roomCode': roomCode,
      }));
    } catch (e) {
      isConnecting = false;
      errorMessage = 'Failed to connect: $e';
      isOnlineMode = false;
      notifyListeners();
    }
  }

  void leaveOnlineRoom() {
    isOnlineMode = false;
    roomCode = null;
    onlinePlayers.clear();
    _channel?.sink.close();
    _channel = null;
    if (voiceChatConnected) {
      toggleVoiceConnection();
    }
    notifyListeners();
  }

  void startOnlineGame() {
    if (!isHost || _channel == null) return;
    _channel!.sink.add(jsonEncode({
      'action': 'start_game',
      'playerId': myPlayerId,
    }));
  }

  void _handleWSMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String);
      final action = data['action'] as String;

      switch (action) {
        case 'room_created':
          isConnecting = false;
          roomCode = data['roomCode'] as String;
          myColor = PlayerColor.red;
          isHost = true;
          _updateOnlinePlayers(data['players']);
          notifyListeners();
          break;

        case 'player_joined':
        case 'player_left':
          isConnecting = false;
          _updateOnlinePlayers(data['players']);
          notifyListeners();
          break;

        case 'game_started':
          _initializeOnlineGame();
          break;

        case 'game_event':
          _handleOnlineGameEvent(data['event']);
          break;

        case 'voice_stream':
          final senderColorStr = data['senderColor'] as String;
          final audioBase64 = data['audio'] as String;
          _playVoiceChunk(senderColorStr, audioBase64);
          break;

        case 'error':
          isConnecting = false;
          errorMessage = data['message'] as String;
          isOnlineMode = false;
          _channel?.sink.close();
          notifyListeners();
          break;
      }
    } catch (e) {
      print('Error parsing websocket message: $e');
    }
  }

  void _updateOnlinePlayers(dynamic playersList) {
    onlinePlayers = List<Map<String, dynamic>>.from(playersList);
    final me = onlinePlayers.firstWhere((p) => p['id'] == myPlayerId, orElse: () => {});
    if (me.isNotEmpty) {
      final colorStr = me['color'] as String;
      myColor = PlayerColor.values.firstWhere((c) => c.name == colorStr);
      isHost = me['isHost'] as bool;
    }
  }

  void _playVoiceChunk(String colorStr, String base64) {
    if (kIsWeb && !voiceChatDeafened) {
      playJsAudioChunk(colorStr, base64);
      final senderColor = PlayerColor.values.firstWhere((c) => c.name == colorStr);
      speakingPlayers[senderColor] = true;
      notifyListeners();
      Timer(const Duration(milliseconds: 400), () {
        speakingPlayers[senderColor] = false;
        notifyListeners();
      });
    }
  }

  void _initializeOnlineGame() {
    numberOfPlayers = onlinePlayers.length;
    final colorOrder = [PlayerColor.red, PlayerColor.green, PlayerColor.yellow, PlayerColor.blue];
    
    players = [];
    for (final col in colorOrder) {
      final playerMap = onlinePlayers.firstWhere((p) => p['color'] == col.name, orElse: () => {});
      if (playerMap.isNotEmpty) {
        players.add(Player(
          color: col,
          name: playerMap['name'] as String,
        ));
      }
    }

    currentPlayerIndex = 0;
    diceValue = 1;
    diceRolled = false;
    isRolling = false;
    movablePieceIds = [];
    rankCounter = 1;
    gameOver = false;
    notifyListeners();
  }

  void _handleOnlineGameEvent(dynamic event) {
    final type = event['type'] as String;
    if (type == 'roll') {
      final val = event['value'] as int;
      _applyRemoteRoll(val);
    } else if (type == 'move') {
      final pieceId = event['pieceId'] as int;
      _applyPieceMovement(pieceId);
    }
  }

  Future<void> _applyRemoteRoll(int val) async {
    isRolling = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600));
    diceValue = val;
    diceRolled = true;
    isRolling = false;
    _calculateMovablePieces();
    notifyListeners();

    if (movablePieceIds.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 800));
      _nextTurn();
    }
  }

  void toggleVoiceConnection() {
    if (voiceChatConnected) {
      voiceChatConnected = false;
      speakingPlayers.clear();
      if (kIsWeb) {
        stopJsRecording();
      }
    } else {
      voiceChatConnected = true;
      if (kIsWeb) {
        initJsVoiceChat((String base64) {
          if (isOnlineMode && _channel != null && voiceChatConnected && !voiceChatMuted) {
            _channel!.sink.add(jsonEncode({
              'action': 'voice_stream',
              'playerId': myPlayerId,
              'audio': base64,
            }));
            
            speakingPlayers[myColor!] = true;
            notifyListeners();
            Timer(const Duration(milliseconds: 400), () {
              speakingPlayers[myColor!] = false;
              notifyListeners();
            });
          }
        });
        startJsRecording();
      }
    }
    notifyListeners();
  }

  void toggleVoiceMute() {
    voiceChatMuted = !voiceChatMuted;
    if (voiceChatMuted) {
      if (kIsWeb) {
        stopJsRecording();
      }
      if (myColor != null) {
        speakingPlayers[myColor!] = false;
      }
    } else {
      if (kIsWeb && voiceChatConnected) {
        startJsRecording();
      }
    }
    notifyListeners();
  }

  void toggleVoiceDeafen() {
    voiceChatDeafened = !voiceChatDeafened;
    notifyListeners();
  }

  // Starting positions on main path for each colour
  static const Map<PlayerColor, int> startPositions = {
    PlayerColor.red: 0,
    PlayerColor.green: 13,
    PlayerColor.yellow: 26,
    PlayerColor.blue: 39,
  };

  // Home column entry square on main path
  static const Map<PlayerColor, int> homeEntries = {
    PlayerColor.red: 51,
    PlayerColor.green: 12,
    PlayerColor.yellow: 25,
    PlayerColor.blue: 38,
  };

  // Home column base (100 + offset), 6 steps to finish (106)
  static const Map<PlayerColor, int> homeColumnBase = {
    PlayerColor.red: 100,
    PlayerColor.green: 200,
    PlayerColor.yellow: 300,
    PlayerColor.blue: 400,
  };

  void initGame(int numPlayers) {
    numberOfPlayers = numPlayers;
    final colors = [PlayerColor.red, PlayerColor.green, PlayerColor.yellow, PlayerColor.blue];
    final names = ['Red', 'Green', 'Yellow', 'Blue'];
    players = List.generate(
      numPlayers,
      (i) => Player(color: colors[i], name: names[i]),
    );
    currentPlayerIndex = 0;
    diceValue = 1;
    diceRolled = false;
    isRolling = false;
    movablePieceIds = [];
    rankCounter = 1;
    gameOver = false;
    notifyListeners();
  }

  Player get currentPlayer => players[currentPlayerIndex];

  Future<void> rollDice() async {
    if (diceRolled || isRolling || gameOver) return;
    if (isOnlineMode && currentPlayer.color != myColor) return;

    isRolling = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600));
    diceValue = Random().nextInt(6) + 1;

    if (isOnlineMode && _channel != null) {
      _channel!.sink.add(jsonEncode({
        'action': 'game_event',
        'playerId': myPlayerId,
        'event': {
          'type': 'roll',
          'value': diceValue,
        }
      }));
    }

    diceRolled = true;
    isRolling = false;
    _calculateMovablePieces();
    notifyListeners();

    if (movablePieceIds.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 800));
      _nextTurn();
    }
  }

  void _calculateMovablePieces() {
    movablePieceIds = [];
    final player = currentPlayer;

    for (final piece in player.pieces) {
      if (piece.isFinished) continue;

      if (piece.isAtBase) {
        // Can only leave base on 6
        if (diceValue == 6) {
          movablePieceIds.add(piece.id);
        }
      } else {
        // Check if move is valid (won't overshoot home)
        final newPos = _calculateNewPosition(piece, diceValue);
        if (newPos != null) {
          movablePieceIds.add(piece.id);
        }
      }
    }
  }

  int? _calculateNewPosition(GamePiece piece, int steps) {
    final base = homeColumnBase[piece.color]!;
    final entry = homeEntries[piece.color]!;
    final start = startPositions[piece.color]!;

    if (piece.isAtBase) return null;

    final pos = piece.position;

    // Already in home column
    if (pos >= base && pos < base + 6) {
      final homeStep = pos - base;
      final newStep = homeStep + steps;
      if (newStep == 6) return base + 6; // finished
      if (newStep < 6) return base + newStep;
      return null; // overshoot
    }

    // On main path
    // Calculate distance from start
    int distFromStart = (pos - start + 52) % 52;
    int distToEntry = (entry - start + 52) % 52 + 1; // entry is last main square before home col

    if (distFromStart + steps > distToEntry + 6) return null;

    if (distFromStart + steps > distToEntry) {
      // Moving into home column
      final homeStep = distFromStart + steps - distToEntry;
      if (homeStep == 6) return base + 6; // finished
      return base + homeStep;
    }

    // Stay on main path
    return (pos + steps) % 52;
  }

  void movePiece(int pieceId) {
    if (!diceRolled || gameOver) return;
    if (isOnlineMode && currentPlayer.color != myColor) return;

    if (isOnlineMode && _channel != null) {
      _channel!.sink.add(jsonEncode({
        'action': 'game_event',
        'playerId': myPlayerId,
        'event': {
          'type': 'move',
          'pieceId': pieceId,
        }
      }));
    }

    _applyPieceMovement(pieceId);
  }

  void _applyPieceMovement(int pieceId) {
    final player = currentPlayer;
    final pieceIndex = player.pieces.indexWhere((p) => p.id == pieceId);
    if (pieceIndex == -1) return;

    final piece = player.pieces[pieceIndex];
    bool extraTurn = false;

    if (piece.isAtBase && diceValue == 6) {
      player.pieces[pieceIndex].position = startPositions[player.color]!;
      player.pieces[pieceIndex].state = PieceState.active;
      extraTurn = true;
    } else {
      final newPos = _calculateNewPosition(piece, diceValue);
      if (newPos == null) return;

      final base = homeColumnBase[player.color]!;
      if (newPos == base + 6) {
        player.pieces[pieceIndex].state = PieceState.finished;
        player.pieces[pieceIndex].position = newPos;
        extraTurn = true;
      } else {
        player.pieces[pieceIndex].position = newPos;
        if (newPos < 100) {
          _checkCapture(player, newPos);
        }
      }

      if (diceValue == 6) extraTurn = true;
    }

    if (player.hasWon) {
      player.rank = rankCounter++;
      if (rankCounter > numberOfPlayers) {
        gameOver = true;
      }
    }

    diceRolled = false;
    movablePieceIds = [];
    notifyListeners();

    if (!gameOver && !extraTurn) {
      _nextTurn();
    }
  }

  void _checkCapture(Player mover, int pos) {
    if (safeSquares.contains(pos)) return;

    for (final player in players) {
      if (player.color == mover.color) continue;
      for (final piece in player.pieces) {
        if (piece.position == pos && piece.state == PieceState.active) {
          piece.position = -1;
          piece.state = PieceState.home;
        }
      }
    }
  }

  void _nextTurn() {
    do {
      currentPlayerIndex = (currentPlayerIndex + 1) % numberOfPlayers;
    } while (players[currentPlayerIndex].hasWon);
    diceRolled = false;
    movablePieceIds = [];
    notifyListeners();
  }

  Color colorOf(PlayerColor c) {
    switch (c) {
      case PlayerColor.red:
        return const Color(0xFFE53935);
      case PlayerColor.green:
        return const Color(0xFF43A047);
      case PlayerColor.yellow:
        return const Color(0xFFFDD835);
      case PlayerColor.blue:
        return const Color(0xFF1E88E5);
    }
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }
}
