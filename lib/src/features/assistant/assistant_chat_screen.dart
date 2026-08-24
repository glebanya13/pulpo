import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../core/ai/ai_errors.dart';
import '../../core/ai/ai_models.dart';
import '../../core/ai/assistant_energy.dart';
import '../../core/ai/pulpo_ai_service.dart';
import '../../core/l10n/tr.dart';
import '../../core/pro/pro_controller.dart';
import '../../core/pro/pro_guard.dart';
import '../../core/pro/pro_limits.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/money_format.dart';
import '../../data/db/app_database.dart' as db;
import '../../data/repositories/providers.dart';
import '../../data/repositories/settings_service.dart';
import '../../widgets/assistant_energy_chip.dart';
import '../../widgets/pressable.dart';
import '../../widgets/ai_assistant_mark.dart';
import 'app_chat_context.dart';
import 'assistant_transactions.dart';

class _ChatMsg {
  const _ChatMsg({
    required this.fromUser,
    required this.text,
    this.imagePath,
    this.time = const TimeOfDay(hour: 0, minute: 0),
  });

  final bool fromUser;
  final String text;
  final String? imagePath;
  final TimeOfDay time;
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
  final _speech = stt.SpeechToText();
  final _messages = <_ChatMsg>[];
  db.Account? _account;
  bool _busy = false;
  bool _gateChecked = false;
  bool _listening = false;
  int _listenSeconds = 0;
  Timer? _listenTimer;
  Timer? _burnTimer;
  DateTime? _burnAnchor;

  @override
  void initState() {
    super.initState();
    _input.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureAccess());
  }

  @override
  void dispose() {
    unawaited(_speech.cancel());
    _listenTimer?.cancel();
    _burnTimer?.cancel();
    _input.dispose();
    _listCtrl.dispose();
    super.dispose();
  }

  bool get _shouldBurnEnergy {
    if (ref.read(proControllerProvider).isPro) return false;
    // Only burn while the mic is live — not while waiting on the network.
    return _listening;
  }

  /// Flat cost per successful assistant reply (~8s of the free quota).
  static const _textTurnCostMs = 8000;

  Future<void> _chargeTextTurn() async {
    if (ref.read(proControllerProvider).isPro) return;
    final left = await ref
        .read(assistantEnergyProvider.notifier)
        .consumeMs(_textTurnCostMs);
    if (!mounted || left > 0) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(Tr.of(context).aiEnergyEmpty)),
    );
    await openPaywall(context, ProGate.ai);
  }

  void _syncEnergyBurn() {
    if (!_shouldBurnEnergy) {
      _flushEnergyBurn();
      _burnTimer?.cancel();
      _burnTimer = null;
      _burnAnchor = null;
      return;
    }
    _burnAnchor ??= DateTime.now();
    _burnTimer ??= Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => unawaited(_tickEnergyBurn()),
    );
  }

  Future<void> _flushEnergyBurn() async {
    final anchor = _burnAnchor;
    if (anchor == null) return;
    final elapsed = DateTime.now().difference(anchor).inMilliseconds;
    _burnAnchor = DateTime.now();
    if (elapsed > 0) {
      await ref.read(assistantEnergyProvider.notifier).consumeMs(elapsed);
    }
  }

  Future<void> _tickEnergyBurn() async {
    if (!mounted || !_shouldBurnEnergy) {
      _syncEnergyBurn();
      return;
    }
    final anchor = _burnAnchor ?? DateTime.now();
    final now = DateTime.now();
    final elapsed = now.difference(anchor).inMilliseconds;
    _burnAnchor = now;
    if (elapsed <= 0) return;
    final left =
        await ref.read(assistantEnergyProvider.notifier).consumeMs(elapsed);
    if (!mounted) return;
    if (left > 0) return;
    if (_listening) await _stopListening();
    _syncEnergyBurn();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(Tr.of(context).aiEnergyEmpty)),
    );
    await openPaywall(context, ProGate.ai);
  }

  Future<void> _ensureAccess() async {
    if (_gateChecked) return;
    _gateChecked = true;
    final ok = await requireAi(context, ref, allowFreeEnergy: true);
    if (!mounted) return;
    if (!ok) {
      if (context.canPop()) context.pop();
      return;
    }
    if (_messages.isEmpty) {
      setState(() {
        _messages.add(_ChatMsg(
          fromUser: false,
          text: Tr.of(context).aiChatWelcome,
          time: TimeOfDay.now(),
        ));
      });
    }
  }

  String _localeId(String locale) => switch (locale) {
        'uk' => 'uk_UA',
        'ru' => 'ru_RU',
        'en' => 'en_US',
        _ => 'es_ES',
      };

  Future<void> _toggleListening() async {
    if (_busy) return;
    if (_listening) {
      await _stopListening();
      final text = _input.text.trim();
      if (text.isNotEmpty) await _send(text);
      return;
    }

    final ok = await requireAi(context, ref, allowFreeEnergy: true);
    if (!mounted || !ok) return;

    final tr = Tr.of(context);
    final available = await _speech.initialize(
      onError: (_) {
        if (mounted) _stopListening();
      },
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted && _listening) _stopListening();
        }
      },
    );
    if (!available) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr.aiSpeechUnavailable)),
      );
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

    setState(() {
      _listening = true;
      _listenSeconds = 0;
    });
    _syncEnergyBurn();
    _listenTimer?.cancel();
    _listenTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _listenSeconds++);
    });

    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        setState(() => _input.text = result.recognizedWords);
      },
      listenOptions: stt.SpeechListenOptions(
        localeId: matched ?? preferred,
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 4),
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
        cancelOnError: true,
      ),
    );
  }

  Future<void> _stopListening() async {
    _listenTimer?.cancel();
    _listenTimer = null;
    await _speech.stop();
    if (mounted) {
      setState(() {
        _listening = false;
        _listenSeconds = 0;
      });
      _syncEnergyBurn();
    }
  }

  Future<db.Account?> _resolveAccount() async {
    final accounts = ref.read(accountsProvider).valueOrNull ?? [];
    if (accounts.isEmpty) return null;
    return _account ?? accounts.first;
  }

  Future<void> _send([String? overrideText]) async {
    final text = (overrideText ?? _input.text).trim();
    if (text.isEmpty || _busy) return;

    final ok = await requireAi(context, ref, allowFreeEnergy: true);
    if (!mounted || !ok) return;

    await _stopListening();

    setState(() {
      _messages.add(_ChatMsg(fromUser: true, text: text, time: TimeOfDay.now()));
      _input.clear();
      _busy = true;
    });
    _syncEnergyBurn();
    _scrollToEnd();

    try {
      await _handleUserText(text);
      await _chargeTextTurn();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMsg(
          fromUser: false,
          text: describeAiError(Tr.of(context), e),
          time: TimeOfDay.now(),
        ));
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        _syncEnergyBurn();
      }
      _scrollToEnd();
    }
  }

  Future<void> _handleUserText(String text) async {
    final tr = Tr.of(context);
    final locale = ref.read(settingsControllerProvider).locale;
    final welcome = tr.aiChatWelcome;
    final prior = _chatHistory(welcome);
    final cats = ref.read(categoriesProvider).valueOrNull ?? [];
    final names = cats.map((c) => tr.categoryName(c.name)).toList();
    final account = await _resolveAccount();
    final currencyHint = account?.currency ??
        ref.read(settingsControllerProvider).baseCurrency;

    var turn = await ref.read(pulpoAiServiceProvider).assistantTurn(
          userMessage: text,
          appContext: buildAppChatContext(ref),
          locale: locale,
          categoryNames: names,
          currencyHint: currencyHint,
          history: prior,
        );

    if (turn.intent == 'record' && turn.transactions.isEmpty) {
      try {
        final drafts =
            await ref.read(pulpoAiServiceProvider).parseNaturalLanguageBatch(
                  text,
                  locale: locale,
                  categoryNames: names,
                  currencyHint: currencyHint,
                );
        turn = AssistantTurnResult(
          intent: 'record',
          reply: turn.reply.isNotEmpty ? turn.reply : tr.aiBusy,
          transactions: drafts,
        );
      } catch (_) {
        // keep question-style reply
      }
    }

    if (turn.isRecord) {
      if (account == null) {
        setState(() {
          _messages.add(_ChatMsg(
            fromUser: false,
            text: tr.addAccountFirst,
            time: TimeOfDay.now(),
          ));
        });
        return;
      }

      if (!mounted) return;
      final approved = await confirmAssistantDrafts(
        context: context,
        drafts: turn.transactions,
        account: account,
        categories: cats,
        tr: tr,
      );
      if (!mounted || !approved) {
        setState(() {
          _messages.add(_ChatMsg(
            fromUser: false,
            text: tr.cancel,
            time: TimeOfDay.now(),
          ));
        });
        return;
      }

      await saveAssistantDrafts(
        ref: ref,
        drafts: turn.transactions,
        account: account,
        tr: tr,
      );
      if (!mounted) return;

      final total = turn.transactions.fold<double>(
        0,
        (sum, d) => sum + (d.amount ?? 0),
      );
      final reply = turn.reply.trim().isNotEmpty
          ? turn.reply.trim()
          : tr.aiAssistantRecorded(
              turn.transactions.length,
              formatMoney(total, currencyHint),
            );

      setState(() {
        _messages.add(_ChatMsg(
          fromUser: false,
          text: reply,
          time: TimeOfDay.now(),
        ));
      });
      return;
    }

    // assistantTurn already falls back to chatAboutApp when JSON fails;
    // avoid a third network hop if the model returned an empty reply.
    final reply = turn.reply.trim();
    if (reply.isEmpty) {
      throw const PulpoAiException(AiErrorCode.emptyResponse);
    }

    if (!mounted) return;
    setState(() {
      _messages.add(_ChatMsg(
        fromUser: false,
        text: reply,
        time: TimeOfDay.now(),
      ));
    });
  }

  List<({String role, String text})> _chatHistory(String welcome) {
    final prior = <({String role, String text})>[];
    for (var i = 0; i < _messages.length - 1; i++) {
      final m = _messages[i];
      if (!m.fromUser && m.text == welcome) continue;
      prior.add((role: m.fromUser ? 'user' : 'model', text: m.text));
    }
    return prior;
  }

  Future<void> _pickReceipt(ImageSource source) async {
    if (_busy) return;
    final ok = await requireAi(context, ref, allowFreeEnergy: true);
    if (!mounted || !ok) return;

    final tr = Tr.of(context);
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1200,
      imageQuality: 80,
    );
    if (picked == null || !mounted) return;

    final dir = await getApplicationDocumentsDirectory();
    final receiptsDir = Directory(p.join(dir.path, 'receipts'));
    if (!receiptsDir.existsSync()) receiptsDir.createSync(recursive: true);
    final name = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final dest = p.join(receiptsDir.path, name);
    await File(picked.path).copy(dest);

    setState(() {
      _messages.add(_ChatMsg(
        fromUser: true,
        text: tr.aiChatReceiptSent,
        imagePath: dest,
        time: TimeOfDay.now(),
      ));
      _busy = true;
    });
    _syncEnergyBurn();
    _scrollToEnd();

    try {
      final locale = ref.read(settingsControllerProvider).locale;
      final cats = ref.read(categoriesProvider).valueOrNull ?? [];
      final names = cats.map((c) => tr.categoryName(c.name)).toList();
      final account = await _resolveAccount();
      if (account == null) {
        setState(() {
          _messages.add(_ChatMsg(
            fromUser: false,
            text: tr.addAccountFirst,
            time: TimeOfDay.now(),
          ));
        });
        return;
      }

      final receipt = await ref.read(pulpoAiServiceProvider).analyzeReceipt(
            File(dest),
            locale: locale,
            categoryNames: names,
            currencyHint: account.currency,
          );

      if (receipt.amount == null || receipt.amount! <= 0) {
        setState(() {
          _messages.add(_ChatMsg(
            fromUser: false,
            text: tr.aiReceiptUnreadable,
            time: TimeOfDay.now(),
          ));
        });
        return;
      }

      final draft = receiptToDraft(receipt);
      if (!mounted) return;
      final approved = await confirmAssistantDrafts(
        context: context,
        drafts: [draft],
        account: account,
        categories: cats,
        tr: tr,
      );
      if (!mounted || !approved) return;

      await saveAssistantDrafts(
        ref: ref,
        drafts: [draft],
        account: account,
        tr: tr,
        receiptPath: dest,
      );
      if (!mounted) return;

      setState(() {
        _messages.add(_ChatMsg(
          fromUser: false,
          text: tr.aiAssistantReceiptSaved(
            formatMoney(receipt.amount!, receipt.currency ?? account.currency),
          ),
          time: TimeOfDay.now(),
        ));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMsg(
          fromUser: false,
          text: describeAiError(tr, e),
          time: TimeOfDay.now(),
        ));
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        _syncEnergyBurn();
      }
      _scrollToEnd();
    }
  }

  Future<void> _showPhotoOptions() async {
    final tr = Tr.of(context);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.camera),
              title: Text(tr.receiptCamera),
              onTap: () {
                Navigator.pop(ctx);
                unawaited(_pickReceipt(ImageSource.camera));
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.image),
              title: Text(tr.receiptGallery),
              onTap: () {
                Navigator.pop(ctx);
                unawaited(_pickReceipt(ImageSource.gallery));
              },
            ),
          ],
        ),
      ),
    );
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

  String _formatListenTime() {
    final m = _listenSeconds ~/ 60;
    final s = _listenSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  void _closeChat() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    final hasText = _input.text.trim().isNotEmpty;
    final accounts = ref.watch(accountsProvider).valueOrNull ?? [];
    final account = _account ?? accounts.firstOrNull;
    final isPro = ref.watch(proControllerProvider).isPro;

    return Scaffold(
      resizeToAvoidBottomInset: true,
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
                  Row(
                    children: [
                      if (context.canPop())
                        Pressable(
                          onTap: () => context.pop(),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: context.surface,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(LucideIcons.arrowLeft,
                                size: 18, color: context.primaryText),
                          ),
                        )
                      else
                        const SizedBox(width: 42),
                      Expanded(
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: context.surface,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  tr.aiAssistantEyebrow,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                    color: context.mutedText,
                                  ),
                                ),
                                Text(
                                  tr.aiChatTitle,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                    height: 1.15,
                                    color: context.primaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (!isPro) ...[
                        const AssistantEnergyChip(),
                        const SizedBox(width: 8),
                      ],
                      Pressable(
                        onTap: _closeChat,
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: context.surface,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            LucideIcons.x,
                            size: 18,
                            color: context.primaryText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (account != null) ...[
                    const SizedBox(height: 8),
                    Pressable(
                      onTap: () async {
                        final picked =
                            await pickAssistantAccount(context, ref);
                        if (picked != null) {
                          setState(() => _account = picked);
                        }
                      },
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: context.surface,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.wallet,
                                  size: 14, color: context.mutedText),
                              const SizedBox(width: 6),
                              Text(
                                account.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: context.primaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
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
                    return _AssistantBubble(
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
                  return _AssistantBubble(
                    fromUser: m.fromUser,
                    time: m.time,
                    imagePath: m.imagePath,
                    child: Text(
                      m.text,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color:
                            m.fromUser ? AppColors.ink : context.primaryText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_listening)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: AppColors.danger.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatListenTime(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: context.primaryText,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        tr.aiRecording,
                        style: TextStyle(
                          fontSize: 13,
                          color: context.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Scaffold already shrinks for the keyboard — do not add
            // viewInsets again or the composer floats with a huge gap.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                8,
                AppSpacing.lg,
                12,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Pressable(
                    onTap: _busy ? null : _showPhotoOptions,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: context.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(LucideIcons.camera,
                          size: 18, color: context.primaryText),
                    ),
                  ),
                  const SizedBox(width: 8),
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
                    onTap: _busy
                        ? null
                        : () {
                            if (hasText) {
                              unawaited(_send());
                            } else {
                              unawaited(_toggleListening());
                            }
                          },
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: _listening
                            ? AppColors.danger.withValues(alpha: 0.85)
                            : (hasText ? AppColors.lime : context.surface),
                        shape: BoxShape.circle,
                        boxShadow: hasText && !_listening
                            ? [
                                BoxShadow(
                                  color: AppColors.lime.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        hasText
                            ? LucideIcons.send
                            : (_listening
                                ? LucideIcons.square
                                : LucideIcons.mic),
                        size: 18,
                        color: hasText || _listening
                            ? AppColors.ink
                            : context.primaryText,
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

class _AssistantBubble extends StatelessWidget {
  const _AssistantBubble({
    this.fromUser = false,
    required this.child,
    this.time,
    this.imagePath,
  });

  final bool fromUser;
  final Widget child;
  final TimeOfDay? time;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final timeLabel = time == null
        ? null
        : '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            fromUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!fromUser) ...[
            const AiAssistantMark(size: 28, iconSize: 13),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.72,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: fromUser ? AppColors.lime : context.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(fromUser ? 16 : 4),
                  bottomRight: Radius.circular(fromUser ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (imagePath != null &&
                      File(imagePath!).existsSync()) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(imagePath!),
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  child,
                  if (timeLabel != null) ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        timeLabel,
                        style: TextStyle(
                          fontSize: 10,
                          color: fromUser
                              ? AppColors.ink.withValues(alpha: 0.55)
                              : context.faintText,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
