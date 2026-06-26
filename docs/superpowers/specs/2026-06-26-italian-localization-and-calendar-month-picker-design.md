# Carburo — Full Italian localization + calendar month/year picker

Date: 2026-06-26

## Problem

The UI is meant to be entirely in Italian, but three gaps remain:

1. **No localization is configured at all.** `MaterialApp.router` sets no
   `locale` / `localizationsDelegates`, and `flutter_localizations` is not a
   dependency. As a result `table_calendar` falls back to English (weekday row
   and month header), and system widgets (date pickers, etc.) are English too.
2. **Default fuel categories are seeded in English** — `_seedFuelCategories()`
   inserts `"Mine"` / `"Not mine"`. They surface in the fill-up category picker
   and the stats donut (`MieNonMieDonut`). They already exist in installed DBs,
   so changing the seed alone does not fix existing users — a data migration is
   required.
3. **Calendar navigation is slow** — only month-by-month chevrons; no quick jump
   to an arbitrary year/month.

## Design

### 1. it_IT localization (root cause of the "English calendar")

- `pubspec.yaml`: add `flutter_localizations: { sdk: flutter }`.
- `main.dart`: make `main()` async — `WidgetsFlutterBinding.ensureInitialized()`,
  `await initializeDateFormatting('it_IT')`, `Intl.defaultLocale = 'it_IT'`, then
  `runApp`.
- `app.dart` (`MaterialApp.router`): set `locale: const Locale('it', 'IT')`,
  `supportedLocales: const [Locale('it', 'IT')]`, and the three global delegates
  (`GlobalMaterialLocalizations.delegate`, `GlobalWidgetsLocalizations.delegate`,
  `GlobalCupertinoLocalizations.delegate`).
- `calendar_screen.dart`: pass `locale: 'it_IT'` to `TableCalendar` and add a
  `titleTextFormatter` that capitalizes the first letter of the month header
  ("Luglio 2026" rather than the intl default "luglio 2026").

Effect: the whole app renders in Italian in one shot.

### 2. "Mie" / "Non mie" fuel categories

- Seed (`database.dart`): `'Mine'` → `'Mie'`, `'Not mine'` → `'Non mie'` for
  fresh installs.
- Migration `schemaVersion 3 → 4`, block `from < 4`:
  ```sql
  UPDATE categories SET name='Mie'     WHERE name='Mine'     AND kind='fuel';
  UPDATE categories SET name='Non mie' WHERE name='Not mine' AND kind='fuel';
  ```
  Exact-string match preserves any user renames. No DDL/column change.
- Update the `Mine`/`Not mine` references in code comments
  (`extra_sections.dart`, `database.dart`).

### 3. "Vai al mese" combined modal

- Add `onHeaderTapped:` to `TableCalendar` → opens `showDialog` with a
  `_MonthPickerDialog` (`StatefulBuilder`):
  - Top row: `‹  2026  ›` — arrows change the year, clamped to
    `2015 … currentYear + 1` (consistent with `firstDay` / `lastDay`).
  - Below: a 4×3 grid of abbreviated months (Gen…Dic); the active month is
    highlighted.
  - Tapping a month closes the dialog and sets `_focusedDay` **and**
    `_selectedDay` to the **1st of the chosen month** (clamped to `lastDay`), so
    the day-events list below immediately reflects the new month.
- The existing month chevrons stay. No new package — `showDialog` + Material
  widgets only.

## Testing

- `flutter analyze` clean.
- Migration unit test: open a schema-3 DB seeded with `Mine`/`Not mine`, run the
  upgrade to 4, assert they become `Mie`/`Non mie`, and assert a user-renamed
  category is left untouched.
- Light widget test for the modal: tap header → dialog appears → change year →
  tap month → `focusedDay` updated to the 1st of that month.
- Manual on-device check of the it_IT calendar rendering (CI `build-apk`
  validates compilation; locale rendering is eyeballed).

## Version / CI

- Bump `pubspec.yaml` `0.6.0+16` → `0.7.0+17` (user-visible feature).
- `main` is PR-gated; required checks `build-and-test`, `version-check`,
  `build-apk`. Commit identity: zN3utr4l.

## Out of scope

- No category-management UI changes.
- No new dependencies beyond `flutter_localizations` (SDK-bundled).
