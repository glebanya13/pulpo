import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/app_info.dart';
import '../../core/l10n/tr.dart';
import '../../core/open_link.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/pressable.dart';

/// In-app Crisp chat. Opens the Crisp chatbox for [AppInfo.crispWebsiteId]
/// in a full-screen WebView so support stays inside the app.
class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key});

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  static const _timeout = Duration(seconds: 20);

  late final WebViewController _controller;
  bool _loading = true;
  bool _failed = false;
  Timer? _timeoutTimer;

  Uri get _chatUri => Uri.parse(
    'https://go.crisp.chat/chat/embed/?website_id=${AppInfo.crispWebsiteId}',
  );

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // The stock Android WebView UA carries the "; wv" marker — Cloudflare
      // (in front of Crisp) can loop its JS challenge on it and the chatbox
      // never finishes loading. Present a normal Chrome mobile UA.
      ..setUserAgent(
        'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) '
        'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 '
        'Mobile/15E148 Safari/604.1',
      )
      ..setBackgroundColor(const Color(0xFF1C1C1E))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => _settle(ok: true),
          onWebResourceError: (_) {
            // Sub-resource hiccups are non-fatal; only fail when the main
            // frame itself never finished.
            if (_loading && _failed) _settle(ok: false);
          },
          onHttpError: (_) {},
        ),
      )
      ..loadRequest(_chatUri);
    _timeoutTimer = Timer(_timeout, () {
      if (_loading && mounted) {
        setState(() => _failed = true);
        _settle(ok: false);
      }
    });
  }

  void _settle({required bool ok}) {
    _timeoutTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (!ok) _failed = true;
    });
  }

  Future<void> _retry() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    _timeoutTimer = Timer(_timeout, () {
      if (_loading && mounted) {
        setState(() => _failed = true);
        _settle(ok: false);
      }
    });
    await _controller.loadRequest(_chatUri);
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  RoundIconButton(
                    icon: LucideIcons.x,
                    onTap: () => context.pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: context.surface,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Soporte',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: context.primaryText,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const SizedBox(width: 44),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  WebViewWidget(controller: _controller),
                  if (_loading && !_failed)
                    const Center(child: CircularProgressIndicator()),
                  if (_failed)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.wifiOff,
                              size: 36,
                              color: context.mutedText,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              tr.supportChatError,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: context.mutedText,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ScaledElevatedButton(
                              expand: true,
                              onPressed: _retry,
                              child: Text(tr.retry),
                            ),
                            const SizedBox(height: 8),
                            ScaledTextButton(
                              onPressed: () => openAppLink(context, _chatUri),
                              child: Text(tr.supportChatOpenBrowser),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
