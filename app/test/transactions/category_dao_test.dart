import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uangsaku/src/database/app_database.dart';
import 'package:uangsaku/src/transactions/category_dao.dart';
import 'package:uangsaku/src/transactions/transactions_table.dart';

void main() {
  late AppDatabase database;
  late CategoryDao dao;

  setUp(() {
    // Fresh in-memory database per test — no mocking of drift (testing.md).
    database = AppDatabase(NativeDatabase.memory());
    dao = CategoryDao(database);
  });

  tearDown(() => database.close());

  test('UC-13: watchTree() emits an empty map on a fresh database', () async {
    expect(dao.watchTree(), emits(<Category, List<Subcategory>>{}));
  });

  test('UC-13: inserting a category, then a subcategory, is the same stream, a second emission', () async {
    final emissions = <Map<Category, List<Subcategory>>>[];
    final subscription = dao.watchTree().listen(emissions.add);
    addTearDown(subscription.cancel);

    await pumpEventQueue();
    expect(emissions, hasLength(1));
    expect(emissions.single, isEmpty);

    await dao.insert(name: 'Food');
    await pumpEventQueue();
    expect(emissions, hasLength(2));
    final afterCategory = emissions.last;
    expect(afterCategory, hasLength(1));
    final category = afterCategory.keys.single;
    expect(category.name, 'Food');
    expect(afterCategory[category], isEmpty);

    await dao.insert(categoryId: category.categoryId, name: 'Groceries');
    await pumpEventQueue();
    expect(emissions, hasLength(3));
    final afterSubcategory = emissions.last;
    expect(afterSubcategory[category], hasLength(1));
    expect(afterSubcategory[category]!.single.name, 'Groceries');
  });

  test('FR-10: a subcategory is reachable only under its category — Subcategories has no column pointing at another subcategory', () {
    final columnNames = database.subcategories.$columns
        .map((column) => column.name)
        .toList();
    expect(columnNames, contains('category_id'));
    expect(columnNames, isNot(contains('parent_subcategory_id')));
  });

  test('FR-18: a category can be renamed and deleted', () async {
    await dao.insert(name: 'Food');
    var tree = await dao.watchTree().first;
    final category = tree.keys.single;

    await dao.update(
      id: category.categoryId,
      isSubcategory: false,
      name: 'Groceries',
    );
    tree = await dao.watchTree().first;
    expect(tree.keys.single.name, 'Groceries');

    await dao.delete(id: category.categoryId, isSubcategory: false);
    tree = await dao.watchTree().first;
    expect(tree, isEmpty);
  });

  test('FR-18: a subcategory can be renamed and deleted', () async {
    await dao.insert(name: 'Food');
    var tree = await dao.watchTree().first;
    final category = tree.keys.single;
    await dao.insert(categoryId: category.categoryId, name: 'Groceries');

    tree = await dao.watchTree().first;
    final subcategory = tree[category]!.single;

    await dao.update(
      id: subcategory.subcategoryId,
      isSubcategory: true,
      name: 'Restaurant',
    );
    tree = await dao.watchTree().first;
    expect(tree[category]!.single.name, 'Restaurant');

    await dao.delete(id: subcategory.subcategoryId, isSubcategory: true);
    tree = await dao.watchTree().first;
    expect(tree[category], isEmpty);
  });

  test('D6: deleting a category removes its subcategories, and a transaction tagged with it survives with category_id and subcategory_id null', () async {
    await dao.insert(name: 'Food');
    var tree = await dao.watchTree().first;
    final category = tree.keys.single;
    await dao.insert(categoryId: category.categoryId, name: 'Groceries');
    tree = await dao.watchTree().first;
    final subcategory = tree[category]!.single;

    final transactionId = await database
        .into(database.transactions)
        .insert(
          TransactionsCompanion.insert(
            kind: TransactionKind.expense,
            amount: 1000,
            occurredOn: DateTime(2026, 8, 21),
            categoryId: Value(category.categoryId),
            subcategoryId: Value(subcategory.subcategoryId),
          ),
        );

    await dao.delete(id: category.categoryId, isSubcategory: false);

    tree = await dao.watchTree().first;
    expect(tree, isEmpty);

    final row = await (database.select(
      database.transactions,
    )..where((row) => row.transactionId.equals(transactionId))).getSingle();
    expect(row.categoryId, isNull);
    expect(row.subcategoryId, isNull);
  });

  test('D6: deleting a subcategory nulls only subcategory_id and leaves category_id intact', () async {
    await dao.insert(name: 'Food');
    var tree = await dao.watchTree().first;
    final category = tree.keys.single;
    await dao.insert(categoryId: category.categoryId, name: 'Groceries');
    tree = await dao.watchTree().first;
    final subcategory = tree[category]!.single;

    final transactionId = await database
        .into(database.transactions)
        .insert(
          TransactionsCompanion.insert(
            kind: TransactionKind.expense,
            amount: 1000,
            occurredOn: DateTime(2026, 8, 21),
            categoryId: Value(category.categoryId),
            subcategoryId: Value(subcategory.subcategoryId),
          ),
        );

    await dao.delete(id: subcategory.subcategoryId, isSubcategory: true);

    tree = await dao.watchTree().first;
    expect(tree[category], isEmpty);

    final row = await (database.select(
      database.transactions,
    )..where((row) => row.transactionId.equals(transactionId))).getSingle();
    expect(row.categoryId, category.categoryId);
    expect(row.subcategoryId, isNull);
  });
}
