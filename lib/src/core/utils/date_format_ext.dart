import 'package:intl/intl.dart';

/// Capitalize the first letter of [input] (locale-safe for BMP chars).
String capitalizeFirstLetter(String input) {
  if (input.isEmpty) return input;
  return input[0].toUpperCase() + input.substring(1);
}

/// Ensure month names in a formatted date start with a capital letter.
///
/// Needed for ru/uk (and some es) where `intl` often returns lowercase months
/// like `сентябрь 2026` or `5 сентября 2026`.
String capitalizeMonthsInDate(String formatted, [String? locale]) {
  if (formatted.isEmpty) return formatted;

  final loc = locale ?? Intl.getCurrentLocale();
  final monthForms = <String>{};
  for (var month = 1; month <= 12; month++) {
    final sample = DateTime(2024, month, 15);
    for (final pattern in ['LLLL', 'MMMM', 'LLL', 'MMM']) {
      final form = DateFormat(pattern, loc).format(sample);
      if (form.trim().isNotEmpty) {
        monthForms.add(form.trim().toLowerCase());
      }
    }
  }

  var result = formatted;
  final sorted = monthForms.toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  for (final month in sorted) {
    if (month.isEmpty) continue;
    final capped = capitalizeFirstLetter(month);
    result = result.replaceAllMapped(
      RegExp('(?<!\\p{L})${RegExp.escape(month)}(?!\\p{L})',
          caseSensitive: false, unicode: true),
      (_) => capped,
    );
  }

  // Month-year titles like "сентябрь 2026".
  if (RegExp(r'^\p{L}', unicode: true).hasMatch(result)) {
    result = capitalizeFirstLetter(result);
  }
  return result;
}

/// Format [date] with [pattern], capitalizing month names.
String formatAppDate(
  DateTime date,
  String pattern, {
  String? locale,
}) {
  final loc = locale ?? Intl.getCurrentLocale();
  return capitalizeMonthsInDate(
    DateFormat(pattern, loc).format(date),
    loc,
  );
}

/// Stand-alone month + year, e.g. `Сентябрь 2026`.
String formatMonthYear(DateTime date, {String? locale}) {
  return formatAppDate(date, 'LLLL y', locale: locale);
}
