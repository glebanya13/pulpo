import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Scales and dims on press so taps are obvious.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    this.onTap,
    required this.child,
    this.scale = 0.96,
    this.enabled = true,
  });

  final VoidCallback? onTap;
  final Widget child;
  final double scale;
  final bool enabled;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  var _down = false;

  bool get _active => widget.enabled && widget.onTap != null;

  void _set(bool down) {
    if (!_active || _down == down) return;
    setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _active ? (_) => _set(true) : null,
      onTapUp: _active
          ? (_) {
              Future<void>.delayed(const Duration(milliseconds: 70), () {
                if (mounted) _set(false);
              });
            }
          : null,
      onTapCancel: _active ? () => _set(false) : null,
      onTap: _active
          ? () {
              HapticFeedback.selectionClick();
              widget.onTap!();
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
      onTap: onPressed,
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

/// [FilledButton] with the same press scale.
class ScaledFilledButton extends StatelessWidget {
  const ScaledFilledButton({
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
      onTap: onPressed,
      scale: 0.97,
      child: AbsorbPointer(
        child: FilledButton(
          onPressed: onPressed,
          child: child,
        ),
      ),
    );
  }
}

/// [TextButton] with the same press scale.
class ScaledTextButton extends StatelessWidget {
  const ScaledTextButton({
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
      onTap: onPressed,
      scale: 0.97,
      child: AbsorbPointer(
        child: TextButton(
          onPressed: onPressed,
          child: child,
        ),
      ),
    );
  }
}

/// [OutlinedButton] with the same press scale.
class ScaledOutlinedButton extends StatelessWidget {
  const ScaledOutlinedButton({
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
      onTap: onPressed,
      scale: 0.97,
      child: AbsorbPointer(
        child: OutlinedButton(
          onPressed: onPressed,
          child: child,
        ),
      ),
    );
  }
}
