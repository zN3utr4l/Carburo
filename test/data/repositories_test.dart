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
