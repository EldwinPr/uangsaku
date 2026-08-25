import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import 'settings_providers.dart';
import 'settings_table.dart';

/// `SettingsScreen` — UC-14's currency toggle folded into one hub with
/// language, theme mode and theme color (FEAT03 D3). Was `CurrencyScreen`
/// before this issue; the currency section's behavior is unchanged.
///
/// Five sections, each watching its own provider and firing its own write
/// through `ref.read(settingsProvider.notifier)…` — never rendering what the
/// write returns (`riverpod.md`, the read/write asymmetry). The fifth,
/// `_DataSection` (FEAT20), fires through `databaseMaintenanceProvider`
/// instead.
///
/// **Every control stays enabled at all times** (FEAT03 D3, NFR-4's
/// zero-refusals fit criterion) — nothing on this screen is ever disabled,
/// greyed or hidden, including the currently-selected option in each
/// section. `_DataSection`'s restore and delete controls are the second and
/// third *named* exceptions to NFR-4's zero-refusals fit criterion (D5,
/// `docs/fr-nfr.md`): their Continue/Cancel confirm dialogs are a genuine
/// refusal path (Cancel aborts) because both operations destroy real,
/// already-recorded data with no undo — categorically unlike every other
/// write in this app.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(loc.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _CurrencySection(),
          SizedBox(height: 24),
          _LanguageSection(),
          SizedBox(height: 24),
          _ThemeModeSection(),
          SizedBox(height: 24),
          _ThemeColorSection(),
          SizedBox(height: 24),
          _DataSection(),
        ],
      ),
    );
  }
}

class _CurrencySection extends ConsumerWidget {
  const _CurrencySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final currency = ref.watch(currencyProvider);

    return _Section(
      title: loc.currencySectionTitle,
      child: currency.when(
        data: (stored) => _CurrencyOptions(stored: stored),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('$error')),
      ),
    );
  }
}

class _CurrencyOptions extends ConsumerWidget {
  const _CurrencyOptions({required this.stored});

  final Currency stored;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: SegmentedButton<Currency>(
        segments: [
          for (final option in Currency.values)
            ButtonSegment<Currency>(
              value: option,
              label: Text(option.name),
              // No `enabled: false` on any segment — both values stay
              // selectable at all times (FEAT03 D3, NFR-4 zero refusals).
            ),
        ],
        selected: {stored},
        onSelectionChanged: (chosen) =>
            _choose(context, ref, stored: stored, chosen: chosen.single),
      ),
    );
  }

  Future<void> _choose(
    BuildContext context,
    WidgetRef ref, {
    required Currency stored,
    required Currency chosen,
  }) async {
    // D9: the notice fires only when the chosen currency differs from the
    // stored one.
    if (chosen != stored) {
      await _showRelabelNotice(context);
    }

    // Message 10 — unconditional, outside the `opt` box (D5): it runs
    // whether or not the notice was shown.
    await ref.read(settingsProvider.notifier).setCurrency(chosen);
  }

  /// Message 9: existing amounts are re-labelled, not converted (FR-19,
  /// D6) — the same integers, a different prefix. Acknowledged and
  /// proceeds; there is no cancel (D5).
  Future<void> _showRelabelNotice(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.currencySectionTitle),
        content: Text(loc.currencyRelabelDialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc.okButton),
          ),
        ],
      ),
    );
  }
}

class _LanguageSection extends ConsumerWidget {
  const _LanguageSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final language = ref.watch(languageProvider);

    return _Section(
      title: loc.languageSectionTitle,
      child: language.when(
        data: (stored) => Center(
          child: SegmentedButton<AppLanguage>(
            segments: [
              ButtonSegment<AppLanguage>(
                value: AppLanguage.en,
                label: Text(loc.languageEnglish),
              ),
              ButtonSegment<AppLanguage>(
                value: AppLanguage.id,
                label: Text(loc.languageIndonesian),
              ),
            ],
            selected: {stored},
            onSelectionChanged: (chosen) =>
                ref.read(settingsProvider.notifier).setLanguage(chosen.single),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('$error')),
      ),
    );
  }
}

class _ThemeModeSection extends ConsumerWidget {
  const _ThemeModeSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeModeProvider);

    return _Section(
      title: loc.themeModeSectionTitle,
      child: themeMode.when(
        data: (stored) => Center(
          child: SegmentedButton<AppThemeMode>(
            segments: [
              ButtonSegment<AppThemeMode>(
                value: AppThemeMode.system,
                label: Text(loc.themeModeSystem),
              ),
              ButtonSegment<AppThemeMode>(
                value: AppThemeMode.light,
                label: Text(loc.themeModeLight),
              ),
              ButtonSegment<AppThemeMode>(
                value: AppThemeMode.dark,
                label: Text(loc.themeModeDark),
              ),
            ],
            selected: {stored},
            onSelectionChanged: (chosen) =>
                ref.read(settingsProvider.notifier).setThemeMode(chosen.single),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('$error')),
      ),
    );
  }
}

/// A small fixed set of Material preset swatches — not a full color picker
/// (FEAT03 D1, "if possible" item, out of scope: a custom picker). `null`
/// (the first swatch) resets to the app's default seed.
const List<Color?> _presetSeedColors = [
  null,
  Colors.deepPurple,
  Colors.blue,
  Colors.teal,
  Colors.green,
  Colors.orange,
  Colors.pink,
  Colors.indigo,
];

class _ThemeColorSection extends ConsumerWidget {
  const _ThemeColorSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final seedColor = ref.watch(seedColorProvider);

    return _Section(
      title: loc.themeColorSectionTitle,
      child: seedColor.when(
        data: (stored) => Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final (index, swatch) in _presetSeedColors.indexed)
              _SwatchButton(
                key: ValueKey('theme-swatch-$index'),
                swatch: swatch,
                selected: swatch?.toARGB32() == stored,
                onTap: () => ref
                    .read(settingsProvider.notifier)
                    .setSeedColor(swatch?.toARGB32()),
              ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('$error')),
      ),
    );
  }
}

class _SwatchButton extends StatelessWidget {
  const _SwatchButton({
    super.key,
    required this.swatch,
    required this.selected,
    required this.onTap,
  });

  final Color? swatch;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // No `onTap: null` anywhere — every swatch, including the one already
    // selected, stays tappable at all times (NFR-4 zero refusals).
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: swatch ?? Theme.of(context).colorScheme.surfaceContainer,
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.onSurface
                : Colors.transparent,
            width: 3,
          ),
        ),
        child: swatch == null
            ? Icon(
                Icons.refresh,
                size: 18,
                color: Theme.of(context).colorScheme.onSurface,
              )
            : null,
      ),
    );
  }
}

/// `_DataSection` — backup, restore and delete-all (FEAT20 D6,
/// `class-settings.drawio`). Backup fires immediately, no dialog (D5): it is
/// non-destructive, and the OS share sheet is itself the "did you mean
/// this" moment. Restore and delete each require the app's first genuine
/// Continue/Cancel confirm dialog — the second and third named exceptions to
/// NFR-4's zero-refusals fit criterion (`docs/fr-nfr.md`), because both
/// destroy real, already-recorded data with no undo.
class _DataSection extends ConsumerWidget {
  const _DataSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;

    return _Section(
      title: loc.dataSectionTitle,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          OutlinedButton.icon(
            onPressed: () => _backup(context, ref),
            icon: const Icon(Icons.ios_share),
            label: Text(loc.backupButton),
          ),
          OutlinedButton.icon(
            onPressed: () => _restore(context, ref),
            icon: const Icon(Icons.restore),
            label: Text(loc.restoreButton),
          ),
          OutlinedButton.icon(
            onPressed: () => _deleteAll(context, ref),
            icon: const Icon(Icons.delete_forever),
            label: Text(loc.deleteAllDataButton),
          ),
        ],
      ),
    );
  }

  /// D6: no dialog, no `await` in the caller — fire and forget, matching
  /// every other write in this app (`riverpod.md`, the read/write
  /// asymmetry). `ScaffoldMessenger`/the localized string are captured
  /// before the write so this never touches `context` after an `await`.
  void _backup(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    unawaited(
      ref.read(databaseMaintenanceProvider.notifier).backup().then((_) {
        messenger.showSnackBar(
          SnackBar(content: Text(loc.backupSharedMessage)),
        );
      }),
    );
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final loc = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(databaseMaintenanceProvider.notifier);

    final file = await notifier.pickRestoreCandidate();
    if (file == null) return; // D6: cancelled picker, do nothing.

    if (!context.mounted) return;
    if (!await _looksLikeSqliteFile(file)) {
      if (!context.mounted) return;
      await _showAcknowledgeDialog(
        context,
        title: loc.invalidBackupFileTitle,
        content: loc.invalidBackupFileContent,
      );
      return;
    }

    if (!context.mounted) return;
    final confirmed = await _showConfirmDialog(
      context,
      title: loc.restoreConfirmTitle,
      content: loc.restoreConfirmContent,
      confirmLabel: loc.restoreButton,
    );
    if (confirmed != true) return; // D5: Cancel genuinely aborts.

    await notifier.restore(file);
    messenger.showSnackBar(SnackBar(content: Text(loc.restoreCompleteMessage)));
  }

  Future<void> _deleteAll(BuildContext context, WidgetRef ref) async {
    final loc = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(databaseMaintenanceProvider.notifier);

    final confirmed = await _showConfirmDialog(
      context,
      title: loc.deleteAllConfirmTitle,
      content: loc.deleteAllConfirmContent,
      confirmLabel: loc.deleteAllDataButton,
    );
    if (confirmed != true) return; // D5: Cancel genuinely aborts.

    await notifier.deleteAll();
    messenger.showSnackBar(
      SnackBar(content: Text(loc.deleteAllCompleteMessage)),
    );
  }

  /// D4: reads the picked file's first 16 bytes and compares against the
  /// standard SQLite header magic string. Screen-local pre-write validation,
  /// mirroring `AccountFormScreen._nameCollides`'s established precedent.
  ///
  /// Synchronous `dart:io` (`openSync`/`readSync`), not `openRead(...).first`
  /// — a real, OS-callback-driven asynchronous read never resolves under
  /// `testWidgets`'s FakeAsync zone (only microtask-resolved `Future`s do);
  /// a synchronous read has no such dependency and behaves identically on a
  /// real device.
  Future<bool> _looksLikeSqliteFile(File file) async {
    final raf = file.openSync();
    try {
      final header = raf.readSync(16);
      return String.fromCharCodes(header) == 'SQLite format 3\x00';
    } finally {
      raf.closeSync();
    }
  }

  /// D4: single-button acknowledge dialog for an invalid picked file,
  /// mirroring `AccountFormScreen._showBlockedNotice`'s established
  /// precedent — informs only, does not proceed.
  Future<void> _showAcknowledgeDialog(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    final loc = AppLocalizations.of(context)!;
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc.okButton),
          ),
        ],
      ),
    );
  }

  /// D5: this app's first genuine two-button confirm dialog — unlike every
  /// acknowledge dialog above, Cancel here really aborts. The affirmative
  /// button repeats the action's own name (`confirmLabel`) rather than a
  /// generic "Continue", matching this app's other action-labelled buttons.
  /// Returns `true` only when the affirmative action was tapped.
  Future<bool?> _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String content,
    required String confirmLabel,
  }) {
    final loc = AppLocalizations.of(context)!;
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(loc.cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
