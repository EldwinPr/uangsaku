import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uangsaku/src/accounts/account_dao.dart';
import 'package:uangsaku/src/accounts/accounts_table.dart';
import 'package:uangsaku/src/database/app_database.dart';
import 'package:uangsaku/src/transactions/transactions_table.dart';

/// UC-01's query tests (`pm/issues/uc01-balance-sheet/plan.md`, Definition
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

  test('FR-2 / D4: an account with openingAmount X and no transactions yields AccountBalance = X', () async {
    // Opening amounts alone are the whole balance on a fresh database.
    await insertAccount('Wallet', AccountGroup.HOLDING, 250000);

    final balances = await dao.watchBalances().first;

    expect(balances, hasLength(1));
    expect(balances.single.account.name, 'Wallet');
    expect(balances.single.balance, 250000);
  });

  test('FR-2 / D4: balance = opening + income - expense with ledger rows inserted directly', () async {
    // The ledger half of D4's expression: rows enter through to_account_id
    // and leave through from_account_id.
    final walletId = await insertAccount(
      'Wallet',
      AccountGroup.HOLDING,
      100000,
    );
    await insertTransaction(
      kind: TransactionKind.income,
      amount: 50000,
      toAccountId: walletId,
    );
    await insertTransaction(
      kind: TransactionKind.expense,
      amount: 20000,
      fromAccountId: walletId,
    );

    final balances = await dao.watchBalances().first;

    expect(balances.single.balance, 130000);
  });

  test('FR-1 / D4: spendable and owedToMe are never merged — a RECEIVABLE balance does not land in spendable', () async {
    await insertAccount('Wallet', AccountGroup.HOLDING, 100000);
    await insertAccount('Budi', AccountGroup.RECEIVABLE, 50000);

    final position = await dao.watchPosition().first;

    // Two figures, not one: money sitting with Budi cannot buy lunch.
    expect(position.spendable, 100000);
    expect(position.owedToMe, 50000);
    expect(position.owedByMe, 0);
    expect(position.net, 150000);
  });

  test('FR-8 (schema shape): a transfer between two HOLDING accounts changes neither spendable nor net', () async {
    // Both fall out of D4's sides-based expression with no kind filter —
    // the property this test pins.
    final a = await insertAccount('Wallet', AccountGroup.HOLDING, 100000);
    final b = await insertAccount('Savings', AccountGroup.HOLDING, 50000);
    await insertTransaction(
      kind: TransactionKind.transfer,
      amount: 30000,
      fromAccountId: a,
      toAccountId: b,
    );

    final position = await dao.watchPosition().first;

    expect(position.spendable, 150000); // unchanged by the move
    expect(position.net, 150000);
  });

  test('FR-9 (schema shape): a lend moves the amount from spendable into owedToMe leaving net unchanged', () async {
    final wallet = await insertAccount('Wallet', AccountGroup.HOLDING, 100000);
    final person = await insertAccount('Budi', AccountGroup.RECEIVABLE, 0);
    await insertTransaction(
      kind: TransactionKind.lend,
      amount: 40000,
      fromAccountId: wallet,
      toAccountId: person,
    );

    final position = await dao.watchPosition().first;

    expect(position.spendable, 60000);
    expect(position.owedToMe, 40000);
    expect(position.net, 100000); // unchanged
  });

  test('FR-4 / D4: a PAYABLE account entered at -500000 drags net down by 500000 and a borrow pushes owedByMe further negative', () async {
    final card = await insertAccount(
      'Credit card',
      AccountGroup.PAYABLE,
      -500000,
    );
    final before = await dao.watchPosition().first;
    expect(before.owedByMe, -500000);
    expect(before.net, -500000);

    final wallet = await insertAccount('Wallet', AccountGroup.HOLDING, 0);
    // A borrow runs PAYABLE account → wallet: the payable goes further
    // down, the wallet up, net unmoved.
    await insertTransaction(
      kind: TransactionKind.borrow,
      amount: 200000,
      fromAccountId: card,
      toAccountId: wallet,
    );

    final after = await dao.watchPosition().first;
    expect(after.owedByMe, -700000);
    expect(after.spendable, 200000);
    expect(after.net, -500000);
  });

  test('D5 / Q4: adjustment encodings A (side follows sign, |amount|) and B (fixed to-side, signed amount) drive the same account to the same resulting balance', () async {
    Future<int> runScenario({required bool encodingB}) async {
      final scenarioDb = AppDatabase(NativeDatabase.memory());
      try {
        final scenarioDao = AccountDao(scenarioDb);
        final walletId = await scenarioDb
            .into(scenarioDb.accounts)
            .insert(
              AccountsCompanion.insert(
                name: 'Wallet',
                group: AccountGroup.HOLDING,
                openingAmount: 100000,
              ),
            );
        if (encodingB) {
          // Option B: one fixed side (to), the amount signed.
          await scenarioDb
              .into(scenarioDb.transactions)
              .insert(
                TransactionsCompanion.insert(
                  kind: TransactionKind.adjustment,
                  amount: 30000,
                  occurredOn: DateTime(2026, 8, 23),
                  toAccountId: Value(walletId),
                ),
              );
          await scenarioDb
              .into(scenarioDb.transactions)
              .insert(
                TransactionsCompanion.insert(
                  kind: TransactionKind.adjustment,
                  amount: -20000,
                  occurredOn: DateTime(2026, 8, 23),
                  toAccountId: Value(walletId),
                ),
              );
        } else {
          // Option A: side follows the sign, amount always positive.
          await scenarioDb
              .into(scenarioDb.transactions)
              .insert(
                TransactionsCompanion.insert(
                  kind: TransactionKind.adjustment,
                  amount: 30000,
                  occurredOn: DateTime(2026, 8, 23),
                  toAccountId: Value(walletId),
                ),
              );
          await scenarioDb
              .into(scenarioDb.transactions)
              .insert(
                TransactionsCompanion.insert(
                  kind: TransactionKind.adjustment,
                  amount: 20000,
                  occurredOn: DateTime(2026, 8, 23),
                  fromAccountId: Value(walletId),
                ),
              );
        }
        final balances = await scenarioDao.watchBalances().first;
        return balances.single.balance;
      } finally {
        await scenarioDb.close();
      }
    }

    final encodingA = await runScenario(encodingB: false);
    final encodingB = await runScenario(encodingB: true);

    // Whichever way Q4 is answered, these figures were already correct.
    expect(encodingA, encodingB);
    expect(encodingA, 110000); // opening + diff, both encodings
  });

  test('NFR-2 / D4: an empty database yields four zeros and an empty list, not an error', () async {
    final position = await dao.watchPosition().first;
    expect(position.spendable, 0);
    expect(position.owedToMe, 0);
    expect(position.owedByMe, 0);
    expect(position.net, 0);

    expect(await dao.watchBalances().first, isEmpty);
  });

  test('FEAT11 D2: a PERSON account with a positive balance lands in owedToMe, not spendable or owedByMe', () async {
    await insertAccount('Wallet', AccountGroup.HOLDING, 100000);
    await insertAccount('Sam', AccountGroup.PERSON, 20000);

    final position = await dao.watchPosition().first;

    expect(position.spendable, 100000);
    expect(position.owedToMe, 20000);
    expect(position.owedByMe, 0);
    expect(position.net, 120000);
  });

  test('FEAT11 D2: a PERSON account with a negative balance lands in owedByMe, signed-negative, not spendable or owedToMe', () async {
    await insertAccount('Wallet', AccountGroup.HOLDING, 100000);
    await insertAccount('Sam', AccountGroup.PERSON, -20000);

    final position = await dao.watchPosition().first;

    expect(position.spendable, 100000);
    expect(position.owedToMe, 0);
    expect(position.owedByMe, -20000);
    expect(position.net, 80000);
  });

  test('FEAT11 D2: a PERSON account with a zero balance lands in neither owedToMe nor owedByMe, but net still counts it', () async {
    await insertAccount('Sam', AccountGroup.PERSON, 0);

    final position = await dao.watchPosition().first;

    expect(position.owedToMe, 0);
    expect(position.owedByMe, 0);
    expect(position.net, 0);
  });

  test('FEAT11 D2: PERSON and RECEIVABLE/PAYABLE balances combine within owedToMe/owedByMe', () async {
    await insertAccount('Budi', AccountGroup.RECEIVABLE, 30000);
    await insertAccount('Card', AccountGroup.PAYABLE, -10000);
    await insertAccount('Sam', AccountGroup.PERSON, 5000);
    await insertAccount('Dee', AccountGroup.PERSON, -7000);

    final position = await dao.watchPosition().first;

    expect(position.owedToMe, 35000); // 30000 (RECEIVABLE) + 5000 (PERSON>0)
    expect(position.owedByMe, -17000); // -10000 (PAYABLE) + -7000 (PERSON<0)
    expect(position.net, 18000);
  });
}
