# Carburo — Phase 1 (Core) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (the user prefers inline execution, no subagents) to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a working local-first Flutter Android app that lets the user manage vehicles (manual entry), log fuel-ups, see a dashboard with real consumption stats, and import the existing `Consumi.xlsx` history.

**Architecture:** Feature-first + layered. `domain/` (pure models + services, no I/O) ← `data/` (Drift SQLite DB, repositories, Excel importer) ← `features/` (Riverpod-driven UI). The consumption math lives in a pure, heavily-tested `ConsumptionCalculator`.

**Tech Stack:** Flutter (stable), Riverpod 3.x (code-gen), Freezed 3.x, Drift 2.34, go_router 17.x, fl_chart 1.x, `excel`, `intl`. Tests: `flutter_test` + `mocktail` + in-memory Drift.

**Spec:** `docs/superpowers/specs/2026-06-22-carburo-design.md`

## Global Constraints

- Use the **latest stable** version of every dependency (resolve via `flutter pub add`); do not hand-pin older versions. Confirmed majors: Riverpod **3.x**, Freezed **3.x**, Drift **2.34**, go_router **17.x**, fl_chart **1.x**, dio **5.x**.
- Freezed 3.x syntax: `@freezed class X with _$X` for data classes, `@freezed sealed class X with _$X` for unions; add `const X._();` when the class has custom getters/methods.
- Riverpod 3.x code-gen: `@riverpod` annotation, `Ref ref` parameter (not `XRef`), `part 'file.g.dart';`, generated provider is `<name>Provider`.
- Money in EUR, distance in km, volume in liters; stored canonically.
- Android `minSdk 24`, `applicationId io.github.zn3utr4l.carburo`.
- Git identity: `zN3utr4l <zN3utr4l@users.noreply.github.com>` (already configured for `D:\repos\Personal`). Every commit ends with the Co-Authored-By trailer used in the repo's existing commit.
- TDD: failing test → run (fail) → minimal impl → run (pass) → commit. Frequent commits.
- All work is offline/local-first in Phase 1 (no network).

## File Structure (Phase 1)

```
pubspec.yaml                                   # deps + flutter config
analysis_options.yaml                          # lints
build.yaml                                     # build_runner config (drift/freezed/riverpod)
lib/main.dart                                  # entrypoint → ProviderScope(App)
lib/src/
  app/
    app.dart                                   # MaterialApp.router + theme
    router.dart                                # go_router config + shell
    theme.dart                                 # Material 3 light/dark
  core/
    result.dart                                # sealed Result<T> / Failure (freezed)
    formatters.dart                            # currency/number/date/volume formatters
  domain/
    models/
      enums.dart                               # FuelType, SpecSource
      category.dart                            # Category (freezed)
      vehicle.dart                             # Vehicle + VehicleSpecs (freezed)
      fill_up.dart                             # FillUp (freezed)
      consumption_interval.dart                # ConsumptionInterval (freezed + getters)
      vehicle_stats.dart                       # VehicleStats (freezed + getters)
    services/
      consumption_calculator.dart             # pure full-to-full math
      stats_service.dart                       # pure aggregates
    repositories/
      category_repository.dart                 # abstract
      vehicle_repository.dart                  # abstract
      fill_up_repository.dart                  # abstract
  data/
    database/
      tables.dart                              # Drift tables
      database.dart                            # AppDatabase + migration + seed
      connection.dart                          # native opener (path_provider)
      mappers.dart                             # Drift row <-> domain model
    repositories/
      category_repository_impl.dart
      vehicle_repository_impl.dart
      fill_up_repository_impl.dart
    importer/
      excel_importer.dart                      # parse Consumi.xlsx → import result
  providers.dart                               # Riverpod providers: db, repos, services
  features/
    dashboard/
      dashboard_screen.dart
      dashboard_providers.dart
      widgets/stat_card.dart
      widgets/spend_chart.dart
    fillups/
      fill_up_form_screen.dart
      history_screen.dart
      fillup_providers.dart
    vehicles/
      vehicles_screen.dart
      vehicle_form_screen.dart
      vehicle_providers.dart
    settings/
      settings_screen.dart
test/
  domain/consumption_calculator_test.dart
  domain/stats_service_test.dart
  data/database_test.dart
  data/repositories_test.dart
  data/excel_importer_test.dart
  features/fill_up_form_test.dart
  helpers/test_db.dart
  fixtures/consumi_sample.xlsx
```

---

### Task 1: Project scaffold, dependencies, lints, smoke test

**Files:**
- Create: `pubspec.yaml`, `analysis_options.yaml`, `build.yaml`, `lib/main.dart`, `lib/src/app/app.dart`
- Create: `test/smoke_test.dart`
- Create: `.gitignore`

**Interfaces:**
- Produces: `App` widget (root); `main()` wraps it in `ProviderScope`.

- [ ] **Step 1: Create the Flutter project in-place**

Run from `D:\repos\Personal\Carburo`:
```bash
flutter create --org io.github.zn3utr4l --project-name carburo --platforms=android .
```
This generates the Android scaffold without clobbering `docs/`.

- [ ] **Step 2: Add dependencies (latest stable)**

```bash
flutter pub add flutter_riverpod riverpod_annotation go_router fl_chart dio intl drift sqlite3_flutter_libs path_provider path freezed_annotation json_annotation excel
flutter pub add dev:build_runner dev:freezed dev:json_serializable dev:riverpod_generator dev:drift_dev dev:mocktail dev:custom_lint dev:riverpod_lint
```

- [ ] **Step 3: Configure `analysis_options.yaml`**

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  plugins:
    - custom_lint
  exclude:
    - "**/*.freezed.dart"
    - "**/*.g.dart"

linter:
  rules:
    prefer_const_constructors: true
    prefer_final_locals: true
    require_trailing_commas: true
```

- [ ] **Step 4: Create `build.yaml`**

```yaml
targets:
  $default:
    builders:
      drift_dev:
        options:
          store_date_time_values_as_text: true
```

- [ ] **Step 5: Set `minSdk` in `android/app/build.gradle.kts`**

Find `minSdk = flutter.minSdkVersion` and replace with `minSdk = 24`.

- [ ] **Step 6: Write `lib/src/app/app.dart`**

```dart
import 'package:flutter/material.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Carburo',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const Scaffold(body: Center(child: Text('Carburo'))),
    );
  }
}
```

- [ ] **Step 7: Write `lib/main.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/app/app.dart';

void main() {
  runApp(const ProviderScope(child: App()));
}
```

- [ ] **Step 8: Write the smoke test `test/smoke_test.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carburo/src/app/app.dart';

void main() {
  testWidgets('App renders title', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    expect(find.text('Carburo'), findsOneWidget);
  });
}
```

- [ ] **Step 9: Run analyze + test**

Run: `flutter analyze && flutter test`
Expected: analyze clean, smoke test PASS.

- [ ] **Step 10: Commit**

```bash
git add -A
git commit -m "feat: scaffold Flutter app with deps, lints, smoke test"
```

---

### Task 2: Core types — enums + Result/Failure

**Files:**
- Create: `lib/src/domain/models/enums.dart`
- Create: `lib/src/core/result.dart`
- Test: `test/domain/result_test.dart`

**Interfaces:**
- Produces: `enum FuelType { petrol, diesel, lpg, cng, hybrid, electric }`, `enum SpecSource { carquery, manual }`.
- Produces: sealed `Result<T>` with `Ok<T>(value)` and `Err<T>(failure)`; `Failure(message)`.

- [ ] **Step 1: Write `lib/src/domain/models/enums.dart`**

```dart
enum FuelType { petrol, diesel, lpg, cng, hybrid, electric }

enum SpecSource { carquery, manual }
```

- [ ] **Step 2: Write the failing test `test/domain/result_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:carburo/src/core/result.dart';

void main() {
  test('Ok carries a value, Err carries a failure', () {
    const Result<int> ok = Ok(42);
    const Result<int> err = Err(Failure('boom'));

    expect(switch (ok) { Ok(:final value) => value, Err() => -1 }, 42);
    expect(switch (err) { Ok() => '', Err(:final failure) => failure.message }, 'boom');
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/domain/result_test.dart`
Expected: FAIL (`result.dart` not found).

- [ ] **Step 4: Write `lib/src/core/result.dart`**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'result.freezed.dart';

@freezed
class Failure with _$Failure {
  const factory Failure(String message) = _Failure;
}

sealed class Result<T> {
  const Result();
}

class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}
```

- [ ] **Step 5: Generate code**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: creates `result.freezed.dart`.

- [ ] **Step 6: Run test to verify it passes**

Run: `flutter test test/domain/result_test.dart`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "feat: add domain enums and Result/Failure types"
```

---

### Task 3: Domain models — Category, Vehicle/VehicleSpecs, FillUp

**Files:**
- Create: `lib/src/domain/models/category.dart`, `vehicle.dart`, `fill_up.dart`
- Test: `test/domain/models_test.dart`

**Interfaces:**
- Produces `Category({int id, String name, int color, bool isDefault})` with `fromJson`/`toJson`.
- Produces `VehicleSpecs({double? tankCapacityL, double? mfrConsumption, double? mfrRangeKm, int? powerPs, SpecSource source, String? catalogRef})`.
- Produces `Vehicle({int id, String make, String model, int? year, String? trim, FuelType fuelType, String? plate, int colorTag, bool isDefault, VehicleSpecs specs, DateTime createdAt, DateTime updatedAt})`.
- Produces `FillUp({int id, int vehicleId, DateTime date, double amount, double? liters, double odometer, bool isFull, double? rangeKm, String? station, int categoryId, String? note, double? latitude, double? longitude, String? receiptPhotoPath, DateTime createdAt, DateTime updatedAt})`.

- [ ] **Step 1: Write the failing test `test/domain/models_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:carburo/src/domain/models/category.dart';
import 'package:carburo/src/domain/models/vehicle.dart';
import 'package:carburo/src/domain/models/fill_up.dart';
import 'package:carburo/src/domain/models/enums.dart';

void main() {
  test('Vehicle has default empty specs and round-trips JSON', () {
    final v = Vehicle(
      id: 1,
      make: 'Renault',
      model: 'Clio',
      fuelType: FuelType.hybrid,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
    expect(v.specs.source, SpecSource.manual);
    expect(Vehicle.fromJson(v.toJson()), v);
  });

  test('FillUp allows null liters and round-trips JSON', () {
    final f = FillUp(
      id: 1,
      vehicleId: 1,
      date: DateTime(2026, 1, 1),
      amount: 40,
      odometer: 1000,
      categoryId: 1,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
    expect(f.liters, isNull);
    expect(f.isFull, isTrue);
    expect(FillUp.fromJson(f.toJson()), f);
  });

  test('Category round-trips JSON', () {
    const c = Category(id: 1, name: 'Mine', color: 0xFF4CAF50, isDefault: true);
    expect(Category.fromJson(c.toJson()), c);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/domain/models_test.dart`
Expected: FAIL (model files missing).

- [ ] **Step 3: Write `lib/src/domain/models/category.dart`**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'category.freezed.dart';
part 'category.g.dart';

@freezed
class Category with _$Category {
  const factory Category({
    required int id,
    required String name,
    required int color,
    @Default(false) bool isDefault,
  }) = _Category;

  factory Category.fromJson(Map<String, Object?> json) => _$CategoryFromJson(json);
}
```

- [ ] **Step 4: Write `lib/src/domain/models/vehicle.dart`**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'enums.dart';

part 'vehicle.freezed.dart';
part 'vehicle.g.dart';

@freezed
class VehicleSpecs with _$VehicleSpecs {
  const factory VehicleSpecs({
    double? tankCapacityL,
    double? mfrConsumption,
    double? mfrRangeKm,
    int? powerPs,
    @Default(SpecSource.manual) SpecSource source,
    String? catalogRef,
  }) = _VehicleSpecs;

  factory VehicleSpecs.fromJson(Map<String, Object?> json) =>
      _$VehicleSpecsFromJson(json);
}

@freezed
class Vehicle with _$Vehicle {
  const factory Vehicle({
    required int id,
    required String make,
    required String model,
    int? year,
    String? trim,
    required FuelType fuelType,
    String? plate,
    @Default(0) int colorTag,
    @Default(false) bool isDefault,
    @Default(VehicleSpecs()) VehicleSpecs specs,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Vehicle;

  factory Vehicle.fromJson(Map<String, Object?> json) => _$VehicleFromJson(json);
}
```

- [ ] **Step 5: Write `lib/src/domain/models/fill_up.dart`**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'fill_up.freezed.dart';
part 'fill_up.g.dart';

@freezed
class FillUp with _$FillUp {
  const factory FillUp({
    required int id,
    required int vehicleId,
    required DateTime date,
    required double amount,
    double? liters,
    required double odometer,
    @Default(true) bool isFull,
    double? rangeKm,
    String? station,
    required int categoryId,
    String? note,
    double? latitude,
    double? longitude,
    String? receiptPhotoPath,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _FillUp;

  factory FillUp.fromJson(Map<String, Object?> json) => _$FillUpFromJson(json);
}
```

- [ ] **Step 6: Generate code + run test**

Run: `dart run build_runner build --delete-conflicting-outputs && flutter test test/domain/models_test.dart`
Expected: PASS (all three tests).

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "feat: add Category, Vehicle/VehicleSpecs, FillUp domain models"
```

---

### Task 4: ConsumptionCalculator (pure full-to-full math)

This is the heart of the app — test it hard.

**Files:**
- Create: `lib/src/domain/models/consumption_interval.dart`
- Create: `lib/src/domain/services/consumption_calculator.dart`
- Test: `test/domain/consumption_calculator_test.dart`

**Interfaces:**
- Produces `ConsumptionInterval({int fromFillUpId, int toFillUpId, double distanceKm, double liters, double cost})` with getters `litersPer100Km`, `kmPerLiter`, `costPer100Km`.
- Produces `class ConsumptionCalculator { const ConsumptionCalculator(); List<ConsumptionInterval> intervals(List<FillUp> fills); }`.

- [ ] **Step 1: Write `lib/src/domain/models/consumption_interval.dart`**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'consumption_interval.freezed.dart';

@freezed
class ConsumptionInterval with _$ConsumptionInterval {
  const factory ConsumptionInterval({
    required int fromFillUpId,
    required int toFillUpId,
    required double distanceKm,
    required double liters,
    required double cost,
  }) = _ConsumptionInterval;

  const ConsumptionInterval._();

  double get litersPer100Km => liters / distanceKm * 100;
  double get kmPerLiter => distanceKm / liters;
  double get costPer100Km => cost / distanceKm * 100;
}
```

- [ ] **Step 2: Write the failing test `test/domain/consumption_calculator_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:carburo/src/domain/models/fill_up.dart';
import 'package:carburo/src/domain/services/consumption_calculator.dart';

FillUp fill({
  required int id,
  required double odometer,
  double? liters,
  double amount = 0,
  bool isFull = true,
}) =>
    FillUp(
      id: id,
      vehicleId: 1,
      date: DateTime(2026, 1, id),
      amount: amount,
      liters: liters,
      odometer: odometer,
      isFull: isFull,
      categoryId: 1,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

void main() {
  const calc = ConsumptionCalculator();

  test('two full tanks → one interval with correct math', () {
    final result = calc.intervals([
      fill(id: 1, odometer: 1000, liters: 30, amount: 60),
      fill(id: 2, odometer: 1500, liters: 40, amount: 80),
    ]);
    expect(result, hasLength(1));
    final i = result.single;
    expect(i.distanceKm, 500);
    expect(i.liters, 40); // liters added at the closing full tank
    expect(i.cost, 80);
    expect(i.litersPer100Km, closeTo(8.0, 1e-9));
    expect(i.kmPerLiter, closeTo(12.5, 1e-9));
    expect(i.costPer100Km, closeTo(16.0, 1e-9));
  });

  test('partial fill between two fulls accumulates into the interval', () {
    final result = calc.intervals([
      fill(id: 1, odometer: 1000, liters: 30, amount: 60),
      fill(id: 2, odometer: 1200, liters: 10, amount: 20, isFull: false),
      fill(id: 3, odometer: 1500, liters: 30, amount: 60),
    ]);
    expect(result, hasLength(1));
    final i = result.single;
    expect(i.distanceKm, 500);
    expect(i.liters, 40); // 10 (partial) + 30 (closing full)
    expect(i.cost, 80);
  });

  test('interval containing a null-liters fill is skipped', () {
    final result = calc.intervals([
      fill(id: 1, odometer: 1000, liters: 30),
      fill(id: 2, odometer: 1200, liters: null, isFull: false),
      fill(id: 3, odometer: 1500, liters: 30),
    ]);
    expect(result, isEmpty);
  });

  test('single fill-up produces no interval', () {
    expect(calc.intervals([fill(id: 1, odometer: 1000, liters: 30)]), isEmpty);
  });

  test('unordered input is sorted by odometer', () {
    final result = calc.intervals([
      fill(id: 2, odometer: 1500, liters: 40, amount: 80),
      fill(id: 1, odometer: 1000, liters: 30, amount: 60),
    ]);
    expect(result.single.fromFillUpId, 1);
    expect(result.single.toFillUpId, 2);
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/domain/consumption_calculator_test.dart`
Expected: FAIL (calculator missing).

- [ ] **Step 4: Generate the interval model**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: creates `consumption_interval.freezed.dart`.

- [ ] **Step 5: Write `lib/src/domain/services/consumption_calculator.dart`**

```dart
import '../models/fill_up.dart';
import '../models/consumption_interval.dart';

/// Computes fuel consumption between consecutive *full* tanks.
/// Partial fills accumulate into the next full-to-full interval.
class ConsumptionCalculator {
  const ConsumptionCalculator();

  List<ConsumptionInterval> intervals(List<FillUp> fills) {
    final sorted = [...fills]..sort((a, b) => a.odometer.compareTo(b.odometer));
    final result = <ConsumptionInterval>[];

    FillUp? lastFull;
    double liters = 0;
    double cost = 0;
    bool hasNullLiters = false;

    for (final f in sorted) {
      if (lastFull != null) {
        if (f.liters == null) {
          hasNullLiters = true;
        } else {
          liters += f.liters!;
        }
        cost += f.amount;
      }
      if (f.isFull) {
        final isValid = lastFull != null &&
            f.odometer > lastFull.odometer &&
            !hasNullLiters &&
            liters > 0;
        if (isValid) {
          result.add(
            ConsumptionInterval(
              fromFillUpId: lastFull!.id,
              toFillUpId: f.id,
              distanceKm: f.odometer - lastFull.odometer,
              liters: liters,
              cost: cost,
            ),
          );
        }
        lastFull = f;
        liters = 0;
        cost = 0;
        hasNullLiters = false;
      }
    }
    return result;
  }
}
```

- [ ] **Step 6: Run test to verify it passes**

Run: `flutter test test/domain/consumption_calculator_test.dart`
Expected: PASS (all cases).

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "feat: add ConsumptionCalculator with full-to-full intervals"
```

---

### Task 5: StatsService (pure aggregates)

**Files:**
- Create: `lib/src/domain/models/vehicle_stats.dart`
- Create: `lib/src/domain/services/stats_service.dart`
- Test: `test/domain/stats_service_test.dart`

**Interfaces:**
- Produces `VehicleStats({double totalSpend, double? avgPricePerLiter, double? avgConsumption, double totalKm, DateTime? lastFillDate, Map<int,double> spendByCategory, int fillUpCount})`.
- Produces `class StatsService { const StatsService([ConsumptionCalculator calc]); VehicleStats compute(List<FillUp> fills); }`.
  - `avgPricePerLiter` = sum(amount of fills with liters) / sum(liters); null if no liters.
  - `avgConsumption` (L/100km) = sum(interval liters) / sum(interval distance) * 100; null if no valid interval.
  - `totalKm` = maxOdometer − minOdometer; 0 if < 2 fills.

- [ ] **Step 1: Write `lib/src/domain/models/vehicle_stats.dart`**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'vehicle_stats.freezed.dart';

@freezed
class VehicleStats with _$VehicleStats {
  const factory VehicleStats({
    @Default(0) double totalSpend,
    double? avgPricePerLiter,
    double? avgConsumption,
    @Default(0) double totalKm,
    DateTime? lastFillDate,
    @Default(<int, double>{}) Map<int, double> spendByCategory,
    @Default(0) int fillUpCount,
  }) = _VehicleStats;
}
```

- [ ] **Step 2: Write the failing test `test/domain/stats_service_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:carburo/src/domain/models/fill_up.dart';
import 'package:carburo/src/domain/services/stats_service.dart';

FillUp fill({
  required int id,
  required double odometer,
  double? liters,
  double amount = 0,
  int categoryId = 1,
  bool isFull = true,
}) =>
    FillUp(
      id: id,
      vehicleId: 1,
      date: DateTime(2026, 1, id),
      amount: amount,
      liters: liters,
      odometer: odometer,
      isFull: isFull,
      categoryId: categoryId,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

void main() {
  const service = StatsService();

  test('empty input → zeroed stats', () {
    final s = service.compute([]);
    expect(s.totalSpend, 0);
    expect(s.avgPricePerLiter, isNull);
    expect(s.fillUpCount, 0);
  });

  test('aggregates spend, price/L, consumption, km, category split', () {
    final s = service.compute([
      fill(id: 1, odometer: 1000, liters: 30, amount: 60, categoryId: 1),
      fill(id: 2, odometer: 1500, liters: 40, amount: 90, categoryId: 2),
    ]);
    expect(s.totalSpend, 150);
    expect(s.fillUpCount, 2);
    expect(s.totalKm, 500);
    // price/L = (60+90)/(30+40) = 150/70
    expect(s.avgPricePerLiter, closeTo(150 / 70, 1e-9));
    // consumption interval: liters 40 over 500 km → 8 L/100km
    expect(s.avgConsumption, closeTo(8.0, 1e-9));
    expect(s.spendByCategory[1], 60);
    expect(s.spendByCategory[2], 90);
    expect(s.lastFillDate, DateTime(2026, 1, 2));
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/domain/stats_service_test.dart`
Expected: FAIL.

- [ ] **Step 4: Generate model + write `lib/src/domain/services/stats_service.dart`**

```dart
import '../models/fill_up.dart';
import '../models/vehicle_stats.dart';
import 'consumption_calculator.dart';

class StatsService {
  const StatsService([this._calc = const ConsumptionCalculator()]);

  final ConsumptionCalculator _calc;

  VehicleStats compute(List<FillUp> fills) {
    if (fills.isEmpty) return const VehicleStats();

    final sorted = [...fills]..sort((a, b) => a.odometer.compareTo(b.odometer));

    var totalSpend = 0.0;
    var litersWithPrice = 0.0;
    var costWithPrice = 0.0;
    final byCategory = <int, double>{};
    DateTime? lastDate;

    for (final f in sorted) {
      totalSpend += f.amount;
      byCategory.update(f.categoryId, (v) => v + f.amount, ifAbsent: () => f.amount);
      if (f.liters != null) {
        litersWithPrice += f.liters!;
        costWithPrice += f.amount;
      }
      if (lastDate == null || f.date.isAfter(lastDate)) lastDate = f.date;
    }

    final intervals = _calc.intervals(sorted);
    double? avgConsumption;
    if (intervals.isNotEmpty) {
      final liters = intervals.fold(0.0, (s, i) => s + i.liters);
      final distance = intervals.fold(0.0, (s, i) => s + i.distanceKm);
      avgConsumption = liters / distance * 100;
    }

    return VehicleStats(
      totalSpend: totalSpend,
      avgPricePerLiter: litersWithPrice > 0 ? costWithPrice / litersWithPrice : null,
      avgConsumption: avgConsumption,
      totalKm: sorted.last.odometer - sorted.first.odometer,
      lastFillDate: lastDate,
      spendByCategory: byCategory,
      fillUpCount: fills.length,
    );
  }
}
```

- [ ] **Step 5: Generate + run test**

Run: `dart run build_runner build --delete-conflicting-outputs && flutter test test/domain/stats_service_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat: add StatsService aggregates"
```

---

### Task 6: Drift database — tables, migration, seed, mappers

**Files:**
- Create: `lib/src/data/database/tables.dart`, `database.dart`, `connection.dart`, `mappers.dart`
- Create: `test/helpers/test_db.dart`
- Test: `test/data/database_test.dart`

**Interfaces:**
- Produces Drift tables `Categories`, `Vehicles`, `FillUps` and `AppDatabase` with generated companions and DAOs.
- Produces `AppDatabase.forTesting(QueryExecutor)` and `openConnection()` (native, via path_provider).
- Produces mapper extensions: `VehicleData.toDomain()`, `FillUpData.toDomain()`, `CategoryData.toDomain()`, and domain `.toCompanion()` helpers.
- `onCreate` seeds categories: `Mine` (`0xFF4CAF50`, default) and `Not mine` (`0xFF9E9E9E`); enables `PRAGMA foreign_keys`.

- [ ] **Step 1: Write `lib/src/data/database/tables.dart`**

```dart
import 'package:drift/drift.dart';

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get color => integer()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
}

class Vehicles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get make => text()();
  TextColumn get model => text()();
  IntColumn get year => integer().nullable()();
  TextColumn get trim => text().nullable()();
  TextColumn get fuelType => text()();
  TextColumn get plate => text().nullable()();
  IntColumn get colorTag => integer().withDefault(const Constant(0))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  RealColumn get tankCapacityL => real().nullable()();
  RealColumn get mfrConsumption => real().nullable()();
  RealColumn get mfrRangeKm => real().nullable()();
  IntColumn get powerPs => integer().nullable()();
  TextColumn get specSource => text().withDefault(const Constant('manual'))();
  TextColumn get catalogRef => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

class FillUps extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get vehicleId =>
      integer().references(Vehicles, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get date => dateTime()();
  RealColumn get amount => real()();
  RealColumn get liters => real().nullable()();
  RealColumn get odometer => real()();
  BoolColumn get isFull => boolean().withDefault(const Constant(true))();
  RealColumn get rangeKm => real().nullable()();
  TextColumn get station => text().nullable()();
  IntColumn get categoryId => integer().references(Categories, #id)();
  TextColumn get note => text().nullable()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  TextColumn get receiptPhotoPath => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
```

- [ ] **Step 2: Write `lib/src/data/database/database.dart`**

```dart
import 'package:drift/drift.dart';
import 'tables.dart';
import 'connection.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Categories, Vehicles, FillUps])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await into(categories).insert(
            CategoriesCompanion.insert(
              name: 'Mine',
              color: 0xFF4CAF50,
              isDefault: const Value(true),
            ),
          );
          await into(categories).insert(
            CategoriesCompanion.insert(name: 'Not mine', color: 0xFF9E9E9E),
          );
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
```

- [ ] **Step 3: Write `lib/src/data/database/connection.dart`**

```dart
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'carburo.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
```

- [ ] **Step 4: Write `lib/src/data/database/mappers.dart`**

```dart
import 'package:drift/drift.dart';
import '../../domain/models/category.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/fill_up.dart';
import '../../domain/models/vehicle.dart';
import 'database.dart';

FuelType _fuel(String s) =>
    FuelType.values.firstWhere((e) => e.name == s, orElse: () => FuelType.petrol);
SpecSource _source(String s) =>
    SpecSource.values.firstWhere((e) => e.name == s, orElse: () => SpecSource.manual);

extension CategoryMapper on Category {
  CategoriesCompanion toCompanion() => CategoriesCompanion(
        id: id == 0 ? const Value.absent() : Value(id),
        name: Value(name),
        color: Value(color),
        isDefault: Value(isDefault),
      );
}

extension CategoryRowMapper on CategoryData {
  Category toDomain() =>
      Category(id: id, name: name, color: color, isDefault: isDefault);
}

extension VehicleMapper on Vehicle {
  VehiclesCompanion toCompanion() => VehiclesCompanion(
        id: id == 0 ? const Value.absent() : Value(id),
        make: Value(make),
        model: Value(model),
        year: Value(year),
        trim: Value(trim),
        fuelType: Value(fuelType.name),
        plate: Value(plate),
        colorTag: Value(colorTag),
        isDefault: Value(isDefault),
        tankCapacityL: Value(specs.tankCapacityL),
        mfrConsumption: Value(specs.mfrConsumption),
        mfrRangeKm: Value(specs.mfrRangeKm),
        powerPs: Value(specs.powerPs),
        specSource: Value(specs.source.name),
        catalogRef: Value(specs.catalogRef),
        createdAt: Value(createdAt),
        updatedAt: Value(updatedAt),
      );
}

extension VehicleRowMapper on VehicleData {
  Vehicle toDomain() => Vehicle(
        id: id,
        make: make,
        model: model,
        year: year,
        trim: trim,
        fuelType: _fuel(fuelType),
        plate: plate,
        colorTag: colorTag,
        isDefault: isDefault,
        specs: VehicleSpecs(
          tankCapacityL: tankCapacityL,
          mfrConsumption: mfrConsumption,
          mfrRangeKm: mfrRangeKm,
          powerPs: powerPs,
          source: _source(specSource),
          catalogRef: catalogRef,
        ),
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

extension FillUpMapper on FillUp {
  FillUpsCompanion toCompanion() => FillUpsCompanion(
        id: id == 0 ? const Value.absent() : Value(id),
        vehicleId: Value(vehicleId),
        date: Value(date),
        amount: Value(amount),
        liters: Value(liters),
        odometer: Value(odometer),
        isFull: Value(isFull),
        rangeKm: Value(rangeKm),
        station: Value(station),
        categoryId: Value(categoryId),
        note: Value(note),
        latitude: Value(latitude),
        longitude: Value(longitude),
        receiptPhotoPath: Value(receiptPhotoPath),
        createdAt: Value(createdAt),
        updatedAt: Value(updatedAt),
      );
}

extension FillUpRowMapper on FillUpData {
  FillUp toDomain() => FillUp(
        id: id,
        vehicleId: vehicleId,
        date: date,
        amount: amount,
        liters: liters,
        odometer: odometer,
        isFull: isFull,
        rangeKm: rangeKm,
        station: station,
        categoryId: categoryId,
        note: note,
        latitude: latitude,
        longitude: longitude,
        receiptPhotoPath: receiptPhotoPath,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
```

> Note: Drift generates row classes named `CategoryData`, `VehicleData`, `FillUpData` (singular of the table name). If generation produces different names, update the extensions to match the generated names.

- [ ] **Step 5: Write `test/helpers/test_db.dart`**

```dart
import 'package:drift/native.dart';
import 'package:carburo/src/data/database/database.dart';

AppDatabase makeTestDb() => AppDatabase.forTesting(NativeDatabase.memory());
```

- [ ] **Step 6: Write the failing test `test/data/database_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_db.dart';

void main() {
  test('onCreate seeds two categories with a default', () async {
    final db = makeTestDb();
    addTearDown(db.close);

    final cats = await db.select(db.categories).get();
    expect(cats, hasLength(2));
    expect(cats.where((c) => c.isDefault), hasLength(1));
    expect(cats.map((c) => c.name), containsAll(['Mine', 'Not mine']));
  });
}
```

- [ ] **Step 7: Generate code, run test**

Run: `dart run build_runner build --delete-conflicting-outputs && flutter test test/data/database_test.dart`
Expected: PASS. (Fix mapper row-class names per the note if analyze complains.)

- [ ] **Step 8: Commit**

```bash
git add -A
git commit -m "feat: add Drift database, tables, seed and mappers"
```

---

### Task 7: Repositories over Drift

**Files:**
- Create: `lib/src/domain/repositories/category_repository.dart`, `vehicle_repository.dart`, `fill_up_repository.dart`
- Create: `lib/src/data/repositories/category_repository_impl.dart`, `vehicle_repository_impl.dart`, `fill_up_repository_impl.dart`
- Test: `test/data/repositories_test.dart`

**Interfaces:**
- `abstract class CategoryRepository { Future<List<Category>> all(); }`
- `abstract class VehicleRepository { Future<List<Vehicle>> all(); Future<Vehicle> getById(int id); Future<int> upsert(Vehicle v); Future<void> delete(int id); Future<Vehicle?> defaultVehicle(); }`
- `abstract class FillUpRepository { Future<List<FillUp>> forVehicle(int vehicleId); Future<int> upsert(FillUp f); Future<void> delete(int id); }`
- Impls take an `AppDatabase` and use the Task 6 mappers.

- [ ] **Step 1: Write the abstract repositories**

`lib/src/domain/repositories/category_repository.dart`:
```dart
import '../models/category.dart';

abstract class CategoryRepository {
  Future<List<Category>> all();
}
```

`lib/src/domain/repositories/vehicle_repository.dart`:
```dart
import '../models/vehicle.dart';

abstract class VehicleRepository {
  Future<List<Vehicle>> all();
  Future<Vehicle> getById(int id);
  Future<int> upsert(Vehicle vehicle);
  Future<void> delete(int id);
  Future<Vehicle?> defaultVehicle();
}
```

`lib/src/domain/repositories/fill_up_repository.dart`:
```dart
import '../models/fill_up.dart';

abstract class FillUpRepository {
  Future<List<FillUp>> forVehicle(int vehicleId);
  Future<int> upsert(FillUp fillUp);
  Future<void> delete(int id);
}
```

- [ ] **Step 2: Write the failing test `test/data/repositories_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:carburo/src/data/repositories/category_repository_impl.dart';
import 'package:carburo/src/data/repositories/vehicle_repository_impl.dart';
import 'package:carburo/src/data/repositories/fill_up_repository_impl.dart';
import 'package:carburo/src/domain/models/enums.dart';
import 'package:carburo/src/domain/models/fill_up.dart';
import 'package:carburo/src/domain/models/vehicle.dart';
import '../helpers/test_db.dart';

void main() {
  test('vehicle upsert/getById/default + fill-up CRUD round-trip', () async {
    final db = makeTestDb();
    addTearDown(db.close);
    final cats = CategoryRepositoryImpl(db);
    final vehicles = VehicleRepositoryImpl(db);
    final fills = FillUpRepositoryImpl(db);

    final defaultCat = (await cats.all()).firstWhere((c) => c.isDefault);

    final id = await vehicles.upsert(
      Vehicle(
        id: 0,
        make: 'Renault',
        model: 'Clio',
        fuelType: FuelType.hybrid,
        isDefault: true,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    );
    expect((await vehicles.getById(id)).make, 'Renault');
    expect((await vehicles.defaultVehicle())!.id, id);

    final fid = await fills.upsert(
      FillUp(
        id: 0,
        vehicleId: id,
        date: DateTime(2026, 1, 1),
        amount: 40,
        liters: 30,
        odometer: 1000,
        categoryId: defaultCat.id,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    );
    expect(await fills.forVehicle(id), hasLength(1));

    await fills.delete(fid);
    expect(await fills.forVehicle(id), isEmpty);
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/data/repositories_test.dart`
Expected: FAIL (impls missing).

- [ ] **Step 4: Write `lib/src/data/repositories/category_repository_impl.dart`**

```dart
import 'package:drift/drift.dart';
import '../../domain/models/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../database/database.dart';
import '../database/mappers.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl(this._db);
  final AppDatabase _db;

  @override
  Future<List<Category>> all() async {
    final rows = await _db.select(_db.categories).get();
    return rows.map((r) => r.toDomain()).toList();
  }
}
```

- [ ] **Step 5: Write `lib/src/data/repositories/vehicle_repository_impl.dart`**

```dart
import 'package:drift/drift.dart';
import '../../domain/models/vehicle.dart';
import '../../domain/repositories/vehicle_repository.dart';
import '../database/database.dart';
import '../database/mappers.dart';

class VehicleRepositoryImpl implements VehicleRepository {
  VehicleRepositoryImpl(this._db);
  final AppDatabase _db;

  @override
  Future<List<Vehicle>> all() async {
    final rows = await _db.select(_db.vehicles).get();
    return rows.map((r) => r.toDomain()).toList();
  }

  @override
  Future<Vehicle> getById(int id) async {
    final row = await (_db.select(_db.vehicles)..where((t) => t.id.equals(id)))
        .getSingle();
    return row.toDomain();
  }

  @override
  Future<int> upsert(Vehicle vehicle) {
    return _db.into(_db.vehicles).insertOnConflictUpdate(vehicle.toCompanion());
  }

  @override
  Future<void> delete(int id) async {
    await (_db.delete(_db.vehicles)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<Vehicle?> defaultVehicle() async {
    final row = await (_db.select(_db.vehicles)
          ..where((t) => t.isDefault.equals(true))
          ..limit(1))
        .getSingleOrNull();
    return row?.toDomain();
  }
}
```

- [ ] **Step 6: Write `lib/src/data/repositories/fill_up_repository_impl.dart`**

```dart
import 'package:drift/drift.dart';
import '../../domain/models/fill_up.dart';
import '../../domain/repositories/fill_up_repository.dart';
import '../database/database.dart';
import '../database/mappers.dart';

class FillUpRepositoryImpl implements FillUpRepository {
  FillUpRepositoryImpl(this._db);
  final AppDatabase _db;

  @override
  Future<List<FillUp>> forVehicle(int vehicleId) async {
    final rows = await (_db.select(_db.fillUps)
          ..where((t) => t.vehicleId.equals(vehicleId))
          ..orderBy([(t) => OrderingTerm.asc(t.odometer)]))
        .get();
    return rows.map((r) => r.toDomain()).toList();
  }

  @override
  Future<int> upsert(FillUp fillUp) {
    return _db.into(_db.fillUps).insertOnConflictUpdate(fillUp.toCompanion());
  }

  @override
  Future<void> delete(int id) async {
    await (_db.delete(_db.fillUps)..where((t) => t.id.equals(id))).go();
  }
}
```

- [ ] **Step 7: Run test to verify it passes**

Run: `flutter test test/data/repositories_test.dart`
Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add -A
git commit -m "feat: add Drift-backed repositories with CRUD"
```

---

### Task 8: Riverpod providers wiring

**Files:**
- Create: `lib/src/providers.dart`
- Test: `test/providers_test.dart`

**Interfaces:**
- Produces `appDatabaseProvider` (`AppDatabase`, keepAlive, disposes db), `categoryRepositoryProvider`, `vehicleRepositoryProvider`, `fillUpRepositoryProvider`, `statsServiceProvider`.

- [ ] **Step 1: Write `lib/src/providers.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'data/database/database.dart';
import 'data/repositories/category_repository_impl.dart';
import 'data/repositories/fill_up_repository_impl.dart';
import 'data/repositories/vehicle_repository_impl.dart';
import 'domain/repositories/category_repository.dart';
import 'domain/repositories/fill_up_repository.dart';
import 'domain/repositories/vehicle_repository.dart';
import 'domain/services/stats_service.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}

@Riverpod(keepAlive: true)
CategoryRepository categoryRepository(Ref ref) =>
    CategoryRepositoryImpl(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
VehicleRepository vehicleRepository(Ref ref) =>
    VehicleRepositoryImpl(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
FillUpRepository fillUpRepository(Ref ref) =>
    FillUpRepositoryImpl(ref.watch(appDatabaseProvider));

@riverpod
StatsService statsService(Ref ref) => const StatsService();
```

- [ ] **Step 2: Write the failing test `test/providers_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carburo/src/providers.dart';
import 'helpers/test_db.dart';

void main() {
  test('repositories resolve and category seed is reachable', () async {
    final db = makeTestDb();
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    addTearDown(db.close);

    final cats = await container.read(categoryRepositoryProvider).all();
    expect(cats, hasLength(2));
  });
}
```

- [ ] **Step 3: Generate code, run test**

Run: `dart run build_runner build --delete-conflicting-outputs && flutter test test/providers_test.dart`
Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "feat: wire Riverpod providers for db, repos and services"
```

---

### Task 9: Vehicles feature — list + manual add/edit form

**Files:**
- Create: `lib/src/core/formatters.dart`
- Create: `lib/src/features/vehicles/vehicle_providers.dart`
- Create: `lib/src/features/vehicles/vehicles_screen.dart`
- Create: `lib/src/features/vehicles/vehicle_form_screen.dart`
- Test: `test/features/vehicles_test.dart`

**Interfaces:**
- Produces `vehiclesProvider` (`FutureProvider<List<Vehicle>>`).
- Produces `VehiclesScreen` (lists vehicles, FAB → form) and `VehicleFormScreen({Vehicle? initial})` (manual make/model/year/trim/fuelType/specs; saves via repo then invalidates `vehiclesProvider`).
- Produces formatters: `fmtEuro`, `fmtLiters`, `fmtKm`, `fmtConsumption`, `fmtDate`.

- [ ] **Step 1: Write `lib/src/core/formatters.dart`**

```dart
import 'package:intl/intl.dart';

final _euro = NumberFormat.currency(locale: 'it_IT', symbol: '€');
final _num1 = NumberFormat('#,##0.0', 'it_IT');
final _num0 = NumberFormat('#,##0', 'it_IT');
final _date = DateFormat('dd/MM/yyyy', 'it_IT');

String fmtEuro(num v) => _euro.format(v);
String fmtLiters(num v) => '${_num1.format(v)} L';
String fmtKm(num v) => '${_num0.format(v)} km';
String fmtConsumption(num v) => '${_num1.format(v)} L/100km';
String fmtDate(DateTime d) => _date.format(d);
```

- [ ] **Step 2: Write `lib/src/features/vehicles/vehicle_providers.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/vehicle.dart';
import '../../providers.dart';

part 'vehicle_providers.g.dart';

@riverpod
Future<List<Vehicle>> vehicles(Ref ref) =>
    ref.watch(vehicleRepositoryProvider).all();
```

- [ ] **Step 3: Write the failing test `test/features/vehicles_test.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carburo/src/features/vehicles/vehicles_screen.dart';
import 'package:carburo/src/providers.dart';
import '../helpers/test_db.dart';

void main() {
  testWidgets('VehiclesScreen shows empty state then a saved vehicle', (tester) async {
    final db = makeTestDb();
    addTearDown(db.close);
    await db.into(db.vehicles).insert(
          db.vehicles.createCompanion(false).copyWith(),
        );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: VehiclesScreen()),
      ),
    );
    await tester.pumpAndSettle();
    // The seeded insert above is illustrative; assert the screen renders.
    expect(find.byType(VehiclesScreen), findsOneWidget);
  });
}
```

> Note: replace the illustrative insert with a real vehicle via `VehicleRepositoryImpl(db).upsert(...)` to assert its make appears in the list. Keep the test focused on "list renders saved vehicles".

- [ ] **Step 4: Run test to verify it fails**

Run: `flutter test test/features/vehicles_test.dart`
Expected: FAIL (screen missing).

- [ ] **Step 5: Write `lib/src/features/vehicles/vehicles_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'vehicle_providers.dart';
import 'vehicle_form_screen.dart';

class VehiclesScreen extends ConsumerWidget {
  const VehiclesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(vehiclesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Veicoli')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const VehicleFormScreen()),
        ),
        child: const Icon(Icons.add),
      ),
      body: vehiclesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Errore: $e')),
        data: (vehicles) => vehicles.isEmpty
            ? const Center(child: Text('Nessun veicolo. Aggiungine uno.'))
            : ListView(
                children: [
                  for (final v in vehicles)
                    ListTile(
                      leading: const Icon(Icons.directions_car),
                      title: Text('${v.make} ${v.model}'),
                      subtitle: Text(v.trim ?? ''),
                      trailing: v.isDefault ? const Icon(Icons.star) : null,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => VehicleFormScreen(initial: v),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
```

- [ ] **Step 6: Write `lib/src/features/vehicles/vehicle_form_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/vehicle.dart';
import '../../providers.dart';
import 'vehicle_providers.dart';

class VehicleFormScreen extends ConsumerStatefulWidget {
  const VehicleFormScreen({super.key, this.initial});
  final Vehicle? initial;

  @override
  ConsumerState<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends ConsumerState<VehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _make = TextEditingController(text: widget.initial?.make);
  late final _model = TextEditingController(text: widget.initial?.model);
  late final _tank = TextEditingController(
    text: widget.initial?.specs.tankCapacityL?.toString(),
  );
  late FuelType _fuel = widget.initial?.fuelType ?? FuelType.petrol;
  late bool _isDefault = widget.initial?.isDefault ?? false;

  @override
  void dispose() {
    _make.dispose();
    _model.dispose();
    _tank.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final now = DateTime.now();
    final base = widget.initial;
    final vehicle = Vehicle(
      id: base?.id ?? 0,
      make: _make.text.trim(),
      model: _model.text.trim(),
      year: base?.year,
      trim: base?.trim,
      fuelType: _fuel,
      isDefault: _isDefault,
      specs: (base?.specs ?? const VehicleSpecs()).copyWith(
        tankCapacityL: double.tryParse(_tank.text.replaceAll(',', '.')),
      ),
      createdAt: base?.createdAt ?? now,
      updatedAt: now,
    );
    await ref.read(vehicleRepositoryProvider).upsert(vehicle);
    ref.invalidate(vehiclesProvider);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.initial == null ? 'Nuovo veicolo' : 'Modifica veicolo')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _make,
              decoration: const InputDecoration(labelText: 'Marca'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Obbligatorio' : null,
            ),
            TextFormField(
              controller: _model,
              decoration: const InputDecoration(labelText: 'Modello'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Obbligatorio' : null,
            ),
            DropdownButtonFormField<FuelType>(
              initialValue: _fuel,
              decoration: const InputDecoration(labelText: 'Carburante'),
              items: [
                for (final f in FuelType.values)
                  DropdownMenuItem(value: f, child: Text(f.name)),
              ],
              onChanged: (f) => setState(() => _fuel = f ?? _fuel),
            ),
            TextFormField(
              controller: _tank,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Capacità serbatoio (L)'),
            ),
            SwitchListTile(
              title: const Text('Veicolo predefinito'),
              value: _isDefault,
              onChanged: (v) => setState(() => _isDefault = v),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _save, child: const Text('Salva')),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 7: Generate code, run test**

Run: `dart run build_runner build --delete-conflicting-outputs && flutter test test/features/vehicles_test.dart`
Expected: PASS. (Adjust the test per the Step 3 note to insert a real vehicle and assert its make text.)

- [ ] **Step 8: Commit**

```bash
git add -A
git commit -m "feat: vehicles list + manual add/edit form"
```

---

### Task 10: Fill-up add/edit form with live €/L and validation

**Files:**
- Create: `lib/src/features/fillups/fillup_providers.dart`
- Create: `lib/src/features/fillups/fill_up_form_screen.dart`
- Test: `test/features/fill_up_form_test.dart`

**Interfaces:**
- Produces `fillUpsProvider(int vehicleId)` (`FutureProvider.family<List<FillUp>, int>`).
- Produces `FillUpFormScreen({required int vehicleId, FillUp? initial})`: fields amount, liters, odometer, date, full/partial, category, station, note; shows live €/L; validates amount>0, odometer required, liters>0 when present; warns (non-blocking SnackBar) if odometer < last odometer for the vehicle; saves and invalidates `fillUpsProvider`.

- [ ] **Step 1: Write `lib/src/features/fillups/fillup_providers.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/category.dart';
import '../../domain/models/fill_up.dart';
import '../../providers.dart';

part 'fillup_providers.g.dart';

@riverpod
Future<List<FillUp>> fillUps(Ref ref, int vehicleId) =>
    ref.watch(fillUpRepositoryProvider).forVehicle(vehicleId);

@riverpod
Future<List<Category>> categories(Ref ref) =>
    ref.watch(categoryRepositoryProvider).all();
```

- [ ] **Step 2: Write the failing test `test/features/fill_up_form_test.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carburo/src/features/fillups/fill_up_form_screen.dart';
import 'package:carburo/src/providers.dart';
import '../helpers/test_db.dart';

void main() {
  testWidgets('shows live €/L when amount and liters are entered', (tester) async {
    final db = makeTestDb();
    addTearDown(db.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: FillUpFormScreen(vehicleId: 1)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('amount')), '40');
    await tester.enterText(find.byKey(const Key('liters')), '32');
    await tester.pump();

    expect(find.textContaining('1,25'), findsWidgets); // 40 / 32 = 1.25 €/L
  });

  testWidgets('blocks save when amount is empty', (tester) async {
    final db = makeTestDb();
    addTearDown(db.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: FillUpFormScreen(vehicleId: 1)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Salva'));
    await tester.pump();
    expect(find.text('Obbligatorio'), findsWidgets);
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/features/fill_up_form_test.dart`
Expected: FAIL.

- [ ] **Step 4: Write `lib/src/features/fillups/fill_up_form_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/formatters.dart';
import '../../domain/models/fill_up.dart';
import '../../providers.dart';
import 'fillup_providers.dart';

double? _parse(String s) => double.tryParse(s.trim().replaceAll(',', '.'));

class FillUpFormScreen extends ConsumerStatefulWidget {
  const FillUpFormScreen({super.key, required this.vehicleId, this.initial});
  final int vehicleId;
  final FillUp? initial;

  @override
  ConsumerState<FillUpFormScreen> createState() => _FillUpFormScreenState();
}

class _FillUpFormScreenState extends ConsumerState<FillUpFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _amount = TextEditingController(text: widget.initial?.amount.toString());
  late final _liters = TextEditingController(text: widget.initial?.liters?.toString());
  late final _odometer = TextEditingController(text: widget.initial?.odometer.toString());
  late final _station = TextEditingController(text: widget.initial?.station);
  late final _note = TextEditingController(text: widget.initial?.note);
  late DateTime _date = widget.initial?.date ?? DateTime.now();
  late bool _isFull = widget.initial?.isFull ?? true;
  int? _categoryId;

  @override
  void dispose() {
    for (final c in [_amount, _liters, _odometer, _station, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  String get _pricePerLiter {
    final a = _parse(_amount.text);
    final l = _parse(_liters.text);
    if (a == null || l == null || l == 0) return '—';
    return '${fmtEuro(a / l)}/L';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final cats = await ref.read(categoriesProvider.future);
    final categoryId = _categoryId ??
        cats.firstWhere((c) => c.isDefault, orElse: () => cats.first).id;
    final odometer = _parse(_odometer.text)!;

    final existing = await ref.read(fillUpRepositoryProvider).forVehicle(widget.vehicleId);
    if (existing.isNotEmpty && odometer < existing.last.odometer && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attenzione: odometro inferiore al precedente')),
      );
    }

    final now = DateTime.now();
    final base = widget.initial;
    await ref.read(fillUpRepositoryProvider).upsert(
          FillUp(
            id: base?.id ?? 0,
            vehicleId: widget.vehicleId,
            date: _date,
            amount: _parse(_amount.text)!,
            liters: _parse(_liters.text),
            odometer: odometer,
            isFull: _isFull,
            station: _station.text.trim().isEmpty ? null : _station.text.trim(),
            categoryId: categoryId,
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
            createdAt: base?.createdAt ?? now,
            updatedAt: now,
          ),
        );
    ref.invalidate(fillUpsProvider(widget.vehicleId));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cats = ref.watch(categoriesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(widget.initial == null ? 'Nuovo rifornimento' : 'Modifica')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              key: const Key('amount'),
              controller: _amount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Importo (€)'),
              onChanged: (_) => setState(() {}),
              validator: (v) {
                final n = _parse(v ?? '');
                if (v == null || v.trim().isEmpty) return 'Obbligatorio';
                if (n == null || n <= 0) return 'Deve essere > 0';
                return null;
              },
            ),
            TextFormField(
              key: const Key('liters'),
              controller: _liters,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Litri'),
              onChanged: (_) => setState(() {}),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final n = _parse(v);
                if (n == null || n <= 0) return 'Deve essere > 0';
                return null;
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('Prezzo: $_pricePerLiter',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            TextFormField(
              key: const Key('odometer'),
              controller: _odometer,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Odometro (km)'),
              validator: (v) =>
                  _parse(v ?? '') == null ? 'Obbligatorio' : null,
            ),
            SwitchListTile(
              title: const Text('Pieno'),
              value: _isFull,
              onChanged: (v) => setState(() => _isFull = v),
            ),
            cats.maybeWhen(
              data: (list) => DropdownButtonFormField<int>(
                initialValue: _categoryId ??
                    list.firstWhere((c) => c.isDefault, orElse: () => list.first).id,
                decoration: const InputDecoration(labelText: 'Categoria'),
                items: [
                  for (final c in list)
                    DropdownMenuItem(value: c.id, child: Text(c.name)),
                ],
                onChanged: (v) => setState(() => _categoryId = v),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
            TextFormField(
              controller: _station,
              decoration: const InputDecoration(labelText: 'Distributore'),
            ),
            TextFormField(
              controller: _note,
              decoration: const InputDecoration(labelText: 'Note'),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _save, child: const Text('Salva')),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Generate code, run test**

Run: `dart run build_runner build --delete-conflicting-outputs && flutter test test/features/fill_up_form_test.dart`
Expected: PASS (both tests).

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat: fill-up add/edit form with live price/L and validation"
```

---

### Task 11: History screen — grouped list + delete

**Files:**
- Create: `lib/src/features/fillups/history_screen.dart`
- Test: `test/features/history_test.dart`

**Interfaces:**
- Produces `HistoryScreen({required int vehicleId})`: lists fill-ups (desc by date), each row shows date, amount, liters, €/L; swipe (Dismissible) to delete via repo + invalidate.

- [ ] **Step 1: Write the failing test `test/features/history_test.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carburo/src/data/repositories/fill_up_repository_impl.dart';
import 'package:carburo/src/data/repositories/vehicle_repository_impl.dart';
import 'package:carburo/src/domain/models/enums.dart';
import 'package:carburo/src/domain/models/fill_up.dart';
import 'package:carburo/src/domain/models/vehicle.dart';
import 'package:carburo/src/features/fillups/history_screen.dart';
import 'package:carburo/src/providers.dart';
import '../helpers/test_db.dart';

void main() {
  testWidgets('history lists a saved fill-up', (tester) async {
    final db = makeTestDb();
    addTearDown(db.close);
    final vid = await VehicleRepositoryImpl(db).upsert(
      Vehicle(id: 0, make: 'R', model: 'C', fuelType: FuelType.petrol,
          createdAt: DateTime(2026), updatedAt: DateTime(2026)),
    );
    await FillUpRepositoryImpl(db).upsert(
      FillUp(id: 0, vehicleId: vid, date: DateTime(2026, 1, 1), amount: 40,
          liters: 32, odometer: 1000, categoryId: 1,
          createdAt: DateTime(2026), updatedAt: DateTime(2026)),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(home: HistoryScreen(vehicleId: vid)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('40'), findsWidgets);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/history_test.dart`
Expected: FAIL.

- [ ] **Step 3: Write `lib/src/features/fillups/history_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/formatters.dart';
import '../../providers.dart';
import 'fillup_providers.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key, required this.vehicleId});
  final int vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(fillUpsProvider(vehicleId));
    return Scaffold(
      appBar: AppBar(title: const Text('Storico')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Errore: $e')),
        data: (fills) {
          final sorted = [...fills]..sort((a, b) => b.date.compareTo(a.date));
          if (sorted.isEmpty) {
            return const Center(child: Text('Nessun rifornimento.'));
          }
          return ListView(
            children: [
              for (final f in sorted)
                Dismissible(
                  key: ValueKey(f.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) async {
                    await ref.read(fillUpRepositoryProvider).delete(f.id);
                    ref.invalidate(fillUpsProvider(vehicleId));
                  },
                  child: ListTile(
                    title: Text('${fmtDate(f.date)} · ${fmtEuro(f.amount)}'),
                    subtitle: Text(f.liters == null
                        ? '—'
                        : '${fmtLiters(f.liters!)} · ${fmtEuro(f.amount / f.liters!)}/L'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/history_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: history screen with swipe-to-delete"
```

---

### Task 12: Dashboard — stat cards + headline chart

**Files:**
- Create: `lib/src/features/dashboard/dashboard_providers.dart`
- Create: `lib/src/features/dashboard/widgets/stat_card.dart`
- Create: `lib/src/features/dashboard/dashboard_screen.dart`
- Test: `test/features/dashboard_test.dart`

**Interfaces:**
- Produces `dashboardVehicleProvider` (`FutureProvider<Vehicle?>` = defaultVehicle ?? first).
- Produces `vehicleStatsProvider(int vehicleId)` (`FutureProvider.family<VehicleStats,int>`) using `statsServiceProvider` over `fillUpsProvider`.
- Produces `DashboardScreen` showing stat cards (total spend, avg €/L, avg consumption, total km) and a monthly-spend bar chart; FAB → fill-up form for the current vehicle.

- [ ] **Step 1: Write `lib/src/features/dashboard/dashboard_providers.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/vehicle.dart';
import '../../domain/models/vehicle_stats.dart';
import '../../providers.dart';
import '../fillups/fillup_providers.dart';

part 'dashboard_providers.g.dart';

@riverpod
Future<Vehicle?> dashboardVehicle(Ref ref) async {
  final repo = ref.watch(vehicleRepositoryProvider);
  final def = await repo.defaultVehicle();
  if (def != null) return def;
  final all = await repo.all();
  return all.isEmpty ? null : all.first;
}

@riverpod
Future<VehicleStats> vehicleStats(Ref ref, int vehicleId) async {
  final fills = await ref.watch(fillUpsProvider(vehicleId).future);
  return ref.watch(statsServiceProvider).compute(fills);
}
```

- [ ] **Step 2: Write `lib/src/features/dashboard/widgets/stat_card.dart`**

```dart
import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Write the failing test `test/features/dashboard_test.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carburo/src/data/repositories/fill_up_repository_impl.dart';
import 'package:carburo/src/data/repositories/vehicle_repository_impl.dart';
import 'package:carburo/src/domain/models/enums.dart';
import 'package:carburo/src/domain/models/fill_up.dart';
import 'package:carburo/src/domain/models/vehicle.dart';
import 'package:carburo/src/features/dashboard/dashboard_screen.dart';
import 'package:carburo/src/providers.dart';
import '../helpers/test_db.dart';

void main() {
  testWidgets('dashboard shows total spend for the default vehicle', (tester) async {
    final db = makeTestDb();
    addTearDown(db.close);
    final vid = await VehicleRepositoryImpl(db).upsert(
      Vehicle(id: 0, make: 'R', model: 'C', fuelType: FuelType.petrol,
          isDefault: true, createdAt: DateTime(2026), updatedAt: DateTime(2026)),
    );
    for (final m in [1, 2]) {
      await FillUpRepositoryImpl(db).upsert(
        FillUp(id: 0, vehicleId: vid, date: DateTime(2026, m, 1), amount: 50,
            liters: 40, odometer: 1000.0 * m, categoryId: 1,
            createdAt: DateTime(2026), updatedAt: DateTime(2026)),
      );
    }

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('100'), findsWidgets); // total spend 100€
  });
}
```

- [ ] **Step 4: Run test to verify it fails**

Run: `flutter test test/features/dashboard_test.dart`
Expected: FAIL.

- [ ] **Step 5: Write `lib/src/features/dashboard/dashboard_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/formatters.dart';
import 'dashboard_providers.dart';
import 'widgets/stat_card.dart';
import '../fillups/fill_up_form_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicleAsync = ref.watch(dashboardVehicleProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Carburo')),
      body: vehicleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Errore: $e')),
        data: (vehicle) {
          if (vehicle == null) {
            return const Center(child: Text('Aggiungi un veicolo per iniziare.'));
          }
          final statsAsync = ref.watch(vehicleStatsProvider(vehicle.id));
          return statsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Errore: $e')),
            data: (s) => GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.all(12),
              childAspectRatio: 1.6,
              children: [
                StatCard(label: 'Spesa totale', value: fmtEuro(s.totalSpend)),
                StatCard(
                  label: 'Prezzo medio',
                  value: s.avgPricePerLiter == null
                      ? '—'
                      : '${fmtEuro(s.avgPricePerLiter!)}/L',
                ),
                StatCard(
                  label: 'Consumo medio',
                  value: s.avgConsumption == null
                      ? '—'
                      : fmtConsumption(s.avgConsumption!),
                ),
                StatCard(label: 'Km totali', value: fmtKm(s.totalKm)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: vehicleAsync.maybeWhen(
        data: (v) => v == null
            ? null
            : FloatingActionButton.extended(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FillUpFormScreen(vehicleId: v.id),
                  ),
                ),
                icon: const Icon(Icons.local_gas_station),
                label: const Text('Rifornimento'),
              ),
        orElse: () => null,
      ),
    );
  }
}
```

- [ ] **Step 6: Generate code, run test**

Run: `dart run build_runner build --delete-conflicting-outputs && flutter test test/features/dashboard_test.dart`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "feat: dashboard with stat cards"
```

---

### Task 13: App shell — theme, router, bottom navigation

**Files:**
- Create: `lib/src/app/theme.dart`, `lib/src/app/router.dart`
- Modify: `lib/src/app/app.dart` (use `MaterialApp.router`)
- Create: `lib/src/features/settings/settings_screen.dart` (skeleton; import lands in Task 14)
- Test: `test/app/router_test.dart`

**Interfaces:**
- Produces `appTheme(Brightness)` → `ThemeData`.
- Produces `appRouter` (`GoRouter`) with a `StatefulShellRoute.indexedStack` over Dashboard/History/Vehicles/Settings + a bottom `NavigationBar`.

- [ ] **Step 1: Write `lib/src/app/theme.dart`**

```dart
import 'package:flutter/material.dart';

ThemeData appTheme(Brightness brightness) => ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.teal,
        brightness: brightness,
      ),
      useMaterial3: true,
    );
```

- [ ] **Step 2: Write `lib/src/features/settings/settings_screen.dart`**

```dart
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Impostazioni')),
      body: const Center(child: Text('Impostazioni')),
    );
  }
}
```

- [ ] **Step 3: Write `lib/src/app/router.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/vehicles/vehicles_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/dashboard',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => _HomeShell(shell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/vehicles', builder: (_, __) => const VehiclesScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
        ]),
      ],
    ),
  ],
);

class _HomeShell extends StatelessWidget {
  const _HomeShell({required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: shell.goBranch,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.directions_car), label: 'Veicoli'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Impostazioni'),
        ],
      ),
    );
  }
}
```

> History is reached from the dashboard/vehicle context in Phase 1; it joins the bottom bar in a later phase if desired.

- [ ] **Step 4: Rewrite `lib/src/app/app.dart`**

```dart
import 'package:flutter/material.dart';
import 'router.dart';
import 'theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Carburo',
      theme: appTheme(Brightness.light),
      darkTheme: appTheme(Brightness.dark),
      routerConfig: appRouter,
    );
  }
}
```

- [ ] **Step 5: Update the smoke test + write `test/app/router_test.dart`**

Update `test/smoke_test.dart` to pump with an overridden in-memory db (so `appDatabaseProvider` does not touch the filesystem):
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carburo/src/app/app.dart';
import 'package:carburo/src/providers.dart';
import 'helpers/test_db.dart';

void main() {
  testWidgets('App boots to dashboard with nav bar', (tester) async {
    final db = makeTestDb();
    addTearDown(db.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Veicoli'), findsWidgets);
  });
}
```
(Delete the old `test/smoke_test.dart` body and replace with the above, or move it to `test/app/router_test.dart`.)

- [ ] **Step 6: Run analyze + full test suite**

Run: `flutter analyze && flutter test`
Expected: clean + all tests PASS.

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "feat: app shell with Material 3 theme and bottom navigation"
```

---

### Task 14: Excel importer + Settings import entry

**Files:**
- Create: `lib/src/domain/models/import_result.dart`
- Create: `lib/src/data/importer/excel_importer.dart`
- Modify: `lib/src/features/settings/settings_screen.dart`
- Test: `test/data/excel_importer_test.dart`
- Add dep: `file_picker`

**Interfaces:**
- Produces `ImportResult({List<FillUp> rows, int skipped, List<String> warnings})`.
- Produces `class ExcelImporter` with:
  - `ImportResult mapRows(List<List<Object?>> rows, {required int vehicleId, required int categoryId})` — pure; rows[0]=title, rows[1]=header, data from row 2; cols: 0=date(serial or DateTime), 1=amount, 2=odometer, 3=rangeKm.
  - `ImportResult parseBytes(Uint8List bytes, {required int vehicleId, required int categoryId})` — extracts raw rows via the `excel` package then calls `mapRows`.
- Excel serial date: `DateTime(1899, 12, 30).add(Duration(days: serial))`.

- [ ] **Step 1: Add the dependency**

```bash
flutter pub add file_picker
```

- [ ] **Step 2: Write `lib/src/domain/models/import_result.dart`**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'fill_up.dart';

part 'import_result.freezed.dart';

@freezed
class ImportResult with _$ImportResult {
  const factory ImportResult({
    @Default(<FillUp>[]) List<FillUp> rows,
    @Default(0) int skipped,
    @Default(<String>[]) List<String> warnings,
  }) = _ImportResult;
}
```

- [ ] **Step 3: Write the failing test `test/data/excel_importer_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:carburo/src/data/importer/excel_importer.dart';

void main() {
  const importer = ExcelImporter();

  test('maps data rows, skips header and empty, flags zero-odometer anomaly', () {
    final rows = <List<Object?>>[
      ['RENAULT Clio', null, null, null, null],            // title
      ['Data', 'Importo', 'Kilometraggio', 'Autonomia', 'Differenza'], // header
      [45146, 300, 0, 0, 3963],                            // anomaly: odometer 0
      [45174, 40, 3963, 590, 4553],                        // normal
      [null, null, null, null, null],                      // empty → skipped
    ];

    final result = importer.mapRows(rows, vehicleId: 7, categoryId: 1);

    expect(result.rows, hasLength(2));
    expect(result.skipped, 1);
    expect(result.warnings, isNotEmpty); // zero-odometer flagged
    final first = result.rows.first;
    expect(first.vehicleId, 7);
    expect(first.amount, 300);
    expect(first.liters, isNull);
    expect(first.rangeKm, 3963);
    expect(first.date, DateTime(1899, 12, 30).add(const Duration(days: 45146)));
  });

  test('accepts DateTime values in the date column', () {
    final rows = <List<Object?>>[
      ['title', null, null, null, null],
      ['Data', 'Importo', 'Km', 'Aut', 'Diff'],
      [DateTime(2023, 8, 21), 40, 3963, 590, 4553],
    ];
    final result = importer.mapRows(rows, vehicleId: 1, categoryId: 1);
    expect(result.rows.single.date, DateTime(2023, 8, 21));
  });
}
```

- [ ] **Step 4: Run test to verify it fails**

Run: `flutter test test/data/excel_importer_test.dart`
Expected: FAIL.

- [ ] **Step 5: Write `lib/src/data/importer/excel_importer.dart`**

```dart
import 'dart:typed_data';
import 'package:excel/excel.dart';
import '../../domain/models/fill_up.dart';
import '../../domain/models/import_result.dart';

class ExcelImporter {
  const ExcelImporter();

  static final _epoch = DateTime(1899, 12, 30);

  double? _num(Object? v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().replaceAll(',', '.'));
  }

  DateTime? _date(Object? v) {
    if (v is DateTime) return v;
    final n = _num(v);
    return n == null ? null : _epoch.add(Duration(days: n.toInt()));
  }

  ImportResult mapRows(
    List<List<Object?>> rows, {
    required int vehicleId,
    required int categoryId,
  }) {
    final out = <FillUp>[];
    final warnings = <String>[];
    var skipped = 0;
    final now = DateTime.now();

    for (var i = 2; i < rows.length; i++) {
      final r = rows[i];
      final date = _date(r.isNotEmpty ? r[0] : null);
      final amount = _num(r.length > 1 ? r[1] : null);
      final odometer = _num(r.length > 2 ? r[2] : null);

      if (date == null && amount == null && odometer == null) {
        skipped++;
        continue;
      }
      if (date == null || amount == null || odometer == null) {
        skipped++;
        warnings.add('Riga ${i + 1}: dati incompleti, saltata.');
        continue;
      }
      if (odometer == 0) {
        warnings.add('Riga ${i + 1}: odometro 0 (anomalia) — importata comunque.');
      }

      out.add(
        FillUp(
          id: 0,
          vehicleId: vehicleId,
          date: date,
          amount: amount,
          odometer: odometer,
          rangeKm: _num(r.length > 3 ? r[3] : null),
          categoryId: categoryId,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
    return ImportResult(rows: out, skipped: skipped, warnings: warnings);
  }

  ImportResult parseBytes(
    Uint8List bytes, {
    required int vehicleId,
    required int categoryId,
  }) {
    final book = Excel.decodeBytes(bytes);
    final sheet = book.tables[book.tables.keys.first]!;
    final rows = sheet.rows
        .map((row) => row.map((cell) => cell?.value).toList())
        .toList();
    return mapRows(rows, vehicleId: vehicleId, categoryId: categoryId);
  }
}
```

> Note: the `excel` package (4.x) wraps cell values in `CellValue` subtypes (`IntCellValue`, `DoubleCellValue`, `DateCellValue`, `TextCellValue`). If `cell?.value` returns those wrappers rather than raw `num`/`DateTime`/`String`, extend `_num`/`_date` to unwrap them (e.g. `IntCellValue v => v.value`). Confirm against the installed version while wiring `parseBytes`; `mapRows` (the tested core) is unaffected.

- [ ] **Step 6: Generate code, run test**

Run: `dart run build_runner build --delete-conflicting-outputs && flutter test test/data/excel_importer_test.dart`
Expected: PASS.

- [ ] **Step 7: Wire the Settings import action**

Rewrite `lib/src/features/settings/settings_screen.dart`:
```dart
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/importer/excel_importer.dart';
import '../../providers.dart';
import '../vehicles/vehicle_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
    );
    final bytes = picked?.files.single.bytes;
    if (bytes == null) return;

    final vehicles = await ref.read(vehicleRepositoryProvider).all();
    final cats = await ref.read(categoryRepositoryProvider).all();
    if (vehicles.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Crea prima un veicolo.')),
        );
      }
      return;
    }
    final defaultCat = cats.firstWhere((c) => c.isDefault, orElse: () => cats.first);
    final result = const ExcelImporter().parseBytes(
      bytes,
      vehicleId: vehicles.first.id,
      categoryId: defaultCat.id,
    );
    final repo = ref.read(fillUpRepositoryProvider);
    for (final f in result.rows) {
      await repo.upsert(f);
    }
    ref.invalidate(vehiclesProvider);

    if (context.mounted) {
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Import completato'),
          content: Text(
            'Importate: ${result.rows.length}\n'
            'Saltate: ${result.skipped}\n'
            'Avvisi: ${result.warnings.length}',
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Impostazioni')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('Importa da Excel'),
            subtitle: const Text('Carica il tuo Consumi.xlsx'),
            onTap: () => _import(context, ref),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 8: Run analyze + full suite**

Run: `flutter analyze && flutter test`
Expected: clean + all PASS.

- [ ] **Step 9: Commit**

```bash
git add -A
git commit -m "feat: Excel importer and Settings import action"
```

---

## Self-Review

**1. Spec coverage (Phase 1 scope):**
- Domain model (Vehicle/VehicleSpecs/FillUp/Category) → Tasks 3, 6. ✓
- Full-to-full consumption logic → Task 4. ✓
- Aggregates + category split → Task 5. ✓
- Local-first Drift DB + seed categories → Task 6. ✓
- Repositories → Task 7. ✓
- Manual vehicle management (catalog wizard deferred to Phase 2) → Task 9. ✓
- Rich fill-up entry (amount/liters/odometer/full/category/station/note; €/L live; odometer warning) → Task 10. GPS + photo deferred to Phase 2. ✓ (documented deferral)
- History list + delete → Task 11. ✓
- Dashboard stats → Task 12. ✓
- Material 3 + navigation → Task 13. ✓
- Excel import of `Consumi.xlsx` → Task 14. ✓
- Deferred to later phases (per spec §14): CarQuery catalog wizard, charts/comparison panel, CSV/JSON backup, full i18n EN, GPS/photo, CI/CD + signed APK. These get their own plans.

**2. Placeholder scan:** No `TBD`/`TODO`/"add error handling"-style placeholders. Two implementation notes (Drift generated row-class names; `excel` `CellValue` unwrapping) flag version-specific facts to confirm against installed packages — both have concrete fallback instructions, not deferred work.

**3. Type consistency:** Repository method names (`all`, `getById`, `upsert`, `delete`, `defaultVehicle`, `forVehicle`) are identical across abstract defs (Task 7), impls (Task 7), and provider/UI consumers (Tasks 8–14). Provider names (`appDatabaseProvider`, `categoryRepositoryProvider`, `vehicleRepositoryProvider`, `fillUpRepositoryProvider`, `statsServiceProvider`, `vehiclesProvider`, `fillUpsProvider`, `categoriesProvider`, `dashboardVehicleProvider`, `vehicleStatsProvider`) match between definition and use. `VehicleStats`/`ConsumptionInterval`/`ImportResult` field names match their tests.

---

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-06-22-carburo-phase1-core.md`.

This is Phase 1 (Core) of 5. Phases 2–5 (CarQuery catalog wizard, charts & real-vs-declared comparison, CSV/JSON backup, CI/CD + signed APK) will each get their own plan once Phase 1 lands.

**Two execution options:**

1. **Inline Execution (recommended given your no-subagents preference)** — execute tasks in this session with the `superpowers:executing-plans` skill, batching with review checkpoints.
2. **Subagent-Driven** — a fresh subagent per task with review between tasks (faster iteration, but conflicts with your inline-only preference).

**Which approach?**

