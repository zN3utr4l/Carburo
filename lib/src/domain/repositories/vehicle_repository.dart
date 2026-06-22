import '../models/vehicle.dart';

abstract class VehicleRepository {
  Future<List<Vehicle>> all();
  Future<Vehicle> getById(int id);
  Future<int> upsert(Vehicle vehicle);
  Future<void> delete(int id);
  Future<Vehicle?> defaultVehicle();
}
