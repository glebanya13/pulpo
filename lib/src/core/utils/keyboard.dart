import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Drops text focus and forcibly hides the IME.
///
/// Needed because disposing a focused [TextField] on pop can leave the
/// soft keyboard stuck on the previous route (common on iOS).
void dismissKeyboard() {
  FocusManager.instance.primaryFocus?.unfocus();
  SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
}

/// Hides the keyboard whenever a route is popped or replaced.
class KeyboardDismissObserver extends NavigatorObserver {
  void _dismiss() => dismissKeyboard();

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _dismiss();

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _dismiss();

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _dismiss();
}
