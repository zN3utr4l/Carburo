// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(dashboardVehicle)
final dashboardVehicleProvider = DashboardVehicleProvider._();

final class DashboardVehicleProvider
    extends
        $FunctionalProvider<AsyncValue<Vehicle?>, Vehicle?, FutureOr<Vehicle?>>
    with $FutureModifier<Vehicle?>, $FutureProvider<Vehicle?> {
  DashboardVehicleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dashboardVehicleProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dashboardVehicleHash();

  @$internal
  @override
  $FutureProviderElement<Vehicle?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Vehicle?> create(Ref ref) {
    return dashboardVehicle(ref);
  }
}

String _$dashboardVehicleHash() => r'18a4beea6c6cf4546795ce103f753c24eef6a856';

@ProviderFor(vehicleStats)
final vehicleStatsProvider = VehicleStatsFamily._();

final class VehicleStatsProvider
    extends
        $FunctionalProvider<
          AsyncValue<VehicleStats>,
          VehicleStats,
          FutureOr<VehicleStats>
        >
    with $FutureModifier<VehicleStats>, $FutureProvider<VehicleStats> {
  VehicleStatsProvider._({
    required VehicleStatsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'vehicleStatsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$vehicleStatsHash();

  @override
  String toString() {
    return r'vehicleStatsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<VehicleStats> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<VehicleStats> create(Ref ref) {
    final argument = this.argument as int;
    return vehicleStats(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is VehicleStatsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$vehicleStatsHash() => r'a891a17653c3970ba3b4094519eb668b1c4792bf';

final class VehicleStatsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<VehicleStats>, int> {
  VehicleStatsFamily._()
    : super(
        retry: null,
        name: r'vehicleStatsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  VehicleStatsProvider call(int vehicleId) =>
      VehicleStatsProvider._(argument: vehicleId, from: this);

  @override
  String toString() => r'vehicleStatsProvider';
}
