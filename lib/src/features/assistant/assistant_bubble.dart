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
  static const double _rL = 20;
  static const double _rS = 6;
  static const double _minMetaWidth = 76;

  @override
  Widget build(BuildContext context) {
    final inbound = !fromUser;
    final timeLabel = time == null
        ? null
        : '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}';
    final hasImage =
        imagePath != null && File(imagePath!).existsSync();
    // Text stays snug; tables keep a wider disc without filling the row.
    final widthFactor = wide ? 0.88 : 0.72;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxBubbleWidth = (constraints.maxWidth * widthFactor)
              .clamp(0.0, constraints.maxWidth);
          final margin = (constraints.maxWidth - maxBubbleWidth)
              .clamp(0.0, constraints.maxWidth);
          const avatarGap = 34.0;
          final maxW = inbound
              ? (maxBubbleWidth - avatarGap).clamp(0.0, maxBubbleWidth)
              : maxBubbleWidth;

          final bubbleColor = fromUser
              ? AppColors.lime
              : (context.isDark
                  ? const Color(0xFF333333)
                  : context.surface);

          final bubble = Container(
            clipBehavior: Clip.antiAlias,
            constraints: BoxConstraints(
              maxWidth: maxW,
              minWidth: timeLabel != null
                  ? (maxW < _minMetaWidth ? maxW : _minMetaWidth)
                  : 0,
            ),
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
              if (!inbound) SizedBox(width: margin),
              if (!inbound) const Spacer(),
              if (inbound)
                const Padding(
                  padding: EdgeInsets.only(right: 6, bottom: 2),
                  child: AiAssistantMark(size: 28, iconSize: 13),
                ),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: inbound
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.end,
                children: [bubbleWithSelection],
              ),
              if (inbound) SizedBox(width: margin),
              if (inbound) const Spacer(),
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
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
          child: child,
        ),
        if (timeLabel != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                timeLabel,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.2,
                  color: fromUser
                      ? AppColors.ink.withValues(alpha: 0.5)
                      : context.faintText,
                ),
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
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                timeLabel,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.2,
                  color: fromUser
                      ? AppColors.ink.withValues(alpha: 0.5)
                      : context.faintText,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
