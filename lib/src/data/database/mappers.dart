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

extension CategoryRowMapper on CategoryRow {
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

extension VehicleRowMapper on VehicleRow {
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

extension FillUpRowMapper on FillUpRow {
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
