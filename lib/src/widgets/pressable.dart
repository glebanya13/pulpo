import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Scales and dims on press so taps are obvious.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.onTap,
    required this.child,
    this.scale = 0.96,
    this.enabled = true,
  });

  final VoidCallback onTap;
  final Widget child;
  final double scale;
  final bool enabled;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  var _down = false;

  void _set(bool down) {
    if (!widget.enabled || _down == down) return;
    setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.enabled ? (_) => _set(true) : null,
      onTapUp: widget.enabled
          ? (_) {
              Future<void>.delayed(const Duration(milliseconds: 70), () {
                if (mounted) _set(false);
              });
            }
          : null,
      onTapCancel: widget.enabled ? () => _set(false) : null,
      onTap: widget.enabled
          ? () {
              HapticFeedback.selectionClick();
              widget.onTap();
            }
          : null,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: _down ? 0.72 : 1,
          duration: const Duration(milliseconds: 90),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Lime [ElevatedButton] with the same press scale as custom chips.
class ScaledElevatedButton extends StatelessWidget {
  const ScaledElevatedButton({
    super.key,
    required this.onPressed,
    required this.child,
  });

  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      enabled: onPressed != null,
      onTap: onPressed ?? () {},
      scale: 0.97,
      child: AbsorbPointer(
        child: ElevatedButton(
          onPressed: onPressed,
          child: child,
        ),
      ),
    );
  }
}
