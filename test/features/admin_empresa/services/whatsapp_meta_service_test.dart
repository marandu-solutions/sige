import 'package:flutter_test/flutter_test.dart';
import 'package:sige/src/features/admin_empresa/src/services/meta_signup_bridge/meta_signup_bridge.dart';
import 'package:sige/src/features/admin_empresa/src/services/whatsapp_meta_service.dart';

class TestMetaSignupBridge implements MetaSignupBridge {
  MetaEmbeddedSignupResult? simulatedResult;
  bool shouldThrowException = false;
  String exceptionMessage = 'Bridge runtime failure';
  int launchCallCount = 0;

  @override
  bool get isSupported => true;

  @override
  String get platformName => 'test_bridge';

  @override
  Future<MetaEmbeddedSignupResult> launchEmbeddedSignup({
    required String appId,
    String? configId,
    bool simulationMode = false,
  }) async {
    launchCallCount++;
    if (shouldThrowException) {
      throw Exception(exceptionMessage);
    }
    if (simulatedResult != null) {
      return simulatedResult!;
    }
    return MetaEmbeddedSignupResult.success(
      code: 'mock_auth_code_123',
      wabaId: 'mock_waba_456',
      phoneNumberId: 'mock_phone_789',
    );
  }
}

void main() {
  group('WhatsAppMetaService Static Helpers', () {
    test('currentCompetencia formats dates to YYYY_MM', () {
      final nov2026 = DateTime(2026, 11, 8);
      expect(WhatsAppMetaService.currentCompetencia(nov2026), equals('2026_11'));

      final jan2027 = DateTime(2027, 1, 15);
      expect(WhatsAppMetaService.currentCompetencia(jan2027), equals('2027_01'));

      final defaultNow = WhatsAppMetaService.currentCompetencia();
      final now = DateTime.now();
      expect(
        defaultNow,
        equals('${now.year}_${now.month.toString().padLeft(2, '0')}'),
      );
    });

    test('generateRecentCompetencias produces descending monthly codes', () {
      final nov2026 = DateTime(2026, 11, 8);
      final list = WhatsAppMetaService.generateRecentCompetencias(
        count: 5,
        fromDate: nov2026,
      );

      expect(list, equals(['2026_11', '2026_10', '2026_09', '2026_08', '2026_07']));
    });

    test('generateRecentCompetencias handles year rollover', () {
      final feb2027 = DateTime(2027, 2, 1);
      final list = WhatsAppMetaService.generateRecentCompetencias(
        count: 4,
        fromDate: feb2027,
      );

      expect(list, equals(['2027_02', '2027_01', '2026_12', '2026_11']));
    });
  });

  group('WhatsAppMetaService Onboarding Orchestration', () {
    late TestMetaSignupBridge mockBridge;

    setUp(() {
      mockBridge = TestMetaSignupBridge();
    });

    test('startEmbeddedSignup notifies authenticatingInMeta step', () async {
      mockBridge.simulatedResult = MetaEmbeddedSignupResult.cancelled(
        reason: 'User closed the window',
      );
      final service = WhatsAppMetaService(bridge: mockBridge);

      final steps = <MetaSignupStep>[];

      try {
        await service.startEmbeddedSignup(
          tenantId: 'tenant_epi_01',
          appId: 'test_app_123',
          onStepChanged: (step) => steps.add(step),
        );
      } catch (_) {}

      expect(steps, contains(MetaSignupStep.authenticatingInMeta));
    });

    test('startEmbeddedSignup handles user cancellation throwing MetaSignupException.userCancelled', () async {
      mockBridge.simulatedResult = MetaEmbeddedSignupResult.cancelled(
        reason: 'Popup closed',
      );
      final service = WhatsAppMetaService(bridge: mockBridge);

      expect(
        () => service.startEmbeddedSignup(
          tenantId: 'tenant_epi_01',
          appId: 'test_app_123',
        ),
        throwsA(isA<MetaSignupException>().having(
          (e) => e.errorCode,
          'errorCode',
          equals(MetaSignupErrorCode.userCancelled),
        )),
      );
    });

    test('startEmbeddedSignup handles bridge error throwing MetaSignupException.invalidAuthCode', () async {
      mockBridge.simulatedResult = MetaEmbeddedSignupResult.error(
        'OAuth dialog authorization failed',
      );
      final service = WhatsAppMetaService(bridge: mockBridge);

      expect(
        () => service.startEmbeddedSignup(
          tenantId: 'tenant_epi_01',
          appId: 'test_app_123',
        ),
        throwsA(isA<MetaSignupException>().having(
          (e) => e.errorCode,
          'errorCode',
          equals(MetaSignupErrorCode.invalidAuthCode),
        )),
      );
    });

    test('startEmbeddedSignup throws missingSessionData when wabaId or phoneNumberId is empty', () async {
      mockBridge.simulatedResult = const MetaEmbeddedSignupResult(
        status: MetaSignupStatus.success,
        code: 'valid_code',
        wabaId: '',
        phoneNumberId: '',
      );

      final service = WhatsAppMetaService(bridge: mockBridge);

      expect(
        () => service.startEmbeddedSignup(
          tenantId: 'tenant_epi_01',
          appId: 'test_app_123',
        ),
        throwsA(isA<MetaSignupException>().having(
          (e) => e.errorCode,
          'errorCode',
          equals(MetaSignupErrorCode.missingSessionData),
        )),
      );
    });

    test('startEmbeddedSignup wraps unhandled bridge runtime failure into MetaSignupException', () async {
      mockBridge.shouldThrowException = true;
      mockBridge.exceptionMessage = 'Fatal crash in Web JS SDK';

      final service = WhatsAppMetaService(bridge: mockBridge);

      expect(
        () => service.startEmbeddedSignup(
          tenantId: 'tenant_epi_01',
          appId: 'test_app_123',
        ),
        throwsA(isA<MetaSignupException>().having(
          (e) => e.errorCode,
          'errorCode',
          equals(MetaSignupErrorCode.unknown),
        )),
      );
    });

    test('completeOnboarding polymorphic alias forwards to startEmbeddedSignup seamlessly', () async {
      mockBridge.simulatedResult = MetaEmbeddedSignupResult.cancelled(
        reason: 'User cancelled',
      );
      final service = WhatsAppMetaService(bridge: mockBridge);

      expect(
        () => service.completeOnboarding(
          tenantId: 'tenant_epi_01',
          appId: 'test_app_123',
        ),
        throwsA(isA<MetaSignupException>().having(
          (e) => e.errorCode,
          'errorCode',
          equals(MetaSignupErrorCode.userCancelled),
        )),
      );
    });
  });
}
