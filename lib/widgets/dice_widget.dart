import 'package:flutter/material.dart';

class DiceWidget extends StatefulWidget {
  final int value;
  final bool isRolling;
  final bool canRoll;
  final VoidCallback onRoll;

  const DiceWidget({
    super.key,
    required this.value,
    required this.isRolling,
    required this.canRoll,
    required this.onRoll,
  });

  @override
  State<DiceWidget> createState() => _DiceWidgetState();
}

class _DiceWidgetState extends State<DiceWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotateAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _rotateAnim = Tween<double>(begin: 0, end: 2 * 3.14159)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _scaleAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(DiceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRolling && !oldWidget.isRolling) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.canRoll ? widget.onRoll : null,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (ctx, child) {
          return Transform.scale(
            scale: widget.isRolling ? _scaleAnim.value : 1.0,
            child: Transform.rotate(
              angle: widget.isRolling ? _rotateAnim.value : 0,
              child: child,
            ),
          );
        },
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.canRoll
                  ? [const Color(0xFF6C3CE1), const Color(0xFFAA00FF)]
                  : [const Color(0xFF3A3A6A), const Color(0xFF2A2A5A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: widget.canRoll
                ? [
                    BoxShadow(
                      color: const Color(0xFF6C3CE1).withOpacity(0.6),
                      blurRadius: 20,
                      spreadRadius: 2,
                    )
                  ]
                : [],
          ),
          child: widget.isRolling
              ? const Center(
                  child: Text('🎲', style: TextStyle(fontSize: 40)))
              : Padding(
                  padding: const EdgeInsets.all(12),
                  child: Image.asset(
                    'assets/images/dice/${widget.value}.png',
                    fit: BoxFit.contain,
                  ),
                ),
        ),
      ),
    );
  }
}
