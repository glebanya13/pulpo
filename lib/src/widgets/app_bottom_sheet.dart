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
    builder: builder,
  );
}
