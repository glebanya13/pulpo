import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../core/fx_rate_service.dart';
import '../../core/l10n/tr.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/color_well.dart';
import '../../widgets/pressable.dart';
import '../../core/utils/lucide_icon_map.dart';
import '../../core/utils/money_format.dart';
import '../../data/db/app_database.dart' as db;
import '../../data/repositories/providers.dart';
import '../../data/repositories/settings_service.dart';
import '../../data/repositories/transaction_repository.dart';

class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  db.Account? _from;
  db.Account? _to;
  double _amount = 0;
  double _rate = 1;
  double _fee = 0;
  final _amountCtrl = TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  String _fxKey(String from, String to) => 'fx_rate_${from}_$to';

  void _tryLoadFxRate() {
    final from = _from;
    final to = _to;
    if (from == null || to == null) return;

    final prefs = ref.read(sharedPreferencesProvider);
    final key = _fxKey(from.currency, to.currency);
    final last = prefs.getDouble(key);
    if (last != null && last > 0) _rate = last;
  }

  Future<void> _refreshFxRate() async {
    final from = _from;
    final to = _to;
    if (from == null || to == null) return;
    if (from.currency == to.currency) {
      setState(() => _rate = 1);
      return;
    }
    setState(_tryLoadFxRate);
    final live = await FxRateService().fetchRate(from.currency, to.currency);
    if (!mounted) return;
    if (live == null || live <= 0) return;
    setState(() => _rate = live);
    _trySaveFxRate();
  }

  void _trySaveFxRate() {
    final from = _from;
    final to = _to;
    if (from == null || to == null) return;

    final prefs = ref.read(sharedPreferencesProvider);
    final key = _fxKey(from.currency, to.currency);
    prefs.setDouble(key, _rate);
  }

  double get _effectiveRate {
    if (_from != null && _to != null && _from!.currency == _to!.currency) {
      return 1;
    }
    return _rate;
  }

  double get _received =>
      ((_amount * _effectiveRate) - _fee).clamp(0, double.infinity);

  Future<void> _pickAccount({required bool from}) async {
    final tr = Tr.of(context);
    await ref.read(accountsProvider.future);
    if (!mounted) return;
    final accs = ref.read(accountsProvider).valueOrNull ?? const [];
    final picked = await showModalBottomSheet<db.Account>(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              from ? tr.transferFrom : tr.transferTo,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: context.primaryText,
              ),
            ),
            const SizedBox(height: 12),
            for (final a in accs)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: ColorWellIcon(
                  color: Color(a.color),
                  icon: lucideByKey(a.icon),
                  size: 42,
                  iconSize: 18,
                  radius: 14,
                ),
                title: Text(a.name,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: context.primaryText)),
                subtitle: Text(a.currency,
                    style: TextStyle(color: context.mutedText)),
                onTap: () => Navigator.pop(ctx, a),
              ),
          ],
        ),
      ),
    );
    if (picked != null) {
      setState(() {
        if (from) {
          _from = picked;
        } else {
          _to = picked;
        }
      });

      if (_from != null && _to != null) {
        await _refreshFxRate();
      }
    }
  }

  Future<void> _submit() async {
    if (_from == null || _to == null || _amount <= 0) return;
    if (_from!.id == _to!.id) return;

    await ref.read(transactionRepositoryProvider).addTransfer(
          fromAccountId: _from!.id,
          toAccountId: _to!.id,
          fromAmount: _amount,
          toAmount: _received,
          fromCurrency: _from!.currency,
          toCurrency: _to!.currency,
          date: DateTime.now(),
        );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    final sameCurrency =
        _from != null && _to != null && _from!.currency == _to!.currency;

    final form = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Label(tr.transferFrom),
        _AccountRow(account: _from, onTap: () => _pickAccount(from: true)),
        const SizedBox(height: 8),
        Center(
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: context.emphasized,
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.arrowDown,
                size: 16, color: AppColors.lime),
          ),
        ),
        const SizedBox(height: 8),
        _Label(tr.transferTo),
        _AccountRow(account: _to, onTap: () => _pickAccount(from: false)),
        const SizedBox(height: 20),
        Center(
          child: Text(tr.transferSending,
              style: TextStyle(fontSize: 13, color: context.faintText)),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _amountCtrl,
          textAlign: TextAlign.center,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.w800,
            letterSpacing: -2,
            color: context.primaryText,
          ),
          decoration: InputDecoration(
            hintText: '0.00',
            border: InputBorder.none,
            filled: false,
            contentPadding: EdgeInsets.zero,
            hintStyle: TextStyle(
              color: context.primaryText.withValues(alpha: 0.4),
            ),
          ),
          onChanged: (v) =>
              setState(() => _amount = double.tryParse(v) ?? 0),
        ),
        if (!sameCurrency && _from != null && _to != null) ...[
          const SizedBox(height: 12),
          _RateCard(
            from: _from!.currency,
            to: _to!.currency,
            rate: _effectiveRate,
            onEdit: () async {
              final ctrl =
                  TextEditingController(text: _rate.toStringAsFixed(4));
              final result = await showDialog<double>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(
                      '${tr.ratePrefix}${_from!.currency} = ? ${_to!.currency}'),
                  content: TextField(
                    controller: ctrl,
                    autofocus: true,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(tr.cancel)),
                    TextButton(
                      onPressed: () => Navigator.pop(
                          ctx, double.tryParse(ctrl.text) ?? 1),
                      child: Text(tr.ok),
                    ),
                  ],
                ),
              );
              if (result != null) {
                setState(() => _rate = result);
                _trySaveFxRate();
              }
            },
          ),
          const SizedBox(height: 8),
          Center(
            child: Column(
              children: [
                Text(tr.transferRecipientGets,
                    style: TextStyle(
                        fontSize: 12, color: context.faintText)),
                const SizedBox(height: 4),
                Text(
                  formatMoney(_received, _to!.currency),
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: context.accent,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: InkWell(
            onTap: () async {
              final ctrl =
                  TextEditingController(text: _fee.toStringAsFixed(2));
              final result = await showDialog<double>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(tr.fee),
                  content: TextField(
                    controller: ctrl,
                    autofocus: true,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(tr.cancel)),
                    TextButton(
                      onPressed: () => Navigator.pop(
                          ctx, double.tryParse(ctrl.text) ?? 0),
                      child: Text(tr.ok),
                    ),
                  ],
                ),
              );
              if (result != null) setState(() => _fee = result);
            },
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: context.scaffoldBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(LucideIcons.percent,
                        size: 14, color: context.primaryText),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(tr.fee,
                        style: TextStyle(
                            fontSize: 13, color: context.mutedText)),
                  ),
                  Text(
                    _to != null
                        ? formatMoney(_fee, _to!.currency)
                        : _fee.toStringAsFixed(2),
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: context.primaryText),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        ScaledElevatedButton(
          onPressed: _submit,
          child: Text(tr.confirm),
        ),
      ],
    );

    if (widget.embedded) {
      return SingleChildScrollView(
        padding: const EdgeInsets.only(top: 12, bottom: 12),
        child: form,
      );
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
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
                  Flexible(
                    child: Text(
                      tr.transferBetweenTitle,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: context.primaryText),
                    ),
                  ),
                  const SizedBox(width: 42),
                ],
              ),
              const SizedBox(height: 24),
              form,
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: context.faintText,
        ),
      ),
    );
  }
}

class _AccountRow extends ConsumerWidget {
  const _AccountRow({required this.account, required this.onTap});
  final db.Account? account;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balances = ref.watch(accountBalancesProvider);
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            ColorWellIcon(
              color: account != null
                  ? Color(account!.color)
                  : const Color(0xFF8A94A6),
              icon: account != null
                  ? lucideByKey(account!.icon)
                  : LucideIcons.wallet,
              size: 42,
              iconSize: 18,
              radius: 14,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account?.name ?? Tr.of(context).selectAccount,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: account == null
                          ? context.faintText
                          : context.primaryText,
                    ),
                  ),
                  if (account != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${Tr.of(context).balancePrefix}${formatMoney(balances[account!.id] ?? 0, account!.currency)}',
                      style: TextStyle(
                          fontSize: 11, color: context.faintText),
                    ),
                  ],
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight,
                size: 16, color: context.faintText),
          ],
        ),
      ),
    );
  }
}

class _RateCard extends StatelessWidget {
  const _RateCard({
    required this.from,
    required this.to,
    required this.rate,
    required this.onEdit,
  });
  final String from;
  final String to;
  final double rate;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.lime.withValues(alpha: 0.1),
          border:
              Border.all(color: AppColors.lime.withValues(alpha: 0.4), width: 1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.repeat, color: context.primaryText),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(Tr.of(context).exchangeRate,
                      style: TextStyle(
                          fontSize: 11, color: context.mutedText)),
                  Text(
                    '1 $from = ${rate.toStringAsFixed(4)} $to',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: context.primaryText),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.pencil,
                size: 14, color: context.faintText),
          ],
        ),
      ),
    );
  }
}
