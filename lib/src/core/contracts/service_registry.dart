/// Registro Central de Serviços e Inversão de Controle (IoC)
/// Permite que features opcionais (como Leads ou Estoque) registrem implementações
/// sem que o Atendimento precise importar os pacotes diretamente.
class ServiceRegistry {
  static final ServiceRegistry _instance = ServiceRegistry._internal();
  factory ServiceRegistry() => _instance;
  ServiceRegistry._internal();

  final Map<Type, dynamic> _services = {};

  /// Registra a implementação de uma interface [T]
  void register<T>(T service) {
    _services[T] = service;
  }

  /// Remove o registro de [T]
  void unregister<T>() {
    _services.remove(T);
  }

  /// Recupera o serviço registrado ou retorna null caso a feature não esteja instalada/ativa
  T? get<T>() {
    return _services[T] as T?;
  }

  /// Verifica se o serviço está registrado
  bool has<T>() => _services.containsKey(T);

  /// Limpa todos os serviços (útil para testes ou logout)
  void clear() {
    _services.clear();
  }
}

/// Acesso simplificado a serviços registrados
T? getService<T>() => ServiceRegistry().get<T>();
