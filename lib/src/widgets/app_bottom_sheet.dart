import 'package:flutter/material.dart';

/// Modal sheet above the floating tab bar (macOS/desktop safe).
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Color? backgroundColor,
  ShapeBorder? shape,
  bool transparent = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: transparent ? Colors.transparent : backgroundColor,
    shape: shape,
    clipBehavior: Clip.antiAlias,
    sheetAnimationStyle: const AnimationStyle(
      duration: Duration(milliseconds: 380),
      reverseDuration: Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ),
    builder: (context) {
      return Stack(
        children: [
          // Основной контент модалки
          Padding(
            padding: const EdgeInsets.only(top: 48),
            child: builder(context),
          ),

          // Кнопка закрытия
          Positioned(
            top: 12,
            right: 12,
            child: Material(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.of(context).pop(),
                child: const SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(
                    Icons.close,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}