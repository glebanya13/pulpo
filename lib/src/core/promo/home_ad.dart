import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/settings_service.dart';
import '../app_info.dart';
import '../pro/pro_controller.dart';

const _kHomeAdPath = 'config/home_ad';
const _kDismissedKey = 'home_ad_dismissed_rev';

const _kAdLangs = ['es', 'en', 'ru', 'uk'];

@immutable
class HomeAdCopy {
  const HomeAdCopy({
    required this.title,
    required this.body,
    required this.ctaLabel,
  });

  final String title;
  final String body;
  final String ctaLabel;

  factory HomeAdCopy.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return const HomeAdCopy(title: '', body: '', ctaLabel: '');
    }
    return HomeAdCopy(
      title: (data['title'] as String?)?.trim() ?? '',
      body: (data['body'] as String?)?.trim() ?? '',
      ctaLabel: (data['ctaLabel'] as String?)?.trim() ?? '',
    );
  }

  bool get hasTitle => title.isNotEmpty;
}

/// One slide in the home promo carousel (raw + per-locale copy).
@immutable
class HomeAdItem {
  const HomeAdItem({
    required this.id,
    required this.ctaUrl,
    required this.i18n,
    this.enabled = true,
    this.imageUrl,
    this.fallback = const HomeAdCopy(title: '', body: '', ctaLabel: ''),
  });

  final String id;
  final bool enabled;
  final String ctaUrl;
  final String? imageUrl;
  /// Locale → copy. Keys: es / en / ru / uk.
  final Map<String, HomeAdCopy> i18n;
  /// Legacy flat fields when i18n is missing.
  final HomeAdCopy fallback;

  HomeAdCopy copyFor(String lang) {
    final code = _kAdLangs.contains(lang) ? lang : 'es';
    HomeAdCopy? pick(String l) {
      final c = i18n[l];
      if (c != null && c.hasTitle) return c;
      return null;
    }

    final fromI18n = pick(code) ??
        (code == 'uk' ? pick('ru') : null) ??
        pick('es') ??
        pick('en');
    if (fromI18n != null) return fromI18n;
    if (fallback.hasTitle) return fallback;
    for (final c in i18n.values) {
      if (c.hasTitle) return c;
    }
    return fallback;
  }

  /// Resolved slide for display in [lang].
  ResolvedHomeAd resolve(String lang) {
    final copy = copyFor(lang);
    return ResolvedHomeAd(
      id: id,
      title: copy.title,
      body: copy.body,
      ctaLabel: copy.ctaLabel,
      ctaUrl: ctaUrl,
      imageUrl: imageUrl,
    );
  }

  bool isActionableFor(String lang) {
    if (!enabled) return false;
    final r = resolve(lang);
    return r.title.isNotEmpty && r.ctaUrl.isNotEmpty;
  }

  factory HomeAdItem.fromMap(Map<String, dynamic> data, {String? fallbackId}) {
    final id = (data['id'] as String?)?.trim();
    final fallback = HomeAdCopy.fromMap({
      'title': data['title'],
      'body': data['body'],
      'ctaLabel': data['ctaLabel'],
    });

    final i18n = <String, HomeAdCopy>{};
    final rawI18n = data['i18n'];
    if (rawI18n is Map) {
      for (final e in rawI18n.entries) {
        final key = e.key.toString();
        if (!_kAdLangs.contains(key)) continue;
        final value = e.value;
        if (value is! Map) continue;
        final copy = HomeAdCopy.fromMap(Map<String, dynamic>.from(value));
        if (copy.hasTitle) i18n[key] = copy;
      }
    }

    if (i18n.isEmpty && fallback.hasTitle) {
      i18n['es'] = fallback;
    }

    return HomeAdItem(
      id: (id != null && id.isNotEmpty) ? id : (fallbackId ?? 'ad'),
      enabled: data['enabled'] != false,
      ctaUrl: (data['ctaUrl'] as String?)?.trim() ?? '',
      imageUrl: _nullableHttpUrl(data['imageUrl']),
      i18n: i18n,
      fallback: fallback,
    );
  }

  static String? _nullableHttpUrl(dynamic raw) {
    final s = raw?.toString().trim();
    if (s == null || s.isEmpty) return null;
    final uri = Uri.tryParse(s);
    if (uri == null || !(uri.isScheme('https') || uri.isScheme('http'))) {
      return null;
    }
    return s;
  }
}

@immutable
class ResolvedHomeAd {
  const ResolvedHomeAd({
    required this.id,
    required this.title,
    required this.body,
    required this.ctaLabel,
    required this.ctaUrl,
    this.imageUrl,
  });

  final String id;
  final String title;
  final String body;
  final String ctaLabel;
  final String ctaUrl;
  final String? imageUrl;
}

/// Remote promo carousel for the free-tier home dashboard.
@immutable
class HomeAdCarousel {
  const HomeAdCarousel({
    required this.enabled,
    required this.revision,
    required this.items,
  });

  final bool enabled;
  final String revision;
  final List<HomeAdItem> items;

  List<ResolvedHomeAd> resolvedFor(String lang) => [
        for (final i in items)
          if (i.isActionableFor(lang)) i.resolve(lang),
      ];

  bool isActionableFor(String lang) =>
      enabled && resolvedFor(lang).isNotEmpty;

  factory HomeAdCarousel.fromFirestore(Map<String, dynamic> data) {
    final rev = data['revision']?.toString().trim();
    final updated = data['updatedAt']?.toString().trim();
    final revision = (rev != null && rev.isNotEmpty)
        ? rev
        : (updated != null && updated.isNotEmpty ? updated : '1');

    final rawItems = data['items'];
    final items = <HomeAdItem>[];
    if (rawItems is List) {
      for (var i = 0; i < rawItems.length; i++) {
        final row = rawItems[i];
        if (row is! Map) continue;
        items.add(
          HomeAdItem.fromMap(
            Map<String, dynamic>.from(row),
            fallbackId: 'ad_$i',
          ),
        );
      }
    }

    if (items.isEmpty) {
      final legacy = HomeAdItem.fromMap(data, fallbackId: 'legacy');
      if (legacy.isActionableFor('es')) items.add(legacy);
    }

    return HomeAdCarousel(
      enabled: data['enabled'] == true,
      revision: revision,
      items: items,
    );
  }
}

/// Carousel already resolved for the user's app language.
@immutable
class VisibleHomeAds {
  const VisibleHomeAds({
    required this.revision,
    required this.items,
  });

  final String revision;
  final List<ResolvedHomeAd> items;
}

final homeAdProvider = StreamProvider<HomeAdCarousel?>((ref) {
  if (!AppInfo.firebaseConfigured) {
    return Stream.value(null);
  }
  return FirebaseFirestore.instance.doc(_kHomeAdPath).snapshots().map((snap) {
    if (!snap.exists || snap.data() == null) return null;
    try {
      return HomeAdCarousel.fromFirestore(snap.data()!);
    } catch (e, st) {
      debugPrint('home_ad parse: $e\n$st');
      return null;
    }
  });
});

final homeAdDismissedRevisionProvider = StateProvider<String?>((ref) {
  return ref.watch(sharedPreferencesProvider).getString(_kDismissedKey);
});

/// Active carousel for the current user (null if Pro / off / dismissed).
final visibleHomeAdProvider = Provider<VisibleHomeAds?>((ref) {
  if (ref.watch(proControllerProvider).isPro) return null;
  final ad = ref.watch(homeAdProvider).valueOrNull;
  if (ad == null || !ad.enabled) return null;
  final dismissed = ref.watch(homeAdDismissedRevisionProvider);
  if (dismissed != null && dismissed == ad.revision) return null;
  final lang = ref.watch(settingsControllerProvider.select((s) => s.locale));
  final items = ad.resolvedFor(lang);
  if (items.isEmpty) return null;
  return VisibleHomeAds(revision: ad.revision, items: items);
});

Future<void> dismissHomeAd(WidgetRef ref, String revision) async {
  final prefs = ref.read(sharedPreferencesProvider);
  await prefs.setString(_kDismissedKey, revision);
  ref.read(homeAdDismissedRevisionProvider.notifier).state = revision;
}
