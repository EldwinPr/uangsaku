import 'package:drift/drift.dart';

import '../database/app_database.dart';

/// `CategoryDao` — categories and subcategories (UC-13).
///
/// Reads `Categories, Subcategories`; writes also touch `Transactions` to
/// null out `categoryId` / `subcategoryId` on delete (D6, `drift.md` §DAOs —
/// a DAO may join another module's tables).
///
/// **Not a `@DriftAccessor`/`DatabaseAccessor` subtype**, unlike `drift.md`'s
/// worked shape — a plain composition over `AppDatabase` instead. Verified
/// against the real toolchain while building this issue: `DatabaseAccessor`
/// extends `DatabaseConnectionUser`, which already declares
/// `update<T, D>(TableInfo<T, D>)` and `delete<T, D>(TableInfo<T, D>)`. The
/// class diagram names this DAO's own methods `update()` / `delete()` with
/// an incompatible (named-parameter) signature, and Dart rejects that
/// declaration outright as an invalid override — no method body can work
/// around it, only a different base shape can. Composing over `AppDatabase`
/// keeps every name the diagram draws exact without extending a class that
/// already owns two of them. Flagged for the as-built pass and for
/// `drift.md`, which still shows the `DatabaseAccessor` shape as the only
/// one.
class CategoryDao {
  CategoryDao(this._db);

  final AppDatabase _db;

  /// The full category + subcategory tree, one emission per change.
  ///
  /// A category with no subcategories appears with an empty list, so the
  /// screen can offer "add subcategory" under it (D4).
  Stream<Map<Category, List<Subcategory>>> watchTree() {
    final query = _db.select(_db.categories).join([
      leftOuterJoin(
        _db.subcategories,
        _db.subcategories.categoryId.equalsExp(_db.categories.categoryId),
      ),
    ]);

    return query.watch().map((rows) {
      final tree = <Category, List<Subcategory>>{};
      for (final row in rows) {
        final category = row.readTable(_db.categories);
        final subcategory = row.readTableOrNull(_db.subcategories);
        final subcategoriesForCategory = tree.putIfAbsent(
          category,
          () => <Subcategory>[],
        );
        if (subcategory != null) {
          subcategoriesForCategory.add(subcategory);
        }
      }
      return tree;
    });
  }

  /// Inserts a category when [categoryId] is null, otherwise a subcategory
  /// under it — the two arities the sequence diagram draws (D5).
  Future<void> insert({int? categoryId, required String name}) async {
    if (categoryId == null) {
      await _db
          .into(_db.categories)
          .insert(CategoriesCompanion.insert(name: name));
    } else {
      await _db
          .into(_db.subcategories)
          .insert(
            SubcategoriesCompanion.insert(categoryId: categoryId, name: name),
          );
    }
  }

  /// Renames a category or a subcategory (FR-18).
  Future<void> update({
    required int id,
    required bool isSubcategory,
    required String name,
  }) async {
    if (isSubcategory) {
      await (_db.update(_db.subcategories)
            ..where((row) => row.subcategoryId.equals(id)))
          .write(SubcategoriesCompanion(name: Value(name)));
    } else {
      await (_db.update(_db.categories)
            ..where((row) => row.categoryId.equals(id)))
          .write(CategoriesCompanion(name: Value(name)));
    }
  }

  /// Deletes a category or a subcategory (FR-18).
  ///
  /// D6: the delete cascades to a category's own subcategories, and any
  /// transaction referencing what is deleted survives with its tag nulled —
  /// NFR-4 forbids refusing the delete, and re-parenting is not
  /// representable (`Subcategories.categoryId` is NOT NULL). Explicit
  /// statement order, independent of `PRAGMA foreign_keys` (which is off).
  Future<void> delete({required int id, required bool isSubcategory}) async {
    await _db.transaction(() async {
      if (isSubcategory) {
        await (_db.update(_db.transactions)
              ..where((row) => row.subcategoryId.equals(id)))
            .write(const TransactionsCompanion(subcategoryId: Value(null)));
        await (_db.delete(
          _db.subcategories,
        )..where((row) => row.subcategoryId.equals(id))).go();
      } else {
        final subcategoryIds =
            await (_db.select(_db.subcategories)
                  ..where((row) => row.categoryId.equals(id)))
                .map((row) => row.subcategoryId)
                .get();

        await (_db.update(_db.transactions)..where(
              (row) =>
                  row.categoryId.equals(id) |
                  row.subcategoryId.isIn(subcategoryIds),
            ))
            .write(
              const TransactionsCompanion(
                categoryId: Value(null),
                subcategoryId: Value(null),
              ),
            );
        await (_db.delete(
          _db.subcategories,
        )..where((row) => row.categoryId.equals(id))).go();
        await (_db.delete(
          _db.categories,
        )..where((row) => row.categoryId.equals(id))).go();
      }
    });
  }
}
