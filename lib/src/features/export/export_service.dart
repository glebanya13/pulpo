import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../data/db/app_database.dart' as db;
import '../../data/db/enums.dart';

enum ExportFormat { csv, excel, pdf }

class ExportService {
  Future<void> shareTransactions({
    required List<db.Transaction> txs,
    required ExportFormat format,
    required DateTime start,
    required DateTime end,
  }) async {
    final stamp = DateFormat('yyyyMMdd').format(start);
    final stamp2 = DateFormat('yyyyMMdd').format(end);
    final dir = await getTemporaryDirectory();

    switch (format) {
      case ExportFormat.csv:
      case ExportFormat.excel:
        final ext = format == ExportFormat.excel ? 'xls' : 'csv';
        final file = File('${dir.path}/pulpo-$stamp-$stamp2.$ext');
        await file.writeAsString(_toCsv(txs), flush: true);
        await Share.shareXFiles([XFile(file.path, mimeType: 'text/csv')]);
      case ExportFormat.pdf:
        final doc = pw.Document();
        doc.addPage(
          pw.MultiPage(
            build: (ctx) => [
              pw.Text('Pulpo export $stamp – $stamp2'),
              pw.SizedBox(height: 12),
              pw.TableHelper.fromTextArray(
                headers: const ['Date', 'Type', 'Amount', 'Note'],
                data: [
                  for (final t in txs)
                    [
                      DateFormat('yyyy-MM-dd').format(t.date),
                      TxType.values[t.type].name,
                      t.amount.toStringAsFixed(2),
                      t.note ?? '',
                    ],
                ],
              ),
            ],
          ),
        );
        final file = File('${dir.path}/pulpo-$stamp-$stamp2.pdf');
        await file.writeAsBytes(await doc.save());
        await Share.shareXFiles([XFile(file.path, mimeType: 'application/pdf')]);
    }
  }

  String _toCsv(List<db.Transaction> txs) {
    final buf = StringBuffer('date,type,amount,currency,note\n');
    for (final t in txs) {
      final note = (t.note ?? '').replaceAll('"', '""');
      buf.writeln(
        '${t.date.toIso8601String()},${TxType.values[t.type].name},${t.amount},${t.currency},"$note"',
      );
    }
    return buf.toString();
  }
}

final exportService = ExportService();
