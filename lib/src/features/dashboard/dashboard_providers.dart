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
