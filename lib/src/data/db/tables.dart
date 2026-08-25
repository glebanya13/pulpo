import 'package:drift/drift.dart';

/// Кастомный CHECK для перечислений хранится как INTEGER.
class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 60)();
  IntColumn get type => integer()(); // AccountType.index
  TextColumn get currency => text().withLength(min: 3, max: 6)();
  RealColumn get initialBalance => real().withDefault(const Constant(0))();
  TextColumn get icon => text().withDefault(const Constant('wallet'))();
  IntColumn get color => integer().withDefault(const Constant(0xFF0F0F0F))();
  BoolColumn get includeInTotal => boolean().withDefault(const Constant(true))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  RealColumn get creditLimit => real().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get parentId => integer().nullable().references(Categories, #id)();
  TextColumn get name => text().withLength(min: 1, max: 60)();
  TextColumn get icon => text().withDefault(const Constant('circle'))();
  IntColumn get color => integer().withDefault(const Constant(0xFFF2F2F2))();
  IntColumn get type => integer()(); // CategoryType.index: expense=0, income=1, both=2
  BoolColumn get isHidden => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get accountId => integer().references(Accounts, #id)();
  IntColumn get categoryId => integer().nullable().references(Categories, #id)();
  RealColumn get amount => real()(); // всегда положительная
  TextColumn get currency => text().withLength(min: 3, max: 6)();
  IntColumn get type => integer()(); // TxType.index: expense=0, income=1, transfer=2
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().nullable()();
  TextColumn get counterparty => text().nullable()();
  IntColumn get transferGroupId => integer().nullable()(); // связка для transfer-пары
  IntColumn get status => integer().withDefault(const Constant(0))(); // 0=confirmed, 1=planned, 2=draft
  TextColumn get receiptPath => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
}

class TransactionTags extends Table {
  IntColumn get transactionId => integer().references(Transactions, #id, onDelete: KeyAction.cascade)();
  IntColumn get tagId => integer().references(Tags, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {transactionId, tagId};
}

class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get period => integer()(); // 0=week, 1=month, 2=quarter, 3=year, 4=custom
  RealColumn get amount => real()();
  TextColumn get currency => text().withLength(min: 3, max: 6)();
  TextColumn get categoryIdsJson => text().withDefault(const Constant('[]'))();
  BoolColumn get rollover => boolean().withDefault(const Constant(false))();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  IntColumn get color => integer().withDefault(const Constant(0xFFCDFF3A))();
}

class Goals extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  RealColumn get targetAmount => real()();
  RealColumn get currentAmount => real().withDefault(const Constant(0))();
  TextColumn get currency => text().withLength(min: 3, max: 6)();
  DateTimeColumn get targetDate => dateTime().nullable()();
  IntColumn get accountId => integer().nullable().references(Accounts, #id)();
  TextColumn get icon => text().withDefault(const Constant('target'))();
  IntColumn get color => integer().withDefault(const Constant(0xFFCDFF3A))();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Debts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get counterparty => text()();
  RealColumn get amount => real()();
  RealColumn get paidAmount => real().withDefault(const Constant(0))();
  TextColumn get currency => text().withLength(min: 3, max: 6)();
  IntColumn get direction => integer()(); // 0=iOwe, 1=owedToMe
  DateTimeColumn get dueDate => dateTime().nullable()();
  RealColumn get interestRate => real().nullable()();
  IntColumn get status => integer().withDefault(const Constant(0))(); // 0=active, 1=closed
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class RecurringRules extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get templateJson => text()(); // сериализованный шаблон транзакции
  TextColumn get frequency => text()(); // daily/weekly/monthly/yearly
  IntColumn get interval => integer().withDefault(const Constant(1))();
  DateTimeColumn get nextRunAt => dateTime()();
  DateTimeColumn get endAt => dateTime().nullable()();
  BoolColumn get isPaused => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class ExchangeRates extends Table {
  TextColumn get base => text().withLength(min: 3, max: 6)();
  TextColumn get quote => text().withLength(min: 3, max: 6)();
  DateTimeColumn get date => dateTime()();
  RealColumn get rate => real()();

  @override
  Set<Column> get primaryKey => {base, quote, date};
}

class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

class Subscriptions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get logoLetter => text().withDefault(const Constant(''))();
  IntColumn get logoColor => integer().withDefault(const Constant(0xFF0F0F0F))();
  RealColumn get amount => real()();
  TextColumn get currency => text().withLength(min: 3, max: 6)();
  TextColumn get cycle => text().withDefault(const Constant('monthly'))(); // monthly | yearly
  DateTimeColumn get nextPayment => dateTime()();
  IntColumn get accountId => integer().nullable().references(Accounts, #id)();
  IntColumn get categoryId => integer().nullable().references(Categories, #id)();
  BoolColumn get isPaused => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Persisted AI assistant chat (survives leaving the screen / relaunch).
class AssistantMessages extends Table {
  IntColumn get id => integer().autoIncrement()();
  BoolColumn get isFromUser => boolean()();
  TextColumn get body => text()();
  TextColumn get imagePath => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

/// Local + cloud error diagnostics (AI, auth, etc.). Synced to Firestore when signed in.
class ErrorLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get source => text().withLength(min: 1, max: 80)();
  TextColumn get message => text()();
  TextColumn get detail => text().nullable()();
}
