import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../data/db/app_database.dart' as db;
import '../../data/db/enums.dart';
import '../../core/l10n/tr.dart';

enum ExportFormat { csv, excel, pdf }

String _txTypeLabel(Tr tr, TxType type) {
  switch (type) {
    case TxType.income:
      return tr.income;
    case TxType.expense:
      return tr.expense;
    case TxType.transfer:
      return tr.transfer;
  }
}

class _ExportTotals {
  const _ExportTotals({
    required this.income,
    required this.expense,
    required this.currencyLabel,
  });

  final double income;
  final double expense;
  final String currencyLabel;

  double get net => income - expense;

  String money(double v) {
    final n = v.toStringAsFixed(2);
    return currencyLabel.isEmpty ? n : '$n $currencyLabel';
  }
}

_ExportTotals _totalsOf(List<db.Transaction> txs) {
  var income = 0.0;
  var expense = 0.0;
  final currencies = <String>{};
  for (final t in txs) {
    currencies.add(t.currency);
    switch (TxType.values[t.type]) {
      case TxType.income:
        income += t.amount;
      case TxType.expense:
        expense += t.amount;
      case TxType.transfer:
        break;
    }
  }
  final currencyLabel = currencies.length == 1 ? currencies.first : '';
  return _ExportTotals(
    income: income,
    expense: expense,
    currencyLabel: currencyLabel,
  );
}

class ExportService {
  Future<void> shareTransactions({
    required List<db.Transaction> txs,
    required ExportFormat format,
    required DateTime start,
    required DateTime end,
    required String locale,
    Rect? shareOrigin,
  }) async {
    final stamp = DateFormat('yyyyMMdd').format(start);
    final stamp2 = DateFormat('yyyyMMdd').format(end);
    final dir = await getTemporaryDirectory();
    final range = '$stamp-$stamp2';
    final tr = Tr.fromLang(locale);
    final totals = _totalsOf(txs);

    switch (format) {
      case ExportFormat.csv:
        final file = File('${dir.path}/monedero-$range.csv');
        await file.writeAsString(_toCsv(txs, tr, totals), flush: true);
        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'text/csv')],
          sharePositionOrigin: shareOrigin,
        );
      case ExportFormat.excel:
        final file = File('${dir.path}/monedero-$range.xlsx');
        await file.writeAsBytes(
          buildTransactionsXlsx(txs, tr: tr),
          flush: true,
        );
        await Share.shareXFiles(
          [
            XFile(
              file.path,
              mimeType:
                  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            ),
          ],
          sharePositionOrigin: shareOrigin,
        );
      case ExportFormat.pdf:
        final fontData =
            await rootBundle.load('assets/fonts/DejaVuSans.ttf');
        final font = pw.Font.ttf(fontData);
        final doc = pw.Document();
        doc.addPage(
          pw.MultiPage(
            theme: pw.ThemeData.withFont(base: font, bold: font),
            build: (ctx) => [
              pw.Text(
                'Monedero $stamp – $stamp2',
                style: pw.TextStyle(
                    fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 12),
              pw.TableHelper.fromTextArray(
                headers: [
                  tr.exportPdfDate,
                  tr.exportPdfType,
                  tr.exportPdfAmount,
                  tr.exportPdfNote,
                ],
                data: [
                  for (final t in txs)
                    [
                      DateFormat('yyyy-MM-dd').format(t.date),
                      _txTypeLabel(tr, TxType.values[t.type]),
                      t.amount.toStringAsFixed(2),
                      t.note ?? '',
                    ],
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                '${tr.exportTotalIncome}: ${totals.money(totals.income)}',
                style: pw.TextStyle(
                    fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                '${tr.exportTotalExpense}: ${totals.money(totals.expense)}',
                style: pw.TextStyle(
                    fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                '${tr.exportNet}: ${totals.money(totals.net)}',
                style: pw.TextStyle(
                    fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        );
        final file = File('${dir.path}/monedero-$range.pdf');
        await file.writeAsBytes(await doc.save());
        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'application/pdf')],
          sharePositionOrigin: shareOrigin,
        );
    }
  }

  String _toCsv(
    List<db.Transaction> txs,
    Tr tr,
    _ExportTotals totals,
  ) {
    final buf = StringBuffer('date,type,amount,currency,note\n');
    for (final t in txs) {
      final note = (t.note ?? '').replaceAll('"', '""');
      buf.writeln(
        '${t.date.toIso8601String()},${TxType.values[t.type].name},${t.amount},${t.currency},"$note"',
      );
    }
    buf.writeln();
    buf.writeln('${tr.exportTotalIncome},${totals.income.toStringAsFixed(2)},${totals.currencyLabel}');
    buf.writeln('${tr.exportTotalExpense},${totals.expense.toStringAsFixed(2)},${totals.currencyLabel}');
    buf.writeln('${tr.exportNet},${totals.net.toStringAsFixed(2)},${totals.currencyLabel}');
    return buf.toString();
  }
}

String _xml(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

String _col(int i) => String.fromCharCode(65 + i);

String _inline(String col, int row, String value) =>
    '<c r="$col$row" t="inlineStr"><is><t>${_xml(value)}</t></is></c>';

String _num(String col, int row, double value) =>
    '<c r="$col$row" t="n"><v>${value.toStringAsFixed(2)}</v></c>';

/// Office Open XML (.xlsx) workbook.
List<int> buildTransactionsXlsx(
  List<db.Transaction> txs, {
  Tr? tr,
}) {
  final labels = tr ?? Tr.fromLang('en');
  final sums = _totalsOf(txs);
  final rows = StringBuffer();
  rows.writeln('<row r="1">');
  const headers = ['date', 'type', 'amount', 'currency', 'note'];
  for (var i = 0; i < headers.length; i++) {
    rows.write(_inline(_col(i), 1, headers[i]));
  }
  rows.writeln('</row>');
  for (var r = 0; r < txs.length; r++) {
    final t = txs[r];
    final row = r + 2;
    rows.writeln('<row r="$row">');
    rows.write(_inline(_col(0), row, DateFormat('yyyy-MM-dd').format(t.date)));
    rows.write(_inline(_col(1), row, TxType.values[t.type].name));
    rows.write(_num(_col(2), row, t.amount));
    rows.write(_inline(_col(3), row, t.currency));
    rows.write(_inline(_col(4), row, t.note ?? ''));
    rows.writeln('</row>');
  }

  var row = txs.length + 3;
  void summaryRow(String label, double amount) {
    rows.writeln('<row r="$row">');
    rows.write(_inline(_col(0), row, label));
    rows.write(_num(_col(1), row, amount));
    if (sums.currencyLabel.isNotEmpty) {
      rows.write(_inline(_col(2), row, sums.currencyLabel));
    }
    rows.writeln('</row>');
    row++;
  }

  summaryRow(labels.exportTotalIncome, sums.income);
  summaryRow(labels.exportTotalExpense, sums.expense);
  summaryRow(labels.exportNet, sums.net);

  final files = <String, String>{
    '[Content_Types].xml':
        '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
<Default Extension="xml" ContentType="application/xml"/>
<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
</Types>''',
    '_rels/.rels': '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
</Relationships>''',
    'xl/workbook.xml':
        '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"
 xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
<sheets><sheet name="Monedero" sheetId="1" r:id="rId1"/></sheets>
</workbook>''',
    'xl/_rels/workbook.xml.rels':
        '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
</Relationships>''',
    'xl/worksheets/sheet1.xml':
        '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
<sheetData>
$rows
</sheetData>
</worksheet>''',
  };

  final archive = Archive();
  files.forEach((name, content) {
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  });
  return ZipEncoder().encode(archive);
}

final exportService = ExportService();
