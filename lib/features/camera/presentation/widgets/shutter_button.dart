import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The primary capture control. Handles its own press animation and haptic
/// feedback, and guards against duplicate taps while a capture is already
/// in flight (the [isBusy] flag disables the control entirely).
class ShutterButton extends StatefulWidget {
  const ShutterButton({
    super.key,
    required this.onPressed,
    required this.isBusy,
    required this.hapticsEnabled,
  });

  final VoidCallback onPressed;
  final bool isBusy;
  final bool hapticsEnabled;

  @override
  State<ShutterButton> createState() => _ShutterButtonState();
}

class _ShutterButtonState extends State<ShutterButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.isBusy) return;
    setState(() => _pressed = value);
  }

  void _handleTap() {
    if (widget.isBusy) return;
    if (widget.hapticsEnabled) HapticFeedback.mediumImpact();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Take photo',
      enabled: !widget.isBusy,
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: _handleTap,
        child: AnimatedScale(
          scale: _pressed ? 0.88 : 1.0,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: Container(
            width: 76,
            height: 76,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3.5),
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isBusy ? Colors.white38 : Colors.white,
              ),
              child: widget.isBusy
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.black87,
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
