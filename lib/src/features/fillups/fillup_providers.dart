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
