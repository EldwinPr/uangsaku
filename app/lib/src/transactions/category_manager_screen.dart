import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../database/app_database.dart';
import 'transactions_providers.dart';

/// `CategoryManagerScreen` — UC-13: create, rename and delete categories and
/// subcategories, exactly two levels (FR-10, FR-18).
///
/// Watches `categoryTreeProvider` and renders whatever it emits; every
/// control fires `ref.read(categoriesProvider.notifier).…` and never renders
/// what the call returns — the updated tree arrives on the next stream
/// emission (message 8/14/23 on the sequence diagram).
///
/// **Every control stays enabled, always** (D7, NFR-4's zero-refusals fit
/// criterion): add, rename and delete at both levels, whether or not a
/// category has subcategories or transactions reference it. A subcategory
/// row offers no "add subcategory" control — FR-10's two levels are
/// enforced by that absence, never by a refusal.
class CategoryManagerScreen extends ConsumerWidget {
  const CategoryManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final tree = ref.watch(categoryTreeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(loc.categoryManagerTitle)),
      floatingActionButton: FloatingActionButton(
        // Explicit tag (FEAT02 plan D1): reached with `AppShell`'s
        // `IndexedStack` still mounted underneath, whose Balance Sheet tab
        // has its own FAB — the shared default tag would otherwise collide
        // (Flutter's Hero identity requirement), not a business-logic
        // change.
        heroTag: 'category-manager-fab',
        onPressed: () => _promptAdd(context, ref, categoryId: null),
        tooltip: loc.addCategoryTooltip,
        child: const Icon(Icons.add),
      ),
      body: tree.when(
        data: (categories) => _CategoryList(tree: categories),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('$error')),
      ),
    );
  }
}

class _CategoryList extends ConsumerWidget {
  const _CategoryList({required this.tree});

  final Map<Category, List<Subcategory>> tree;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final categoryEntries = tree.entries.toList();

    if (categoryEntries.isEmpty) {
      return Center(child: Text(loc.noCategoriesYet));
    }

    return ListView(
      children: [
        for (final entry in categoryEntries)
          _CategoryTile(category: entry.key, subcategories: entry.value),
      ],
    );
  }
}

class _CategoryTile extends ConsumerWidget {
  const _CategoryTile({required this.category, required this.subcategories});

  final Category category;
  final List<Subcategory> subcategories;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    return ExpansionTile(
      title: Text(category.name),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: loc.addSubcategoryTooltip,
            onPressed: () =>
                _promptAdd(context, ref, categoryId: category.categoryId),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: loc.renameCategoryTooltip,
            onPressed: () => _promptRename(
              context,
              ref,
              id: category.categoryId,
              isSubcategory: false,
              currentName: category.name,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: loc.deleteCategoryTooltip,
            onPressed: () => ref
                .read(categoriesProvider.notifier)
                .remove(id: category.categoryId, isSubcategory: false),
          ),
        ],
      ),
      children: [
        for (final subcategory in subcategories)
          ListTile(
            title: Text(subcategory.name),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: loc.renameSubcategoryTooltip,
                  onPressed: () => _promptRename(
                    context,
                    ref,
                    id: subcategory.subcategoryId,
                    isSubcategory: true,
                    currentName: subcategory.name,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: loc.deleteSubcategoryTooltip,
                  onPressed: () => ref
                      .read(categoriesProvider.notifier)
                      .remove(
                        id: subcategory.subcategoryId,
                        isSubcategory: true,
                      ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

Future<void> _promptAdd(
  BuildContext context,
  WidgetRef ref, {
  required int? categoryId,
}) async {
  final name = await _promptForName(context, initialValue: '');
  if (name == null) {
    return;
  }
  await ref
      .read(categoriesProvider.notifier)
      .add(categoryId: categoryId, name: name);
}

Future<void> _promptRename(
  BuildContext context,
  WidgetRef ref, {
  required int id,
  required bool isSubcategory,
  required String currentName,
}) async {
  final name = await _promptForName(context, initialValue: currentName);
  if (name == null) {
    return;
  }
  await ref
      .read(categoriesProvider.notifier)
      .rename(id: id, isSubcategory: isSubcategory, name: name);
}

Future<String?> _promptForName(
  BuildContext context, {
  required String initialValue,
}) {
  final loc = AppLocalizations.of(context)!;
  final controller = TextEditingController(text: initialValue);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      content: TextField(controller: controller, autofocus: true),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(controller.text),
          child: Text(loc.saveButton),
        ),
      ],
    ),
  );
}
