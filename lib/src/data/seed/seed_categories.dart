import 'package:drift/drift.dart';

import '../db/app_database.dart';
import '../db/enums.dart';

/// Системные категории — храним name как slug ('food', 'transport'),
/// UI переводит через Tr.categoryByKey. Кастомные категории хранят
/// произвольное имя.
const expenseSeed = <_Cat>[
  _Cat('food', 'utensils', 0xFF8BD44A),
  _Cat('transport', 'car', 0xFFFF7A45),
  _Cat('housing', 'home', 0xFF7C6CFF),
  _Cat('health', 'heart-pulse', 0xFFFF5CA8),
  _Cat('entertainment', 'clapperboard', 0xFF5B8CFF),
  _Cat('clothing', 'shirt', 0xFFFFB020),
  _Cat('communication', 'wifi', 0xFF2EB5FF),
  _Cat('education', 'graduation-cap', 0xFF3DDC84),
  _Cat('gifts', 'gift', 0xFFFF7A9C),
  _Cat('beauty', 'sparkles', 0xFFE85DFF),
  _Cat('other_expense', 'circle', 0xFF8A94A6),
];

const incomeSeed = <_Cat>[
  _Cat('salary', 'briefcase', 0xFFCDFF3A),
  _Cat('freelance', 'laptop', 0xFF2ECF9A),
  _Cat('gift_income', 'gift', 0xFFFFB020),
  _Cat('investments', 'trending-up', 0xFF3DDC84),
  _Cat('other_income', 'circle', 0xFF8A94A6),
];

/// Идемпотентно добавляет системные категории по slug.
///
/// Если пользователь установил старую версию, где в seed не было income-категорий,
/// или миграция v3 частично «съела» дубли — недостающие slug-и досеиваются.
/// Пользовательские (кастомные) категории не трогаются.
Future<void> seedCategoriesIfEmpty(AppDatabase db) async {
  await _fixLegacyOtherIncomeDupe(db);

  final existing = await db.select(db.categories).get();
  final existingSlugs = existing.map((c) => c.name).toSet();

  var order = existing
      .where((c) => c.type == CategoryType.expense.index)
      .length;
  for (final c in expenseSeed) {
    if (existingSlugs.contains(c.name)) continue;
    await db.into(db.categories).insert(
          CategoriesCompanion.insert(
            name: c.name,
            type: CategoryType.expense.index,
            icon: Value(c.icon),
            color: Value(c.color),
            sortOrder: Value(order++),
          ),
        );
  }

  order = existing
      .where((c) => c.type == CategoryType.income.index)
      .length;
  for (final c in incomeSeed) {
    if (existingSlugs.contains(c.name)) continue;
    await db.into(db.categories).insert(
          CategoriesCompanion.insert(
            name: c.name,
            type: CategoryType.income.index,
            icon: Value(c.icon),
            color: Value(c.color),
            sortOrder: Value(order++),
          ),
        );
  }
}

/// Чинит артефакт миграции v3: она мапила ЛЮБУЮ категорию с именем «Другое»
/// в slug `other_expense`, включая income-строку. В результате у части
/// пользователей появлялась income-категория со slug `other_expense`
/// (дубль к правильной `other_income`, которую досеивает seed).
///
/// Стратегия:
/// - если есть income-`other_income` — переносим все транзакции с income-`other_expense`
///   на неё и удаляем дубль;
/// - если её нет — просто переименовываем income-`other_expense` в `other_income`.
Future<void> _fixLegacyOtherIncomeDupe(AppDatabase db) async {
  final incomeType = CategoryType.income.index;
  final cats = await db.select(db.categories).get();
  Category? dupe;
  Category? canonical;
  for (final c in cats) {
    if (c.type != incomeType) continue;
    if (c.name == 'other_expense') dupe = c;
    if (c.name == 'other_income') canonical = c;
  }
  if (dupe == null) return;
  final dupeId = dupe.id;

  if (canonical != null) {
    final canonicalId = canonical.id;
    await (db.update(db.transactions)
          ..where((t) => t.categoryId.equals(dupeId)))
        .write(TransactionsCompanion(categoryId: Value(canonicalId)));
    await (db.delete(db.categories)..where((c) => c.id.equals(dupeId))).go();
  } else {
    await (db.update(db.categories)..where((c) => c.id.equals(dupeId)))
        .write(const CategoriesCompanion(name: Value('other_income')));
  }
}

/// Соответствие «старое RU-имя → slug». Используется миграцией v3 для
/// переноса уже сохранённых у пользователей категорий на slug-формат.
const legacyRuNameToSlug = <String, String>{
  // expense
  'Еда': 'food',
  'Транспорт': 'transport',
  'Жильё': 'housing',
  'Здоровье': 'health',
  'Развлечения': 'entertainment',
  'Одежда': 'clothing',
  'Связь': 'communication',
  'Образование': 'education',
  'Подарки': 'gifts',
  'Красота': 'beauty',
  'Другое': 'other_expense',
  // income
  'Зарплата': 'salary',
  'Фриланс': 'freelance',
  'Подарок': 'gift_income',
  'Инвестиции': 'investments',
};

class _Cat {
  final String name;
  final String icon;
  final int color;
  const _Cat(this.name, this.icon, this.color);
}
