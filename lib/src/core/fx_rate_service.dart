import 'dart:convert';

import 'package:http/http.dart' as http;

/// Live FX rates with no API key.
/// Primary: open.er-api.com. Fallback: Frankfurter (ECB).
class FxRateService {
  FxRateService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _timeout = Duration(seconds: 8);

  Future<double?> fetchRate(String from, String to) async {
    final a = from.toUpperCase();
    final b = to.toUpperCase();
    if (a == b) return 1;
    return await _openErApi(a, b) ?? await _frankfurter(a, b);
  }

  Future<double?> _openErApi(String from, String to) async {
    try {
      final uri = Uri.parse('https://open.er-api.com/v6/latest/$from');
      final res = await _client.get(uri).timeout(_timeout);
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body);
      if (json is! Map || json['result'] != 'success') return null;
      final rates = json['rates'];
      if (rates is! Map) return null;
      final v = rates[to];
      if (v is num && v > 0) return v.toDouble();
    } catch (_) {}
    return null;
  }

  Future<double?> _frankfurter(String from, String to) async {
    try {
      final uri = Uri.parse(
          'https://api.frankfurter.app/latest?from=$from&to=$to');
      final res = await _client.get(uri).timeout(_timeout);
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body);
      if (json is! Map) return null;
      final rates = json['rates'];
      if (rates is! Map) return null;
      final v = rates[to];
      if (v is num && v > 0) return v.toDouble();
    } catch (_) {}
    return null;
  }
}
