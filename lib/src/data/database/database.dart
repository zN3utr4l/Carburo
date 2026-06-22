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
