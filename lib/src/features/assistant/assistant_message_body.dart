part of 'assistant_chat_screen.dart';

/// User messages stay plain; assistant messages may include markdown tables.
class _AssistantMessageBody extends StatelessWidget {
  const _AssistantMessageBody({
    required this.text,
    required this.fromUser,
    required this.style,
    this.blocks = const [],
    this.categories = const [],
  });

  final String text;
  final bool fromUser;
  final TextStyle style;
  final List<ChatBodyBlock> blocks;
  final List<db.Category> categories;

  @override
  Widget build(BuildContext context) {
    if (fromUser) {
      return Text(text, style: style);
    }

    final resolved =
        blocks.isNotEmpty ? blocks : parseChatBody(text);
    if (resolved.isEmpty) {
      return Text(text, style: style);
    }
    if (resolved.length == 1 && resolved.first is ChatProseBlock) {
      return Text((resolved.first as ChatProseBlock).text, style: style);
    }

    final catByName = <String, db.Category>{
      for (final c in categories) c.name.toLowerCase().trim(): c,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < resolved.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          switch (resolved[i]) {
            ChatProseBlock(:final text) => Text(text, style: style),
            ChatTableBlock(:final table) => _ChatDataTable(
                table: table,
                categoriesByName: catByName,
              ),
          },
        ],
      ],
    );
  }
}

/// Kebo-style spend table: tinted header, category icons, TOTAL pill.
class _ChatDataTable extends StatelessWidget {
  const _ChatDataTable({
    required this.table,
    required this.categoriesByName,
  });

  final ChatMarkdownTable table;
  final Map<String, db.Category> categoriesByName;

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);
    final headers = table.headers;
    final dataRows = <List<String>>[];
    List<String>? totalRow;

    for (final row in table.rows) {
      if (row.isNotEmpty && isChatTableTotalLabel(row.first)) {
        totalRow = row;
      } else {
        dataRows.add(row);
      }
    }

    final headerBg = context.isDark
        ? AppColors.lime.withValues(alpha: 0.16)
        : AppColors.lime.withValues(alpha: 0.28);
    final rowDivider = context.divider;
    final cellStyle = TextStyle(
      fontSize: 12,
      height: 1.25,
      fontWeight: FontWeight.w500,
      color: context.primaryText,
    );
    final headerStyle = TextStyle(
      fontSize: 11,
      height: 1.2,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.2,
      color: context.isDark ? AppColors.lime : AppColors.ink,
    );

    final colCount = headers.length;
    final tableMinWidth = (colCount * 108.0).clamp(240.0, 520.0);

    Widget tableColumn({required double width}) {
      return SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: headerBg,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  for (var c = 0; c < colCount; c++)
                    Expanded(
                      flex: c == colCount - 1 ? 3 : 4,
                      child: Text(
                        headers[c],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: c == colCount - 1
                            ? TextAlign.right
                            : TextAlign.left,
                        style: headerStyle,
                      ),
                    ),
                ],
              ),
            ),
            for (var r = 0; r < dataRows.length; r++) ...[
              if (r > 0)
                Divider(height: 1, thickness: 1, color: rowDivider),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    for (var c = 0; c < colCount; c++)
                      Expanded(
                        flex: c == colCount - 1 ? 3 : 4,
                        child: c == 0
                            ? _CategoryCell(
                                label: dataRows[r][c],
                                category: categoriesByName[
                                    dataRows[r][c].toLowerCase().trim()],
                                style: cellStyle,
                              )
                            : Text(
                                c < dataRows[r].length ? dataRows[r][c] : '',
                                style: cellStyle.copyWith(
                                  fontWeight: c == colCount - 1
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                                textAlign: c == colCount - 1
                                    ? TextAlign.right
                                    : TextAlign.left,
                              ),
                      ),
                  ],
                ),
              ),
            ],
            if (totalRow != null) ...[
              Divider(height: 1, thickness: 1, color: rowDivider),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        tr.totalWord.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: context.primaryText,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.lime,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        totalRow.length > 1 ? totalRow.last : totalRow.first,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: context.isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: context.primaryText.withValues(alpha: 0.06),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final needScroll = w < tableMinWidth - 0.5;
          final child = tableColumn(
            width: needScroll ? tableMinWidth : w,
          );
          if (!needScroll) return child;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: child,
          );
        },
      ),
    );
  }
}

class _CategoryCell extends StatelessWidget {
  const _CategoryCell({
    required this.label,
    required this.style,
    this.category,
  });

  final String label;
  final TextStyle style;
  final db.Category? category;

  @override
  Widget build(BuildContext context) {
    final cat = category;
    if (cat == null) {
      return Text(label, style: style, maxLines: 2, overflow: TextOverflow.ellipsis);
    }
    return Row(
      children: [
        Icon(
          lucideByKey(cat.icon),
          size: 14,
          color: Color(cat.color),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: style,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
