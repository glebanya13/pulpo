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
import '../../core/ai/ai_record_hint.dart';
import '../../core/ai/assistant_energy.dart';
import '../../core/ai/pulpo_ai_service.dart';
import '../../core/l10n/tr.dart';
import '../../core/pro/pro_controller.dart';
import '../../core/pro/pro_guard.dart';
import '../../core/pro/pro_limits.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/lucide_icon_map.dart';
import '../../core/utils/money_format.dart';
import '../../core/utils/speech_locale.dart';
import '../../data/db/app_database.dart' as db;
import '../../data/repositories/assistant_chat_repository.dart';
import '../../data/repositories/error_log_repository.dart';
import '../../data/repositories/providers.dart';
import '../../data/repositories/settings_service.dart';
import '../../widgets/assistant_energy_chip.dart';
import '../../widgets/pressable.dart';
import '../../widgets/ai_assistant_mark.dart';
import 'app_chat_context.dart';
import 'assistant_transactions.dart';

part 'assistant_bubble.dart';

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
  db.Account? _account;
  bool _busy = false;
  String _busyLabel = '';
  bool _gateChecked = false;
  bool _listening = false;
  bool _resumingListen = false;
  bool _needsRestart = false;
  bool _stopAndSendPending = false;
  String _listenBase = '';
  int _listenSeconds = 0;
  int _speechRestartCount = 0;
  Timer? _listenTimer;
  Timer? _burnTimer;
  DateTime? _burnAnchor;

  /// Cap STT auto-restarts so a flaky mic can't drain battery / free energy.
  static const _maxSpeechRestarts = 40;

  AssistantChatRepository get _chat =>
      ref.read(assistantChatRepositoryProvider);

  Future<void> _append({
    required bool isFromUser,
    required String body,
    String? imagePath,
  }) {
    return _chat.add(
      isFromUser: isFromUser,
      body: body,
      imagePath: imagePath,
    );
  }

  Future<void> _logError(Object error, [StackTrace? st]) {
    return ref.read(errorLogRepositoryProvider).record(
          source: 'assistant_chat',
          error: error,
          stackTrace: st,
        );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(assistantChatSyncProvider.future);
      if (!mounted) return;
      unawaited(ref.read(pulpoAiServiceProvider).prefetch());
      await _ensureAccess();
    });
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
      const Duration(milliseconds: 1000),
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
    await _chat.ensureWelcome(Tr.of(context).aiChatWelcome);
    _scrollToEnd();
    if (!mounted) return;
    final scanReceipt =
        GoRouterState.of(context).uri.queryParameters['scanReceipt'] == '1';
    if (scanReceipt) {
      await _showPhotoOptions();
    }
  }

  Future<void> _toggleListening() async {
    if (_busy) return;
    if (_listening) {
      await _stopListening();
      return;
    }

    final ok = await requireAi(context, ref, allowFreeEnergy: true);
    if (!mounted || !ok) return;

    final tr = Tr.of(context);
    final available = await _speech.initialize(
      onError: (error) {
        if (isSoftSpeechError(error)) {
          if (mounted && _listening && !_stopAndSendPending) {
            unawaited(_continueListening());
          }
          return;
        }
        if (mounted) unawaited(_stopListening());
      },
      onStatus: (status) {
        // Platform STT ends on pause/timeout — keep the mic open until the
        // user taps stop. Auto-sending here was cutting long dictation short.
        if (status == 'done' || status == 'notListening') {
          if (mounted && _listening && !_stopAndSendPending) {
            unawaited(_continueListening());
          }
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

    setState(() {
      _listening = true;
      _listenBase = _input.text.trim();
      _listenSeconds = 0;
      _speechRestartCount = 0;
    });
    _syncEnergyBurn();
    _listenTimer?.cancel();
    _listenTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _listenSeconds++);
    });

    await _startSpeechEngine();
  }

  Future<void> _continueListening() async {
    if (!_listening || !mounted) return;
    if (_speechRestartCount >= _maxSpeechRestarts) {
      await _stopListening();
      return;
    }
    if (_resumingListen) {
      _needsRestart = true;
      return;
    }
    _resumingListen = true;
    _needsRestart = false;
    _speechRestartCount++;
    _listenBase = _input.text.trim();
    try {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (!_listening || !mounted) return;
      await _startSpeechEngine();
    } finally {
      _resumingListen = false;
      if (_needsRestart && _listening && mounted && !_stopAndSendPending) {
        _needsRestart = false;
        unawaited(_continueListening());
      }
    }
  }

  Future<void> _startSpeechEngine() async {
    if (!_listening || !mounted) return;
    final preferred = speechLocaleId(ref.read(settingsControllerProvider).locale);
    final locales = await _speech.locales();
    final matched = locales
        .where((l) =>
            l.localeId == preferred ||
            l.localeId.startsWith(preferred.split('_').first))
        .map((l) => l.localeId)
        .firstOrNull;

    await _speech.listen(
      onResult: (result) {
        if (!mounted || !_listening) return;
        final chunk = result.recognizedWords.trim();
        final combined = _listenBase.isEmpty
            ? chunk
            : (chunk.isEmpty ? _listenBase : '$_listenBase $chunk');
        setState(() => _input.text = combined);
        // Lock committed words so the next listen segment appends cleanly.
        if (result.finalResult && combined.isNotEmpty) {
          _listenBase = combined;
        }
      },
      listenOptions: stt.SpeechListenOptions(
        localeId: matched ?? preferred,
        listenFor: const Duration(minutes: 10),
        pauseFor: const Duration(seconds: 20),
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
        cancelOnError: false,
      ),
    );
  }

  Future<void> _stopListening() async {
    _listenTimer?.cancel();
    _listenTimer = null;
    _resumingListen = false;
    if (mounted) {
      setState(() {
        _listening = false;
        _listenBase = '';
        _listenSeconds = 0;
        _speechRestartCount = 0;
      });
      _syncEnergyBurn();
    } else {
      _listening = false;
      _listenBase = '';
      _speechRestartCount = 0;
    }
    await _speech.stop();
  }

  Future<void> _stopListeningAndSend() async {
    if (_busy || _stopAndSendPending) return;
    if (!_listening) {
      final text = _input.text.trim();
      if (text.isNotEmpty) await _send(text);
      return;
    }
    _stopAndSendPending = true;
    try {
      final text = _input.text.trim();
      await _stopListening();
      if (!mounted || text.isEmpty) return;
      await _send(text);
    } finally {
      _stopAndSendPending = false;
    }
  }

  Future<db.Account?> _resolveAccount() async {
    final accounts = ref.read(accountsProvider).valueOrNull ?? [];
    final open = accounts.where((a) => !a.isArchived);
    if (open.isEmpty) return null;
    if (_account != null && open.any((a) => a.id == _account!.id)) {
      return _account;
    }
    return open.first;
  }

  Future<void> _send([String? overrideText]) async {
    final text = (overrideText ?? _input.text).trim();
    if (text.isEmpty || _busy) return;

    final ok = await requireAi(context, ref, allowFreeEnergy: true);
    if (!mounted || !ok) return;

    await _stopListening();

    setState(() {
      _input.clear();
      _busy = true;
      _busyLabel = Tr.of(context).aiBusy;
    });
    await _append(isFromUser: true, body: text);
    _syncEnergyBurn();
    _scrollToEnd();

    try {
      final charge = await _handleUserText(text);
      if (charge) await _chargeTextTurn();
    } catch (e, st) {
      await _logError(e, st);
      if (!mounted) return;
      await _append(
        isFromUser: false,
        body: describeAiError(Tr.of(context), e),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _busyLabel = '';
        });
        _syncEnergyBurn();
      }
      _scrollToEnd();
    }
  }

  /// Returns true when the turn should consume free-energy quota.
  Future<bool> _handleUserText(String text) async {
    final tr = Tr.of(context);
    final locale = ref.read(settingsControllerProvider).locale;
    final welcome = tr.aiChatWelcome;
    final cats = ref.read(categoriesProvider).valueOrNull ?? [];
    final names = cats.map((c) => tr.categoryName(c.name)).toList();
    final allAccounts = ref.read(accountsProvider).valueOrNull ?? [];
    final accountNames = allAccounts
        .where((a) => !a.isArchived)
        .map((a) => a.name)
        .toList();
    final account = await _resolveAccount();
    final currencyHint = account?.currency ??
        ref.read(settingsControllerProvider).baseCurrency;

    late AssistantTurnResult turn;
    var alreadyParsedBatch = false;

    // Record-looking messages: local/AI batch only — no full app snapshot.
    if (looksLikeTransactionRecord(text)) {
      if (mounted) {
        setState(() => _busyLabel = tr.aiParsing);
      }
      try {
        final drafts =
            await ref.read(pulpoAiServiceProvider).parseNaturalLanguageBatch(
                  text,
                  locale: locale,
                  categoryNames: names,
                  accountNames: accountNames,
                  currencyHint: currencyHint,
                );
        alreadyParsedBatch = true;
        if (drafts.isNotEmpty) {
          turn = AssistantTurnResult(
            intent: 'record',
            reply: '',
            transactions: drafts,
          );
        } else {
          turn = await _fullAssistantTurn(
            text: text,
            locale: locale,
            welcome: welcome,
            names: names,
            accountNames: accountNames,
            currencyHint: currencyHint,
          );
        }
      } catch (e, st) {
        await _logError(e, st);
        if (mounted) {
          setState(() => _busyLabel = tr.aiBusy);
        }
        turn = await _fullAssistantTurn(
          text: text,
          locale: locale,
          welcome: welcome,
          names: names,
          accountNames: accountNames,
          currencyHint: currencyHint,
        );
      }
    } else {
      turn = await _fullAssistantTurn(
        text: text,
        locale: locale,
        welcome: welcome,
        names: names,
        accountNames: accountNames,
        currencyHint: currencyHint,
      );
    }

    // Retry batch only for bare "record" with no txs — not for clarify.
    if (!alreadyParsedBatch &&
        turn.intent == 'record' &&
        turn.transactions.isEmpty &&
        !turn.isClarify) {
      if (mounted) {
        setState(() => _busyLabel = tr.aiParsing);
      }
      try {
        final drafts =
            await ref.read(pulpoAiServiceProvider).parseNaturalLanguageBatch(
                  text,
                  locale: locale,
                  categoryNames: names,
                  accountNames: accountNames,
                  currencyHint: currencyHint,
                );
        turn = AssistantTurnResult(
          intent: 'record',
          reply: turn.reply.isNotEmpty ? turn.reply : tr.aiBusy,
          transactions: drafts,
        );
      } catch (e, st) {
        await _logError(e, st);
      }
    }

    if (turn.isRecord) {
      if (account == null) {
        await _append(isFromUser: false, body: tr.addAccountFirst);
        return true;
      }

      if (!mounted) return false;
      final confirmed = await confirmAssistantDrafts(
        context: context,
        drafts: turn.transactions,
        account: account,
        allAccounts: allAccounts,
        categories: cats,
        tr: tr,
      );
      if (!mounted || confirmed == null) {
        await _append(isFromUser: false, body: tr.cancel);
        return false;
      }

      await saveAssistantDrafts(
        ref: ref,
        drafts: confirmed.drafts,
        accounts: confirmed.accounts,
        toAccounts: confirmed.toAccounts,
        tr: tr,
      );
      if (!mounted) return false;

      final total = confirmed.drafts.fold<double>(
        0,
        (sum, d) => sum + (d.amount ?? 0),
      );
      final reply = turn.reply.trim().isNotEmpty
          ? turn.reply.trim()
          : tr.aiAssistantRecorded(
              confirmed.drafts.length,
              formatMoney(total, currencyHint),
            );

      await _append(isFromUser: false, body: reply);
      return true;
    }

    final reply = turn.reply.trim();
    if (reply.isEmpty) {
      throw const PulpoAiException(AiErrorCode.emptyResponse);
    }

    if (!mounted) return false;
    await _append(isFromUser: false, body: reply);
    return true;
  }

  Future<AssistantTurnResult> _fullAssistantTurn({
    required String text,
    required String locale,
    required String welcome,
    required List<String> names,
    List<String> accountNames = const [],
    required String currencyHint,
  }) async {
    final stored = await _chat.all();
    final prior = _chatHistory(stored, welcome);
    final scope = looksLikeBalanceQuestion(text)
        ? AppContextScope.balances
        : AppContextScope.full;
    return ref.read(pulpoAiServiceProvider).assistantTurn(
          userMessage: text,
          appContext: buildAppChatContext(ref, scope: scope),
          locale: locale,
          categoryNames: names,
          accountNames: accountNames,
          currencyHint: currencyHint,
          history: prior,
        );
  }

  List<({String role, String text})> _chatHistory(
    List<db.AssistantMessage> messages,
    String welcome,
  ) {
    final prior = <({String role, String text})>[];
    for (var i = 0; i < messages.length - 1; i++) {
      final m = messages[i];
      if (!m.isFromUser && m.body == welcome) continue;
      prior.add((role: m.isFromUser ? 'user' : 'model', text: m.body));
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
      _busy = true;
      _busyLabel = tr.aiBusy;
    });
    await _append(
      isFromUser: true,
      body: tr.aiChatReceiptSent,
      imagePath: dest,
    );
    _syncEnergyBurn();
    _scrollToEnd();

    try {
      final locale = ref.read(settingsControllerProvider).locale;
      final cats = ref.read(categoriesProvider).valueOrNull ?? [];
      final names = cats.map((c) => tr.categoryName(c.name)).toList();
      final account = await _resolveAccount();
      if (account == null) {
        await _append(isFromUser: false, body: tr.addAccountFirst);
        return;
      }

      final receipt = await ref.read(pulpoAiServiceProvider).analyzeReceipt(
            File(dest),
            locale: locale,
            categoryNames: names,
            currencyHint: account.currency,
          );

      if (receipt.amount == null || receipt.amount! <= 0) {
        await _append(isFromUser: false, body: tr.aiReceiptUnreadable);
        return;
      }

      final draft = receiptToDraft(receipt);
      if (!mounted) return;
      final confirmed = await confirmAssistantDrafts(
        context: context,
        drafts: [draft],
        account: account,
        allAccounts: ref.read(accountsProvider).valueOrNull ?? [],
        categories: cats,
        tr: tr,
      );
      if (!mounted || confirmed == null) {
        await _append(isFromUser: false, body: tr.cancel);
        return;
      }

      await saveAssistantDrafts(
        ref: ref,
        drafts: confirmed.drafts,
        accounts: confirmed.accounts,
        toAccounts: confirmed.toAccounts,
        tr: tr,
        receiptPath: dest,
      );
      if (!mounted) return;

      await _append(
        isFromUser: false,
        body: tr.aiAssistantReceiptSaved(
          formatMoney(receipt.amount!, receipt.currency ?? account.currency),
        ),
      );
      await _chargeTextTurn();
    } catch (e, st) {
      await _logError(e, st);
      if (!mounted) return;
      await _append(isFromUser: false, body: describeAiError(tr, e));
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _busyLabel = '';
        });
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

  String _formatListenTime() => formatListenMmSs(_listenSeconds);

  void _closeChat() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  Future<void> _confirmClearChat() async {
    if (_busy) return;
    final tr = Tr.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr.aiClearChatTitle),
        content: Text(tr.aiClearChatBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFE53E3E),
            ),
            child: Text(tr.aiClearChat),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _chat.clear();
    if (!mounted) return;
    await _chat.ensureWelcome(tr.aiChatWelcome);
  }

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    final messages =
        ref.watch(assistantMessagesProvider).valueOrNull ?? const [];
    final accounts = ref.watch(accountsProvider).valueOrNull ?? [];
    final openAccounts =
        accounts.where((a) => !a.isArchived).toList(growable: false);
    final account = _account ?? openAccounts.firstOrNull;
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
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: context.surface,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              tr.aiChatTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                                height: 1.15,
                                color: context.primaryText,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (!isPro) ...[
                        const SizedBox(width: 6),
                        const AssistantEnergyChip(),
                      ],
                      const SizedBox(width: 6),
                      Pressable(
                        onTap: messages.isEmpty || _busy
                            ? null
                            : _confirmClearChat,
                        child: Opacity(
                          opacity: messages.isEmpty || _busy ? 0.35 : 1,
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: context.surface,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              LucideIcons.trash2,
                              size: 18,
                              color: context.primaryText,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
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
                  if (openAccounts.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 34,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: openAccounts.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final a = openAccounts[i];
                          final selected = account?.id == a.id;
                          final fg = selected
                              ? (context.isDark
                                  ? AppColors.ink
                                  : Colors.white)
                              : context.primaryText;
                          final bg = selected
                              ? (context.isDark
                                  ? AppColors.lime
                                  : AppColors.ink)
                              : context.surface;
                          return Pressable(
                            onTap: () => setState(() => _account = a),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: bg,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    lucideByKey(a.icon),
                                    size: 14,
                                    color: selected
                                        ? fg
                                        : Color(a.color),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    a.name,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: fg,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
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
                itemCount: messages.length + (_busy ? 1 : 0),
                itemBuilder: (context, i) {
                  if (_busy && i == messages.length) {
                    return _AssistantBubble(
                      child: Text(
                        _busyLabel.isNotEmpty ? _busyLabel : tr.aiBusy,
                        style: TextStyle(
                          fontSize: 14,
                          color: context.mutedText,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    );
                  }
                  final m = messages[i];
                  return _AssistantBubble(
                    fromUser: m.isFromUser,
                    time: TimeOfDay.fromDateTime(m.createdAt),
                    imagePath: m.imagePath,
                    child: SelectableText(
                      m.body,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.38,
                        color: m.isFromUser
                            ? AppColors.ink
                            : context.primaryText,
                        fontWeight: FontWeight.w400,
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
                    child: DefaultSelectionStyle(
                      selectionColor: AppColors.lime.withValues(alpha: 0.45),
                      cursorColor: AppColors.lime,
                      child: TextField(
                        controller: _input,
                        minLines: 1,
                        maxLines: 4,
                        enableInteractiveSelection: true,
                        cursorColor: AppColors.lime,
                        style: TextStyle(
                          color: context.primaryText,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
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
                  ),
                  const SizedBox(width: 8),
                  ListenableBuilder(
                    listenable: _input,
                    builder: (context, _) {
                      final hasText = _input.text.trim().isNotEmpty;
                      return Pressable(
                        onTap: _busy
                            ? null
                            : () {
                                if (_listening) {
                                  unawaited(_stopListeningAndSend());
                                } else if (hasText) {
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
                                : (hasText
                                    ? AppColors.lime
                                    : context.surface),
                            shape: BoxShape.circle,
                            boxShadow: hasText && !_listening
                                ? [
                                    BoxShadow(
                                      color: AppColors.lime
                                          .withValues(alpha: 0.35),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Icon(
                            _listening
                                ? LucideIcons.square
                                : (hasText
                                    ? LucideIcons.send
                                    : LucideIcons.mic),
                            size: 18,
                            color: hasText || _listening
                                ? AppColors.ink
                                : context.primaryText,
                          ),
                        ),
                      );
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
