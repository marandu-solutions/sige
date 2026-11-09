import 'dart:async';
import 'meta_mock_contracts.dart';
import 'finops_test_fixtures.dart';

/// Custom error contract matching Firebase Cloud Functions HttpsError
class HttpsErrorContract implements Exception {
  final String code;
  final String message;

  HttpsErrorContract(this.code, this.message);

  @override
  String toString() => 'HttpsErrorContract($code): $message';
}

/// Simulated Multiplatform Meta Signup Bridge
class MockMetaSignupBridge {
  MetaEmbeddedSignupResult? simulatedResult;
  bool shouldThrowException = false;
  String exceptionMessage = 'Bridge runtime failure';

  int launchCallCount = 0;
  String? lastAppId;
  String? lastConfigId;
  bool? lastSimulationMode;

  Future<MetaEmbeddedSignupResult> launchEmbeddedSignup({
    required String appId,
    String? configId,
    bool simulationMode = false,
  }) async {
    launchCallCount++;
    lastAppId = appId;
    lastConfigId = configId;
    lastSimulationMode = simulationMode;

    if (shouldThrowException) {
      throw Exception(exceptionMessage);
    }

    if (simulatedResult != null) {
      return simulatedResult!;
    }

    // Default simulation result
    return FinOpsTestFixtures.sampleSuccessSignupResult();
  }
}

/// Simulated Backend Cloud Function: completeWhatsAppEmbeddedSignup
class MockCompleteWhatsAppSignupBackend {
  bool isAuthenticated = true;
  String currentAuthUid = 'test_user_admin_01';
  bool simulateExpiredCode = false;
  bool simulateWebhookSubscriptionFailure = false;
  bool simulateGraphTimeout = false;

  final Map<String, SecretVaultRecordContract> secretTokensVault = {};
  final Map<String, GlobalRoutingRecordContract> globalRoutingIndex = {};
  final Map<String, WhatsAppNumberModelContract> tenantNumbers = {};

  Future<Map<String, dynamic>> completeWhatsAppEmbeddedSignup({
    required Map<String, dynamic> data,
  }) async {
    // 1. Auth check
    if (!isAuthenticated) {
      throw HttpsErrorContract(
        'unauthenticated',
        'O usuário deve estar autenticado.',
      );
    }

    // 2. Validate mandatory parameters
    final tenantId = data['tenantId'] as String?;
    final code = data['code'] as String?;
    final wabaId = data['wabaId'] as String?;
    final phoneNumberId = data['phoneNumberId'] as String?;

    if (tenantId == null ||
        tenantId.trim().isEmpty ||
        code == null ||
        code.trim().isEmpty ||
        wabaId == null ||
        wabaId.trim().isEmpty ||
        phoneNumberId == null ||
        phoneNumberId.trim().isEmpty) {
      throw HttpsErrorContract(
        'invalid-argument',
        'Parâmetros obrigatórios ausentes (tenantId, code, wabaId, phoneNumberId).',
      );
    }

    // 3. Simule Graph API v21.0 code exchange
    if (simulateGraphTimeout) {
      throw HttpsErrorContract('deadline-exceeded', 'Meta Graph API timeout');
    }

    if (simulateExpiredCode || code.contains('expired')) {
      throw HttpsErrorContract(
        'permission-denied',
        'OAuthException: This authorization code has expired or is invalid.',
      );
    }

    final permanentAccessToken = 'EAAGm0PX4ZCps_${code.hashCode}_permanent_token';

    // 4. Simule subscribed_apps registration
    if (simulateWebhookSubscriptionFailure) {
      throw HttpsErrorContract(
        'internal',
        'Failed to subscribe application to WABA webhooks (Graph error).',
      );
    }

    final now = DateTime.now();

    // 5. Atomic Batch Write: Secret Vault
    final secretVaultDoc = SecretVaultRecordContract(
      tenantId: tenantId,
      wabaId: wabaId,
      phoneNumberId: phoneNumberId,
      accessToken: permanentAccessToken,
      scopes: const [
        'whatsapp_business_management',
        'whatsapp_business_messaging',
      ],
      updatedAt: now,
    );
    secretTokensVault['$tenantId/$phoneNumberId'] = secretVaultDoc;

    // 6. Atomic Batch Write: Global Routing Index O(1)
    final routingDoc = GlobalRoutingRecordContract(
      phoneNumberId: phoneNumberId,
      wabaId: wabaId,
      tenantId: tenantId,
      active: true,
      updatedAt: now,
    );
    globalRoutingIndex[phoneNumberId] = routingDoc;

    // 7. Atomic Batch Write: Public Tenant Number
    final publicDoc = WhatsAppNumberModelContract(
      id: phoneNumberId,
      tenantId: tenantId,
      wabaId: wabaId,
      phoneNumberId: phoneNumberId,
      displayPhoneNumber: '+55 11 98877-6655',
      verifiedName: 'Empresa Teste WhatsApp Oficial',
      qualityRating: MetaQualityRating.green,
      messagingLimitTier: MetaMessagingTier.tier1k,
      codeVerificationStatus: 'VERIFIED',
      status: 'connected',
      webhookSubscribed: true,
      isDefault: tenantNumbers.values.where((n) => n.tenantId == tenantId).isEmpty,
      iaAtivaNesteNumero: true,
      connectedByUid: currentAuthUid,
      connectedAt: now,
      lastSyncAt: now,
    );
    tenantNumbers['$tenantId/$phoneNumberId'] = publicDoc;

    return {
      'success': true,
      'number': publicDoc.toFirestoreMap(),
    };
  }
}

/// Simulated WhatsAppMetaService orchestrating flow, Firestore Streams & FinOps Telemetry
class MockWhatsAppMetaService {
  final MockMetaSignupBridge bridge;
  final MockCompleteWhatsAppSignupBackend backend;

  final _numbersController = StreamController<List<WhatsAppNumberModelContract>>.broadcast();
  final _finopsController = StreamController<FinOpsUsageModelContract>.broadcast();

  final List<WhatsAppNumberModelContract> _inMemoryNumbers = [];
  FinOpsUsageModelContract? _currentFinops;

  MockWhatsAppMetaService({
    required this.bridge,
    required this.backend,
  });

  void seedInitialData({
    List<WhatsAppNumberModelContract>? numbers,
    FinOpsUsageModelContract? finops,
  }) {
    if (numbers != null) {
      _inMemoryNumbers.clear();
      _inMemoryNumbers.addAll(numbers);
      _numbersController.add(List.unmodifiable(_inMemoryNumbers));
    }
    if (finops != null) {
      _currentFinops = finops;
      _finopsController.add(finops);
    }
  }

  Stream<List<WhatsAppNumberModelContract>> watchConnectedNumbers(String tenantId) {
    // Immediate initial push
    Future.microtask(() {
      final filtered = _inMemoryNumbers.where((n) => n.tenantId == tenantId).toList();
      _numbersController.add(filtered);
    });
    return _numbersController.stream;
  }

  Stream<FinOpsUsageModelContract> watchUsageMetrics(String tenantId, String competencia) {
    Future.microtask(() {
      if (_currentFinops != null &&
          _currentFinops!.tenantId == tenantId &&
          _currentFinops!.competencia == competencia) {
        _finopsController.add(_currentFinops!);
      }
    });
    return _finopsController.stream;
  }

  Future<WhatsAppNumberModelContract> completeOnboarding({
    required String tenantId,
    required String appId,
    String? configId,
    bool simulationMode = false,
  }) async {
    // 1. Launch popup via bridge
    final signupResult = await bridge.launchEmbeddedSignup(
      appId: appId,
      configId: configId,
      simulationMode: simulationMode,
    );

    if (signupResult.isCancelled) {
      throw Exception(signupResult.errorMessage ?? 'Cancelled by user');
    }

    if (signupResult.isError || signupResult.code == null) {
      throw Exception(signupResult.errorMessage ?? 'Signup failed');
    }

    // 2. Call backend
    final response = await backend.completeWhatsAppEmbeddedSignup(
      data: {
        'tenantId': tenantId,
        'code': signupResult.code,
        'wabaId': signupResult.wabaId,
        'phoneNumberId': signupResult.phoneNumberId,
      },
    );

    final numberMap = response['number'] as Map<String, dynamic>;
    final newNumber = WhatsAppNumberModelContract.fromFirestoreMap(
      signupResult.phoneNumberId!,
      numberMap,
    );

    _inMemoryNumbers.removeWhere((n) => n.id == newNumber.id);
    _inMemoryNumbers.add(newNumber);
    _numbersController.add(List.unmodifiable(_inMemoryNumbers));

    return newNumber;
  }

  Future<void> toggleIa({
    required String tenantId,
    required String phoneNumberId,
    required bool enabled,
  }) async {
    final idx = _inMemoryNumbers.indexWhere(
      (n) => n.tenantId == tenantId && n.phoneNumberId == phoneNumberId,
    );
    if (idx != -1) {
      final updated = _inMemoryNumbers[idx].copyWith(
        iaAtivaNesteNumero: enabled,
        lastSyncAt: DateTime.now(),
      );
      _inMemoryNumbers[idx] = updated;
      _numbersController.add(List.unmodifiable(_inMemoryNumbers));
    }
  }

  Future<void> syncNumber({
    required String tenantId,
    required String phoneNumberId,
  }) async {
    final idx = _inMemoryNumbers.indexWhere(
      (n) => n.tenantId == tenantId && n.phoneNumberId == phoneNumberId,
    );
    if (idx != -1) {
      final updated = _inMemoryNumbers[idx].copyWith(
        lastSyncAt: DateTime.now(),
      );
      _inMemoryNumbers[idx] = updated;
      _numbersController.add(List.unmodifiable(_inMemoryNumbers));
    }
  }

  Future<void> removeNumber({
    required String tenantId,
    required String phoneNumberId,
  }) async {
    _inMemoryNumbers.removeWhere(
      (n) => n.tenantId == tenantId && n.phoneNumberId == phoneNumberId,
    );
    _numbersController.add(List.unmodifiable(_inMemoryNumbers));
  }

  Future<void> updateMonthlyBudget({
    required String tenantId,
    required String competencia,
    required double newBudgetBrl,
  }) async {
    if (_currentFinops != null &&
        _currentFinops!.tenantId == tenantId &&
        _currentFinops!.competencia == competencia) {
      _currentFinops = FinOpsUsageModelContract(
        competencia: _currentFinops!.competencia,
        tenantId: _currentFinops!.tenantId,
        orcamentoMensalBrl: newBudgetBrl,
        alertaOrcamentoPercentual: _currentFinops!.alertaOrcamentoPercentual,
        iaMetrics: _currentFinops!.iaMetrics,
        whatsappMetrics: _currentFinops!.whatsappMetrics,
        historicoDiario: _currentFinops!.historicoDiario,
        updatedAt: DateTime.now(),
      );
      _finopsController.add(_currentFinops!);
    }
  }

  Future<void> recordTelemetryUsage({
    required String tenantId,
    required String competencia,
    required double additionalIaCost,
    required double additionalWaCost,
    required int additionalMsgs,
    int? tokensIn,
    int? tokensOut,
  }) async {
    if (_currentFinops == null) return;

    final updatedIa = IaMetricsContract(
      totalRequests: _currentFinops!.iaMetrics.totalRequests + 1,
      tokensInput: _currentFinops!.iaMetrics.tokensInput + (tokensIn ?? 150),
      tokensOutput: _currentFinops!.iaMetrics.tokensOutput + (tokensOut ?? 50),
      audiosTranscritosMinutos: _currentFinops!.iaMetrics.audiosTranscritosMinutos,
      documentosAnalisados: _currentFinops!.iaMetrics.documentosAnalisados,
      custoAcumuladoBrl: _currentFinops!.iaMetrics.custoAcumuladoBrl + additionalIaCost,
      economiaEstimadaHorasHumanas: _currentFinops!.iaMetrics.economiaEstimadaHorasHumanas + 0.1,
    );

    final updatedWa = WhatsAppMetricsContract(
      totalConversas: _currentFinops!.whatsappMetrics.totalConversas + additionalMsgs,
      conversasServicoGratuitas: _currentFinops!.whatsappMetrics.conversasServicoGratuitas,
      conversasUtilidade: _currentFinops!.whatsappMetrics.conversasUtilidade + additionalMsgs,
      conversasMarketing: _currentFinops!.whatsappMetrics.conversasMarketing,
      conversasAutenticacao: _currentFinops!.whatsappMetrics.conversasAutenticacao,
      custoAcumuladoBrl: _currentFinops!.whatsappMetrics.custoAcumuladoBrl + additionalWaCost,
    );

    _currentFinops = FinOpsUsageModelContract(
      competencia: _currentFinops!.competencia,
      tenantId: _currentFinops!.tenantId,
      orcamentoMensalBrl: _currentFinops!.orcamentoMensalBrl,
      alertaOrcamentoPercentual: _currentFinops!.alertaOrcamentoPercentual,
      iaMetrics: updatedIa,
      whatsappMetrics: updatedWa,
      historicoDiario: _currentFinops!.historicoDiario,
      updatedAt: DateTime.now(),
    );

    _finopsController.add(_currentFinops!);
  }

  void dispose() {
    _numbersController.close();
    _finopsController.close();
  }
}

/// Static HTML specification inspector to verify web/index.html requirements
class WebIndexHtmlInspector {
  static bool hasAsyncSdkScript(String htmlContent) {
    return htmlContent.contains('connect.facebook.net/en_US/sdk.js') &&
        (htmlContent.contains('async') || htmlContent.contains('defer') || htmlContent.contains('createElement'));
  }

  static bool hasOriginFilteredMessageListener(String htmlContent) {
    return htmlContent.contains('addEventListener(\'message\'') ||
        htmlContent.contains('addEventListener("message"');
  }

  static bool hasOriginWhitelisting(String htmlContent) {
    return htmlContent.contains('facebook.com');
  }

  static bool hasEmbeddedSignupEventTypeCheck(String htmlContent) {
    return htmlContent.contains('WA_EMBEDDED_SIGNUP');
  }

  static bool hasLaunchFunction(String htmlContent) {
    return htmlContent.contains('sigeLaunchWhatsAppEmbeddedSignup');
  }

  static bool hasSessionInfoVersion3(String htmlContent) {
    return htmlContent.contains('sessionInfoVersion') &&
        (htmlContent.contains("'3'") || htmlContent.contains('"3"'));
  }

  static bool hasRequiredScopes(String htmlContent) {
    return htmlContent.contains('whatsapp_business_management') &&
        htmlContent.contains('whatsapp_business_messaging');
  }
}
