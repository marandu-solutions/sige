import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Registry Provider that holds the map of registered services
final _registryProvider = StateProvider<Map<Type, dynamic>>((ref) => {});

/// Service Registry for decoupling modules.
/// It acts as a central hub where modules can register their implementations
/// and other modules can request them via their abstract interfaces (contracts).
class ServiceRegistry {
  static final ServiceRegistry _instance = ServiceRegistry._internal();
  factory ServiceRegistry() => _instance;
  ServiceRegistry._internal();

  /// Provider container to access Riverpod state
  ProviderContainer? _container;

  /// Initialize the registry with a ProviderContainer
  void init(ProviderContainer container) {
    _container = container;
  }

  /// Registers an implementation [T] for a given interface type.
  void register<T>(T implementation) {
    if (_container == null) {
      throw StateError('ServiceRegistry not initialized. Call init() first.');
    }

    final currentMap = _container!.read(_registryProvider);
    _container!.read(_registryProvider.notifier).state = {
      ...currentMap,
      T: implementation,
    };
  }

  /// Retrieves an implementation of type [T] if registered.
  /// Returns null if the service is not found (module not loaded/contracted).
  T? get<T>() {
    if (_container == null) return null;

    final registry = _container!.read(_registryProvider);
    return registry[T] as T?;
  }
}

/// Helper function to easily get a service from anywhere
T? getService<T>() => ServiceRegistry().get<T>();
