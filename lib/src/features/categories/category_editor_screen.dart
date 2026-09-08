import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/tr.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/color_well.dart';
import '../../core/utils/lucide_icon_map.dart';
import '../../data/db/enums.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/providers.dart';
import '../../widgets/common.dart';
import '../../widgets/pressable.dart';

const _palette = categoryPalette;

const _iconKeys = [
  'utensils', 'car', 'home', 'heart-pulse', 'clapperboard', 'shirt',
  'wifi', 'graduation-cap', 'gift', 'sparkles', 'briefcase', 'laptop',
  'trending-up', 'wallet', 'credit-card', 'coins', 'piggy-bank',
  'target', 'plane', 'shopping-bag', 'circle',
];

class CategoryEditorScreen extends ConsumerStatefulWidget {
  const CategoryEditorScreen({
    super.key,
    this.existingId,
    this.defaultType = CategoryType.expense,
    this.parentId,
  });

  final int? existingId;
  final CategoryType defaultType;
  final int? parentId;

  bool get isEdit => existingId != null;

  @override
  ConsumerState<CategoryEditorScreen> createState() =>
      _CategoryEditorScreenState();
}

class _CategoryEditorScreenState extends ConsumerState<CategoryEditorScreen> {
  final _nameCtrl = TextEditingController();
  int _color = 0xFF8BD44A;
  String _icon = 'circle';
  bool _initialized = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized && widget.isEdit) {
      final cats = ref.read(categoriesProvider).valueOrNull ?? [];
      final existing = cats.where((c) => c.id == widget.existingId).firstOrNull;
      if (existing != null) {
        _nameCtrl.text = Tr.of(context).categoryName(existing.name);
        _color = existing.color;
        _icon = existing.icon;
        _initialized = true;
      }
    } else {
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(categoryRepositoryProvider);
      if (widget.isEdit) {
        await repo.update(
          id: widget.existingId!,
          name: _nameCtrl.text.trim(),
          icon: _icon,
          color: _color,
        );
      } else {
        await repo.add(
          name: _nameCtrl.text.trim(),
          type: widget.defaultType,
          icon: _icon,
          color: _color,
          parentId: widget.parentId,
        );
      }
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final tr = Tr.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: Text(tr.deleteCategoryTitle),
        content: Text(tr.deleteTxBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx, false),
            child: Text(tr.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dctx, true),
            style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFE53E3E)),
            child: Text(tr.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(categoryRepositoryProvider).delete(widget.existingId!);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final tr = Tr.of(context);

    return Scaffold(
      body: StickyScrollPage(
        header: PageHeader(
          first: widget.isEdit ? tr.editCategory : tr.newCategory,
          onBack: () => context.pop(),
        ),
        children: [
          // Live preview
          Center(
            child: ColorWellIcon(
              color: Color(_color),
              icon: lucideByKey(_icon),
              size: 72,
              iconSize: 32,
              radius: 22,
            ),
          ),
          const SizedBox(height: 24),

          // Name
          TextField(
            controller: _nameCtrl,
            autofocus: !widget.isEdit,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => FocusScope.of(context).unfocus(),
            decoration: InputDecoration(labelText: tr.titleLabel),
          ),
          const SizedBox(height: 28),

          // Color
          Text(
            tr.colorLabel,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.mutedText),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _palette
                .map((c) => Pressable(
                      onTap: () => setState(() => _color = c),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(c),
                          shape: BoxShape.circle,
                          border: _color == c
                              ? Border.all(
                                  color: context.isDark
                                      ? Colors.white
                                      : AppColors.ink,
                                  width: 2.5)
                              : null,
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 28),

          // Icon
          Text(
            tr.iconLabel,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.mutedText),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 6,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (final key in _iconKeys)
                Pressable(
                  onTap: () => setState(() => _icon = key),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _icon == key
                          ? AppColors.lime.withValues(alpha: 0.3)
                          : context.scaffoldBg,
                      borderRadius: BorderRadius.circular(14),
                      border: _icon == key
                          ? Border.all(color: AppColors.lime, width: 2)
                          : null,
                    ),
                    child: Icon(lucideByKey(key), color: context.primaryText),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 32),

          ScaledElevatedButton(
            expand: true,
            onPressed: _saving ? null : _save,
            child: Text(_saving ? '...' : tr.save),
          ),

          if (widget.isEdit) ...[
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: _delete,
                style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFE53E3E)),
                child: Text(tr.delete),
              ),
            ),
          ],

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
