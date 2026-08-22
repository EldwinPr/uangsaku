import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings_providers.dart';
import 'settings_table.dart';

/// `CurrencyScreen` — UC-14: see which currency the app is recording in and
/// change it between `IDR` and `USD` (FR-19).
///
/// Watches `currencyProvider` and renders whatever it emits (message 7, 15);
/// selecting a value fires
/// `ref.read(settingsProvider.notifier).setCurrency(chosen)` and never
/// renders what the call returns — the re-labelled currency arrives on the
/// next stream emission (`riverpod.md`, the read/write asymmetry).
///
/// **Both `IDR` and `USD` stay enabled at all times, including the one
/// currently in force** (D4, NFR-4's zero-refusals fit criterion) — nothing
/// on this screen is ever disabled, greyed or hidden.
///
/// **D9: the notice fires only when the chosen currency differs from the
/// stored one.** It is a dialog that is acknowledged and proceeds — there is
/// no cancel (D5) — and `setCurrency()` runs either way (message 10 sits
/// outside the `opt` box).
class CurrencyScreen extends ConsumerWidget {
  const CurrencyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Currency')),
      body: currency.when(
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
              // selectable at all times, including the one currently in
              // force (D4, NFR-4's zero refusals).
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
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Currency'),
        content: const Text(
          'Existing amounts are re-labelled, not converted. The same '
          'recorded numbers will show with the new currency.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
