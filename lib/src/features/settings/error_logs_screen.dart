import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/l10n/tr.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/error_log_repository.dart';
import '../../widgets/common.dart';
import '../../widgets/pressable.dart';

class ErrorLogsScreen extends ConsumerWidget {
  const ErrorLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = Tr.of(context);
    final logs = ref.watch(errorLogsProvider);

    return Scaffold(
      body: StickyScrollPage(
        header: PageHeader(
          first: tr.errorLogsTitle,
          onBack: () => context.pop(),
        ),
        headerGap: 16,
        children: [
          Text(
            tr.errorLogsSubtitle,
            style: TextStyle(fontSize: 13, color: context.mutedText),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Pressable(
                  onTap: () async {
                    final text =
                        await ref.read(errorLogRepositoryProvider).dumpText();
                    await Clipboard.setData(ClipboardData(text: text));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(tr.errorLogsCopied)),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: context.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      tr.errorLogsCopy,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: context.primaryText,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Pressable(
                  onTap: () async {
                    final text =
                        await ref.read(errorLogRepositoryProvider).dumpText();
                    await Share.share(text, subject: tr.errorLogsTitle);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: context.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      tr.errorLogsShare,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: context.primaryText,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Pressable(
                onTap: () async {
                  await ref.read(errorLogRepositoryProvider).clear();
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(LucideIcons.trash2,
                      size: 18, color: context.mutedText),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          logs.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('$e'),
            data: (rows) {
              if (rows.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Text(
                    tr.errorLogsEmpty,
                    style: TextStyle(color: context.mutedText),
                  ),
                );
              }
              return Column(
                children: [
                  for (final r in rows)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: context.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${r.createdAt.toIso8601String()} · ${r.source}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: context.mutedText,
                            ),
                          ),
                          const SizedBox(height: 6),
                          SelectableText(
                            r.message,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: context.primaryText,
                            ),
                          ),
                          if (r.detail != null &&
                              r.detail!.trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            SelectableText(
                              r.detail!,
                              style: TextStyle(
                                fontSize: 11,
                                height: 1.35,
                                color: context.mutedText,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
