import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import 'category_dao.dart';

/// The category + subcategory tree, watched by `CategoryManagerScreen`
/// (messages 2, 8, 14, 23 on `seq-uc13-categories.drawio`).
///
/// The diagram never draws `categoryTreeProvider → CategoryDao.watchTree()`
/// itself, but `class-transactions.drawio` does, and a provider that emits
/// four times has to be watching something — built per that edge (plan,
/// "The read path the diagram elides").
///
/// Hand-written `StreamProvider`, not `@riverpod`: verified against the real
/// toolchain while building this issue — `riverpod_generator` throws
/// `InvalidTypeException: The type is invalid and cannot be converted to
/// code` on any provider whose signature mentions `Category` or
/// `Subcategory` (drift's generated row classes, declared in
/// `app_database.g.dart`, a `part of 'app_database.dart'`). A `Stream<int>`
/// return type builds; swapping only the type to `Stream<Category>`
/// reproduces the failure, isolating the generated part-file class as the
/// cause, not this provider's shape. `riverpod.md` recommends codegen by
/// default; this is the exception, alongside `appDatabaseProvider`'s.
final categoryTreeProvider =
    StreamProvider.autoDispose<Map<Category, List<Subcategory>>>((ref) {
      final database = ref.watch(appDatabaseProvider);
      return CategoryDao(database).watchTree();
    });

/// Writes for both `Category` and `Subcategory` (UC-13). `add()` / `rename()`
/// / `remove()` forward to `CategoryDao` and return nothing to the screen —
/// the changed tree arrives on `categoryTreeProvider`'s next emission, never
/// as this notifier's return value (`riverpod.md`, the read/write asymmetry).
///
/// Hand-written `NotifierProvider`, not `@riverpod`, for a second reason on
/// top of the one above: `riverpod_generator` would name the generated
/// provider `categoriesNotifierProvider`, not the `categoriesProvider` the
/// class diagram names. Per D2's contingency, the class diagram wins — same
/// precedent `appDatabaseProvider` set in `app_database.dart` (FEAT01 ruling
/// 3).
class CategoriesNotifier extends Notifier<void> {
  late CategoryDao _dao;

  @override
  void build() {
    _dao = CategoryDao(ref.watch(appDatabaseProvider));
  }

  /// Adds a category when [categoryId] is null, otherwise a subcategory
  /// under it (D5).
  Future<void> add({int? categoryId, required String name}) {
    return _dao.insert(categoryId: categoryId, name: name);
  }

  /// Renames a category or a subcategory (FR-18).
  Future<void> rename({
    required int id,
    required bool isSubcategory,
    required String name,
  }) {
    return _dao.update(id: id, isSubcategory: isSubcategory, name: name);
  }

  /// Deletes a category or a subcategory (FR-18, D6).
  Future<void> remove({required int id, required bool isSubcategory}) {
    return _dao.delete(id: id, isSubcategory: isSubcategory);
  }
}

final categoriesProvider =
    NotifierProvider.autoDispose<CategoriesNotifier, void>(
      CategoriesNotifier.new,
    );
