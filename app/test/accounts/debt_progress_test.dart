import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uangsaku/src/accounts/account_dao.dart';
import 'package:uangsaku/src/accounts/accounts_table.dart';
import 'package:uangsaku/src/database/app_database.dart';
import 'package:uangsaku/src/transactions/transactions_table.dart';

/// UC-10's query tests (`pm/issues/uc10-debt-progress/plan.md`, Definition
/// of done). Every figure under test is derived by `AccountDao`'s watched
/// SQL — nothing is mocked; fixtures insert `Accounts` and `Transactions`
/// rows directly through the in-memory database (test scaffolding, not a
/// write path).
void main() {
  late AppDatabase database;
  late AccountDao dao;

  setUp(() {
    // Fresh in-memory database per test — no mocking of drift (testing.md).
    database = AppDatabase(NativeDatabase.memory());
    dao = AccountDao(database);
  });

  tearDown(() => database.close());

  Future<int> insertAccount(
    String name,
    AccountGroup group,
    int openingAmount,
  ) => database
      .into(database.accounts)
      .insert(
        AccountsCompanion.insert(
          name: name,
          group: group,
          openingAmount: openingAmount,
        ),
      );

  Future<void> insertTransaction({
    required TransactionKind kind,
    required int amount,
    int? fromAccountId,
    int? toAccountId,
  }) => database
      .into(database.transactions)
      .insert(
        TransactionsCompanion.insert(
          kind: kind,
          amount: amount,
          occurredOn: DateTime(2026, 8, 23),
          fromAccountId: Value(fromAccountId),
          toAccountId: Value(toAccountId),
        ),
      );

  test('FR-11 / D4: a RECEIVABLE opened at 500000 with a repayment of 200000 yields paid 200000 and remaining 300000', () async {
    final debtId = await insertAccount('Budi', AccountGroup.RECEIVABLE, 500000);
    await insertTransaction(
      kind: TransactionKind.repayment,
      amount: 200000,
      // Repaying a receivable moves money FROM the person's account back
      // to the wallet — its balance falls toward zero.
      fromAccountId: debtId,
    );

    final progress = await dao.watchDebtProgress(debtId).first;

    expect(progress.paid, 200000);
    expect(progress.remaining, 300000);
    expect(progress.settled, false);
  });

  test('FR-11 / D4: a PAYABLE stored signed (-500000), borrowed against, then repaid 400000 yields paid 400000 and remaining 600000 — magnitudes despite negative storage', () async {
    final cardId = await insertAccount('Card', AccountGroup.PAYABLE, -500000);
    // A borrow runs PAYABLE account -> wallet: further down.
    await insertTransaction(
      kind: TransactionKind.borrow,
      amount: 500000,
      fromAccountId: cardId,
    );
    // A repayment runs wallet -> payable account: toward zero.
    await insertTransaction(
      kind: TransactionKind.repayment,
      amount: 400000,
      toAccountId: cardId,
    );

    final progress = await dao.watchDebtProgress(cardId).first;

    // balance = -500000 - 500000 + 400000 = -600000; FR-11 asks "how much
    // is left", so remaining is the magnitude (D4).
    expect(progress.paid, 400000);
    expect(progress.remaining, 600000);
  });

  test("D4: an additional lend raises remaining and leaves paid untouched — paid counts only repayments, so the two figures move independently", () async {
    final debtId = await insertAccount('Budi', AccountGroup.RECEIVABLE, 500000);
    await insertTransaction(
      kind: TransactionKind.repayment,
      amount: 200000,
      fromAccountId: debtId,
    );
    expect((await dao.watchDebtProgress(debtId).first).remaining, 300000);

    // Lending more into the same account raises what is owed but is not
    // money repaid.
    await insertTransaction(
      kind: TransactionKind.lend,
      amount: 100000,
      toAccountId: debtId,
    );

    final progress = await dao.watchDebtProgress(debtId).first;
    expect(progress.remaining, 400000); // +100000
    expect(progress.paid, 200000); // untouched
  });

  test('D5 / Q4: a downward adjustment correction drives remaining to the same value under encoding A (from-side, |amount|) and encoding B (fixed to-side, signed amount) and leaves paid unchanged under both', () async {
    Future<DebtProgress> runScenario({required bool encodingB}) async {
      final scenarioDb = AppDatabase(NativeDatabase.memory());
      try {
        final scenarioDao = AccountDao(scenarioDb);
        final debtId = await scenarioDb
            .into(scenarioDb.accounts)
            .insert(
              AccountsCompanion.insert(
                name: 'Budi',
                group: AccountGroup.RECEIVABLE,
                openingAmount: 500000,
              ),
            );
        if (encodingB) {
          // Option B: one fixed side (to), the amount signed.
          await scenarioDb
              .into(scenarioDb.transactions)
              .insert(
                TransactionsCompanion.insert(
                  kind: TransactionKind.adjustment,
                  amount: -100000,
                  occurredOn: DateTime(2026, 8, 23),
                  toAccountId: Value(debtId),
                ),
              );
        } else {
          // Option A: side follows the sign, amount always positive.
          await scenarioDb
              .into(scenarioDb.transactions)
              .insert(
                TransactionsCompanion.insert(
                  kind: TransactionKind.adjustment,
                  amount: 100000,
                  occurredOn: DateTime(2026, 8, 23),
                  fromAccountId: Value(debtId),
                ),
              );
        }
        return await scenarioDao.watchDebtProgress(debtId).first;
      } finally {
        await scenarioDb.close();
      }
    }

    final encodingA = await runScenario(encodingB: false);
    final encodingB = await runScenario(encodingB: true);

    // Whichever way Q4 is answered, this screen was already correct and
    // stays correct: 500000 corrected down by 100000, nothing repaid.
    expect(encodingA.remaining, 400000);
    expect(encodingB.remaining, 400000);
    expect(encodingA.paid, 0);
    expect(encodingB.paid, 0);
  });

  test('FR-11 / D6: setSettled flips settled and stamps settled_at, the stream re-emits with settled true, and calling it twice still succeeds (NFR-4)', () async {
    final debtId = await insertAccount('Budi', AccountGroup.RECEIVABLE, 500000);

    expect((await dao.watchDebtProgress(debtId).first).settled, false);

    await dao.setSettled(debtId);

    final afterFirst = await dao.watchDebtProgress(debtId).first;
    expect(afterFirst.settled, true);

    final row = await (database.select(
      database.accounts,
    )..where((a) => a.accountId.equals(debtId))).getSingle();
    expect(row.settledAt, isNotNull);

    // Ticking twice is harmless — no refusal path (NFR-4).
    await dao.setSettled(debtId);
    final afterSecond = await dao.watchDebtProgress(debtId).first;
    expect(afterSecond.settled, true);
    expect(afterSecond.paid, afterFirst.paid);
    expect(afterSecond.remaining, afterFirst.remaining);
  });

  test('FR-11 / D4: a debt with no transactions yields paid 0 and remaining = |openingAmount|', () async {
    final debtId = await insertAccount('Budi', AccountGroup.RECEIVABLE, 500000);

    final progress = await dao.watchDebtProgress(debtId).first;

    expect(progress.paid, 0); // COALESCE over an empty repayment sum
    expect(progress.remaining, 500000);
  });
}
