import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../db/app_database.dart';
import 'providers.dart';

/// Error-only local diagnostics. Never logs routine / success paths.
class ErrorLogRepository {
  ErrorLogRepository(this._db);

  final AppDatabase _db;
  static const _maxRows = 300;
  static const fileName = 'monedero_errors.jsonl';

  Future<void> record({
    required String source,
    required Object error,
    StackTrace? stackTrace,
    String? detail,
  }) async {
    final message = error.toString();
    final extra = [
      if (detail != null && detail.trim().isNotEmpty) detail.trim(),
      if (stackTrace != null)
        stackTrace.toString().split('\n').take(12).join('\n'),
    ].join('\n');
    try {
      await _db.into(_db.errorLogs).insert(
            ErrorLogsCompanion.insert(
              source: source,
              message: message.length > 2000
                  ? '${message.substring(0, 2000)}…'
                  : message,
              detail: Value(extra.isEmpty
                  ? null
                  : (extra.length > 4000
                      ? '${extra.substring(0, 4000)}…'
                      : extra)),
            ),
          );
      await _prune();
      await _appendFile(
        source: source,
        message: message,
        detail: extra.isEmpty ? null : extra,
      );
    } catch (e) {
      debugPrint('ErrorLogRepository.record failed: $e');
    }
  }

  Future<void> _prune() async {
    final rows = await (_db.select(_db.errorLogs)
          ..orderBy([(t) => OrderingTerm.desc(t.id)])
          ..limit(_maxRows + 50))
        .get();
    if (rows.length <= _maxRows) return;
    final cutoff = rows[_maxRows - 1].id;
    await (_db.delete(_db.errorLogs)
          ..where((t) => t.id.isSmallerThanValue(cutoff)))
        .go();
  }

  Future<void> _appendFile({
    required String source,
    required String message,
    String? detail,
  }) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, fileName));
      final line = jsonEncode({
        'at': DateTime.now().toIso8601String(),
        'source': source,
        'message': message,
        'detail': ?detail,
      });
      await file.writeAsString('$line\n', mode: FileMode.append, flush: true);
    } catch (_) {}
  }

  Stream<List<ErrorLog>> watchRecent({int limit = 100}) {
    return (_db.select(_db.errorLogs)
          ..orderBy([(t) => OrderingTerm.desc(t.id)])
          ..limit(limit))
        .watch();
  }

  Future<List<ErrorLog>> recent({int limit = 100}) {
    return (_db.select(_db.errorLogs)
          ..orderBy([(t) => OrderingTerm.desc(t.id)])
          ..limit(limit))
        .get();
  }

  Future<String> dumpText({int limit = 100}) async {
    final rows = await recent(limit: limit);
    if (rows.isEmpty) return '(no errors)';
    final buf = StringBuffer();
    for (final r in rows.reversed) {
      buf.writeln('--- ${r.createdAt.toIso8601String()} [${r.source}]');
      buf.writeln(r.message);
      if (r.detail != null && r.detail!.trim().isNotEmpty) {
        buf.writeln(r.detail);
      }
      buf.writeln();
    }
    return buf.toString();
  }

  Future<void> clear() async {
    await _db.delete(_db.errorLogs).go();
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, fileName));
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  static Future<String> filePath() async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, fileName);
  }
}

final errorLogRepositoryProvider = Provider<ErrorLogRepository>((ref) {
  return ErrorLogRepository(ref.watch(databaseProvider));
});

final errorLogsProvider = StreamProvider<List<ErrorLog>>((ref) {
  return ref.watch(errorLogRepositoryProvider).watchRecent();
});
