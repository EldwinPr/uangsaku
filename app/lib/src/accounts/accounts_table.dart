import 'package:drift/drift.dart';

/// Which of FR-1's three kinds of money an account holds.
///
/// Stored with `.textEnum<AccountGroup>()`, never by index — see `docs/enums.md`.
enum AccountGroup {
  /// Money the owner holds and can actually spend (FR-2, FR-3).
  HOLDING,

  /// Money owed to the owner (FR-5).
  RECEIVABLE,

  /// Money the owner owes (FR-4).
  PAYABLE,
}

/// `Account` — one row per wallet, debt or receivable (FR-1).
///
/// No stored balance (NFR-2): every balance is derived from `Transactions`.
class Accounts extends Table {
  IntColumn get accountId => integer().autoIncrement()();

  TextColumn get name => text()();

  /// FR-1's three-way split — never a debit/credit column (NFR-1).
  TextColumn get group => textEnum<AccountGroup>()();

  /// Minor units of `Settings.currency`. Never a `double` — NFR-2.
  IntColumn get openingAmount => integer()();

  /// FR-11's "just tick" — a flag, not an enum (`docs/enums.md`).
  BoolColumn get settled => boolean().withDefault(const Constant(false))();

  DateTimeColumn get settledAt => dateTime().nullable()();
}
