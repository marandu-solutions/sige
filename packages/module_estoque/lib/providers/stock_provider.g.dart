// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$stockServiceHash() => r'f493b857d038d4de982aef85b4183b45c2fb5806';

/// Provider for the StockService dependency.
///
/// Copied from [stockService].
@ProviderFor(stockService)
final stockServiceProvider = AutoDisposeProvider<StockService>.internal(
  stockService,
  name: r'stockServiceProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$stockServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StockServiceRef = AutoDisposeProviderRef<StockService>;
String _$stockHash() => r'f07e7f5b0a5c8b8662bd579f02461ce73ed32ae5';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$Stock
    extends BuildlessAutoDisposeAsyncNotifier<List<StockItemModel>> {
  late final String tenantId;

  FutureOr<List<StockItemModel>> build(
    String tenantId,
  );
}

/// The main provider for the stock state, using a family to pass the tenantId.
///
/// This provider will manage the state of the stock items list (`AsyncValue<List<StockItemModel>>`).
///
/// Copied from [Stock].
@ProviderFor(Stock)
const stockProvider = StockFamily();

/// The main provider for the stock state, using a family to pass the tenantId.
///
/// This provider will manage the state of the stock items list (`AsyncValue<List<StockItemModel>>`).
///
/// Copied from [Stock].
class StockFamily extends Family<AsyncValue<List<StockItemModel>>> {
  /// The main provider for the stock state, using a family to pass the tenantId.
  ///
  /// This provider will manage the state of the stock items list (`AsyncValue<List<StockItemModel>>`).
  ///
  /// Copied from [Stock].
  const StockFamily();

  /// The main provider for the stock state, using a family to pass the tenantId.
  ///
  /// This provider will manage the state of the stock items list (`AsyncValue<List<StockItemModel>>`).
  ///
  /// Copied from [Stock].
  StockProvider call(
    String tenantId,
  ) {
    return StockProvider(
      tenantId,
    );
  }

  @override
  StockProvider getProviderOverride(
    covariant StockProvider provider,
  ) {
    return call(
      provider.tenantId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'stockProvider';
}

/// The main provider for the stock state, using a family to pass the tenantId.
///
/// This provider will manage the state of the stock items list (`AsyncValue<List<StockItemModel>>`).
///
/// Copied from [Stock].
class StockProvider
    extends AutoDisposeAsyncNotifierProviderImpl<Stock, List<StockItemModel>> {
  /// The main provider for the stock state, using a family to pass the tenantId.
  ///
  /// This provider will manage the state of the stock items list (`AsyncValue<List<StockItemModel>>`).
  ///
  /// Copied from [Stock].
  StockProvider(
    String tenantId,
  ) : this._internal(
          () => Stock()..tenantId = tenantId,
          from: stockProvider,
          name: r'stockProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$stockHash,
          dependencies: StockFamily._dependencies,
          allTransitiveDependencies: StockFamily._allTransitiveDependencies,
          tenantId: tenantId,
        );

  StockProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.tenantId,
  }) : super.internal();

  final String tenantId;

  @override
  FutureOr<List<StockItemModel>> runNotifierBuild(
    covariant Stock notifier,
  ) {
    return notifier.build(
      tenantId,
    );
  }

  @override
  Override overrideWith(Stock Function() create) {
    return ProviderOverride(
      origin: this,
      override: StockProvider._internal(
        () => create()..tenantId = tenantId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        tenantId: tenantId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<Stock, List<StockItemModel>>
      createElement() {
    return _StockProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StockProvider && other.tenantId == tenantId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, tenantId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin StockRef on AutoDisposeAsyncNotifierProviderRef<List<StockItemModel>> {
  /// The parameter `tenantId` of this provider.
  String get tenantId;
}

class _StockProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<Stock, List<StockItemModel>>
    with StockRef {
  _StockProviderElement(super.provider);

  @override
  String get tenantId => (origin as StockProvider).tenantId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
