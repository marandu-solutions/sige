// ignore_for_file: subtype_of_sealed_class, annotate_overrides

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sige/src/features/admin_empresa/src/models/whatsapp_number_model.dart';
import 'package:sige/src/features/admin_empresa/src/providers/whatsapp_finops_providers.dart';
import 'package:sige/src/features/admin_empresa/src/services/meta_signup_bridge/meta_signup_bridge.dart';
import 'package:sige/src/features/admin_empresa/src/services/whatsapp_meta_service.dart';

// =============================================================================
// Lightweight Test Doubles for Firestore, Functions & Meta Bridge
// =============================================================================

class FakeQueryDocumentSnapshot extends Fake
    implements QueryDocumentSnapshot<Map<String, dynamic>> {
  final String _id;
  final Map<String, dynamic> _data;

  FakeQueryDocumentSnapshot(this._id, this._data);

  @override
  String get id => _id;

  @override
  bool get exists => true;

  @override
  Map<String, dynamic> data() => _data;
}

class FakeDocumentSnapshot extends Fake
    implements DocumentSnapshot<Map<String, dynamic>> {
  final String _id;
  final Map<String, dynamic>? _data;
  final bool _exists;

  FakeDocumentSnapshot(this._id, this._data, this._exists);

  @override
  String get id => _id;

  @override
  bool get exists => _exists;

  @override
  Map<String, dynamic>? data() => _data;
}

class FakeQuerySnapshot extends Fake
    implements QuerySnapshot<Map<String, dynamic>> {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _docs;
  FakeQuerySnapshot(this._docs);

  @override
  List<QueryDocumentSnapshot<Map<String, dynamic>>> get docs => _docs;
}

class FakeDocumentReference extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  final String path;
  final FakeFirebaseFirestore firestore;

  FakeDocumentReference(this.path, this.firestore);

  @override
  String get id => path.split('/').last;

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    return FakeCollectionReference('$path/$collectionPath', firestore);
  }

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    if (options?.merge == true && firestore.storage.containsKey(path)) {
      final existing =
          (firestore.storage[path] as Map<String, dynamic>?) ?? {};
      firestore.storage[path] = {...existing, ...data};
    } else {
      firestore.storage[path] = Map<String, dynamic>.from(data);
    }
    firestore.notifyListeners(path);
  }

  @override
  Future<void> update(Map<Object, Object?> data) async {
    final existing = (firestore.storage[path] as Map<String, dynamic>?) ?? {};
    firestore.storage[path] = {...existing, ...data.cast<String, dynamic>()};
    firestore.notifyListeners(path);
  }

  @override
  Future<void> delete() async {
    firestore.storage.remove(path);
    firestore.notifyListeners(path);
  }

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get(
      [GetOptions? options]) async {
    final exists = firestore.storage.containsKey(path);
    final data =
        exists ? (firestore.storage[path] as Map<String, dynamic>) : null;
    return FakeDocumentSnapshot(id, data, exists);
  }

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) {
    late StreamController<DocumentSnapshot<Map<String, dynamic>>> controller;
    void emit() {
      if (controller.isClosed) return;
      final exists = firestore.storage.containsKey(path);
      final data =
          exists ? (firestore.storage[path] as Map<String, dynamic>) : null;
      controller.add(FakeDocumentSnapshot(id, data, exists));
    }

    controller =
        StreamController<DocumentSnapshot<Map<String, dynamic>>>.broadcast(
      onListen: () {
        scheduleMicrotask(emit);
        firestore.registerPathListener(path, emit);
      },
      onCancel: () {
        firestore.unregisterPathListener(path, emit);
      },
    );

    return controller.stream;
  }
}

class FakeCollectionReference extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  final String path;
  final FakeFirebaseFirestore firestore;

  FakeCollectionReference(this.path, this.firestore);

  @override
  DocumentReference<Map<String, dynamic>> doc([String? docPath]) {
    final sub = docPath ?? 'auto_${DateTime.now().microsecondsSinceEpoch}';
    return FakeDocumentReference('$path/$sub', firestore);
  }

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) {
    late StreamController<QuerySnapshot<Map<String, dynamic>>> controller;
    void emit() {
      final docs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
      final prefix = '$path/';
      for (final entry in firestore.storage.entries) {
        if (entry.key.startsWith(prefix)) {
          final sub = entry.key.substring(prefix.length);
          if (!sub.contains('/')) {
            docs.add(FakeQueryDocumentSnapshot(
                sub, entry.value as Map<String, dynamic>));
          }
        }
      }
      if (!controller.isClosed) {
        controller.add(FakeQuerySnapshot(docs));
      }
    }

    controller = StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast(
      onListen: () {
        scheduleMicrotask(emit);
        firestore.registerCollectionListener(path, emit);
      },
      onCancel: () {
        firestore.unregisterCollectionListener(path, emit);
      },
    );

    return controller.stream;
  }
}

class FakeFirebaseFirestore extends Fake implements FirebaseFirestore {
  final Map<String, dynamic> storage = {};
  final Map<String, List<void Function()>> _pathListeners = {};
  final Map<String, List<void Function()>> _collectionListeners = {};

  void registerPathListener(String path, void Function() listener) {
    _pathListeners.putIfAbsent(path, () => []).add(listener);
  }

  void unregisterPathListener(String path, void Function() listener) {
    _pathListeners[path]?.remove(listener);
  }

  void registerCollectionListener(String path, void Function() listener) {
    _collectionListeners.putIfAbsent(path, () => []).add(listener);
  }

  void unregisterCollectionListener(String path, void Function() listener) {
    _collectionListeners[path]?.remove(listener);
  }

  void notifyListeners(String changedPath) {
    // Notify exact path listeners
    final listeners = _pathListeners[changedPath];
    if (listeners != null) {
      for (final l in List<void Function()>.from(listeners)) {
        l();
      }
    }
    // Notify parent collection listeners
    final lastSlash = changedPath.lastIndexOf('/');
    if (lastSlash != -1) {
      final colPath = changedPath.substring(0, lastSlash);
      final colListeners = _collectionListeners[colPath];
      if (colListeners != null) {
        for (final l in List<void Function()>.from(colListeners)) {
          l();
        }
      }
    }
  }

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    return FakeCollectionReference(collectionPath, this);
  }
}

class FakeHttpsCallableResult<T> extends Fake implements HttpsCallableResult<T> {
  @override
  final T data;
  FakeHttpsCallableResult(this.data);
}

class FakeHttpsCallable extends Fake implements HttpsCallable {
  final Future<HttpsCallableResult<dynamic>> Function(dynamic parameters)?
      handler;
  FakeHttpsCallable({this.handler});

  @override
  Future<HttpsCallableResult<T>> call<T>([dynamic parameters]) async {
    if (handler != null) {
      final res = await handler!(parameters);
      return res as HttpsCallableResult<T>;
    }
    throw UnimplementedError('call');
  }
}

class FakeFirebaseFunctions extends Fake implements FirebaseFunctions {
  final HttpsCallable Function(String name, HttpsCallableOptions? options)?
      callableFactory;
  FakeFirebaseFunctions({this.callableFactory});

  @override
  HttpsCallable httpsCallable(String name, {HttpsCallableOptions? options}) {
    if (callableFactory != null) {
      return callableFactory!(name, options);
    }
    throw UnimplementedError('httpsCallable');
  }
}

class TestableMetaBridge implements MetaSignupBridge {
  MetaEmbeddedSignupResult? simulatedResult;
  bool shouldThrowException = false;
  String exceptionMessage = 'Bridge runtime crash in JS SDK';
  int launchCallCount = 0;
  bool lastSimulationMode = false;

  @override
  bool get isSupported => true;

  @override
  String get platformName => 'testable_meta_bridge';

  @override
  Future<MetaEmbeddedSignupResult> launchEmbeddedSignup({
    required String appId,
    String? configId,
    bool simulationMode = false,
  }) async {
    launchCallCount++;
    lastSimulationMode = simulationMode;

    if (shouldThrowException) {
      throw Exception(exceptionMessage);
    }
    if (simulatedResult != null) {
      return simulatedResult!;
    }
    return MetaEmbeddedSignupResult.success(
      code: 'mock_code_123',
      wabaId: 'mock_waba_456',
      phoneNumberId: 'mock_phone_789',
    );
  }
}

// =============================================================================
// MAIN STRESS TEST HARNESS
// =============================================================================

void main() {
  // ---------------------------------------------------------------------------
  // A) ONBOARDING ERROR TRANSITIONS & CONTROLLER STRESS TESTS
  // ---------------------------------------------------------------------------
  group('A) Onboarding Error Transitions & Controller Stress Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FakeFirebaseFunctions fakeFunctions;
    late TestableMetaBridge mockBridge;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      fakeFunctions = FakeFirebaseFunctions(
        callableFactory: (name, options) => FakeHttpsCallable(
          handler: (params) async => FakeHttpsCallableResult<Map<String, dynamic>>({
            'success': true,
            'number': {
              'id': '109283746511223',
              'tenant_id': params['tenantId'],
              'waba_id': params['wabaId'],
              'phone_number_id': params['phoneNumberId'],
              'display_phone_number': '+55 11 98877-6655',
              'verified_name': 'SIGE Enterprise Verified',
              'quality_rating': 'GREEN',
              'messaging_limit_tier': 'TIER_1K',
              'code_verification_status': 'VERIFIED',
              'status': 'connected',
              'webhook_subscribed': true,
              'ia_ativa_neste_numero': true,
              'connected_at': DateTime.now().toIso8601String(),
            },
          }),
        ),
      );
      mockBridge = TestableMetaBridge();
    });

    test('1. Bridge crash throws and controller captures error without UI freeze', () async {
      mockBridge.shouldThrowException = true;
      mockBridge.exceptionMessage = 'FB.login is not a function (bridge script missing)';

      final service = WhatsAppMetaService(
        firestore: fakeFirestore,
        functions: fakeFunctions,
        bridge: mockBridge,
      );

      final controller = EmbeddedSignupController(service);

      // Verify initial state
      expect(controller.state.step, equals(MetaSignupStep.idle));
      expect(controller.state.isBusy, isFalse);

      // Execute onboarding (must complete Future and NOT hang)
      final future = controller.startOnboarding(
        tenantId: 'tenant_epi_01',
        appId: '1234567890',
      );

      await future;

      // Assert error captured and UI is unblocked
      expect(controller.state.isBusy, isFalse);
      expect(controller.state.isError, isTrue);
      expect(controller.state.step, equals(MetaSignupStep.error));
      expect(controller.state.errorMessage, contains('FB.login is not a function'));
      expect(controller.state.connectedNumber, isNull);

      // Reset clears state
      controller.reset();
      expect(controller.state.step, equals(MetaSignupStep.idle));
      expect(controller.state.errorMessage, isNull);
      expect(controller.state.isBusy, isFalse);
    });

    test('2. Bridge returning error status is correctly captured and yields error state', () async {
      mockBridge.simulatedResult = MetaEmbeddedSignupResult.error(
        'Meta Embedded Signup dialog blocked by popup blocker',
      );

      final service = WhatsAppMetaService(
        firestore: fakeFirestore,
        functions: fakeFunctions,
        bridge: mockBridge,
      );

      final controller = EmbeddedSignupController(service);

      await controller.startOnboarding(
        tenantId: 'tenant_epi_01',
        appId: '1234567890',
      );

      expect(controller.state.isBusy, isFalse);
      expect(controller.state.isError, isTrue);
      expect(controller.state.step, equals(MetaSignupStep.error));
      expect(
        controller.state.errorMessage,
        contains('popup blocker'),
      );
    });

    test('3. Bridge returning missing session data throws missingSessionData', () async {
      mockBridge.simulatedResult = const MetaEmbeddedSignupResult(
        status: MetaSignupStatus.success,
        code: 'valid_oauth_code',
        wabaId: null, // missing WABA ID
        phoneNumberId: null,
      );

      final service = WhatsAppMetaService(
        firestore: fakeFirestore,
        functions: fakeFunctions,
        bridge: mockBridge,
      );

      final controller = EmbeddedSignupController(service);

      await controller.startOnboarding(
        tenantId: 'tenant_epi_01',
        appId: '1234567890',
      );

      expect(controller.state.isBusy, isFalse);
      expect(controller.state.isError, isTrue);
      expect(
        controller.state.errorMessage,
        contains('Identificadores WABA ID ou Phone Number ID não foram retornados'),
      );
    });

    test('4. Cloud Function rejection (permission-denied) captured without UI freeze', () async {
      mockBridge.simulatedResult = const MetaEmbeddedSignupResult(
        status: MetaSignupStatus.success,
        code: 'real_oauth_live_code_123',
        wabaId: 'waba_999888',
        phoneNumberId: 'phone_777666',
      );

      // Cloud Function returns permission-denied / token exchange error
      final rejectedFunctions = FakeFirebaseFunctions(
        callableFactory: (name, options) => FakeHttpsCallable(
          handler: (params) async {
            throw Exception('FirebaseFunctionsException(permission-denied, OAuth exchange code invalid or expired)');
          },
        ),
      );

      final service = WhatsAppMetaService(
        firestore: fakeFirestore,
        functions: rejectedFunctions,
        bridge: mockBridge,
      );

      final controller = EmbeddedSignupController(service);

      await controller.startOnboarding(
        tenantId: 'tenant_epi_01',
        appId: '1234567890',
        simulationMode: false,
      );

      expect(controller.state.isBusy, isFalse);
      expect(controller.state.isError, isTrue);
      expect(controller.state.step, equals(MetaSignupStep.error));
      expect(controller.state.errorMessage, contains('OAuth exchange code invalid or expired'));
      expect(controller.state.connectedNumber, isNull);
    });

    test('5. User cancellation yields cancelled state without hanging or error state', () async {
      mockBridge.simulatedResult = MetaEmbeddedSignupResult.cancelled(
        reason: 'Janela fechada pelo usuário antes da confirmação do número.',
      );

      final service = WhatsAppMetaService(
        firestore: fakeFirestore,
        functions: fakeFunctions,
        bridge: mockBridge,
      );

      final controller = EmbeddedSignupController(service);

      await controller.startOnboarding(
        tenantId: 'tenant_epi_01',
        appId: '1234567890',
      );

      expect(controller.state.isBusy, isFalse);
      expect(controller.state.isCancelled, isTrue);
      expect(controller.state.isError, isFalse);
      expect(controller.state.step, equals(MetaSignupStep.cancelled));
      expect(controller.state.errorMessage, contains('Janela fechada pelo usuário'));
      expect(controller.state.connectedNumber, isNull);
    });

    test('6. User retry flow: cancellation -> retry -> successful completion', () async {
      // Step 1: User cancels popup
      mockBridge.simulatedResult = MetaEmbeddedSignupResult.cancelled(
        reason: 'Popup closed',
      );

      final service = WhatsAppMetaService(
        firestore: fakeFirestore,
        functions: fakeFunctions,
        bridge: mockBridge,
      );

      final controller = EmbeddedSignupController(service);

      await controller.startOnboarding(
        tenantId: 'tenant_epi_01',
        appId: '1234567890',
      );

      expect(controller.state.isCancelled, isTrue);

      // Step 2: User clicks "Tentar Novamente" - Bridge now returns success credentials
      mockBridge.simulatedResult = const MetaEmbeddedSignupResult(
        status: MetaSignupStatus.success,
        code: 'retry_auth_code_999',
        wabaId: 'retry_waba_888',
        phoneNumberId: 'retry_phone_777',
      );

      await controller.startOnboarding(
        tenantId: 'tenant_epi_01',
        appId: '1234567890',
      );

      expect(controller.state.isBusy, isFalse);
      expect(controller.state.isCompleted, isTrue);
      expect(controller.state.isCancelled, isFalse);
      expect(controller.state.isError, isFalse);
      expect(controller.state.step, equals(MetaSignupStep.completed));
      expect(controller.state.connectedNumber, isNotNull);
      expect(controller.state.connectedNumber!.phoneNumberId, equals('retry_phone_777'));
    });
  });

  // ---------------------------------------------------------------------------
  // B) PROVIDER REACTIVITY & MULTI-TENANT ISOLATION STRESS TESTS
  // ---------------------------------------------------------------------------
  group('B) Provider Reactivity & Multi-Tenant Isolation Stress Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late WhatsAppMetaService service;

    setUp(() async {
      fakeFirestore = FakeFirebaseFirestore();
      service = WhatsAppMetaService(firestore: fakeFirestore);

      // Seed tenant_alpha across 3 competencies with distinct telemetry
      // 2026_11: Healthy (Total 450.0 / 1000.0 = 45%)
      await fakeFirestore
          .collection('tenant')
          .doc('tenant_alpha')
          .collection('usage_metrics')
          .doc('2026_11')
          .set({
        'competencia': '2026_11',
        'tenant_id': 'tenant_alpha',
        'orcamento_mensal_brl': 1000.0,
        'alerta_orcamento_percentual': 80.0,
        'ia_metrics': {'custo_acumulado_brl': 200.0},
        'whatsapp_metrics': {'custo_acumulado_brl': 250.0},
        'updated_at': DateTime.now().toIso8601String(),
      });

      // 2026_10: Warning (Total 850.0 / 1000.0 = 85%)
      await fakeFirestore
          .collection('tenant')
          .doc('tenant_alpha')
          .collection('usage_metrics')
          .doc('2026_10')
          .set({
        'competencia': '2026_10',
        'tenant_id': 'tenant_alpha',
        'orcamento_mensal_brl': 1000.0,
        'alerta_orcamento_percentual': 80.0,
        'ia_metrics': {'custo_acumulado_brl': 400.0},
        'whatsapp_metrics': {'custo_acumulado_brl': 450.0},
        'updated_at': DateTime.now().toIso8601String(),
      });

      // 2026_09: Exceeded (Total 1150.0 / 1000.0 = 115%)
      await fakeFirestore
          .collection('tenant')
          .doc('tenant_alpha')
          .collection('usage_metrics')
          .doc('2026_09')
          .set({
        'competencia': '2026_09',
        'tenant_id': 'tenant_alpha',
        'orcamento_mensal_brl': 1000.0,
        'alerta_orcamento_percentual': 80.0,
        'ia_metrics': {'custo_acumulado_brl': 650.0},
        'whatsapp_metrics': {'custo_acumulado_brl': 500.0},
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Seed tenant_beta with fixed 2026_11 (Healthy: 100.0 / 1000.0 = 10%)
      await fakeFirestore
          .collection('tenant')
          .doc('tenant_beta')
          .collection('usage_metrics')
          .doc('2026_11')
          .set({
        'competencia': '2026_11',
        'tenant_id': 'tenant_beta',
        'orcamento_mensal_brl': 1000.0,
        'alerta_orcamento_percentual': 80.0,
        'ia_metrics': {'custo_acumulado_brl': 50.0},
        'whatsapp_metrics': {'custo_acumulado_brl': 50.0},
        'updated_at': DateTime.now().toIso8601String(),
      });
    });

    test('1. Mutating selectedCompetenciaProvider updates usageFinopsStreamProvider target without stale data', () async {
      final container = ProviderContainer(
        overrides: [
          whatsappMetaServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(container.dispose);

      // Start at 2026_11
      container.read(selectedCompetenciaProvider('tenant_alpha').notifier).state = '2026_11';
      final modelNov = await container.read(usageFinopsStreamProvider('tenant_alpha').future);

      expect(modelNov, isNotNull);
      expect(modelNov!.competencia, equals('2026_11'));
      expect(modelNov.totalInvestimentoBrl, equals(450.0));
      expect(container.read(finopsBudgetAlertProvider('tenant_alpha')), isFalse);
      expect(container.read(finopsBudgetExceededProvider('tenant_alpha')), isFalse);

      // Mutate to 2026_10 -> verifies immediate reactive switch to October document
      container.read(selectedCompetenciaProvider('tenant_alpha').notifier).state = '2026_10';
      final modelOct = await container.read(usageFinopsStreamProvider('tenant_alpha').future);

      expect(modelOct, isNotNull);
      expect(modelOct!.competencia, equals('2026_10'));
      expect(modelOct.totalInvestimentoBrl, equals(850.0));
      expect(container.read(finopsBudgetAlertProvider('tenant_alpha')), isTrue);
      expect(container.read(finopsBudgetExceededProvider('tenant_alpha')), isFalse);

      // Mutate to 2026_09 -> verifies immediate reactive switch to September document
      container.read(selectedCompetenciaProvider('tenant_alpha').notifier).state = '2026_09';
      final modelSep = await container.read(usageFinopsStreamProvider('tenant_alpha').future);

      expect(modelSep, isNotNull);
      expect(modelSep!.competencia, equals('2026_09'));
      expect(modelSep.totalInvestimentoBrl, equals(1150.0));
      expect(container.read(finopsBudgetAlertProvider('tenant_alpha')), isTrue);
      expect(container.read(finopsBudgetExceededProvider('tenant_alpha')), isTrue);
    });

    test('2. Multi-tenant isolation: mutating tenant_alpha does NOT leak or mutate tenant_beta', () async {
      final container = ProviderContainer(
        overrides: [
          whatsappMetaServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(container.dispose);

      // Set tenant_alpha to 2026_09 (exceeded)
      container.read(selectedCompetenciaProvider('tenant_alpha').notifier).state = '2026_09';
      // Set tenant_beta to 2026_11 (healthy)
      container.read(selectedCompetenciaProvider('tenant_beta').notifier).state = '2026_11';

      final modelAlpha = await container.read(usageFinopsStreamProvider('tenant_alpha').future);
      final modelBeta = await container.read(usageFinopsStreamProvider('tenant_beta').future);

      // Verify tenant_alpha is 2026_09 and exceeded
      expect(modelAlpha!.tenantId, equals('tenant_alpha'));
      expect(modelAlpha.competencia, equals('2026_09'));
      expect(container.read(finopsBudgetExceededProvider('tenant_alpha')), isTrue);

      // Verify tenant_beta is untouched, strictly isolated, and healthy
      expect(modelBeta!.tenantId, equals('tenant_beta'));
      expect(modelBeta.competencia, equals('2026_11'));
      expect(modelBeta.totalInvestimentoBrl, equals(100.0));
      expect(container.read(finopsBudgetAlertProvider('tenant_beta')), isFalse);
      expect(container.read(finopsBudgetExceededProvider('tenant_beta')), isFalse);
    });

    test('3. Selecting non-existent competency yields zeroState without crashing', () async {
      final container = ProviderContainer(
        overrides: [
          whatsappMetaServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(container.dispose);

      // Set to 2025_01 (no document exists in Firestore)
      container.read(selectedCompetenciaProvider('tenant_alpha').notifier).state = '2025_01';
      final modelZero = await container.read(usageFinopsStreamProvider('tenant_alpha').future);

      expect(modelZero, isNotNull);
      expect(modelZero!.competencia, equals('2025_01'));
      expect(modelZero.orcamentoMensalBrl, equals(1000.0));
      expect(modelZero.totalInvestimentoBrl, equals(0.0));
      expect(modelZero.percentualOrcamentoConsumido, equals(0.0));
      expect(container.read(finopsBudgetAlertProvider('tenant_alpha')), isFalse);
      expect(container.read(finopsBudgetExceededProvider('tenant_alpha')), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // C) MOCK & SIMULATION MODE STRESS TESTS
  // ---------------------------------------------------------------------------
  group('C) Mock / Simulation Mode Stress Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FakeFirebaseFunctions fakeFunctions;
    late TestableMetaBridge mockBridge;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockBridge = TestableMetaBridge();
    });

    test('1. Simulation mode executes end-to-end flow from service and persists fallback record', () async {
      mockBridge.simulatedResult = const MetaEmbeddedSignupResult(
        status: MetaSignupStatus.success,
        code: 'sim_auth_code_alpha_999',
        wabaId: 'sim_waba_alpha_888',
        phoneNumberId: 'sim_phone_alpha_777',
      );

      // Simulate Cloud Functions being unavailable in local dev / emulator
      fakeFunctions = FakeFirebaseFunctions(
        callableFactory: (name, options) => FakeHttpsCallable(
          handler: (params) async {
            throw Exception('FirebaseFunctionsException(unavailable, Cloud Functions not reachable in dev)');
          },
        ),
      );

      final service = WhatsAppMetaService(
        firestore: fakeFirestore,
        functions: fakeFunctions,
        bridge: mockBridge,
      );

      final steps = <MetaSignupStep>[];

      final connectedNumber = await service.startEmbeddedSignup(
        tenantId: 'tenant_sim_01',
        appId: '1234567890',
        simulationMode: true,
        onStepChanged: (step) => steps.add(step),
      );

      // Verify all steps reached
      expect(steps, contains(MetaSignupStep.authenticatingInMeta));
      expect(steps, contains(MetaSignupStep.capturingSessionIds));
      expect(steps, contains(MetaSignupStep.exchangingTokenAndSubscribing));
      expect(steps, contains(MetaSignupStep.completed));

      // Verify returned model
      expect(connectedNumber.phoneNumberId, equals('sim_phone_alpha_777'));
      expect(connectedNumber.wabaId, equals('sim_waba_alpha_888'));
      expect(connectedNumber.qualityRating, equals(MetaQualityRating.green));
      expect(connectedNumber.qualityRating.toApiValue(), equals('GREEN'));
      expect(connectedNumber.webhookSubscribed, isTrue);

      // Verify Firestore persisted the simulated record in tenant's subcollection
      final docSnap = await fakeFirestore
          .collection('tenant')
          .doc('tenant_sim_01')
          .collection('whatsapp_numbers')
          .doc('sim_phone_alpha_777')
          .get();

      expect(docSnap.exists, isTrue);
      expect(docSnap.data()!['phone_number_id'], equals('sim_phone_alpha_777'));
      expect(docSnap.data()!['status'], equals('connected'));
    });

    test('2. Complete simulated onboarding flow through Riverpod embeddedSignupControllerProvider', () async {
      mockBridge.simulatedResult = const MetaEmbeddedSignupResult(
        status: MetaSignupStatus.success,
        code: 'sim_riverpod_code_555',
        wabaId: 'sim_riverpod_waba_444',
        phoneNumberId: 'sim_riverpod_phone_333',
      );

      fakeFunctions = FakeFirebaseFunctions(
        callableFactory: (name, options) => FakeHttpsCallable(
          handler: (params) async => FakeHttpsCallableResult<Map<String, dynamic>>({
            'success': true,
            'number': {
              'id': 'sim_riverpod_phone_333',
              'tenant_id': params['tenantId'],
              'waba_id': params['wabaId'],
              'phone_number_id': params['phoneNumberId'],
              'display_phone_number': '+55 11 97766-5544',
              'verified_name': 'Riverpod Simulated Tenant',
              'quality_rating': 'GREEN',
              'messaging_limit_tier': 'TIER_1K',
              'code_verification_status': 'VERIFIED',
              'status': 'connected',
              'webhook_subscribed': true,
              'ia_ativa_neste_numero': true,
              'connected_at': DateTime.now().toIso8601String(),
            },
          }),
        ),
      );

      final service = WhatsAppMetaService(
        firestore: fakeFirestore,
        functions: fakeFunctions,
        bridge: mockBridge,
      );

      final container = ProviderContainer(
        overrides: [
          whatsappMetaServiceProvider.overrideWithValue(service),
          metaSignupBridgeProvider.overrideWithValue(mockBridge),
        ],
      );
      addTearDown(container.dispose);

      final stateTransitions = <MetaSignupStep>[];
      container.listen<EmbeddedSignupState>(
        embeddedSignupControllerProvider,
        (previous, next) {
          stateTransitions.add(next.step);
        },
      );

      final controller = container.read(embeddedSignupControllerProvider.notifier);

      await controller.startOnboarding(
        tenantId: 'tenant_sim_01',
        appId: '1234567890',
        simulationMode: true,
      );

      final finalState = container.read(embeddedSignupControllerProvider);
      expect(finalState.isCompleted, isTrue);
      expect(finalState.isBusy, isFalse);
      expect(finalState.isError, isFalse);
      expect(finalState.connectedNumber, isNotNull);
      expect(finalState.connectedNumber!.phoneNumberId, equals('sim_riverpod_phone_333'));

      // Verify sequence of lifecycle transitions
      expect(
        stateTransitions,
        containsAllInOrder([
          MetaSignupStep.authenticatingInMeta,
          MetaSignupStep.capturingSessionIds,
          MetaSignupStep.exchangingTokenAndSubscribing,
          MetaSignupStep.completed,
        ]),
      );
    });
  });
}
