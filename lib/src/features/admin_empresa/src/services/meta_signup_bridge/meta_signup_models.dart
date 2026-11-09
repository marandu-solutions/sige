/// WhatsApp Embedded Signup Models, DTOs & Exception Architecture
/// Reference: PROJECT.md § Interface Contracts, MD07 §3.1, §6.1, §7.1
library;

/// Status outcome of the Meta Embedded Signup modal flow
enum MetaSignupStatus {
  success,
  cancelled,
  error;

  /// Parses string representation into [MetaSignupStatus] case-insensitively.
  /// Falls back to [MetaSignupStatus.error] for unknown or malformed strings.
  static MetaSignupStatus fromString(String? value) {
    switch (value?.toUpperCase().trim()) {
      case 'SUCCESS':
        return MetaSignupStatus.success;
      case 'CANCELLED':
      case 'CANCELED':
        return MetaSignupStatus.cancelled;
      case 'ERROR':
      default:
        return MetaSignupStatus.error;
    }
  }

  /// Returns uppercase API representation matching Facebook SDK conventions
  String toApiValue() => name.toUpperCase();
}

/// Operational steps during the interactive Embedded Signup flow.
/// Used by Riverpod controllers, UI Steppers, and diagnostic loggers.
enum MetaSignupStep {
  idle,
  authenticatingInMeta,
  capturingSessionIds,
  exchangingTokenAndSubscribing,
  completed,
  error,
  cancelled;

  /// User-friendly Portuguese descriptive label for UI dialogs and steppers
  String get label {
    switch (this) {
      case MetaSignupStep.idle:
        return 'Pronto para iniciar';
      case MetaSignupStep.authenticatingInMeta:
        return 'Autenticando com a Meta...';
      case MetaSignupStep.capturingSessionIds:
        return 'Capturando identificadores (WABA & Telefone)...';
      case MetaSignupStep.exchangingTokenAndSubscribing:
        return 'Ativando webhooks e trocando credenciais...';
      case MetaSignupStep.completed:
        return 'Número conectado e operacional!';
      case MetaSignupStep.error:
        return 'Falha na conexão';
      case MetaSignupStep.cancelled:
        return 'Conexão cancelada';
    }
  }

  /// Sequential step index order for UI Steppers (0-3)
  int get indexOrder => switch (this) {
        MetaSignupStep.idle => 0,
        MetaSignupStep.authenticatingInMeta => 0,
        MetaSignupStep.capturingSessionIds => 1,
        MetaSignupStep.exchangingTokenAndSubscribing => 2,
        MetaSignupStep.completed => 3,
        MetaSignupStep.error => 3,
        MetaSignupStep.cancelled => 3,
      };

  /// Whether this step is an active in-flight processing state
  bool get isInProgress => isProcessing;

  /// Whether this step is an active in-flight processing state
  bool get isProcessing =>
      this == MetaSignupStep.authenticatingInMeta ||
      this == MetaSignupStep.capturingSessionIds ||
      this == MetaSignupStep.exchangingTokenAndSubscribing;

  /// Whether this step represents a terminal/finished state
  bool get isTerminal =>
      this == MetaSignupStep.completed ||
      this == MetaSignupStep.error ||
      this == MetaSignupStep.cancelled;
}

/// Strongly typed DTO returned by the Meta Signup Bridge upon completion
/// of the frontend SDK popup session.
class MetaEmbeddedSignupResult {
  /// Final status of the signup interaction
  final MetaSignupStatus status;

  /// Temporary OAuth authorization code returned by FB.login (expires in minutes)
  final String? code;

  /// WhatsApp Business Account ID captured from the WA_EMBEDDED_SIGNUP event
  final String? wabaId;

  /// WhatsApp Phone Number ID captured from the WA_EMBEDDED_SIGNUP event
  final String? phoneNumberId;

  /// Business Manager ID associated with the selected WABA
  final String? businessId;

  /// Error message or user cancellation reason if status != success
  final String? errorMessage;

  /// Raw data dictionary returned by the JavaScript bridge or simulation
  final Map<String, dynamic>? rawData;

  const MetaEmbeddedSignupResult({
    required this.status,
    this.code,
    this.wabaId,
    this.phoneNumberId,
    this.businessId,
    this.errorMessage,
    this.rawData,
  });

  /// Convenient status inspect getters
  bool get isSuccess => status == MetaSignupStatus.success;
  bool get isCancelled => status == MetaSignupStatus.cancelled;
  bool get isError => status == MetaSignupStatus.error;

  /// Creates a successful result holding all captured identifiers
  factory MetaEmbeddedSignupResult.success({
    required String code,
    required String wabaId,
    required String phoneNumberId,
    String? businessId,
    Map<String, dynamic>? rawData,
  }) {
    return MetaEmbeddedSignupResult(
      status: MetaSignupStatus.success,
      code: code,
      wabaId: wabaId,
      phoneNumberId: phoneNumberId,
      businessId: businessId,
      rawData: rawData,
    );
  }

  /// Creates a cancelled result when the user closes the popup or dismisses login
  factory MetaEmbeddedSignupResult.cancelled({
    String? reason,
    String? errorMessage,
    Map<String, dynamic>? rawData,
  }) {
    return MetaEmbeddedSignupResult(
      status: MetaSignupStatus.cancelled,
      errorMessage: errorMessage ??
          reason ??
          'Fluxo cancelado pelo usuário antes da conclusão.',
      rawData: rawData,
    );
  }

  /// Creates an error result indicating bridge or OAuth runtime failure
  factory MetaEmbeddedSignupResult.error(
    String message, {
    Map<String, dynamic>? rawData,
  }) {
    return MetaEmbeddedSignupResult(
      status: MetaSignupStatus.error,
      errorMessage: message,
      rawData: rawData,
    );
  }

  /// Resilient parser converting JSON maps (from JS Interop, local cache, or tests)
  /// into a strongly typed [MetaEmbeddedSignupResult].
  ///
  /// Supports both snake_case (Meta JS SDK default) and camelCase keys.
  /// Gracefully falls back to [MetaSignupStatus.error] on unknown status values.
  factory MetaEmbeddedSignupResult.fromJson(Map<String, dynamic> json) {
    final rawStatus = (json['status'] as String? ?? '').trim().toLowerCase();
    final MetaSignupStatus status;
    if (rawStatus == 'success') {
      status = MetaSignupStatus.success;
    } else if (rawStatus == 'cancelled' || rawStatus == 'canceled') {
      status = MetaSignupStatus.cancelled;
    } else {
      status = MetaSignupStatus.error;
    }

    String? normalize(dynamic value) {
      if (value == null) return null;
      final str = value.toString().trim();
      return str.isEmpty ? null : str;
    }

    return MetaEmbeddedSignupResult(
      status: status,
      code: normalize(json['code'] ?? json['auth_code']),
      wabaId: normalize(json['waba_id'] ?? json['wabaId']),
      phoneNumberId: normalize(json['phone_number_id'] ?? json['phoneNumberId']),
      businessId: normalize(json['business_id'] ?? json['businessId']),
      errorMessage: normalize(
        json['error_message'] ??
            json['errorMessage'] ??
            json['message'] ??
            json['error'],
      ),
      rawData: json,
    );
  }

  /// Serializes the result to a JSON-compatible map matching Meta SDK expectations
  Map<String, dynamic> toJson() {
    return {
      'status': status.name.toUpperCase(),
      'code': code,
      'waba_id': wabaId,
      'phone_number_id': phoneNumberId,
      'business_id': businessId,
      'error_message': errorMessage,
      if (rawData != null) 'raw_data': rawData,
    };
  }

  /// Immutability helper
  MetaEmbeddedSignupResult copyWith({
    MetaSignupStatus? status,
    String? code,
    String? wabaId,
    String? phoneNumberId,
    String? businessId,
    String? errorMessage,
    Map<String, dynamic>? rawData,
  }) {
    return MetaEmbeddedSignupResult(
      status: status ?? this.status,
      code: code ?? this.code,
      wabaId: wabaId ?? this.wabaId,
      phoneNumberId: phoneNumberId ?? this.phoneNumberId,
      businessId: businessId ?? this.businessId,
      errorMessage: errorMessage ?? this.errorMessage,
      rawData: rawData ?? this.rawData,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MetaEmbeddedSignupResult &&
        other.status == status &&
        other.code == code &&
        other.wabaId == wabaId &&
        other.phoneNumberId == phoneNumberId &&
        other.businessId == businessId &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode => Object.hash(
        status,
        code,
        wabaId,
        phoneNumberId,
        businessId,
        errorMessage,
      );

  @override
  String toString() {
    return 'MetaEmbeddedSignupResult(status: ${status.name}, code: ${code != null ? "[REDACTED]" : "null"}, wabaId: $wabaId, phoneNumberId: $phoneNumberId, businessId: $businessId, errorMessage: $errorMessage)';
  }
}

/// Alias for [MetaEmbeddedSignupResult] for nomenclature compatibility with MD07 §6.1
typedef MetaSignupSessionResult = MetaEmbeddedSignupResult;

/// Machine-readable error code identifiers for [MetaSignupException]
abstract final class MetaSignupErrorCode {
  static const String sdkNotLoaded = 'SDK_NOT_LOADED';
  static const String popupBlocked = 'POPUP_BLOCKED';
  static const String userCancelled = 'USER_CANCELLED';
  static const String missingSessionData = 'MISSING_SESSION_DATA';
  static const String invalidAuthCode = 'INVALID_AUTH_CODE';
  static const String networkTimeout = 'NETWORK_TIMEOUT';
  static const String unsupportedPlatform = 'UNSUPPORTED_PLATFORM';
  static const String backendExchangeFailed = 'BACKEND_EXCHANGE_FAILED';
  static const String unknown = 'UNKNOWN_ERROR';
}

/// Comprehensive, enterprise-grade exception thrown during Meta Signup interactions.
///
/// Encapsulates technical details, machine-readable error codes, and actionable
/// recovery hints to display directly to end-users or administrators.
class MetaSignupException implements Exception {
  /// Detailed description of the error
  final String message;

  /// Machine-readable error code (e.g., [MetaSignupErrorCode.sdkNotLoaded])
  final String errorCode;

  /// Actionable suggestion guiding the user or administrator toward resolution
  final String? recoveryHint;

  /// Underlying platform exception or network error, if available
  final dynamic originalError;

  /// Stack trace associated with the original exception
  final StackTrace? stackTrace;

  const MetaSignupException(
    this.message, {
    String? errorCode,
    String? code,
    this.recoveryHint,
    this.originalError,
    dynamic details,
    this.stackTrace,
  })  : errorCode = errorCode ?? code ?? MetaSignupErrorCode.unknown;

  /// Accessor for error code
  String get code => errorCode;

  /// Accessor for underlying details
  dynamic get details => originalError;

  /// Factory for when the Meta Facebook JS SDK is blocked or unavailable
  factory MetaSignupException.sdkNotLoaded({
    String? details,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return MetaSignupException(
      details ??
          'SDK da Meta (FB) não carregado. Verifique sua conexão HTTPS e bloqueadores de anúncios.',
      errorCode: MetaSignupErrorCode.sdkNotLoaded,
      recoveryHint:
          'Desative temporariamente bloqueadores de anúncios (AdBlock/Brave Shields) ou recarregue a página.',
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }

  /// Factory for when the browser blocks the popup window
  factory MetaSignupException.popupBlocked({
    String? details,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return MetaSignupException(
      details ?? 'O navegador bloqueou a abertura da janela popup da Meta.',
      errorCode: MetaSignupErrorCode.popupBlocked,
      recoveryHint:
          'Habilite a abertura de janelas pop-up nas configurações do seu navegador e tente novamente.',
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }

  /// Factory for when the user explicitly closes or cancels the flow
  factory MetaSignupException.userCancelled({String? details}) {
    return MetaSignupException(
      details ?? 'O fluxo de cadastro incorporado foi cancelado pelo usuário.',
      errorCode: MetaSignupErrorCode.userCancelled,
      recoveryHint:
          'Clique novamente em "Conectar WhatsApp Oficial" para reiniciar o processo quando desejar.',
    );
  }

  /// Factory for when the event listener did not receive the required WABA or Phone IDs
  factory MetaSignupException.missingSessionData({String? details}) {
    return MetaSignupException(
      details ??
          'A Meta não retornou os identificadores obrigatórios (WABA ID ou Phone Number ID).',
      errorCode: MetaSignupErrorCode.missingSessionData,
      recoveryHint:
          'Certifique-se de concluir todas as etapas no popup da Meta, selecionando a Conta WhatsApp e o número verificado.',
    );
  }

  /// Factory for expired or invalid OAuth codes
  factory MetaSignupException.invalidAuthCode({
    String? details,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return MetaSignupException(
      details ?? 'Código de autorização OAuth temporário inválido ou expirado.',
      errorCode: MetaSignupErrorCode.invalidAuthCode,
      recoveryHint:
          'O código de segurança da Meta expirou. Inicie o fluxo novamente para gerar um novo código.',
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }

  /// Factory for network timeouts while communicating with the Meta Graph API
  factory MetaSignupException.networkTimeout({
    String? details,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return MetaSignupException(
      details ?? 'Tempo limite excedido na comunicação com os servidores da Meta.',
      errorCode: MetaSignupErrorCode.networkTimeout,
      recoveryHint:
          'Verifique sua conexão com a internet e tente novamente em instantes.',
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }

  /// Factory for native platforms running without simulation mode
  factory MetaSignupException.unsupportedPlatform({
    String? platformName,
  }) {
    final plat = platformName != null ? ' ($platformName)' : '';
    return MetaSignupException(
      'A plataforma atual$plat não suporta o SDK Web da Meta diretamente.',
      errorCode: MetaSignupErrorCode.unsupportedPlatform,
      recoveryHint:
          'Acesse o SIGE através de um navegador Web homologado (Google Chrome, Edge) ou ative o modo de simulação/homologação.',
    );
  }

  /// Factory for backend exchange or Cloud Function failures
  factory MetaSignupException.backendExchangeFailed({
    required String message,
    String? recoveryHint,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return MetaSignupException(
      message,
      errorCode: MetaSignupErrorCode.backendExchangeFailed,
      recoveryHint: recoveryHint ??
          'Verifique se o backend Cloud Functions está operacional e se as credenciais META_APP_SECRET estão configuradas.',
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer('MetaSignupException[$errorCode]: $message');
    if (recoveryHint != null) {
      buffer.write(' (Dica: $recoveryHint)');
    }
    return buffer.toString();
  }
}

/// Reactive UI state model representing the current lifecycle of the Embedded Signup dialog.
/// Intended for consumption by Riverpod StateNotifiers / AsyncNotifiers in M3 and M4.
class MetaSignupState {
  /// Current operational step
  final MetaSignupStep step;

  /// Successful result if finished
  final MetaEmbeddedSignupResult? result;

  /// Captured exception if failed
  final MetaSignupException? exception;

  /// Diagnostic or user-facing message
  final String? errorMessage;

  /// Suggested resolution guidance
  final String? recoveryHint;

  const MetaSignupState({
    required this.step,
    this.result,
    this.exception,
    this.errorMessage,
    this.recoveryHint,
  });

  /// Initial idle state before interaction starts
  factory MetaSignupState.initial() => const MetaSignupState(step: MetaSignupStep.idle);

  bool get isIdle => step == MetaSignupStep.idle;
  bool get isLoading => step.isProcessing;
  bool get isCompleted => step == MetaSignupStep.completed;
  bool get isCancelled => step == MetaSignupStep.cancelled;
  bool get isError => step == MetaSignupStep.error || errorMessage != null || exception != null;

  MetaSignupState copyWith({
    MetaSignupStep? step,
    MetaEmbeddedSignupResult? result,
    MetaSignupException? exception,
    String? errorMessage,
    String? recoveryHint,
  }) {
    return MetaSignupState(
      step: step ?? this.step,
      result: result ?? this.result,
      exception: exception ?? this.exception,
      errorMessage: errorMessage ?? this.errorMessage,
      recoveryHint: recoveryHint ?? this.recoveryHint,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MetaSignupState &&
        other.step == step &&
        other.result == result &&
        other.exception == exception &&
        other.errorMessage == errorMessage &&
        other.recoveryHint == recoveryHint;
  }

  @override
  int get hashCode => Object.hash(step, result, exception, errorMessage, recoveryHint);

  @override
  String toString() {
    return 'MetaSignupState(step: ${step.name}, isCompleted: $isCompleted, isError: $isError)';
  }
}
