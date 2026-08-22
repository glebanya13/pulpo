import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n/tr.dart';
import 'common.dart';

/// Shows loading / error / data for a single [AsyncValue].
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    super.key,
    required this.value,
    required this.data,
    this.loading,
    this.onRetry,
    this.errorMessage,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final Widget? loading;
  final VoidCallback? onRetry;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () =>
          loading ??
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
      error: (e, _) => ErrorView(
        message: errorMessage ?? dataLoadErrorMessage(Tr.of(context), e),
        onRetry: onRetry,
      ),
    );
  }
}

/// First error among [values], otherwise [child].
class AsyncValuesGate extends StatelessWidget {
  const AsyncValuesGate({
    super.key,
    required this.values,
    required this.child,
    this.onRetry,
  });

  final List<AsyncValue<dynamic>> values;
  final Widget child;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    for (final v in values) {
      if (v.hasError) {
        return ErrorView(
          message: dataLoadErrorMessage(tr, v.error!),
          onRetry: onRetry,
        );
      }
    }
    if (values.any((v) => v.isLoading)) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    return child;
  }
}

String dataLoadErrorMessage(Tr tr, Object error) {
  final text = error.toString().toLowerCase();
  if (text.contains('sqlite') || text.contains('database')) {
    return tr.dataLoadDbError;
  }
  if (text.contains('socket') ||
      text.contains('network') ||
      text.contains('connection')) {
    return tr.dataLoadNetworkError;
  }
  return tr.dataLoadGenericError;
}
