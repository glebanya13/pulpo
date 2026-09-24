import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../core/open_link.dart';
import '../core/promo/home_ad.dart';
import '../core/promo/promo_image_cache.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import 'pressable.dart';

/// Slim auto-advancing promo carousel (between balance and calendar).
class HomeAdCard extends ConsumerStatefulWidget {
  const HomeAdCard({super.key, required this.ad});

  final VisibleHomeAds ad;

  @override
  ConsumerState<HomeAdCard> createState() => _HomeAdCardState();
}

class _HomeAdCardState extends ConsumerState<HomeAdCard> {
  late final PageController _page;
  Timer? _timer;
  var _index = 0;

  List<ResolvedHomeAd> get _items => widget.ad.items;

  @override
  void initState() {
    super.initState();
    _page = PageController();
    _restartTimer();
    _warmImages();
  }

  @override
  void didUpdateWidget(covariant HomeAdCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ad.revision != widget.ad.revision ||
        oldWidget.ad.items.length != widget.ad.items.length) {
      _index = 0;
      if (_page.hasClients) {
        _page.jumpToPage(0);
      }
      _restartTimer();
      _warmImages();
    }
  }

  void _warmImages() {
    unawaited(
      PromoImageCache.warmAll(_items.map((e) => e.imageUrl)),
    );
  }

  void _restartTimer() {
    _timer?.cancel();
    if (_items.length < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_page.hasClients || _items.length < 2) return;
      final next = (_index + 1) % _items.length;
      _page.animateToPage(
        next,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.lime.withValues(alpha: 0.35),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          PageView.builder(
            controller: _page,
            itemCount: items.length,
            onPageChanged: (i) {
              setState(() => _index = i);
              _restartTimer();
            },
            itemBuilder: (context, i) => _Slide(
              item: items[i],
              onDismiss: () => dismissHomeAd(ref, widget.ad.revision),
            ),
          ),
          if (items.length > 1)
            Positioned(
              left: 0,
              right: 40,
              bottom: 4,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < items.length; i++)
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == _index
                            ? (context.isDark
                                ? AppColors.lime
                                : AppColors.ink)
                            : context.faintText.withValues(alpha: 0.45),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({required this.item, required this.onDismiss});

  final ResolvedHomeAd item;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(item.ctaUrl);

    return Pressable(
      onTap: uri == null ? null : () => openAppLink(context, uri),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 10),
        child: Row(
          children: [
            _Thumb(url: item.imageUrl),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: context.primaryText,
                      height: 1.15,
                    ),
                  ),
                  if (item.body.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: context.isDark ? AppColors.lime : AppColors.ink,
                        height: 1.2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (item.ctaLabel.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Text(
                  item.ctaLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: context.isDark ? AppColors.lime : AppColors.ink,
                  ),
                ),
              ),
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              onPressed: onDismiss,
              icon: Icon(LucideIcons.x, size: 16, color: context.faintText),
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumb extends StatefulWidget {
  const _Thumb({required this.url});

  final String? url;

  @override
  State<_Thumb> createState() => _ThumbState();
}

class _ThumbState extends State<_Thumb> {
  File? _file;
  var _loading = false;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant _Thumb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _file = null;
      _resolve();
    }
  }

  Future<void> _resolve() async {
    final url = widget.url;
    if (url == null || url.isEmpty) return;
    setState(() => _loading = true);
    final cached = await PromoImageCache.peek(url);
    if (!mounted) return;
    if (cached != null) {
      setState(() {
        _file = cached;
        _loading = false;
      });
      return;
    }
    final warmed = await PromoImageCache.warm(url);
    if (!mounted) return;
    setState(() {
      _file = warmed;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final file = _file;
    if (file != null) {
      final dpr = MediaQuery.devicePixelRatioOf(context);
      final px = (40 * dpr).round();
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          file,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          cacheWidth: px,
          cacheHeight: px,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, _, _) => const _AccentMark(),
        ),
      );
    }
    if (_loading || (widget.url != null && widget.url!.isNotEmpty)) {
      return const _AccentMark();
    }
    return const _AccentMark();
  }
}

class _AccentMark extends StatelessWidget {
  const _AccentMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.lime,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        LucideIcons.megaphone,
        size: 18,
        color: AppColors.ink,
      ),
    );
  }
}
