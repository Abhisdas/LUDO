import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../providers/game_provider.dart';

class LudoBoardWidget extends StatelessWidget {
  final GameProvider game;

  const LudoBoardWidget({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight);
        return Center(
          child: SizedBox(
            width: size,
            height: size,
            child: GestureDetector(
              onTapDown: (details) => _handleTap(details.localPosition, size),
              child: CustomPaint(
                size: Size(size, size),
                painter: _LudoBoardPainter(game: game),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleTap(Offset pos, double size) {
    if (!game.diceRolled || game.movablePieceIds.isEmpty) return;
    final cell = size / 15;

    for (final player in game.players) {
      if (player.color != game.currentPlayer.color) continue;
      for (final piece in player.pieces) {
        if (!game.movablePieceIds.contains(piece.id)) continue;
        final piecePos = _LudoBoardPainter(game: game).pieceScreenPos(piece, cell);
        final dist = (piecePos - pos).distance;
        if (dist < cell * 0.7) {
          game.movePiece(piece.id);
          return;
        }
      }
    }
  }
}

class _LudoBoardPainter extends CustomPainter {
  final GameProvider game;

  _LudoBoardPainter({required this.game});

  // 52 main path squares as (col, row) going clockwise
  static const List<List<int>> mainPath = [
    // Red start → going up column 6
    [6,14],[6,13],[6,12],[6,11],[6,10],
    // top-left horizontal
    [6,9],[5,9],[4,9],[3,9],[2,9],[1,9],[0,9],
    // left side going up
    [0,8],[0,7],
    // Green start
    [0,6],
    [1,6],[2,6],[3,6],[4,6],[5,6],
    // up column 6
    [6,6],[6,5],[6,4],[6,3],[6,2],[6,1],
    // Yellow start
    [6,0],[7,0],[8,0],
    // right column going down
    [8,1],[8,2],[8,3],[8,4],[8,5],
    // right horizontal
    [8,6],[9,6],[10,6],[11,6],[12,6],[13,6],[14,6],
    // right side going up (going down in row)
    [14,7],[14,8],
    // Blue start
    [13,8],[12,8],[11,8],[10,8],[9,8],
    // down column 8
    [8,8],[8,9],[8,10],[8,11],[8,12],[8,13],
    // bottom horizontal
    [8,14],[7,14],
  ];

  // Home column cells per colour (6 steps towards centre)
  static const Map<String, List<List<int>>> homeColumns = {
    'red':    [[7,13],[7,12],[7,11],[7,10],[7,9],[7,8]],
    'green':  [[1,7],[2,7],[3,7],[4,7],[5,7],[6,7]],
    'yellow': [[7,1],[7,2],[7,3],[7,4],[7,5],[7,6]],
    'blue':   [[13,7],[12,7],[11,7],[10,7],[9,7],[8,7]],
  };

  static const safeIndices = {0, 8, 13, 21, 26, 34, 39, 47};

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.width / 15;

    _drawBackground(canvas, size);
    _drawBaseRegions(canvas, c);
    _drawMainPath(canvas, c);
    _drawHomeColumns(canvas, c);
    _drawSafeSquares(canvas, c);
    _drawStartMarkers(canvas, c);
    _drawCentreTriangles(canvas, c, size);
    _drawPieces(canvas, c);
  }

  void _drawBackground(Canvas canvas, Size size) {
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = const Color(0xFFEEEEEE));
  }

  void _drawBaseRegions(Canvas canvas, double c) {
    final data = {
      'red':    [0.0, 9.0, const Color(0xFFFFCDD2), const Color(0xFFE53935)],
      'green':  [0.0, 0.0, const Color(0xFFC8E6C9), const Color(0xFF43A047)],
      'yellow': [9.0, 0.0, const Color(0xFFFFF9C4), const Color(0xFFFDD835)],
      'blue':   [9.0, 9.0, const Color(0xFFBBDEFB), const Color(0xFF1E88E5)],
    };
    final pieceOffsets = {
      'red':    [Offset(1.3,10.3),Offset(3.3,10.3),Offset(1.3,12.3),Offset(3.3,12.3)],
      'green':  [Offset(1.3,1.3),Offset(3.3,1.3),Offset(1.3,3.3),Offset(3.3,3.3)],
      'yellow': [Offset(10.3,1.3),Offset(12.3,1.3),Offset(10.3,3.3),Offset(12.3,3.3)],
      'blue':   [Offset(10.3,10.3),Offset(12.3,10.3),Offset(10.3,12.3),Offset(12.3,12.3)],
    };

    for (final e in data.entries) {
      final col = (e.value[0] as double) * c;
      final row = (e.value[1] as double) * c;
      final bg = e.value[2] as Color;
      final accent = e.value[3] as Color;

      // Background block
      final rRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(col, row, 6 * c, 6 * c), Radius.circular(c * 0.3));
      canvas.drawRRect(rRect, Paint()..color = bg);
      canvas.drawRRect(rRect,
          Paint()..color = accent..style = PaintingStyle.stroke..strokeWidth = 2);

      // Inner yard
      final innerRRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(col + c * 0.7, row + c * 0.7, 4.6 * c, 4.6 * c),
          Radius.circular(c * 0.2));
      canvas.drawRRect(innerRRect, Paint()..color = Colors.white);

      // Piece slot circles
      for (final off in pieceOffsets[e.key]!) {
        final center = Offset(off.dx * c, off.dy * c);
        canvas.drawCircle(center, c * 0.7, Paint()..color = accent.withOpacity(0.25));
        canvas.drawCircle(center, c * 0.7,
            Paint()..color = accent..style = PaintingStyle.stroke..strokeWidth = 2);
      }
    }
  }

  void _drawMainPath(Canvas canvas, double c) {
    final bg = Paint()..color = Colors.white;
    final border = Paint()
      ..color = const Color(0xFFBDBDBD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (final cell in mainPath) {
      final rect = Rect.fromLTWH(cell[0] * c, cell[1] * c, c, c);
      canvas.drawRect(rect, bg);
      canvas.drawRect(rect, border);
    }
  }

  void _drawHomeColumns(Canvas canvas, double c) {
    final colors = {
      'red': const Color(0xFFE53935),
      'green': const Color(0xFF43A047),
      'yellow': const Color(0xFFFDD835),
      'blue': const Color(0xFF1E88E5),
    };
    for (final e in homeColumns.entries) {
      final paint = Paint()..color = colors[e.key]!.withOpacity(0.6);
      for (final cell in e.value) {
        canvas.drawRect(
            Rect.fromLTWH(cell[0] * c, cell[1] * c, c, c), paint);
      }
    }
  }

  void _drawSafeSquares(Canvas canvas, double c) {
    for (final idx in safeIndices) {
      if (idx >= mainPath.length) continue;
      final cell = mainPath[idx];
      canvas.drawRect(
          Rect.fromLTWH(cell[0] * c, cell[1] * c, c, c),
          Paint()..color = const Color(0xFFE8F5E9));
      _drawStar(canvas,
          Offset((cell[0] + 0.5) * c, (cell[1] + 0.5) * c),
          c * 0.32, const Color(0xFF4CAF50));
    }
  }

  void _drawStar(Canvas canvas, Offset center, double r, Color color) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final outerAngle = (i * 4 * math.pi / 5) - math.pi / 2;
      final innerAngle = outerAngle + 2 * math.pi / 10;
      final op = Offset(center.dx + r * math.cos(outerAngle),
          center.dy + r * math.sin(outerAngle));
      final ip = Offset(center.dx + r * 0.4 * math.cos(innerAngle),
          center.dy + r * 0.4 * math.sin(innerAngle));
      if (i == 0) path.moveTo(op.dx, op.dy);
      else path.lineTo(op.dx, op.dy);
      path.lineTo(ip.dx, ip.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawStartMarkers(Canvas canvas, double c) {
    final starts = {
      'red': 0, 'green': 13, 'yellow': 26, 'blue': 39,
    };
    final colors = {
      'red': const Color(0xFFE53935),
      'green': const Color(0xFF43A047),
      'yellow': const Color(0xFFFDD835),
      'blue': const Color(0xFF1E88E5),
    };
    for (final e in starts.entries) {
      if (e.value >= mainPath.length) continue;
      final cell = mainPath[e.value];
      canvas.drawOval(
          Rect.fromLTWH(cell[0] * c + c * 0.1, cell[1] * c + c * 0.1, c * 0.8, c * 0.8),
          Paint()..color = colors[e.key]!.withOpacity(0.7));
    }
  }

  void _drawCentreTriangles(Canvas canvas, double c, Size size) {
    final center = Offset(7.5 * c, 7.5 * c);
    final corners = [
      [Offset(6 * c, 9 * c), Offset(9 * c, 9 * c)],   // red (bottom)
      [Offset(6 * c, 6 * c), Offset(6 * c, 9 * c)],   // green (left)
      [Offset(6 * c, 6 * c), Offset(9 * c, 6 * c)],   // yellow (top)
      [Offset(9 * c, 6 * c), Offset(9 * c, 9 * c)],   // blue (right)
    ];
    final colors = [
      const Color(0xFFE53935),
      const Color(0xFF43A047),
      const Color(0xFFFDD835),
      const Color(0xFF1E88E5),
    ];

    for (int i = 0; i < 4; i++) {
      final path = Path()
        ..moveTo(corners[i][0].dx, corners[i][0].dy)
        ..lineTo(corners[i][1].dx, corners[i][1].dy)
        ..lineTo(center.dx, center.dy)
        ..close();
      canvas.drawPath(path, Paint()..color = colors[i].withOpacity(0.85));
    }

    // White centre circle
    canvas.drawCircle(center, c * 1.1, Paint()..color = Colors.white);
    // Home emoji
    const textStyle = TextStyle(fontSize: 22);
    final tp = TextPainter(
        text: const TextSpan(text: '🏠', style: textStyle),
        textDirection: TextDirection.ltr)
      ..layout();
    tp.paint(canvas, Offset(center.dx - 11, center.dy - 12));
  }

  void _drawPieces(Canvas canvas, double c) {
    for (final player in game.players) {
      final color = game.colorOf(player.color);
      final isCurrentPlayer = player.color == game.currentPlayer.color;

      for (final piece in player.pieces) {
        final isMovable =
            game.movablePieceIds.contains(piece.id) && isCurrentPlayer;

        if (piece.isAtBase) {
          final pos = _basePieceOffset(player.color, piece.id) * c;
          _drawPiece(canvas, pos, c, color, false, isMovable);
        } else if (!piece.isFinished) {
          final pos = pieceScreenPos(piece, c);
          _drawPiece(canvas, pos, c, color, true, isMovable);
        }
      }
    }
  }

  Offset _basePieceOffset(PlayerColor color, int idx) {
    final positions = {
      PlayerColor.red:    [Offset(1.3,10.3),Offset(3.3,10.3),Offset(1.3,12.3),Offset(3.3,12.3)],
      PlayerColor.green:  [Offset(1.3,1.3),Offset(3.3,1.3),Offset(1.3,3.3),Offset(3.3,3.3)],
      PlayerColor.yellow: [Offset(10.3,1.3),Offset(12.3,1.3),Offset(10.3,3.3),Offset(12.3,3.3)],
      PlayerColor.blue:   [Offset(10.3,10.3),Offset(12.3,10.3),Offset(10.3,12.3),Offset(12.3,12.3)],
    };
    return positions[color]![idx.clamp(0, 3)];
  }

  Offset pieceScreenPos(GamePiece piece, double c) {
    if (piece.isAtBase) {
      return _basePieceOffset(piece.color, piece.id) * c;
    }

    final base = GameProvider.homeColumnBase[piece.color]!;
    final colKey = piece.color.name;

    if (piece.position >= base && piece.position < base + 7) {
      final step = (piece.position - base).clamp(0, 5);
      final cell = homeColumns[colKey]![step];
      return Offset((cell[0] + 0.5) * c, (cell[1] + 0.5) * c);
    }

    if (piece.position >= 0 && piece.position < mainPath.length) {
      final cell = mainPath[piece.position];
      return Offset((cell[0] + 0.5) * c, (cell[1] + 0.5) * c);
    }

    return const Offset(-100, -100);
  }

  void _drawPiece(Canvas canvas, Offset pos, double c, Color color,
      bool onBoard, bool isMovable) {
    final radius = onBoard ? c * 0.38 : c * 0.55;

    if (isMovable) {
      canvas.drawCircle(pos, radius + 5,
          Paint()
            ..color = color.withOpacity(0.35)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    }

    canvas.drawCircle(pos + const Offset(1, 2), radius,
        Paint()..color = Colors.black26);
    canvas.drawCircle(pos, radius, Paint()..color = color);
    canvas.drawCircle(
        pos - Offset(radius * 0.25, radius * 0.25),
        radius * 0.4,
        Paint()..color = Colors.white.withOpacity(0.55));
    canvas.drawCircle(pos, radius,
        Paint()
          ..color = Colors.white.withOpacity(0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(_LudoBoardPainter old) => true;
}
