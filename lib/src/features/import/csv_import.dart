import '../../data/db/enums.dart';

class ImportedRow {
  const ImportedRow({
    required this.date,
    required this.type,
    required this.amount,
    required this.currency,
    this.note,
  });

  final DateTime date;
  final TxType type;
  final double amount;
  final String currency;
  final String? note;
}

class CsvParseResult {
  const CsvParseResult({required this.rows, required this.skipped});

  final List<ImportedRow> rows;
  final int skipped;
}

/// Parses Pulpo CSV (`date,type,amount,currency,note`) and simple bank CSVs.
CsvParseResult parseTransactionCsv(String raw, {required String fallbackCurrency}) {
  final text = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();
  if (text.isEmpty) return const CsvParseResult(rows: [], skipped: 0);

  final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
  if (lines.isEmpty) return const CsvParseResult(rows: [], skipped: 0);

  final delimiter = _detectDelimiter(lines.first);
  var start = 0;
  var dateIdx = 0;
  var typeIdx = 1;
  var amountIdx = 2;
  var currencyIdx = 3;
  var noteIdx = 4;
  var hasType = true;
  var hasCurrency = true;
  var hasNote = true;

  final headerCells = _splitCsvLine(lines.first, delimiter);
  if (_looksLikeHeader(headerCells)) {
    start = 1;
    dateIdx = _headerIndex(headerCells, const ['date', 'fecha', 'дата', 'fecha valor', 'booking', 'value date']) ?? 0;
    typeIdx = _headerIndex(headerCells, const ['type', 'tipo', 'тип']) ?? -1;
    amountIdx = _headerIndex(headerCells, const ['amount', 'importe', 'monto', 'сумма', 'value']) ?? 1;
    currencyIdx = _headerIndex(headerCells, const ['currency', 'moneda', 'валюта', 'divisa']) ?? -1;
    noteIdx = _headerIndex(
          headerCells,
          const ['note', 'notes', 'concepto', 'description', 'descripcion', 'detalle', 'memo', 'заметка'],
        ) ??
        -1;
    hasType = typeIdx >= 0;
    hasCurrency = currencyIdx >= 0;
    hasNote = noteIdx >= 0;
  }

  final rows = <ImportedRow>[];
  var skipped = 0;
  for (var i = start; i < lines.length; i++) {
    final cells = _splitCsvLine(lines[i], delimiter);
    if (cells.isEmpty) {
      skipped++;
      continue;
    }
    final date = _parseDate(_cell(cells, dateIdx));
    final amountRaw = _parseAmount(_cell(cells, amountIdx));
    if (date == null || amountRaw == null || amountRaw == 0) {
      skipped++;
      continue;
    }
    TxType type;
    if (hasType) {
      type = _parseType(_cell(cells, typeIdx), amountRaw);
    } else {
      type = amountRaw < 0 ? TxType.expense : TxType.income;
    }
    final amount = amountRaw.abs();
    final currency = hasCurrency
        ? _normalizeCurrency(_cell(cells, currencyIdx), fallbackCurrency)
        : fallbackCurrency;
    final note = hasNote ? _nullIfEmpty(_cell(cells, noteIdx)) : null;
    rows.add(ImportedRow(
      date: date,
      type: type,
      amount: amount,
      currency: currency,
      note: note,
    ));
  }
  return CsvParseResult(rows: rows, skipped: skipped);
}

String _detectDelimiter(String line) {
  final semi = ';'.allMatches(line).length;
  final comma = ','.allMatches(line).length;
  return semi > comma ? ';' : ',';
}

bool _looksLikeHeader(List<String> cells) {
  final joined = cells.map((c) => c.toLowerCase().trim()).join(' ');
  return joined.contains('date') ||
      joined.contains('fecha') ||
      joined.contains('дата') ||
      joined.contains('amount') ||
      joined.contains('importe') ||
      joined.contains('monto') ||
      joined.contains('сумма') ||
      joined.contains('type') ||
      joined.contains('tipo') ||
      joined.contains('тип');
}

int? _headerIndex(List<String> cells, List<String> names) {
  for (var i = 0; i < cells.length; i++) {
    final v = cells[i].toLowerCase().trim();
    for (final n in names) {
      if (v == n || v.contains(n)) return i;
    }
  }
  return null;
}

String _cell(List<String> cells, int index) {
  if (index < 0 || index >= cells.length) return '';
  return cells[index].trim();
}

List<String> _splitCsvLine(String line, String delimiter) {
  final out = <String>[];
  final buf = StringBuffer();
  var inQuotes = false;
  for (var i = 0; i < line.length; i++) {
    final ch = line[i];
    if (ch == '"') {
      if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
        buf.write('"');
        i++;
      } else {
        inQuotes = !inQuotes;
      }
    } else if (ch == delimiter && !inQuotes) {
      out.add(buf.toString());
      buf.clear();
    } else {
      buf.write(ch);
    }
  }
  out.add(buf.toString());
  return out;
}

DateTime? _parseDate(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return null;
  final iso = DateTime.tryParse(s);
  if (iso != null) return iso;
  final m = RegExp(r'^(\d{1,4})[./-](\d{1,2})[./-](\d{1,4})').firstMatch(s);
  if (m == null) return null;
  final a = int.parse(m.group(1)!);
  final b = int.parse(m.group(2)!);
  final c = int.parse(m.group(3)!);
  if (a > 1900) return DateTime(a, b, c);
  if (c > 1900) {
    if (a > 12) return DateTime(c, b, a);
    return DateTime(c, a, b);
  }
  return null;
}

double? _parseAmount(String raw) {
  var s = raw.trim();
  if (s.isEmpty) return null;
  s = s.replaceAll('\u00A0', '').replaceAll(' ', '');
  s = s.replaceAll('€', '').replaceAll('\$', '').replaceAll('EUR', '');
  if (s.contains(',') && s.contains('.')) {
    if (s.lastIndexOf(',') > s.lastIndexOf('.')) {
      s = s.replaceAll('.', '').replaceAll(',', '.');
    } else {
      s = s.replaceAll(',', '');
    }
  } else if (s.contains(',')) {
    s = s.replaceAll(',', '.');
  }
  return double.tryParse(s);
}

TxType _parseType(String raw, double amount) {
  final s = raw.trim().toLowerCase();
  if (s.contains('income') ||
      s.contains('ingreso') ||
      s.contains('доход') ||
      s == '1') {
    return TxType.income;
  }
  if (s.contains('transfer') ||
      s.contains('transferencia') ||
      s.contains('перевод') ||
      s == '2') {
    return TxType.transfer;
  }
  if (s.contains('expense') ||
      s.contains('gasto') ||
      s.contains('расход') ||
      s == '0') {
    return TxType.expense;
  }
  return amount < 0 ? TxType.expense : TxType.income;
}

String _normalizeCurrency(String raw, String fallback) {
  final s = raw.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
  if (s.length == 3) return s;
  return fallback;
}

String? _nullIfEmpty(String raw) {
  final s = raw.trim();
  return s.isEmpty ? null : s;
}
