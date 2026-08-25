import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uangsaku/l10n/app_localizations.dart';
import 'package:uangsaku/src/accounts/accounts_screen.dart';
import 'package:uangsaku/src/accounts/accounts_table.dart';
import 'package:uangsaku/src/accounts/group_style.dart';
import 'package:uangsaku/src/database/app_database.dart';

/// `AccountsScreen`'s own screen test (FEAT04 D1): the per-account list
/// assertions that used to live in `balance_sheet_screen_test.dart` before
/// the split — same widgets, same behavior, ported verbatim onto the new
/// screen rather than dropped.
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
          home: AccountsScreen(),
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

  testWidgets('FR-2: the account list renders one row per place money lives', (
    tester,
  ) async {
    // Seeded with plain inserts, never by consuming the watch streams
    // first — that would starve the widget's own subscriptions
    // (`testing.md`, verified UC13).
    //
    // The HOLDING account is named 'Cash', not 'Wallet' — since FEAT18 D2
    // this screen's HOLDING section header is itself labeled "Wallet"
    // (`accountGroupLabelHolding`, en), so an account literally named
    // "Wallet" would make its own row's `Text` indistinguishable from the
    // section header's in `find.text`/`accountRow` lookups throughout this
    // file.
    await insertAccount('Cash', AccountGroup.HOLDING, 100000);
    await insertAccount('Budi', AccountGroup.RECEIVABLE, 50000);

    await pumpScreen(tester);

    expect(find.text('Cash'), findsOneWidget);
    expect(find.text('Budi'), findsOneWidget);
    expect(find.text('HOLDING'), findsOneWidget);
    expect(find.text('RECEIVABLE'), findsOneWidget);
    // FEAT17 D1: formatted with a grouping separator, not the raw int.
    // FEAT18 D1: Budi is the RECEIVABLE section's only account, so its row
    // balance and that section's header sum coincide — two widgets, not
    // one (same shape as the other single-account-per-section tests
    // below).
    expect(find.text('50,000'), findsNWidgets(2));

    await unmountAndFlushTimers(tester);
  });

  // The section-header sum stays signed (D1's out-of-scope note) and is
  // itself rendered via an `ExpansionTile`, which builds its own internal
  // `ListTile` — so scoping by `ListTile` type alone isn't enough to avoid
  // colliding with it. Anchor on the account row's own `ListTile` instead
  // (the one whose subtree contains that account's name).
  Finder accountRow(String accountName) =>
      find.widgetWithText(ListTile, accountName);

  testWidgets(
    'FEAT17 D1: a PAYABLE account with a negative derived balance renders '
    'its row balance as a positive, formatted string',
    (tester) async {
      await insertAccount('Card', AccountGroup.PAYABLE, -75000);

      await pumpScreen(tester);

      expect(
        find.descendant(of: accountRow('Card'), matching: find.text('75,000')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: accountRow('Card'), matching: find.text('-75,000')),
        findsNothing,
      );

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets(
    'FEAT17 D1: a HOLDING account with a negative balance still renders '
    'signed',
    (tester) async {
      await insertAccount('Cash', AccountGroup.HOLDING, -30000);

      await pumpScreen(tester);

      expect(
        find.descendant(of: accountRow('Cash'), matching: find.text('-30,000')),
        findsOneWidget,
      );

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets(
    'FEAT17 D1: a PERSON account currently owed by the owner (negative '
    'balance) also renders positive',
    (tester) async {
      await insertAccount('Ivy', AccountGroup.PERSON, -12000);

      await pumpScreen(tester);

      expect(
        find.descendant(of: accountRow('Ivy'), matching: find.text('12,000')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: accountRow('Ivy'), matching: find.text('-12,000')),
        findsNothing,
      );

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets(
    'FEAT18 D1: an empty database renders all four sections with their own '
    'empty-list placeholder',
    (tester) async {
      await pumpScreen(tester);

      // One per section (Holding, Receivable, Payable, Person) — the split
      // shows zero rather than hiding an empty section.
      expect(find.text('No accounts yet.'), findsNWidgets(4));
      expect(find.byKey(const ValueKey('holding-section')), findsOneWidget);
      expect(find.byKey(const ValueKey('receivable-section')), findsOneWidget);
      expect(find.byKey(const ValueKey('payable-section')), findsOneWidget);
      expect(find.byKey(const ValueKey('person-section')), findsOneWidget);

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets(
    'FEAT11 D5: a PERSON row shows the debt-detail icon, same as RECEIVABLE/PAYABLE rows',
    (tester) async {
      await insertAccount('Cash', AccountGroup.HOLDING, 100000);
      await insertAccount('Sam', AccountGroup.PERSON, 20000);

      await pumpScreen(tester);

      // One icon per debt-shaped row — HOLDING gets none.
      expect(find.byIcon(Icons.info_outline), findsOneWidget);

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets(
    'FEAT18 D1/D2: the list splits into four sections (Holding, Receivable, '
    'Payable, Person), each with its own balance sum next to the header',
    (tester) async {
      await insertAccount('Cash', AccountGroup.HOLDING, 100000);
      await insertAccount('Card', AccountGroup.PAYABLE, -20000);
      await insertAccount('Sam', AccountGroup.PERSON, 30000);
      await insertAccount('Ivy', AccountGroup.PERSON, -5000);

      await pumpScreen(tester);

      // All four section headers render, each showing its own accounts
      // only.
      expect(find.byKey(const ValueKey('holding-section')), findsOneWidget);
      expect(find.byKey(const ValueKey('payable-section')), findsOneWidget);
      expect(find.byKey(const ValueKey('person-section')), findsOneWidget);
      expect(find.text('Cash'), findsOneWidget);
      expect(find.text('Card'), findsOneWidget);
      expect(find.text('Sam'), findsOneWidget);
      expect(find.text('Ivy'), findsOneWidget);

      // Holding section: 100000 — its only account (Cash) is positive and
      // HOLDING never `.abs()`s, so the row and the header sum render the
      // identical string, two widgets rather than one (same shape as the
      // dedicated single-account-per-section tests above). Payable
      // section: -20000, the header stays signed ("-20,000") while the row
      // displays 20,000 (FEAT17 D1's ABS() convention, unchanged) — the two
      // strings differ, so the row's is the only "20,000". Person section:
      // 30000 + -5000 = 25000, distinct from either row's own display
      // (30,000 / 5,000). Plain sums of what accountBalancesProvider
      // already derived — not a fifth FR-1 figure.
      expect(find.text('100,000'), findsNWidgets(2));
      expect(find.text('20,000'), findsOneWidget);
      expect(find.text('25,000'), findsOneWidget);

      await unmountAndFlushTimers(tester);
    },
  );

  testWidgets("FEAT18 D1: a PERSON account never contributes to the Holding "
      "section's sum, and a HOLDING account never contributes to Person's", (
    tester,
  ) async {
    await insertAccount('Cash', AccountGroup.HOLDING, 100000);
    await insertAccount('Sam', AccountGroup.PERSON, 30000);

    await pumpScreen(tester);

    // FEAT17 D1: the row balance is now formatted the same way as the
    // section sum, so with a single account per section the two coincide
    // (header sum + row balance) — two widgets, not one.
    expect(find.text('100,000'), findsNWidgets(2));
    expect(find.text('30,000'), findsNWidgets(2));

    await unmountAndFlushTimers(tester);
  });

  group('FEAT18 D3/D4: sign-aware coloring on AccountsScreen', () {
    Color colorOf(Finder textFinder) =>
        (textFinder.evaluate().single.widget as Text).style!.color!;

    testWidgets('a HOLDING account row and its section header both paint '
        'colorScheme.onSurface', (tester) async {
      // A second HOLDING account (Bank) keeps the section sum (150,000)
      // distinct from either individual row's balance — the row is itself
      // a descendant of the section, so scoping by the section's key alone
      // wouldn't otherwise disambiguate the row's `Text` from the header's.
      await insertAccount('Cash', AccountGroup.HOLDING, 100000);
      await insertAccount('Bank', AccountGroup.HOLDING, 50000);

      await pumpScreen(tester);

      final context = tester.element(find.byType(AccountsScreen));
      final expected = Theme.of(context).colorScheme.onSurface;

      expect(
        colorOf(
          find.descendant(
            of: accountRow('Cash'),
            matching: find.text('100,000'),
          ),
        ),
        expected,
      );
      expect(
        colorOf(
          find.descendant(
            of: find.byKey(const ValueKey('holding-section')),
            matching: find.text('150,000'),
          ),
        ),
        expected,
      );

      await unmountAndFlushTimers(tester);
    });

    testWidgets(
      'a RECEIVABLE account row and its section header both paint the same '
      'green accountGroupColor already produces for RECEIVABLE',
      (tester) async {
        // A second RECEIVABLE account (Wati) keeps the section sum
        // (70,000) distinct from either individual row's balance — same
        // reasoning as the HOLDING test above.
        await insertAccount('Budi', AccountGroup.RECEIVABLE, 50000);
        await insertAccount('Wati', AccountGroup.RECEIVABLE, 20000);

        await pumpScreen(tester);

        final context = tester.element(find.byType(AccountsScreen));
        final expected = accountRowColor(
          context,
          AccountGroup.RECEIVABLE,
          50000,
        );

        expect(
          colorOf(
            find.descendant(
              of: accountRow('Budi'),
              matching: find.text('50,000'),
            ),
          ),
          expected,
        );
        expect(
          colorOf(
            find.descendant(
              of: find.byKey(const ValueKey('receivable-section')),
              matching: find.text('70,000'),
            ),
          ),
          expected,
        );

        await unmountAndFlushTimers(tester);
      },
    );

    testWidgets(
      'a PAYABLE account row and its section header both paint the same '
      'red accountGroupColor already produces for PAYABLE',
      (tester) async {
        await insertAccount('Card', AccountGroup.PAYABLE, -75000);

        await pumpScreen(tester);

        final context = tester.element(find.byType(AccountsScreen));
        final expected = accountRowColor(context, AccountGroup.PAYABLE, -75000);

        expect(
          colorOf(
            find.descendant(
              of: accountRow('Card'),
              matching: find.text('75,000'),
            ),
          ),
          expected,
        );
        expect(
          colorOf(
            find.descendant(
              of: find.byKey(const ValueKey('payable-section')),
              matching: find.text('75,000'),
            ),
          ),
          expected,
        );

        await unmountAndFlushTimers(tester);
      },
    );

    testWidgets(
      'a PERSON account with a positive balance paints green, one with a '
      'negative balance paints red',
      (tester) async {
        await insertAccount('Sam', AccountGroup.PERSON, 30000);
        await insertAccount('Ivy', AccountGroup.PERSON, -5000);

        await pumpScreen(tester);

        final context = tester.element(find.byType(AccountsScreen));
        final green = accountRowColor(context, AccountGroup.PERSON, 30000);
        final red = accountRowColor(context, AccountGroup.PERSON, -5000);
        expect(green, isNot(red));

        expect(
          colorOf(
            find.descendant(
              of: accountRow('Sam'),
              matching: find.text('30,000'),
            ),
          ),
          green,
        );
        expect(
          colorOf(
            find.descendant(
              of: accountRow('Ivy'),
              matching: find.text('5,000'),
            ),
          ),
          red,
        );

        await unmountAndFlushTimers(tester);
      },
    );

    testWidgets(
      "the PERSON section header's color follows the section's own signed "
      "sum, independent of any single row",
      (tester) async {
        // Sum: 30000 + -50000 = -20000 (negative), even though the first
        // inserted row (Sam) is itself positive — the header must not just
        // copy the first row's color.
        await insertAccount('Sam', AccountGroup.PERSON, 30000);
        await insertAccount('Ivy', AccountGroup.PERSON, -50000);

        await pumpScreen(tester);

        final context = tester.element(find.byType(AccountsScreen));
        final expected = accountRowColor(context, AccountGroup.PERSON, -20000);

        // The section header's own sum stays signed (D1's out-of-scope
        // note) — unlike a row's balance, it is never `.abs()`'d.
        expect(
          colorOf(
            find.descendant(
              of: find.byKey(const ValueKey('person-section')),
              matching: find.text('-20,000'),
            ),
          ),
          expected,
        );

        await unmountAndFlushTimers(tester);
      },
    );
  });
}
