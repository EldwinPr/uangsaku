import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uangsaku/l10n/app_localizations.dart';
import 'package:uangsaku/src/accounts/accounts_table.dart';
import 'package:uangsaku/src/accounts/balance_sheet_screen.dart';
import 'package:uangsaku/src/accounts/group_style.dart';
import 'package:uangsaku/src/accounts/money_format.dart';
import 'package:uangsaku/src/database/app_database.dart';
import 'package:uangsaku/src/settings/settings_table.dart';
import 'package:uangsaku/src/transactions/transactions_table.dart';

/// UC-01's screen test (plan, Definition of done — *Widget, FR-1*): the
/// primary screen renders the four figures distinctly. Sequence-diagram
/// messages 1/7/13 exercised through real provider watches over a real
/// in-memory database.
///
/// **FEAT04 D1**: the per-account list assertions this file used to carry
/// moved to `test/accounts/accounts_screen_test.dart` alongside the
/// `AccountsScreen` split — `BalanceSheetScreen` no longer renders that
/// list, so this file only ever asserts the four figures now.
void main() {
  late AppDatabase database;

  setUp(() {
    // Fresh in-memory database per test — no mocking of drift (testing.md).
    database = AppDatabase(NativeDatabase.memory());
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

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: BalanceSheetScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// 2026-08-24 overflow audit: the exact conditions that caused the
  /// figure-card overflow the owner reported — a longer `id`-locale label
  /// (this app's seeded default, FEAT03 D1) plus a larger accessibility
  /// text scale — wrapped around the same screen.
  Future<void> pumpScreenStressed(WidgetTester tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
        child: ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(database)],
          child: const MaterialApp(
            locale: Locale('id'),
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: BalanceSheetScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  // drift's `watch()` cancellation schedules a zero-duration `Timer`
  // (`StreamQueryStore.markAsClosed`) that only fires on a later pump; the
  // test body flushes it before returning (`testing.md`, verified UC13).
  Future<void> unmountAndFlushTimers(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  String figureText(WidgetTester tester, String key) =>
      tester.widget<Text>(find.byKey(ValueKey(key))).data!;

  /// Money-format-aware expectation: reads the actual resolved locale off
  /// the same key's `BuildContext` rather than hardcoding a separator style
  /// (`money_format.dart`'s grouping/decimal characters follow the app's
  /// locale, en vs id) — avoids coupling this test to whichever locale the
  /// widget-test harness happens to default to.
  String expectedFigureText(WidgetTester tester, String key, int minorUnits) {
    final context = tester.element(find.byKey(ValueKey(key)));
    return formatMinorUnits(context, minorUnits, Currency.IDR);
  }

  testWidgets('FR-1: the primary screen renders the four figures distinctly', (
    tester,
  ) async {
    // Seeded with plain inserts, never by consuming the watch streams
    // first — that would starve the widget's own subscriptions
    // (`testing.md`, verified UC13).
    await insertAccount('Wallet', AccountGroup.HOLDING, 100000);
    await insertAccount('Budi', AccountGroup.RECEIVABLE, 50000);

    await pumpScreen(tester);

    // Four distinct figures — spendable is not merged with owed-to-me.
    // IDR is the app's seeded default currency (`app_database.dart`).
    expect(
      figureText(tester, 'figure-spendable'),
      expectedFigureText(tester, 'figure-spendable', 100000),
    );
    expect(
      figureText(tester, 'figure-owed-to-me'),
      expectedFigureText(tester, 'figure-owed-to-me', 50000),
    );
    expect(
      figureText(tester, 'figure-owed-by-me'),
      expectedFigureText(tester, 'figure-owed-by-me', 0),
    );
    expect(
      figureText(tester, 'figure-net'),
      expectedFigureText(tester, 'figure-net', 150000),
    );

    // FEAT04 D1: the account list moved to AccountsScreen — none of its
    // rows render here anymore.
    expect(find.text('Wallet'), findsNothing);
    expect(find.text('Budi'), findsNothing);

    await unmountAndFlushTimers(tester);
  });

  testWidgets(
    'FEAT09 D2: the spendable/owed-to-me/owed-by-me figure cards render their AccountGroup color on their icon',
    (tester) async {
      await pumpScreen(tester);

      final context = tester.element(find.byKey(const ValueKey('figure-net')));
      final holdingColor = accountGroupColor(context, AccountGroup.HOLDING);
      final receivableColor = accountGroupColor(
        context,
        AccountGroup.RECEIVABLE,
      );
      final payableColor = accountGroupColor(context, AccountGroup.PAYABLE);

      Color? iconColorAbove(String figureKey) {
        // FEAT10 D2 added a second `Icon` per card (the info tooltip's
        // trailing `Icons.info_outline`) — `.first` picks out the original
        // group icon, which the card's `Row` still renders first.
        final iconFinder = find
            .descendant(
              of: find.ancestor(
                of: find.byKey(ValueKey(figureKey)),
                matching: find.byType(Card),
              ),
              matching: find.byType(Icon),
            )
            .first;
        return tester.widget<Icon>(iconFinder).color;
      }

      expect(iconColorAbove('figure-spendable'), holdingColor);
      expect(iconColorAbove('figure-owed-to-me'), receivableColor);
      expect(iconColorAbove('figure-owed-by-me'), payableColor);

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets('NFR-2 / D4: an empty database renders four zero figures', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(figureText(tester, 'figure-spendable'), '0');
    expect(figureText(tester, 'figure-owed-to-me'), '0');
    expect(figureText(tester, 'figure-owed-by-me'), '0');
    expect(figureText(tester, 'figure-net'), '0');

    await unmountAndFlushTimers(tester);
  });

  testWidgets(
    'FEAT07 D3/D6: the balance-trend line chart renders given seeded data',
    (tester) async {
      await insertAccount('Wallet', AccountGroup.HOLDING, 100000);

      await pumpScreen(tester);

      expect(find.byType(LineChart), findsOneWidget);

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets(
    'FEAT07 D4/D7: the income-vs-expense chart degrades to a message, not a blank chart, on an empty database',
    (tester) async {
      await pumpScreen(tester);

      expect(find.byType(BarChart), findsNothing);

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets(
    'FEAT07 D5/D6: the category-spending donut renders given a seeded expense',
    (tester) async {
      final wallet = await insertAccount('Wallet', AccountGroup.HOLDING, 0);
      await database
          .into(database.transactions)
          .insert(
            TransactionsCompanion.insert(
              kind: TransactionKind.expense,
              amount: 5000,
              occurredOn: DateTime.now(),
              fromAccountId: Value(wallet),
            ),
          );

      await pumpScreen(tester);
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(find.byType(PieChart), findsOneWidget);

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets(
    'FEAT07 D5/D7: the category-spending donut degrades to a message, not a blank chart, with no spending this month',
    (tester) async {
      await pumpScreen(tester);
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(find.byType(PieChart), findsNothing);

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets(
    'FEAT10 D2: each of the seven cards (four figures, three charts) carries a Tooltip with a non-empty message',
    (tester) async {
      await pumpScreen(tester);

      // Distinct from the app-bar's own `IconButton` tooltips (Categories,
      // Settings, Help — each an `Icon` other than `info_outline`) — these
      // are specifically the seven info-icon `Tooltip`s D2 adds.
      Iterable<Tooltip> infoTooltipsOnScreen() => tester
          .widgetList<Tooltip>(find.byType(Tooltip))
          .where(
            (tooltip) =>
                tooltip.child is Icon &&
                (tooltip.child! as Icon).icon == Icons.info_outline,
          );

      // Snapshot at the initial scroll position, then again after
      // scrolling down — the `ListView`'s `Sliver` only builds children
      // near the viewport even for a plain (non-`.builder`) child list
      // (same drag every other below-the-fold chart assertion in this
      // file already needs) — union by message so a card built in both
      // snapshots (e.g. the balance-trend chart) isn't double-counted.
      final messagesSeenAtTop = infoTooltipsOnScreen()
          .map((tooltip) => tooltip.message)
          .toSet();

      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();
      final tooltipsAfterScroll = infoTooltipsOnScreen().toList();
      final allMessages = {
        ...messagesSeenAtTop,
        ...tooltipsAfterScroll.map((tooltip) => tooltip.message),
      };
      expect(allMessages, hasLength(7));
      for (final message in allMessages) {
        expect(message, isNotNull);
        expect(message, isNotEmpty);
      }

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets(
    '2026-08-24 overflow audit: no card overflows under id labels, large '
    'amounts and a large accessibility text scale',
    (tester) async {
      // Large opening amounts so the formatted figures are long strings
      // too (`money_format.dart`'s grouping adds length, not just the
      // label) — both axes of the original overflow bug stressed at once.
      final wallet = await insertAccount(
        'Wallet',
        AccountGroup.HOLDING,
        123456789,
      );
      await insertAccount('Budi', AccountGroup.RECEIVABLE, 987654321);
      await insertAccount('Kartu kredit', AccountGroup.PAYABLE, -12345678);
      await database
          .into(database.transactions)
          .insert(
            TransactionsCompanion.insert(
              kind: TransactionKind.expense,
              amount: 5000,
              occurredOn: DateTime.now(),
              fromAccountId: Value(wallet),
            ),
          );

      await pumpScreenStressed(tester);
      expect(tester.takeException(), isNull);

      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await unmountAndFlushTimers(tester);
    },
  );
}
