import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../core/ai/ai_errors.dart';
import '../../core/ai/pulpo_ai_service.dart';
import '../../core/l10n/tr.dart';
import '../../core/pro/pro_guard.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/settings_service.dart';
import '../../widgets/common.dart';
import '../../widgets/pressable.dart';
import 'app_chat_context.dart';

class _ChatMsg {
  const _ChatMsg({required this.fromUser, required this.text});
  final bool fromUser;
  final String text;
}

class AssistantChatScreen extends ConsumerStatefulWidget {
  const AssistantChatScreen({super.key});

  @override
  ConsumerState<AssistantChatScreen> createState() =>
      _AssistantChatScreenState();
}

class _AssistantChatScreenState extends ConsumerState<AssistantChatScreen> {
  final _input = TextEditingController();
  final _listCtrl = ScrollController();
  final _messages = <_ChatMsg>[];
  bool _busy = false;
  bool _gateChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureAccess());
  }

  @override
  void dispose() {
    _input.dispose();
    _listCtrl.dispose();
    super.dispose();
  }

  Future<void> _ensureAccess() async {
    if (_gateChecked) return;
    _gateChecked = true;
    final ok = await requireAi(context, ref);
    if (!mounted) return;
    if (!ok) {
      if (context.canPop()) context.pop();
      return;
    }
    if (_messages.isEmpty) {
      setState(() {
        _messages.add(_ChatMsg(fromUser: false, text: Tr.of(context).aiChatWelcome));
      });
    }
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _busy) return;

    final ok = await requireAi(context, ref);
    if (!mounted || !ok) return;

    if (_messages.isEmpty) {
      _messages.add(_ChatMsg(fromUser: false, text: Tr.of(context).aiChatWelcome));
    }

    setState(() {
      _messages.add(_ChatMsg(fromUser: true, text: text));
      _input.clear();
      _busy = true;
    });
    _scrollToEnd();

    try {
      final locale = ref.read(settingsControllerProvider).locale;
      final welcome = Tr.of(context).aiChatWelcome;
      final prior = <({String role, String text})>[];
      for (var i = 0; i < _messages.length - 1; i++) {
        final m = _messages[i];
        if (!m.fromUser && m.text == welcome) continue;
        prior.add((role: m.fromUser ? 'user' : 'model', text: m.text));
      }

      final reply = await ref.read(pulpoAiServiceProvider).chatAboutApp(
            userMessage: text,
            appContext: buildAppChatContext(ref),
            locale: locale,
            history: prior,
          );
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMsg(fromUser: false, text: reply.trim()));
        _busy = false;
      });
      _scrollToEnd();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          _ChatMsg(fromUser: false, text: describeAiError(Tr.of(context), e)),
        );
        _busy = false;
      });
      _scrollToEnd();
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_listCtrl.hasClients) return;
      _listCtrl.animateTo(
        _listCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xs,
                AppSpacing.lg,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PageHeader(
                    first: tr.aiChatTitle,
                    onBack: () => context.pop(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr.aiChatHint,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: context.mutedText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                controller: _listCtrl,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: _messages.length + (_busy ? 1 : 0),
                itemBuilder: (context, i) {
                  if (_busy && i == _messages.length) {
                    return _Bubble(
                      fromUser: false,
                      child: Text(
                        tr.aiBusy,
                        style: TextStyle(
                          fontSize: 14,
                          color: context.mutedText,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    );
                  }
                  final m = _messages[i];
                  return _Bubble(
                    fromUser: m.fromUser,
                    child: Text(
                      m.text,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: m.fromUser ? AppColors.ink : context.primaryText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                8,
                AppSpacing.lg,
                12 + bottomInset + keyboard,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: tr.aiChatPlaceholder,
                        filled: true,
                        fillColor: context.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Pressable(
                    onTap: _busy ? null : _send,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.lime,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.lime.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        LucideIcons.send,
                        size: 18,
                        color: AppColors.ink,
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

class _Bubble extends StatelessWidget {
  const _Bubble({required this.fromUser, required this.child});

  final bool fromUser;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: fromUser
              ? AppColors.lime
              : context.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(fromUser ? 16 : 4),
            bottomRight: Radius.circular(fromUser ? 4 : 16),
          ),
        ),
        child: child,
      ),
    );
  }
}
