import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PinPad extends StatelessWidget {
  const PinPad({
    super.key,
    required this.length,
    required this.value,
    required this.onChanged,
    this.dark = false,
  });

  final int length;
  final String value;
  final ValueChanged<String> onChanged;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final fg = dark ? Colors.white : const Color(0xFF0F0F0F);
    final keyBg = dark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFF2F2F2);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < value.length
                      ? const Color(0xFFCDFF3A)
                      : fg.withValues(alpha: 0.18),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 28),
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          ['', '0', '⌫'],
        ]) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final key in row)
                _Key(
                  label: key,
                  fg: fg,
                  bg: keyBg,
                  onTap: key.isEmpty
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          if (key == '⌫') {
                            if (value.isEmpty) return;
                            onChanged(value.substring(0, value.length - 1));
                          } else if (value.length < length) {
                            onChanged('$value$key');
                          }
                        },
                ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({
    required this.label,
    required this.fg,
    required this.bg,
    required this.onTap,
  });

  final String label;
  final Color fg;
  final Color bg;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox(width: 72, height: 72);
    return Material(
      color: bg,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 72,
          height: 72,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: label == '⌫' ? 22 : 26,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
