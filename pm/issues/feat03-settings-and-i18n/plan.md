# FEAT03-settings-and-i18n — Settings hub: language, theme, currency; full Indonesian translation

**Status:** DONE 2026-08-24. Was CONFIRMED — owner's direct request, interactive session (manual
testing feedback: full Indonesian UI with a language toggle, plus light/dark mode and
theme color folded into the currency screen as one Settings hub). No UC owns this, same
class as FEAT01/FEAT02.

**Traces to:** none (infrastructure).
**Depends on:** `FEAT02-navigation-host` — DONE (every screen this touches is reachable
now, which is why translation coverage can actually be checked by reading the running
app's own screens rather than the source alone).

## Decisions

**D1 — Settings gains three columns; this is the app's second schema change.**
`app/lib/src/settings/settings_table.dart`:

```dart
enum AppLanguage { en, id }
enum AppThemeMode { system, light, dark }
```

- `locale` — `textEnum<AppLanguage>()`, default `AppLanguage.id` (the app's home market;
  every other domain-language convention in this repo already follows the client's
  Indonesian).
- `themeMode` — `textEnum<AppThemeMode>()`, default `AppThemeMode.system`. A
  project-owned enum, not Flutter's own `ThemeMode` — table files import only
  `package:drift/drift.dart`, never `material.dart` (same reasoning `AccountGroup`/
  `TransactionKind` already establish); map to Flutter's `ThemeMode` in the widget layer.
- `seedColor` — nullable `IntColumn` (an ARGB32 int, `Color.toARGB32()` on the Flutter
  side — check whether `.value` is deprecated on this project's pinned Flutter 3.47.1
  and use whichever is current). `null` means "use the app's default seed" (the existing
  hardcoded `Colors.deepPurple` in `app.dart`) — this is the "if possible" item; a small
  fixed set of preset swatches (6–8 Material colors) is enough, not a full color wheel.

Follow `drift.md`'s guided migrations exactly, same as `UC02B`'s `v1→v2`: `dart run
drift_dev make-migrations` before and after, `schemaVersion` → `3`, the generated
`stepByStep` helper (`from2To3`) wired into `onUpgrade`, both schema snapshots committed,
the generated migration test filled in with a real fixture (an existing `Settings` row
surviving the upgrade with the three new columns at their defaults) — not left as the
empty template.

**D2 — `SettingsDao`/`SettingsNotifier` gain reads and writes for the three new fields,
alongside the existing currency ones.** Same shape as `setCurrency()`: each write touches
only its own column, nothing else, returns `Future<void>`, and the result arrives back
on the read path. Reasonable naming: `watchLanguage()`/`setLanguage()`,
`watchThemeMode()`/`setThemeMode()`, `watchSeedColor()`/`setSeedColor()` — or a single
combined `AppSettings` record/stream if that reads cleaner than three separate ones;
coder's call, but keep the three writes independent (setting the theme should never
touch the stored language, etc.).

**D3 — `CurrencyScreen` becomes `SettingsScreen`; the currency behavior does not
change.** One screen, four sections: currency (existing `SegmentedButton`, D9's
re-labelling notice unchanged), language (EN/ID), theme mode (system/light/dark), theme
color (the preset swatches). **Every control stays enabled at all times, same as
currency's** — NFR-4 applies to the whole screen, not just the section that already had
it. No new confirmation dialogs beyond the currency one that already exists.

**D4 — `App` (`app.dart`) becomes a `ConsumerWidget` reading `themeMode`/`seedColor`, and
`MaterialApp` gains `localizationsDelegates`/`supportedLocales`/`locale` driven by the
stored language.** `theme`/`darkTheme` both derive from the stored `seedColor` (or the
default) via `ColorScheme.fromSeed(seedColor: ..., brightness: ...)`; `themeMode` maps
the stored `AppThemeMode` to Flutter's `ThemeMode`. The `locale` stream needs to be read
synchronously enough to set `MaterialApp.locale` — watch the provider and rebuild, same
pattern any other screen already watches a stream; a brief flash of the default locale
before the first emission is acceptable (matches how every other screen degrades before
its first emission today).

**D5 — Full Indonesian translation via real Flutter l10n, not hardcoded string
replacement, because a language *toggle* was asked for, not a one-way rewrite.** Add
`flutter_localizations` (SDK) and `intl` to `pubspec.yaml`; `l10n.yaml` +
`lib/l10n/app_en.arb` + `lib/l10n/app_id.arb` covering **every user-facing string in
every screen** — titles, labels, hints, tooltips, button text, empty-state text, error
text. Generate via `flutter gen-l10n` (or `flutter pub get` if `generate: true` in
`pubspec.yaml` triggers it) and replace every hardcoded `Text('...')`/`tooltip:
'...'`/etc. across `app/lib/src/**` with `AppLocalizations.of(context)!.xxx`. Translate
naturally into colloquial-but-clear Bahasa Indonesia appropriate for a personal-finance
app — not machine-literal word-for-word — and where a term already has a form in
`docs/workbook.xlsx` (Indonesian column headers, `Deskripsi` text), prefer consistency
with that over inventing a new term for the same concept.

**D6 — Nothing about NFR-4 changes.** Zero refusals still applies everywhere; this issue
adds preference screens and translated strings, not new business rules.

## Out of scope

- The nav redesign (rename/reorder tabs, center Record button) — next issue.
- The category autocomplete picker — next issue.
- Save-flow UX (auto-close, confirmation, icon) — next issue.
- Account-name uniqueness — next issue.
- A full custom color picker (swatches only, per D1).

## Definition of done

Four commands green; the generated `v2→v3` migration test green; both schema snapshots
committed (`v2` unchanged, `v3` new). Widget tests: `SettingsScreen` renders and writes
all four preferences; switching language actually changes rendered text on at least one
other screen (proves the locale is really wired through `MaterialApp`, not just stored);
switching theme mode changes the resolved brightness. `git diff --stat
app/drift_schemas/` shows only the new `v3` snapshot.
