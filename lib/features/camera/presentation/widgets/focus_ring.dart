import 'package:flutter/material.dart';

/// Brief animated ring shown at the tap-to-focus point.
class FocusRing extends StatefulWidget {
  const FocusRing({super.key, required this.center, required this.onCompleted});

  final Offset center;
  final VoidCallback onCompleted;

  @override
  State<FocusRing> createState() => _FocusRingState();
}

class _FocusRingState extends State<FocusRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onCompleted();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.center.dx - 34,
      top: widget.center.dy - 34,
      child: FadeTransition(
        opacity: Tween(begin: 1.0, end: 0.0).animate(
          CurvedAnimation(parent: _controller, curve: const Interval(0.6, 1.0)),
        ),
        child: ScaleTransition(
          scale: Tween(begin: 1.15, end: 1.0).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOut),
          ),
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}
