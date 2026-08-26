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

enum CsvField { date, amount, type, currency, note }

class CsvColumnMapping {
  const CsvColumnMapping({
    required this.delimiter,
    required this.hasHeader,
    required this.indices,
  });

  final String delimiter;
  final bool hasHeader;
  final Map<CsvField, int?> indices;

  CsvColumnMapping copyWithIndex(CsvField field, int? index) {
    return CsvColumnMapping(
      delimiter: delimiter,
      hasHeader: hasHeader,
      indices: {...indices, field: index},
    );
  }
}

class CsvInspectResult {
  const CsvInspectResult({
    required this.headers,
    required this.sampleRows,
    required this.detected,
    required this.columnCount,
  });

  final List<String> headers;
  final List<List<String>> sampleRows;
  final CsvColumnMapping detected;
  final int columnCount;
}

/// Inspect CSV structure for a mapping UI.
CsvInspectResult inspectCsv(String raw) {
  final text = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();
  if (text.isEmpty) {
    return const CsvInspectResult(
      headers: [],
      sampleRows: [],
      detected: CsvColumnMapping(
        delimiter: ',',
        hasHeader: false,
        indices: {},
      ),
      columnCount: 0,
    );
  }

  final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
  final delimiter = _detectDelimiter(lines.first);
  final first = _splitCsvLine(lines.first, delimiter);
  final hasHeader = _looksLikeHeader(first);
  final columnCount = first.length;
  final headers = hasHeader
      ? [
          for (var i = 0; i < first.length; i++)
            first[i].trim().isEmpty ? 'Col ${i + 1}' : first[i].trim(),
        ]
      : [for (var i = 0; i < columnCount; i++) 'Col ${i + 1}'];

  final dataStart = hasHeader ? 1 : 0;
  final sample = <List<String>>[];
  for (var i = dataStart; i < lines.length && sample.length < 20; i++) {
    sample.add(_splitCsvLine(lines[i], delimiter));
  }

  return CsvInspectResult(
    headers: headers,
    sampleRows: sample,
    detected: _detectMapping(first, delimiter, hasHeader),
    columnCount: columnCount,
  );
}

/// Parses Monedero CSV and simple bank CSVs.
CsvParseResult parseTransactionCsv(
  String raw, {
  required String fallbackCurrency,
  CsvColumnMapping? mapping,
}) {
  final text = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();
  if (text.isEmpty) return const CsvParseResult(rows: [], skipped: 0);

  final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
  if (lines.isEmpty) return const CsvParseResult(rows: [], skipped: 0);

  final map = mapping ??
      () {
        final delimiter = _detectDelimiter(lines.first);
        final headerCells = _splitCsvLine(lines.first, delimiter);
        final hasHeader = _looksLikeHeader(headerCells);
        return _detectMapping(headerCells, delimiter, hasHeader);
      }();

  final start = map.hasHeader ? 1 : 0;
  final dateIdx = map.indices[CsvField.date] ?? 0;
  final amountIdx = map.indices[CsvField.amount] ?? 1;
  final typeIdx = map.indices[CsvField.type];
  final currencyIdx = map.indices[CsvField.currency];
  final noteIdx = map.indices[CsvField.note];

  final rows = <ImportedRow>[];
  var skipped = 0;
  for (var i = start; i < lines.length; i++) {
    final cells = _splitCsvLine(lines[i], map.delimiter);
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
    final TxType type;
    if (typeIdx != null && typeIdx >= 0) {
      type = _parseType(_cell(cells, typeIdx), amountRaw);
    } else {
      type = amountRaw < 0 ? TxType.expense : TxType.income;
    }
    final amount = amountRaw.abs();
    final currency = currencyIdx != null && currencyIdx >= 0
        ? _normalizeCurrency(_cell(cells, currencyIdx), fallbackCurrency)
        : fallbackCurrency;
    final note = noteIdx != null && noteIdx >= 0
        ? _nullIfEmpty(_cell(cells, noteIdx))
        : null;
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

CsvColumnMapping _detectMapping(
  List<String> headerCells,
  String delimiter,
  bool hasHeader,
) {
  if (!hasHeader) {
    return CsvColumnMapping(
      delimiter: delimiter,
      hasHeader: false,
      indices: const {
        CsvField.date: 0,
        CsvField.type: 1,
        CsvField.amount: 2,
        CsvField.currency: 3,
        CsvField.note: 4,
      },
    );
  }
  return CsvColumnMapping(
    delimiter: delimiter,
    hasHeader: true,
    indices: {
      CsvField.date: _headerIndex(
            headerCells,
            const ['date', 'fecha', 'дата', 'fecha valor', 'booking', 'value date'],
          ) ??
          0,
      CsvField.type: _headerIndex(headerCells, const ['type', 'tipo', 'тип']),
      CsvField.amount: _headerIndex(
            headerCells,
            const ['amount', 'importe', 'monto', 'сумма', 'value'],
          ) ??
          1,
      CsvField.currency: _headerIndex(
        headerCells,
        const ['currency', 'moneda', 'валюта', 'divisa'],
      ),
      CsvField.note: _headerIndex(
        headerCells,
        const [
          'note',
          'notes',
          'concepto',
          'description',
          'descripcion',
          'detalle',
          'memo',
          'заметка',
        ],
      ),
    },
  );
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
