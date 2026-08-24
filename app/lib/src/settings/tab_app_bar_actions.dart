import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../transactions/category_manager_screen.dart';
import 'help_screen.dart';
import 'settings_screen.dart';

/// The shared trailing app-bar action set for every tab of `AppShell`
/// (FEAT10 D3) — Categories (only when [showCategories]), then Settings,
/// then Help, in that order. The exact three `IconButton`s
/// `BalanceSheetScreen` used to build inline, lifted out so five screens
/// share one definition instead of five copies drifting apart.
///
/// Not a tracked class — a plain function returning widgets, the same
/// bucket `group_style.dart`/`kind_style.dart` sit in.
List<Widget> tabAppBarActions(
  BuildContext context, {
  required bool showCategories,
}) {
  final loc = AppLocalizations.of(context)!;
  return [
    if (showCategories)
      IconButton(
        tooltip: loc.categoriesTooltip,
        icon: const Icon(Icons.category_outlined),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const CategoryManagerScreen(),
          ),
        ),
      ),
    IconButton(
      tooltip: loc.settingsTooltip,
      icon: const Icon(Icons.settings_outlined),
      onPressed: () => Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen())),
    ),
    IconButton(
      tooltip: loc.helpTooltip,
      icon: const Icon(Icons.help_outline),
      onPressed: () => Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => const HelpScreen())),
    ),
  ];
}
