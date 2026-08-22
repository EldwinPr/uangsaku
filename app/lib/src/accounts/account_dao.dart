import 'package:drift/drift.dart';

import '../accounts/accounts_table.dart';
import '../budgeting/clock.dart';
import '../database/app_database.dart';
import '../transactions/transactions_table.dart';

/// `FinancialPosition` — UC-01's four figures, one query result
/// (`class-accounts.drawio`: *query result · UC-01's four figures*).
///
/// Field names are the four figures sequence-diagram message 7 names and
/// FR-1 lists: what I can spend now, what people owe me, what I owe, and the
/// net. Every field is an `int` counting minor units of `Settings.currency`
/// — never a double (NFR-2, `docs/enums.md`). Plain Dart, immutable, no
/// Flutter import.
class FinancialPosition {
  const FinancialPosition({
    required this.spendable,
    required this.owedToMe,
    required this.owedByMe,
    required this.net,
  });

  /// Σ balance(a) WHERE a.group = HOLDING (D4).
  final int spendable;

  /// Σ balance(a) WHERE a.group = RECEIVABLE (D4).
  final int owedToMe;

  /// Σ balance(a) WHERE a.group = PAYABLE (D4). Already negative — a
  /// payable account stores its amount signed (UC-02 D6, FR-4).
  final int owedByMe;

  /// spendable + owedToMe + owedByMe, summed in SQL over all groups (D4).
  final int net;
}

/// `AccountBalance` — one query result row: one account plus its derived
/// current amount (`class-accounts.drawio`: *query result · one account +
/// derived balance*).
///
/// The account is drift's generated `Account` row class (deliberately
/// omitted from the diagrams by decision — only hand-written classes get a
/// box); [balance] is D4's expression evaluated for it. Nothing here is ever
/// written back — NFR-2 forbids a stored balance.
class AccountBalance {
  const AccountBalance({required this.account, required this.balance});

  final Account account;

  /// Minor units of `Settings.currency`, derived at read time — never a
  /// double (NFR-2).
  final int balance;
}

/// `DebtProgress` — UC-10's two figures plus the settle flag, one query
/// result (`class-accounts.drawio`: *query result · UC-10 paid / remaining*).
///
/// Field names are what sequence-diagram messages 2 and 7 name: [paid] and
/// [remaining], plus [settled] — message 7's *"(settled)"*, which is how the
/// screen learns the tick landed, since the write returns nothing to it.
/// Every amount is an `int` counting minor units of `Settings.currency` —
/// never a double (NFR-2, `docs/enums.md`). Plain Dart, immutable, no
/// Flutter import. Both figures are derived at read time and never written
/// back (NFR-2) — `docs/enums.md`'s stated-non-members entry forbids storing
/// them alongside `opening_amount` and the ledger.
class DebtProgress {
  const DebtProgress({
    required this.paid,
    required this.remaining,
    required this.settled,
  });

  /// Σ t.amount WHERE t.kind = 'repayment' AND the row touches the account,
  /// either side (D4). Derived from UC-08's repayments — workbook step 2,
  /// sequence message 2, `seq-uc08-repayment.drawio`'s note.
  final int paid;

  /// ABS(balance(a)) — the outstanding amount as a magnitude (`decisions.md`
  /// 2026-08-19: *"a debt … its balance is the outstanding amount"*; D4).
  /// PAYABLE balances store signed-negative (UC-02 D6), hence the ABS.
  final int remaining;

  /// FR-11's tick — ISSUE-001 D8's flag, not a lifecycle (`docs/statuses.md`).
  final bool settled;
}

/// `AccountDao` — queries and writes for accounts.
///
/// Reads: `watchPosition()` and `watchBalances()` (UC-01),
/// `watchDebtProgress(accountId)` (UC-10). Writes: `insert()` from UC-02 and
/// `setSettled(accountId)` from UC-10. `update()` remains UC-02B's and is
/// deliberately absent (`pm/findings.md` F14).
///
/// **The join below is written here, inside `AccountDao`, against the
/// `Transactions` table** — ISSUE-005 D1 (`context/index/decisions.md`
/// 2026-08-20): modules reach each other's data by SQL join, never by calling
/// another module's DAO. `TransactionDao` is not imported and no Dart-side
/// stitching in Dart happens; the sums are SQLite's, so each figure has
/// exactly one source (NFR-2). The ledger is **read** here and never
/// **written** — the first write to `Transactions` belongs to UC-03/UC-04
/// (D6).
///
/// **Not a `@DriftAccessor`/`DatabaseAccessor` subtype** — a plain
/// composition over `AppDatabase`, the shape every DAO in this project uses
/// (`context/index/decisions.md` 2026-08-21, UC-13 ruling 1).
///
/// The clock is injected rather than read from the system (the standing
/// discipline, `decisions.md` 2026-08-19) — the same constructor pattern
/// `BudgetDao` shipped — so `setSettled()`'s date stamp is testable.
class AccountDao {
  AccountDao(this._db, {this._clock = const Clock()});

  final AppDatabase _db;
  final Clock _clock;

  /// Message 3 on `seq-uc01-balance-sheet.drawio`.
  ///
  /// One watched query computing all four figures in SQL (D3, D4): each
  /// account's balance is its opening amount plus what entered it through
  /// `to_account_id` minus what left through `from_account_id`; the four
  /// figures are that expression grouped by `Account.group` plus their sum.
  ///
  /// The predicate references **only which sides a row touches** — no
  /// `kind` filter anywhere (D5: whichever encoding Q4 settles on for
  /// adjustments produces identical contributions to these sums), and no
  /// `to_account_id IS NULL` spending predicate (spending is UC-12's figure,
  /// not FR-1's).
  ///
  /// Enum literals arrive as bound variables holding `AccountGroup`'s stored
  /// text (`.textEnum` stores `.name`) rather than string literals inlined
  /// into the SQL, so the enum's storage stays defined in exactly one place.
  Stream<FinancialPosition> watchPosition() {
    return _db
        .customSelect(
          '''
          WITH balances AS (
            SELECT
              accounts."group" AS group_name,
              accounts.opening_amount
                + COALESCE((SELECT SUM(t.amount) FROM transactions t
                            WHERE t.to_account_id = accounts.account_id), 0)
                - COALESCE((SELECT SUM(t.amount) FROM transactions t
                            WHERE t.from_account_id = accounts.account_id), 0)
                AS balance
            FROM accounts
          )
          SELECT
            COALESCE(SUM(CASE WHEN group_name = ? THEN balance ELSE 0 END), 0)
              AS spendable,
            COALESCE(SUM(CASE WHEN group_name = ? THEN balance ELSE 0 END), 0)
              AS owed_to_me,
            COALESCE(SUM(CASE WHEN group_name = ? THEN balance ELSE 0 END), 0)
              AS owed_by_me,
            COALESCE(SUM(balance), 0) AS net
          FROM balances
          ''',
          variables: [
            Variable.withString(AccountGroup.HOLDING.name),
            Variable.withString(AccountGroup.RECEIVABLE.name),
            Variable.withString(AccountGroup.PAYABLE.name),
          ],
          readsFrom: {_db.accounts, _db.transactions},
        )
        .watchSingle()
        .map(
          (row) => FinancialPosition(
            spendable: row.read<int>('spendable'),
            owedToMe: row.read<int>('owed_to_me'),
            owedByMe: row.read<int>('owed_by_me'),
            net: row.read<int>('net'),
          ),
        );
  }

  /// Message 9 on `seq-uc01-balance-sheet.drawio`: one row per account, D4's
  /// per-account expression. Ordered by insertion id so emissions are
  /// deterministic (the diagram draws no ordering; this is the neutral one).
  Stream<List<AccountBalance>> watchBalances() {
    return _db
        .customSelect(
          '''
          SELECT
            accounts.account_id     AS account_id,
            accounts.name           AS account_name,
            accounts."group"        AS group_name,
            accounts.opening_amount AS opening_amount,
            accounts.settled        AS settled,
            accounts.settled_at     AS settled_at,
            accounts.opening_amount
              + COALESCE((SELECT SUM(t.amount) FROM transactions t
                          WHERE t.to_account_id = accounts.account_id), 0)
              - COALESCE((SELECT SUM(t.amount) FROM transactions t
                          WHERE t.from_account_id = accounts.account_id), 0)
              AS balance
          FROM accounts
          ORDER BY accounts.account_id
          ''',
          readsFrom: {_db.accounts, _db.transactions},
        )
        .watch()
        .map(
          (rows) => [
            for (final row in rows)
              AccountBalance(
                account: Account(
                  accountId: row.read<int>('account_id'),
                  name: row.read<String>('account_name'),
                  group: _groupNamed(row.read<String>('group_name')),
                  openingAmount: row.read<int>('opening_amount'),
                  settled: row.read<bool>('settled'),
                  settledAt: row.readNullable<DateTime>('settled_at'),
                ),
                balance: row.read<int>('balance'),
              ),
          ],
        );
  }

  /// Inverse of drift's `.textEnum` storage: `Account.group` stores
  /// `enum.name` as text (`accounts_table.dart`, `docs/enums.md`).
  static AccountGroup _groupNamed(String name) =>
      AccountGroup.values.firstWhere((value) => value.name == name);

  /// Messages 2 and 7 on `seq-uc10-debt-progress.drawio`:
  /// `watchDebtProgress(accountId)` — one watched query computing D4's two
  /// figures in SQL for one debt account.
  ///
  /// `paid` sums only `kind = 'repayment'` rows touching either side of the
  /// account (D4's citation-backed definition — workbook step 2 and sequence
  /// message 2 both name repayments; the filter is also what removes Q4's
  /// only channel into this figure, D5). The balance half carries **no**
  /// `kind` filter and no spending predicate — exactly UC-01's shipped
  /// sides-based expression, shown as a magnitude via ABS because FR-11 asks
  /// "how much is left" and PAYABLE rows store signed-negative (D4).
  ///
  /// The enum literal arrives as a bound variable holding
  /// `TransactionKind`'s stored text (`.textEnum` stores `.name`), the way
  /// [watchPosition] handles `AccountGroup` values.
  Stream<DebtProgress> watchDebtProgress(int accountId) {
    return _db
        .customSelect(
          '''
          SELECT
            accounts.settled AS settled,
            COALESCE((SELECT SUM(t.amount) FROM transactions t
                      WHERE t.kind = ?
                        AND (t.from_account_id = accounts.account_id
                             OR t.to_account_id = accounts.account_id)), 0)
              AS paid,
            ABS(accounts.opening_amount
                + COALESCE((SELECT SUM(t.amount) FROM transactions t
                            WHERE t.to_account_id = accounts.account_id), 0)
                - COALESCE((SELECT SUM(t.amount) FROM transactions t
                            WHERE t.from_account_id = accounts.account_id), 0))
              AS remaining
          FROM accounts
          WHERE accounts.account_id = ?
          ''',
          variables: [
            Variable.withString(TransactionKind.repayment.name),
            Variable.withInt(accountId),
          ],
          readsFrom: {_db.accounts, _db.transactions},
        )
        .watchSingle()
        .map(
          (row) => DebtProgress(
            paid: row.read<int>('paid'),
            remaining: row.read<int>('remaining'),
            settled: row.read<bool>('settled'),
          ),
        );
  }

  /// Message 5 on `seq-uc10-debt-progress.drawio`: `setSettled(accountId)` —
  /// ISSUE-001 D8's flag plus date. One update: `settled = true`, `settled_at`
  /// stamped from the injected clock (D6). Returns `Future<void>`; no result
  /// reaches the screen — the read path re-emits with `settled: true`
  /// instead (message 7, `riverpod.md`'s read/write asymmetry).
  ///
  /// One move on the flag, false→true (`docs/enums.md` stated non-members) —
  /// there is deliberately no un-settle method on any diagram. Calling it
  /// twice is harmless (idempotent update, refreshed date), which NFR-4
  /// prefers to any guard.
  Future<void> setSettled(int accountId) async {
    await (_db.update(
      _db.accounts,
    )..where((row) => row.accountId.equals(accountId))).write(
      AccountsCompanion(
        settled: const Value(true),
        settledAt: Value(_clock.today()),
      ),
    );
  }

  /// Message 3 on `seq-uc02-add-account.drawio`: `insert(account)`.
  ///
  /// Returns the new account id because drift's `insert()` gives it back for
  /// free; nobody consumes it — the write path never returns its result to
  /// the UI (`riverpod.md`, the read/write asymmetry).
  Future<int> insert(AccountsCompanion account) {
    return _db.into(_db.accounts).insert(account);
  }
}
