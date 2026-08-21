import 'package:drift/drift.dart';

import '../accounts/accounts_table.dart';
import '../budgeting/budgeting_table.dart';

/// What sort of movement a transaction records (ISSUE-001 D1).
///
/// All seven values live in one ledger table, discriminated by this column.
/// Stored with `.textEnum<TransactionKind>()`, never by index — see
/// `docs/enums.md`.
enum TransactionKind {
  /// `fromAccountId` set, `toAccountId` null (FR-6, UC-04).
  expense,

  /// `fromAccountId` null, `toAccountId` set (FR-7, UC-05).
  income,

  /// Both sides set, wallet to wallet (FR-8, UC-06).
  transfer,

  /// Wallet to the person's `RECEIVABLE` account (FR-9, UC-07).
  lend,

  /// The `PAYABLE` account to the wallet (FR-9, UC-08).
  borrow,

  /// Either side to the other (FR-9, UC-07/UC-08).
  repayment,

  /// FR-18's correction path (UC-03).
  adjustment,
}

/// `Category` — a user-created top-level classification (FR-10).
class Categories extends Table {
  IntColumn get categoryId => integer().autoIncrement()();

  TextColumn get name => text()();
}

/// `Subcategory` — exactly one level under a `Category` (FR-10). No
/// self-referencing nesting.
class Subcategories extends Table {
  IntColumn get subcategoryId => integer().autoIncrement()();

  IntColumn get categoryId => integer().references(Categories, #categoryId)();

  TextColumn get name => text()();
}

/// `Transaction` — the single ledger table for all seven kinds (ISSUE-001 D1).
///
/// **"Is this spending?" is `toAccountId IS NULL`.** Never re-derive it from
/// `kind` — that is how FR-8's "a transfer is not an expense" and FR-9's
/// "lending is not spending" stop being guaranteed by the shape of the data.
class Transactions extends Table {
  IntColumn get transactionId => integer().autoIncrement()();

  TextColumn get kind => textEnum<TransactionKind>()();

  /// Minor units of `Settings.currency`. Never a `double` — NFR-2.
  IntColumn get amount => integer()();

  DateTimeColumn get occurredOn => dateTime()();

  // Both sides reference Accounts; @ReferenceName disambiguates drift's
  // generated reverse-relation name for each (drift_dev build warning
  // otherwise: "Duplicate orderings/filters ... transactionsRefs").
  @ReferenceName('outgoingTransactions')
  IntColumn get fromAccountId =>
      integer().nullable().references(Accounts, #accountId)();

  @ReferenceName('incomingTransactions')
  IntColumn get toAccountId =>
      integer().nullable().references(Accounts, #accountId)();

  IntColumn get categoryId =>
      integer().nullable().references(Categories, #categoryId)();

  IntColumn get subcategoryId =>
      integer().nullable().references(Subcategories, #subcategoryId)();

  IntColumn get budgetGroupId =>
      integer().nullable().references(BudgetGroups, #budgetGroupId)();

  /// Nullable free text. Optional; nothing in the app reads it to make a
  /// decision, and it is not searchable yet (decided 2026-08-21 — that is
  /// UC-09's surface).
  TextColumn get note => text().nullable()();
}
