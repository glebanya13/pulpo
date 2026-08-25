import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../core/ai/ai_errors.dart';
import '../../core/ai/pulpo_ai_service.dart';
import '../../core/l10n/tr.dart';
import '../../core/pro/pro_guard.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/db/app_database.dart' as db;
import '../../data/repositories/providers.dart';
import '../../data/repositories/settings_service.dart';
import '../../widgets/pressable.dart';
import '../assistant/assistant_transactions.dart';

class VoiceAiScreen extends ConsumerStatefulWidget {
  const VoiceAiScreen({super.key});

  @override
  ConsumerState<VoiceAiScreen> createState() => _VoiceAiScreenState();
}

class _VoiceAiScreenState extends ConsumerState<VoiceAiScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final _textCtrl = TextEditingController();
  db.Account? _account;
  bool _listening = false;
  bool _busy = false;
  bool _gateChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureAccess());
  }

  @override
  void dispose() {
    unawaited(_speech.cancel());
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _ensureAccess() async {
    if (_gateChecked) return;
    _gateChecked = true;
    final ok = await requireAi(context, ref, allowFreeEnergy: true);
    if (!mounted) return;
    if (!ok) {
      context.pop();
      return;
    }
    await _startListening();
  }

  String _localeId(String locale) => switch (locale) {
        'uk' => 'uk_UA',
        'ru' => 'ru_RU',
        'en' => 'en_US',
        _ => 'es_ES',
      };

  Future<void> _startListening() async {
    if (_busy) return;
    final tr = Tr.of(context);
    final available = await _speech.initialize(
      onError: (e) {
        debugPrint('speech error: $e');
        if (mounted) setState(() => _listening = false);
      },
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() => _listening = false);
        }
      },
    );
    if (!available) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(tr.aiSpeechUnavailable)));
      return;
    }

    final preferred = _localeId(ref.read(settingsControllerProvider).locale);
    final locales = await _speech.locales();
    final matched = locales
        .where((l) =>
            l.localeId == preferred ||
            l.localeId.startsWith(preferred.split('_').first))
        .map((l) => l.localeId)
        .firstOrNull;

    setState(() => _listening = true);
    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        setState(() => _textCtrl.text = result.recognizedWords);
      },
      listenOptions: stt.SpeechListenOptions(
        localeId: matched ?? preferred,
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 5),
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
        cancelOnError: true,
      ),
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    if (mounted) setState(() => _listening = false);
  }

  Future<void> _clear() async {
    await _stopListening();
    setState(() => _textCtrl.clear());
  }

  Future<void> _submit() async {
    final tr = Tr.of(context);
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    await _stopListening();
    if (!await requireAi(context, ref, allowFreeEnergy: true)) return;
    if (!mounted) return;

    final accounts = ref.read(accountsProvider).valueOrNull ?? [];
    final account = _account ?? (accounts.isNotEmpty ? accounts.first : null);
    if (account == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(tr.addAccountFirst)));
      return;
    }

    setState(() => _busy = true);
    try {
      final cats = ref.read(categoriesProvider).valueOrNull ?? [];
      final locale = ref.read(settingsControllerProvider).locale;
      final names = cats.map((c) => tr.categoryName(c.name)).toList();
      final drafts =
          await ref.read(pulpoAiServiceProvider).parseNaturalLanguageBatch(
                text,
                locale: locale,
                categoryNames: names,
                currencyHint: account.currency,
              );
      if (!mounted) return;
      final confirmed = await confirmAssistantDrafts(
        context: context,
        drafts: drafts,
        account: account,
        categories: cats,
        tr: tr,
      );
      if (confirmed == null || !mounted) return;

      await saveAssistantDrafts(
        ref: ref,
        drafts: confirmed.drafts,
        accounts: confirmed.accounts,
        tr: tr,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr.aiVoiceSaved(confirmed.drafts.length))),
      );
      context.go('/');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(describeAiError(tr, e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickAccount() async {
    final accounts = ref.read(accountsProvider).valueOrNull ?? [];
    if (accounts.isEmpty) return;
    final picked = await showModalBottomSheet<db.Account>(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final a in accounts)
                ListTile(
                  title: Text(a.name),
                  subtitle: Text(a.currency),
                  onTap: () => Navigator.pop(ctx, a),
                ),
            ],
          ),
        );
      },
    );
    if (picked != null) setState(() => _account = picked);
  }

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    final accounts = ref.watch(accountsProvider).valueOrNull ?? [];
    final account = _account ?? (accounts.isNotEmpty ? accounts.first : null);
    final hasText = _textCtrl.text.trim().isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  Pressable(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: context.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(LucideIcons.x,
                          size: 18, color: context.primaryText),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    tr.aiVoiceEntry,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: context.primaryText,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 42),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: context.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.sparkles,
                        size: 28,
                        color: context.mutedText,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      tr.aiVoiceEmptyTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: context.primaryText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tr.aiVoiceEmptyHint,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        color: context.mutedText,
                      ),
                    ),
                    const Spacer(),
                    if (account != null)
                      Pressable(
                        onTap: _pickAccount,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: context.surface,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                account.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: context.primaryText,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(LucideIcons.sparkles,
                                  size: 14, color: AppColors.limeAccent),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 120),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.surface,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: TextField(
                        controller: _textCtrl,
                        maxLines: 5,
                        minLines: 3,
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                          color: context.primaryText,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: _listening
                              ? tr.aiListening
                              : tr.aiVoiceHint,
                          hintStyle: TextStyle(color: context.faintText),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                8,
                24,
                16 + MediaQuery.paddingOf(context).bottom,
              ),
              child: Row(
                children: [
                  _RoundAction(
                    icon: LucideIcons.x,
                    onTap: _busy ? null : _clear,
                  ),
                  const Spacer(),
                  Pressable(
                    onTap: _busy || !hasText ? null : _submit,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: hasText && !_busy
                            ? AppColors.lime
                            : context.surface,
                        shape: BoxShape.circle,
                        boxShadow: hasText && !_busy
                            ? [
                                BoxShadow(
                                  color: AppColors.lime
                                      .withValues(alpha: 0.35),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ]
                            : null,
                      ),
                      child: _busy
                          ? const Padding(
                              padding: EdgeInsets.all(22),
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.ink,
                              ),
                            )
                          : Icon(
                              LucideIcons.check,
                              size: 28,
                              color: hasText
                                  ? AppColors.ink
                                  : context.faintText,
                            ),
                    ),
                  ),
                  const Spacer(),
                  _RoundAction(
                    icon: _listening ? LucideIcons.micOff : LucideIcons.mic,
                    onTap: _busy
                        ? null
                        : () {
                            if (_listening) {
                              unawaited(_stopListening());
                            } else {
                              unawaited(_startListening());
                            }
                          },
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

class _RoundAction extends StatelessWidget {
  const _RoundAction({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: context.surface,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: context.primaryText),
      ),
    );
  }
}
