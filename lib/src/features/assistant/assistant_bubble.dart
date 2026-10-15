part of 'assistant_chat_screen.dart';

class _AssistantBubble extends StatelessWidget {
  const _AssistantBubble({
    this.fromUser = false,
    required this.child,
    this.time,
    this.imagePath,
    this.wide = false,
  });

  final bool fromUser;
  final Widget child;
  final TimeOfDay? time;
  final String? imagePath;
  /// Slightly wider bubble for table replies.
  final bool wide;

  // SoftCard-like chat discs — separate floats on scaffold, not a panel.
  static const double _rL = 16;
  static const double _rS = 6;

  @override
  Widget build(BuildContext context) {
    final inbound = !fromUser;
    final timeLabel = time == null
        ? null
        : '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}';
    final hasImage =
        imagePath != null && File(imagePath!).existsSync();
    final widthFactor = wide ? 0.96 : 0.92;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Must match AiAssistantMark + right padding below (26 + 6).
          const avatarGap = 32.0;
          final usable = inbound
              ? (constraints.maxWidth - avatarGap)
                  .clamp(0.0, constraints.maxWidth)
              : constraints.maxWidth;
          final maxW = (usable * widthFactor).clamp(0.0, usable);

          final bubbleColor = fromUser
              ? AppColors.lime
              : (context.isDark
                  ? const Color(0xFF333333)
                  : context.surface);

          final bubble = Container(
            clipBehavior: Clip.antiAlias,
            constraints: BoxConstraints(maxWidth: maxW),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(_rL),
                topRight: const Radius.circular(_rL),
                bottomLeft: Radius.circular(fromUser ? _rL : _rS),
                bottomRight: Radius.circular(fromUser ? _rS : _rL),
              ),
            ),
            child: hasImage
                ? _mediaBody(
                    context: context,
                    maxW: maxW,
                    timeLabel: timeLabel,
                  )
                : _textBody(
                    context: context,
                    maxW: maxW,
                    timeLabel: timeLabel,
                    stretch: wide,
                  ),
          );

          final bubbleWithSelection = DefaultSelectionStyle(
            selectionColor: fromUser
                ? AppColors.selectionOnLime
                : (context.isDark
                    ? AppColors.selectionDark
                    : AppColors.selectionLight),
            cursorColor: fromUser
                ? AppColors.selectionHandleOnLime
                : (context.isDark
                    ? AppColors.selectionHandle
                    : AppColors.limeAccent),
            child: bubble,
          );

          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (inbound)
                const Padding(
                  padding: EdgeInsets.only(right: 6, bottom: 2),
                  child: AiAssistantMark(size: 26, iconSize: 12),
                ),
              Expanded(
                child: Align(
                  alignment: inbound
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: bubbleWithSelection,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _textBody({
    required BuildContext context,
    required double maxW,
    required String? timeLabel,
    required bool stretch,
  }) {
    // IntrinsicWidth shrink-wraps short messages. Do NOT put an unconstrained
    // Align around the timestamp — it expands to maxW and forces full-width bubbles.
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
          child: stretch ? SizedBox(width: maxW - 24, child: child) : child,
        ),
        if (timeLabel != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
            child: Text(
              timeLabel,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11,
                height: 1.2,
                color: fromUser
                    ? AppColors.ink.withValues(alpha: 0.5)
                    : context.faintText,
              ),
            ),
          ),
      ],
    );
    if (stretch) return SizedBox(width: maxW, child: column);
    return IntrinsicWidth(child: column);
  }

  Widget _mediaBody({
    required BuildContext context,
    required double maxW,
    required String? timeLabel,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(_rL),
            topRight: Radius.circular(_rL),
            bottomLeft: Radius.circular(6),
            bottomRight: Radius.circular(6),
          ),
          child: Image.file(
            File(imagePath!),
            height: 160,
            width: maxW,
            fit: BoxFit.cover,
            cacheWidth: (MediaQuery.devicePixelRatioOf(context) * maxW)
                .round(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: child,
        ),
        if (timeLabel != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
            child: Text(
              timeLabel,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11,
                height: 1.2,
                color: fromUser
                    ? AppColors.ink.withValues(alpha: 0.5)
                    : context.faintText,
              ),
            ),
          ),
      ],
    );
  }
}
