// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'consumption_interval.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ConsumptionInterval {

 int get fromFillUpId; int get toFillUpId; double get distanceKm; double get liters; double get cost;
/// Create a copy of ConsumptionInterval
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConsumptionIntervalCopyWith<ConsumptionInterval> get copyWith => _$ConsumptionIntervalCopyWithImpl<ConsumptionInterval>(this as ConsumptionInterval, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConsumptionInterval&&(identical(other.fromFillUpId, fromFillUpId) || other.fromFillUpId == fromFillUpId)&&(identical(other.toFillUpId, toFillUpId) || other.toFillUpId == toFillUpId)&&(identical(other.distanceKm, distanceKm) || other.distanceKm == distanceKm)&&(identical(other.liters, liters) || other.liters == liters)&&(identical(other.cost, cost) || other.cost == cost));
}


@override
int get hashCode => Object.hash(runtimeType,fromFillUpId,toFillUpId,distanceKm,liters,cost);

@override
String toString() {
  return 'ConsumptionInterval(fromFillUpId: $fromFillUpId, toFillUpId: $toFillUpId, distanceKm: $distanceKm, liters: $liters, cost: $cost)';
}


}

/// @nodoc
abstract mixin class $ConsumptionIntervalCopyWith<$Res>  {
  factory $ConsumptionIntervalCopyWith(ConsumptionInterval value, $Res Function(ConsumptionInterval) _then) = _$ConsumptionIntervalCopyWithImpl;
@useResult
$Res call({
 int fromFillUpId, int toFillUpId, double distanceKm, double liters, double cost
});




}
/// @nodoc
class _$ConsumptionIntervalCopyWithImpl<$Res>
    implements $ConsumptionIntervalCopyWith<$Res> {
  _$ConsumptionIntervalCopyWithImpl(this._self, this._then);

  final ConsumptionInterval _self;
  final $Res Function(ConsumptionInterval) _then;

/// Create a copy of ConsumptionInterval
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fromFillUpId = null,Object? toFillUpId = null,Object? distanceKm = null,Object? liters = null,Object? cost = null,}) {
  return _then(_self.copyWith(
fromFillUpId: null == fromFillUpId ? _self.fromFillUpId : fromFillUpId // ignore: cast_nullable_to_non_nullable
as int,toFillUpId: null == toFillUpId ? _self.toFillUpId : toFillUpId // ignore: cast_nullable_to_non_nullable
as int,distanceKm: null == distanceKm ? _self.distanceKm : distanceKm // ignore: cast_nullable_to_non_nullable
as double,liters: null == liters ? _self.liters : liters // ignore: cast_nullable_to_non_nullable
as double,cost: null == cost ? _self.cost : cost // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [ConsumptionInterval].
extension ConsumptionIntervalPatterns on ConsumptionInterval {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConsumptionInterval value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConsumptionInterval() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConsumptionInterval value)  $default,){
final _that = this;
switch (_that) {
case _ConsumptionInterval():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConsumptionInterval value)?  $default,){
final _that = this;
switch (_that) {
case _ConsumptionInterval() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int fromFillUpId,  int toFillUpId,  double distanceKm,  double liters,  double cost)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConsumptionInterval() when $default != null:
return $default(_that.fromFillUpId,_that.toFillUpId,_that.distanceKm,_that.liters,_that.cost);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int fromFillUpId,  int toFillUpId,  double distanceKm,  double liters,  double cost)  $default,) {final _that = this;
switch (_that) {
case _ConsumptionInterval():
return $default(_that.fromFillUpId,_that.toFillUpId,_that.distanceKm,_that.liters,_that.cost);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int fromFillUpId,  int toFillUpId,  double distanceKm,  double liters,  double cost)?  $default,) {final _that = this;
switch (_that) {
case _ConsumptionInterval() when $default != null:
return $default(_that.fromFillUpId,_that.toFillUpId,_that.distanceKm,_that.liters,_that.cost);case _:
  return null;

}
}

}

/// @nodoc


class _ConsumptionInterval extends ConsumptionInterval {
  const _ConsumptionInterval({required this.fromFillUpId, required this.toFillUpId, required this.distanceKm, required this.liters, required this.cost}): super._();
  

@override final  int fromFillUpId;
@override final  int toFillUpId;
@override final  double distanceKm;
@override final  double liters;
@override final  double cost;

/// Create a copy of ConsumptionInterval
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConsumptionIntervalCopyWith<_ConsumptionInterval> get copyWith => __$ConsumptionIntervalCopyWithImpl<_ConsumptionInterval>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConsumptionInterval&&(identical(other.fromFillUpId, fromFillUpId) || other.fromFillUpId == fromFillUpId)&&(identical(other.toFillUpId, toFillUpId) || other.toFillUpId == toFillUpId)&&(identical(other.distanceKm, distanceKm) || other.distanceKm == distanceKm)&&(identical(other.liters, liters) || other.liters == liters)&&(identical(other.cost, cost) || other.cost == cost));
}


@override
int get hashCode => Object.hash(runtimeType,fromFillUpId,toFillUpId,distanceKm,liters,cost);

@override
String toString() {
  return 'ConsumptionInterval(fromFillUpId: $fromFillUpId, toFillUpId: $toFillUpId, distanceKm: $distanceKm, liters: $liters, cost: $cost)';
}


}

/// @nodoc
abstract mixin class _$ConsumptionIntervalCopyWith<$Res> implements $ConsumptionIntervalCopyWith<$Res> {
  factory _$ConsumptionIntervalCopyWith(_ConsumptionInterval value, $Res Function(_ConsumptionInterval) _then) = __$ConsumptionIntervalCopyWithImpl;
@override @useResult
$Res call({
 int fromFillUpId, int toFillUpId, double distanceKm, double liters, double cost
});




}
/// @nodoc
class __$ConsumptionIntervalCopyWithImpl<$Res>
    implements _$ConsumptionIntervalCopyWith<$Res> {
  __$ConsumptionIntervalCopyWithImpl(this._self, this._then);

  final _ConsumptionInterval _self;
  final $Res Function(_ConsumptionInterval) _then;

/// Create a copy of ConsumptionInterval
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fromFillUpId = null,Object? toFillUpId = null,Object? distanceKm = null,Object? liters = null,Object? cost = null,}) {
  return _then(_ConsumptionInterval(
fromFillUpId: null == fromFillUpId ? _self.fromFillUpId : fromFillUpId // ignore: cast_nullable_to_non_nullable
as int,toFillUpId: null == toFillUpId ? _self.toFillUpId : toFillUpId // ignore: cast_nullable_to_non_nullable
as int,distanceKm: null == distanceKm ? _self.distanceKm : distanceKm // ignore: cast_nullable_to_non_nullable
as double,liters: null == liters ? _self.liters : liters // ignore: cast_nullable_to_non_nullable
as double,cost: null == cost ? _self.cost : cost // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
