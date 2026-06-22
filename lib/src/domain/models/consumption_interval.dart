import 'package:freezed_annotation/freezed_annotation.dart';

part 'consumption_interval.freezed.dart';

@freezed
abstract class ConsumptionInterval with _$ConsumptionInterval {
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
