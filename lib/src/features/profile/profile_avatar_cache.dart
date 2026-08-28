import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _cacheFileName = 'profile_avatar_remote.jpg';
const _cachedUrlKey = 'profile_avatar_remote_url';

/// Disk cache for remote profile photos (Google / Firebase Storage URLs).
class ProfileAvatarCache {
  const ProfileAvatarCache._();

  static Future<File> _cacheFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, _cacheFileName));
  }

  static String normalizeUrl(String url) {
    var u = url.trim();
    if (!u.contains('googleusercontent.com')) return u;
    u = u
        .replaceAll(RegExp(r'=s\d+-c?\b'), '=s256-c')
        .replaceAll(RegExp(r'/s\d+-c?/'), '/s256-c/');
    if (!RegExp(r'[=/]s\d').hasMatch(u)) {
      u = u.contains('?') ? '$u&sz=256' : '$u=s256-c';
    }
    return u;
  }

  static Future<File?> fileForUrl(String url) async {
    final normalized = normalizeUrl(url);
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_cachedUrlKey) != normalized) return null;
    final file = await _cacheFile();
    if (!file.existsSync()) return null;
    return file;
  }

  /// Returns cached file or downloads and stores it.
  static Future<File?> warm(String url) async {
    final normalized = normalizeUrl(url);
    final existing = await fileForUrl(url);
    if (existing != null) return existing;

    try {
      final response = await http
          .get(Uri.parse(normalized))
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) return null;

      final file = await _cacheFile();
      await file.writeAsBytes(response.bodyBytes, flush: true);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cachedUrlKey, normalized);
      return file;
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedUrlKey);
    try {
      final file = await _cacheFile();
      if (file.existsSync()) await file.delete();
    } catch (_) {}
  }
}
