// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fillup_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(fillUps)
final fillUpsProvider = FillUpsFamily._();

final class FillUpsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<FillUp>>,
          List<FillUp>,
          FutureOr<List<FillUp>>
        >
    with $FutureModifier<List<FillUp>>, $FutureProvider<List<FillUp>> {
  FillUpsProvider._({
    required FillUpsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'fillUpsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$fillUpsHash();

  @override
  String toString() {
    return r'fillUpsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<FillUp>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<FillUp>> create(Ref ref) {
    final argument = this.argument as int;
    return fillUps(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FillUpsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$fillUpsHash() => r'08835997427f34215f1f5323bc4aa4b7f8a4fb8e';

final class FillUpsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<FillUp>>, int> {
  FillUpsFamily._()
    : super(
        retry: null,
        name: r'fillUpsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  FillUpsProvider call(int vehicleId) =>
      FillUpsProvider._(argument: vehicleId, from: this);

  @override
  String toString() => r'fillUpsProvider';
}

@ProviderFor(categories)
final categoriesProvider = CategoriesProvider._();

final class CategoriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Category>>,
          List<Category>,
          FutureOr<List<Category>>
        >
    with $FutureModifier<List<Category>>, $FutureProvider<List<Category>> {
  CategoriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categoriesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categoriesHash();

  @$internal
  @override
  $FutureProviderElement<List<Category>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Category>> create(Ref ref) {
    return categories(ref);
  }
}

String _$categoriesHash() => r'ac23bc367a68ecd78ca4fa5f7a78dd4cf6cf0ce9';
