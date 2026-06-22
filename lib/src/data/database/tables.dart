import 'package:drift/drift.dart';

@DataClassName('CategoryRow')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get color => integer()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
}

@DataClassName('VehicleRow')
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

@DataClassName('FillUpRow')
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
