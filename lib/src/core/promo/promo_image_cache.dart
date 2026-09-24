import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/painting.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Disk cache for home-ad creatives (Firebase Storage URLs).
class PromoImageCache {
  const PromoImageCache._();

  static final Map<String, Future<File?>> _inflight = {};

  static String _key(String url) =>
      sha1.convert(utf8.encode(url)).toString();

  static Future<Directory> _dir() async {
    final root = await getApplicationSupportDirectory();
    final dir = Directory(p.join(root.path, 'promo_ads'));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<File> _fileFor(String url) async {
    final dir = await _dir();
    return File(p.join(dir.path, '${_key(url)}.img'));
  }

  /// Cached file if present; otherwise null (does not download).
  static Future<File?> peek(String url) async {
    final file = await _fileFor(url);
    if (!file.existsSync() || file.lengthSync() == 0) return null;
    return file;
  }

  /// Returns a local file, downloading once if needed. Concurrent calls share
  /// the same download.
  static Future<File?> warm(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return Future.value(null);
    return _inflight.putIfAbsent(trimmed, () => _warmOnce(trimmed));
  }

  static Future<File?> _warmOnce(String url) async {
    try {
      final existing = await peek(url);
      if (existing != null) return existing;

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        return null;
      }

      final file = await _fileFor(url);
      await FileImage(file).evict();
      await file.writeAsBytes(response.bodyBytes, flush: true);
      await FileImage(file).evict();
      return file;
    } catch (_) {
      return null;
    } finally {
      // Keep successful futures cached via peek; drop failed so retry works.
      final cached = await peek(url);
      if (cached == null) {
        _inflight.remove(url);
      }
    }
  }

  static Future<void> warmAll(Iterable<String?> urls) async {
    final unique = <String>{
      for (final u in urls)
        if (u != null && u.trim().isNotEmpty) u.trim(),
    };
    await Future.wait(unique.map(warm));
  }
}
