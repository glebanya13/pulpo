import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../core/ai/ai_errors.dart';
import '../../core/ai/ai_models.dart';
import '../../core/ai/pulpo_ai_service.dart';
import '../../core/l10n/tr.dart';
import '../../core/pro/pro_guard.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/color_well.dart';
import '../../core/utils/lucide_icon_map.dart';
import '../../core/utils/money_format.dart';
import '../../data/db/app_database.dart' as db;
import '../../data/db/enums.dart';
import '../../data/repositories/providers.dart';
import '../../data/repositories/settings_service.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../widgets/pressable.dart';

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
    final ok = await requireAi(context, ref);
    if (!mounted) return;
    if (!ok) {
      context.pop();
      return;
    }
    await _startListening();
  }

  String _localeId(String locale) => switch (locale) {
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

  db.Category? _matchCategory(
    String? hint,
    List<db.Category> cats,
    Tr tr,
    TxType type,
  ) {
    if (hint == null || hint.trim().isEmpty) return null;
    final h = hint.toLowerCase().trim();
    final filtered = cats.where((c) {
      final catType = CategoryType.values[c.type];
      if (type == TxType.expense) return catType != CategoryType.income;
      if (type == TxType.income) return catType != CategoryType.expense;
      return true;
    });
    for (final c in filtered) {
      if (c.name.toLowerCase() == h) return c;
      if (tr.categoryName(c.name).toLowerCase() == h) return c;
    }
    for (final c in filtered) {
      final n = tr.categoryName(c.name).toLowerCase();
      if (n.contains(h) || h.contains(n)) return c;
    }
    return null;
  }

  Future<void> _submit() async {
    final tr = Tr.of(context);
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    await _stopListening();
    if (!await requireAi(context, ref)) return;
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
      final approved = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Theme.of(context).cardColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (ctx) => _VoiceConfirmSheet(
          drafts: drafts,
          account: account,
          categories: cats,
          matchCategory: (hint, type) =>
              _matchCategory(hint, cats, tr, type),
        ),
      );
      if (approved != true || !mounted) return;

      final repo = ref.read(transactionRepositoryProvider);
      for (final draft in drafts) {
        final type =
            draft.type == 'income' ? TxType.income : TxType.expense;
        final cat = _matchCategory(draft.categoryHint, cats, tr, type);
        final note = draft.note?.trim().isNotEmpty == true
            ? draft.note!.trim()
            : draft.merchant?.trim();
        await repo.add(
          accountId: account.id,
          categoryId: cat?.id,
          amount: draft.amount!,
          currency: draft.currency ?? account.currency,
          type: type,
          date: draft.date ?? DateTime.now(),
          note: note,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr.aiVoiceSaved(drafts.length))),
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

class _VoiceConfirmSheet extends StatelessWidget {
  const _VoiceConfirmSheet({
    required this.drafts,
    required this.account,
    required this.categories,
    required this.matchCategory,
  });

  final List<TransactionDraftFromAi> drafts;
  final db.Account account;
  final List<db.Category> categories;
  final db.Category? Function(String? hint, TxType type) matchCategory;

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.lime.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.checkCheck,
                    size: 18, color: AppColors.ink),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr.aiVoiceConfirmTitle,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: context.primaryText,
                      ),
                    ),
                    Text(
                      tr.aiVoiceConfirmCount(drafts.length),
                      style: TextStyle(
                        fontSize: 13,
                        color: context.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              Pressable(
                onTap: () => Navigator.pop(context, false),
                child: Icon(LucideIcons.x, color: context.mutedText),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.45,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: drafts.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final d = drafts[i];
                final type =
                    d.type == 'income' ? TxType.income : TxType.expense;
                final cat = matchCategory(d.categoryHint, type);
                final note = d.note?.trim().isNotEmpty == true
                    ? d.note!
                    : (d.merchant ?? '');
                final amount = d.amount ?? 0;
                final sign = type == TxType.income ? '+' : '−';
                final color = type == TxType.income
                    ? AppColors.income
                    : AppColors.expense;
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.scaffoldBg,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      ColorWellIcon(
                        color: cat != null
                            ? Color(cat.color)
                            : AppColors.violet,
                        icon: cat != null
                            ? lucideByKey(cat.icon)
                            : LucideIcons.circle,
                        size: 40,
                        iconSize: 18,
                        radius: 12,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cat != null
                                  ? tr.categoryName(cat.name)
                                  : (d.categoryHint ?? tr.other),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: context.primaryText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                _Chip(text: account.name),
                                if (note.isNotEmpty) _Chip(text: note),
                                _Chip(
                                  text: DateFormat(
                                    'd MMM',
                                    Localizations.localeOf(context)
                                        .languageCode,
                                  ).format(d.date ?? DateTime.now()),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '$sign${formatMoney(amount, d.currency ?? account.currency)}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ScaledElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(tr.aiVoiceApprove),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: context.mutedText,
        ),
      ),
    );
  }
}
