import 'package:flutter_test/flutter_test.dart';
import 'package:sige/src/features/admin_empresa/src/services/meta_signup_bridge/meta_signup_bridge.dart';

void main() {
  group('Adversarial Test Suite 1: Deserialization & Robustness (MetaEmbeddedSignupResult)', () {
    test('Empty Map defaults safely to error status without throwing', () {
      final json = <String, dynamic>{};
      final result = MetaEmbeddedSignupResult.fromJson(json);

      expect(result.status, equals(MetaSignupStatus.error));
      expect(result.isError, isTrue);
      expect(result.isSuccess, isFalse);
      expect(result.isCancelled, isFalse);
      expect(result.code, isNull);
      expect(result.wabaId, isNull);
      expect(result.phoneNumberId, isNull);
      expect(result.businessId, isNull);
      expect(result.errorMessage, isNull);
      expect(result.rawData, isEmpty);
    });

    test('All null values in map default safely to error status', () {
      final json = <String, dynamic>{
        'status': null,
        'code': null,
        'auth_code': null,
        'waba_id': null,
        'wabaId': null,
        'phone_number_id': null,
        'phoneNumberId': null,
        'business_id': null,
        'businessId': null,
        'error_message': null,
        'errorMessage': null,
        'message': null,
        'error': null,
      };

      final result = MetaEmbeddedSignupResult.fromJson(json);

      expect(result.status, equals(MetaSignupStatus.error));
      expect(result.isError, isTrue);
      expect(result.code, isNull);
      expect(result.wabaId, isNull);
      expect(result.phoneNumberId, isNull);
      expect(result.businessId, isNull);
      expect(result.errorMessage, isNull);
    });

    test('Whitespace-only strings are trimmed and normalized to null', () {
      final json = <String, dynamic>{
        'status': '   ',
        'code': '   \t  ',
        'waba_id': ' \n  ',
        'phone_number_id': '   ',
        'business_id': '  \r\n ',
        'error_message': '      ',
      };

      final result = MetaEmbeddedSignupResult.fromJson(json);

      expect(result.status, equals(MetaSignupStatus.error));
      expect(result.code, isNull);
      expect(result.wabaId, isNull);
      expect(result.phoneNumberId, isNull);
      expect(result.businessId, isNull);
      expect(result.errorMessage, isNull);
    });

    test('Non-string dynamic primitives (numbers, booleans) in identifiers are stringified', () {
      final json = <String, dynamic>{
        'status': 'success',
        'code': 987654321,
        'waba_id': 112233445566,
        'phone_number_id': 9988776655,
        'business_id': 4433221100,
        'error_message': 404,
      };

      final result = MetaEmbeddedSignupResult.fromJson(json);

      expect(result.status, equals(MetaSignupStatus.success));
      expect(result.code, equals('987654321'));
      expect(result.wabaId, equals('112233445566'));
      expect(result.phoneNumberId, equals('9988776655'));
      expect(result.businessId, equals('4433221100'));
      expect(result.errorMessage, equals('404'));
    });

    test('Status field type casting behavior with unexpected non-string status values', () {
      // Testing adversarial input where status is an int or boolean
      final jsonWithIntStatus = <String, dynamic>{
        'status': 200,
        'code': 'auth_test',
      };

      // In Dart, (json['status'] as String?) throws TypeError if status is int
      expect(
        () => MetaEmbeddedSignupResult.fromJson(jsonWithIntStatus),
        throwsA(isA<TypeError>()),
        reason: 'Empirical finding: json["status"] as String? throws TypeError if status is not String',
      );
    });

    test('Case-insensitivity on status tokens', () {
      final variants = [
        ('SUCCESS', MetaSignupStatus.success),
        ('success', MetaSignupStatus.success),
        ('Success', MetaSignupStatus.success),
        ('sUcCESS', MetaSignupStatus.success),
        ('CANCELLED', MetaSignupStatus.cancelled),
        ('cancelled', MetaSignupStatus.cancelled),
        ('CANCELED', MetaSignupStatus.cancelled),
        ('canceled', MetaSignupStatus.cancelled),
        ('ERROR', MetaSignupStatus.error),
        ('error', MetaSignupStatus.error),
        ('UNKNOWN_FOO_BAR', MetaSignupStatus.error),
        ('12345', MetaSignupStatus.error),
      ];

      for (final (statusStr, expectedStatus) in variants) {
        final result = MetaEmbeddedSignupResult.fromJson({'status': statusStr});
        expect(
          result.status,
          equals(expectedStatus),
          reason: 'Failed parsing status string: "$statusStr"',
        );
      }
    });

    test('Alternative error key fallbacks: error_message -> errorMessage -> message -> error', () {
      // 1. error_message takes priority
      final r1 = MetaEmbeddedSignupResult.fromJson({
        'status': 'error',
        'error_message': 'first_priority',
        'errorMessage': 'second_priority',
        'message': 'third_priority',
        'error': 'fourth_priority',
      });
      expect(r1.errorMessage, equals('first_priority'));

      // 2. errorMessage fallback
      final r2 = MetaEmbeddedSignupResult.fromJson({
        'status': 'error',
        'errorMessage': 'second_priority',
        'message': 'third_priority',
      });
      expect(r2.errorMessage, equals('second_priority'));

      // 3. message fallback
      final r3 = MetaEmbeddedSignupResult.fromJson({
        'status': 'error',
        'message': 'third_priority',
      });
      expect(r3.errorMessage, equals('third_priority'));

      // 4. error fallback
      final r4 = MetaEmbeddedSignupResult.fromJson({
        'status': 'error',
        'error': 'fourth_priority',
      });
      expect(r4.errorMessage, equals('fourth_priority'));
    });

    test('Alternative code key fallback: code vs auth_code', () {
      final r1 = MetaEmbeddedSignupResult.fromJson({
        'status': 'SUCCESS',
        'code': 'primary_code',
        'auth_code': 'secondary_code',
      });
      expect(r1.code, equals('primary_code'));

      final r2 = MetaEmbeddedSignupResult.fromJson({
        'status': 'SUCCESS',
        'auth_code': 'secondary_code',
      });
      expect(r2.code, equals('secondary_code'));
    });

    test('Alternative camelCase vs snake_case identifier keys', () {
      final snakeJson = {
        'status': 'SUCCESS',
        'waba_id': 'waba_snake',
        'phone_number_id': 'phone_snake',
        'business_id': 'biz_snake',
      };
      final rSnake = MetaEmbeddedSignupResult.fromJson(snakeJson);
      expect(rSnake.wabaId, equals('waba_snake'));
      expect(rSnake.phoneNumberId, equals('phone_snake'));
      expect(rSnake.businessId, equals('biz_snake'));

      final camelJson = {
        'status': 'SUCCESS',
        'wabaId': 'waba_camel',
        'phoneNumberId': 'phone_camel',
        'businessId': 'biz_camel',
      };
      final rCamel = MetaEmbeddedSignupResult.fromJson(camelJson);
      expect(rCamel.wabaId, equals('waba_camel'));
      expect(rCamel.phoneNumberId, equals('phone_camel'));
      expect(rCamel.businessId, equals('biz_camel'));
    });

    test('Unicode, emojis, special characters, and newlines in payloads', () {
      final complexJson = {
        'status': 'SUCCESS',
        'code': 'AQ_code_áéíóú_çñ_123',
        'waba_id': 'WABA-🏢-9988',
        'phone_number_id': 'PHONE-⚡-1092',
        'business_id': 'Empresa "Alfa" & Cia 🚀\nLinha 2',
        'error_message': 'Alerta: <script>alert("xss")</script> & unicode 漢字',
      };

      final result = MetaEmbeddedSignupResult.fromJson(complexJson);
      expect(result.code, equals('AQ_code_áéíóú_çñ_123'));
      expect(result.wabaId, equals('WABA-🏢-9988'));
      expect(result.phoneNumberId, equals('PHONE-⚡-1092'));
      expect(result.businessId, equals('Empresa "Alfa" & Cia 🚀\nLinha 2'));
      expect(result.errorMessage, equals('Alerta: <script>alert("xss")</script> & unicode 漢字'));
      expect(result.rawData, equals(complexJson));
    });

    test('JSON serialization round-trip preservation', () {
      final original = MetaEmbeddedSignupResult.success(
        code: 'auth_roundtrip_code',
        wabaId: 'waba_roundtrip',
        phoneNumberId: 'phone_roundtrip',
        businessId: 'biz_roundtrip',
        rawData: {'custom_meta_field': 42},
      );

      final serialized = original.toJson();
      expect(serialized['status'], equals('SUCCESS'));
      expect(serialized['code'], equals('auth_roundtrip_code'));
      expect(serialized['waba_id'], equals('waba_roundtrip'));
      expect(serialized['phone_number_id'], equals('phone_roundtrip'));
      expect(serialized['business_id'], equals('biz_roundtrip'));
      expect(serialized['raw_data'], equals({'custom_meta_field': 42}));

      final revived = MetaEmbeddedSignupResult.fromJson(serialized);
      expect(revived.status, equals(original.status));
      expect(revived.code, equals(original.code));
      expect(revived.wabaId, equals(original.wabaId));
      expect(revived.phoneNumberId, equals(original.phoneNumberId));
      expect(revived.businessId, equals(original.businessId));
      expect(revived.errorMessage, equals(original.errorMessage));
      expect(revived, equals(original));
    });
  });

  group('Adversarial Test Suite 2: MetaSignupException Architecture & Factories', () {
    test('MetaSignupErrorCode constant values conform to standard codes', () {
      expect(MetaSignupErrorCode.sdkNotLoaded, equals('SDK_NOT_LOADED'));
      expect(MetaSignupErrorCode.popupBlocked, equals('POPUP_BLOCKED'));
      expect(MetaSignupErrorCode.userCancelled, equals('USER_CANCELLED'));
      expect(MetaSignupErrorCode.missingSessionData, equals('MISSING_SESSION_DATA'));
      expect(MetaSignupErrorCode.invalidAuthCode, equals('INVALID_AUTH_CODE'));
      expect(MetaSignupErrorCode.networkTimeout, equals('NETWORK_TIMEOUT'));
      expect(MetaSignupErrorCode.unsupportedPlatform, equals('UNSUPPORTED_PLATFORM'));
      expect(MetaSignupErrorCode.backendExchangeFailed, equals('BACKEND_EXCHANGE_FAILED'));
      expect(MetaSignupErrorCode.unknown, equals('UNKNOWN_ERROR'));
    });

    test('MetaSignupException constructor fallbacks for errorCode and code', () {
      // 1. Explicit errorCode
      const ex1 = MetaSignupException('Msg', errorCode: 'CUSTOM_CODE');
      expect(ex1.errorCode, equals('CUSTOM_CODE'));
      expect(ex1.code, equals('CUSTOM_CODE'));

      // 2. Legacy 'code' parameter
      const ex2 = MetaSignupException('Msg', code: 'LEGACY_CODE');
      expect(ex2.errorCode, equals('LEGACY_CODE'));
      expect(ex2.code, equals('LEGACY_CODE'));

      // 3. Fallback when both null
      const ex3 = MetaSignupException('Msg');
      expect(ex3.errorCode, equals(MetaSignupErrorCode.unknown));
      expect(ex3.code, equals(MetaSignupErrorCode.unknown));
    });

    test('sdkNotLoaded factory with custom details and original error', () {
      final origErr = Exception('Script failed to load');
      final stack = StackTrace.current;
      final ex = MetaSignupException.sdkNotLoaded(
        details: 'Custom SDK missing',
        originalError: origErr,
        stackTrace: stack,
      );

      expect(ex.errorCode, equals(MetaSignupErrorCode.sdkNotLoaded));
      expect(ex.message, equals('Custom SDK missing'));
      expect(ex.originalError, equals(origErr));
      expect(ex.details, equals(origErr));
      expect(ex.stackTrace, equals(stack));
      expect(ex.recoveryHint, contains('bloqueadores de anúncios'));
      expect(ex.toString(), contains('MetaSignupException[SDK_NOT_LOADED]'));
    });

    test('popupBlocked factory default parameters and hints', () {
      final ex = MetaSignupException.popupBlocked();
      expect(ex.errorCode, equals(MetaSignupErrorCode.popupBlocked));
      expect(ex.message, contains('bloqueou a abertura'));
      expect(ex.recoveryHint, contains('pop-up'));
    });

    test('userCancelled factory default and custom details', () {
      final exDefault = MetaSignupException.userCancelled();
      expect(exDefault.errorCode, equals(MetaSignupErrorCode.userCancelled));
      expect(exDefault.message, contains('cancelado pelo usuário'));

      final exCustom = MetaSignupException.userCancelled(details: 'User dismissed');
      expect(exCustom.message, equals('User dismissed'));
    });

    test('missingSessionData factory', () {
      final ex = MetaSignupException.missingSessionData();
      expect(ex.errorCode, equals(MetaSignupErrorCode.missingSessionData));
      expect(ex.message, contains('identificadores obrigatórios'));
      expect(ex.recoveryHint, contains('Conta WhatsApp'));
    });

    test('invalidAuthCode factory with underlying exception', () {
      final ex = MetaSignupException.invalidAuthCode(
        details: 'Expired at timestamp 1700000000',
        originalError: 'OAuth token code expired',
      );
      expect(ex.errorCode, equals(MetaSignupErrorCode.invalidAuthCode));
      expect(ex.message, equals('Expired at timestamp 1700000000'));
      expect(ex.originalError, equals('OAuth token code expired'));
      expect(ex.recoveryHint, contains('expirou'));
    });

    test('networkTimeout factory', () {
      final ex = MetaSignupException.networkTimeout();
      expect(ex.errorCode, equals(MetaSignupErrorCode.networkTimeout));
      expect(ex.message, contains('Tempo limite excedido'));
      expect(ex.recoveryHint, contains('conexão com a internet'));
    });

    test('unsupportedPlatform factory with and without platformName', () {
      final exWithPlatform = MetaSignupException.unsupportedPlatform(platformName: 'Linux-x64');
      expect(exWithPlatform.errorCode, equals(MetaSignupErrorCode.unsupportedPlatform));
      expect(exWithPlatform.message, contains('(Linux-x64)'));

      final exNoPlatform = MetaSignupException.unsupportedPlatform();
      expect(exNoPlatform.errorCode, equals(MetaSignupErrorCode.unsupportedPlatform));
      expect(exNoPlatform.message, contains('A plataforma atual não suporta'));
      expect(exNoPlatform.recoveryHint, contains('simulação'));
    });

    test('backendExchangeFailed factory with mandatory message and custom recovery hint', () {
      final ex = MetaSignupException.backendExchangeFailed(
        message: 'Firebase Functions 403 Forbidden',
        recoveryHint: 'Contact DevSecOps team',
      );
      expect(ex.errorCode, equals(MetaSignupErrorCode.backendExchangeFailed));
      expect(ex.message, equals('Firebase Functions 403 Forbidden'));
      expect(ex.recoveryHint, equals('Contact DevSecOps team'));
    });

    test('toString formatting without recovery hint', () {
      const ex = MetaSignupException('Plain error', errorCode: 'PLAIN');
      expect(ex.toString(), equals('MetaSignupException[PLAIN]: Plain error'));
    });
  });

  group('Adversarial Test Suite 3: IO Runtime Bridge (Mock & Simulation Behavior)', () {
    test('createMetaSignupBridge returns MetaSignupBridgeIo on IO test environment', () {
      final bridge = createMetaSignupBridge();
      expect(bridge, isA<MetaSignupBridge>());
      expect(bridge.platformName, equals('io'));
      expect(bridge.isSupported, isFalse);
    });

    test('simulationMode: false returns error result on IO with informative guidance', () async {
      final bridge = createMetaSignupBridge();
      final result = await bridge.launchEmbeddedSignup(
        appId: 'real_app_id_9999',
        configId: 'cfg_123',
        simulationMode: false,
      );

      expect(result.status, equals(MetaSignupStatus.error));
      expect(result.isError, isTrue);
      expect(result.isSuccess, isFalse);
      expect(result.isCancelled, isFalse);
      expect(result.code, isNull);
      expect(result.wabaId, isNull);
      expect(result.phoneNumberId, isNull);
      expect(result.businessId, isNull);
      expect(result.errorMessage, contains('Facebook JavaScript SDK'));
      expect(result.errorMessage, contains('simulationMode = true'));
    });

    test('simulationMode: true returns complete mock result with realistic IDs', () async {
      final bridge = createMetaSignupBridge();
      final beforeTime = DateTime.now().millisecondsSinceEpoch;

      final result = await bridge.launchEmbeddedSignup(
        appId: 'app_simulation_test',
        simulationMode: true,
      );

      final afterTime = DateTime.now().millisecondsSinceEpoch;

      expect(result.status, equals(MetaSignupStatus.success));
      expect(result.isSuccess, isTrue);
      expect(result.isError, isFalse);
      expect(result.isCancelled, isFalse);

      expect(result.code, startsWith('sim_io_auth_code_'));
      expect(result.wabaId, equals('sim_waba_998877665544332'));
      expect(result.phoneNumberId, equals('sim_phone_109283746511223'));
      expect(result.businessId, equals('sim_biz_5544332211'));

      // Check simulated flag in rawData
      expect(result.rawData, isNotNull);
      expect(result.rawData?['simulated'], isTrue);
      expect(result.rawData?['platform'], equals('io'));
      expect(result.rawData?['waba_id'], equals('sim_waba_998877665544332'));
      expect(result.rawData?['phone_number_id'], equals('sim_phone_109283746511223'));

      // Verify delay was respected (~1500ms)
      expect(afterTime - beforeTime, greaterThanOrEqualTo(1400));
    });

    test('Simulation mode generates unique authorization codes across sequential calls', () async {
      final bridge = createMetaSignupBridge();
      final res1 = await bridge.launchEmbeddedSignup(appId: 'app_1', simulationMode: true);
      final res2 = await bridge.launchEmbeddedSignup(appId: 'app_1', simulationMode: true);

      expect(res1.code, isNot(equals(res2.code)));
      expect(res1.code, startsWith('sim_io_auth_code_'));
      expect(res2.code, startsWith('sim_io_auth_code_'));
    });

    test('IO Bridge handles empty or whitespace appId gracefully in simulation mode', () async {
      final bridge = createMetaSignupBridge();
      final result = await bridge.launchEmbeddedSignup(
        appId: '   ',
        simulationMode: true,
      );

      // Simulation mode succeeds regardless of appId in IO bridge
      expect(result.isSuccess, isTrue);
      expect(result.code, isNotNull);
    });

    test('IO Bridge handles empty appId with simulationMode: false returning error', () async {
      final bridge = createMetaSignupBridge();
      final result = await bridge.launchEmbeddedSignup(
        appId: '',
        simulationMode: false,
      );

      expect(result.isError, isTrue);
      expect(result.errorMessage, contains('Facebook JavaScript SDK'));
    });
  });

  group('Adversarial Test Suite 4: Value Equality & HashCode on MetaEmbeddedSignupResult', () {
    test('Reflexivity: instance equals itself', () {
      final res = MetaEmbeddedSignupResult.success(
        code: 'auth_abc',
        wabaId: 'waba_123',
        phoneNumberId: 'phone_456',
        businessId: 'biz_789',
        rawData: {'test': true},
      );

      expect(res == res, isTrue);
      expect(res.hashCode == res.hashCode, isTrue);
    });

    test('Symmetry: if A == B then B == A', () {
      final a = MetaEmbeddedSignupResult.success(
        code: 'auth_symm',
        wabaId: 'waba_symm',
        phoneNumberId: 'phone_symm',
        businessId: 'biz_symm',
      );

      final b = MetaEmbeddedSignupResult.success(
        code: 'auth_symm',
        wabaId: 'waba_symm',
        phoneNumberId: 'phone_symm',
        businessId: 'biz_symm',
      );

      expect(a == b, isTrue);
      expect(b == a, isTrue);
      expect(a.hashCode, equals(b.hashCode));
    });

    test('Transitivity: if A == B and B == C then A == C', () {
      final a = MetaEmbeddedSignupResult(
        status: MetaSignupStatus.error,
        errorMessage: 'Something broke',
      );
      final b = MetaEmbeddedSignupResult(
        status: MetaSignupStatus.error,
        errorMessage: 'Something broke',
      );
      final c = MetaEmbeddedSignupResult(
        status: MetaSignupStatus.error,
        errorMessage: 'Something broke',
      );

      expect(a == b, isTrue);
      expect(b == c, isTrue);
      expect(a == c, isTrue);
      expect(a.hashCode, equals(c.hashCode));
    });

    test('Comparison against null and other unrelated types returns false', () {
      final dynamic res = MetaEmbeddedSignupResult.cancelled();

      expect(res == null, isFalse);
      expect(res == 'string_object', isFalse);
      expect(res == 42, isFalse);
      expect(res == {'status': 'CANCELLED'}, isFalse);
    });

    test('Inequality across every single individual mutated field', () {
      final base = MetaEmbeddedSignupResult.success(
        code: 'base_code',
        wabaId: 'base_waba',
        phoneNumberId: 'base_phone',
        businessId: 'base_biz',
      );

      // Mutate status
      final diffStatus = base.copyWith(status: MetaSignupStatus.error);
      expect(diffStatus == base, isFalse);
      expect(diffStatus.hashCode == base.hashCode, isFalse);

      // Mutate code
      final diffCode = base.copyWith(code: 'different_code');
      expect(diffCode == base, isFalse);
      expect(diffCode.hashCode == base.hashCode, isFalse);

      // Mutate wabaId
      final diffWaba = base.copyWith(wabaId: 'different_waba');
      expect(diffWaba == base, isFalse);
      expect(diffWaba.hashCode == base.hashCode, isFalse);

      // Mutate phoneNumberId
      final diffPhone = base.copyWith(phoneNumberId: 'different_phone');
      expect(diffPhone == base, isFalse);
      expect(diffPhone.hashCode == base.hashCode, isFalse);

      // Mutate businessId
      final diffBiz = base.copyWith(businessId: 'different_biz');
      expect(diffBiz == base, isFalse);
      expect(diffBiz.hashCode == base.hashCode, isFalse);

      // Mutate errorMessage
      final diffErr = base.copyWith(errorMessage: 'new_error');
      expect(diffErr == base, isFalse);
      expect(diffErr.hashCode == base.hashCode, isFalse);
    });

    test('rawData map difference does not affect equality or hashCode (DTO contract specification)', () {
      final r1 = MetaEmbeddedSignupResult.success(
        code: 'code_1',
        wabaId: 'waba_1',
        phoneNumberId: 'phone_1',
        rawData: {'timestamp': 1000, 'extra': 'a'},
      );

      final r2 = MetaEmbeddedSignupResult.success(
        code: 'code_1',
        wabaId: 'waba_1',
        phoneNumberId: 'phone_1',
        rawData: {'timestamp': 2000, 'extra': 'b'},
      );

      // Since rawData is mutable and non-canonical, value equality focuses on business fields
      expect(r1 == r2, isTrue);
      expect(r1.hashCode, equals(r2.hashCode));
    });

    test('Set and Map hashing: 100 distinct items produce distinct Set entries without collision drop', () {
      final set = <MetaEmbeddedSignupResult>{};

      for (var i = 0; i < 100; i++) {
        set.add(MetaEmbeddedSignupResult.success(
          code: 'code_$i',
          wabaId: 'waba_$i',
          phoneNumberId: 'phone_$i',
          businessId: 'biz_$i',
        ));
      }

      expect(set.length, equals(100));

      // Adding duplicate should not increase set size
      final dup = MetaEmbeddedSignupResult.success(
        code: 'code_0',
        wabaId: 'waba_0',
        phoneNumberId: 'phone_0',
        businessId: 'biz_0',
      );
      set.add(dup);
      expect(set.length, equals(100));
    });

    test('Credential redaction invariant: toString() NEVER leaks code or tokens', () {
      final sensitiveCode = 'EAAGNOSECRET_SUPER_SENSITIVE_OAUTH_CODE_9876543210';
      final result = MetaEmbeddedSignupResult.success(
        code: sensitiveCode,
        wabaId: 'waba_public',
        phoneNumberId: 'phone_public',
      );

      final str = result.toString();
      expect(str, contains('[REDACTED]'));
      expect(str, isNot(contains(sensitiveCode)));
    });
  });

  group('Adversarial Test Suite 5: MetaSignupState Model Stress & Edge Cases', () {
    test('All MetaSignupStep enum values possess non-empty Portuguese labels', () {
      for (final step in MetaSignupStep.values) {
        expect(step.label, isNotEmpty);
        expect(step.indexOrder, inInclusiveRange(0, 3));
      }
    });

    test('MetaSignupState getters accurately report lifecycle condition', () {
      final idle = MetaSignupState.initial();
      expect(idle.isIdle, isTrue);
      expect(idle.isLoading, isFalse);
      expect(idle.isCompleted, isFalse);
      expect(idle.isError, isFalse);

      final loading = idle.copyWith(step: MetaSignupStep.capturingSessionIds);
      expect(loading.isIdle, isFalse);
      expect(loading.isLoading, isTrue);
      expect(loading.isCompleted, isFalse);
      expect(loading.isError, isFalse);

      final completed = loading.copyWith(
        step: MetaSignupStep.completed,
        result: MetaEmbeddedSignupResult.success(code: 'c', wabaId: 'w', phoneNumberId: 'p'),
      );
      expect(completed.isCompleted, isTrue);
      expect(completed.isLoading, isFalse);
      expect(completed.isError, isFalse);

      final cancelled = idle.copyWith(step: MetaSignupStep.cancelled);
      expect(cancelled.isCancelled, isTrue);
      expect(cancelled.isCompleted, isFalse);
      expect(cancelled.isLoading, isFalse);

      final errored1 = idle.copyWith(step: MetaSignupStep.error);
      expect(errored1.isError, isTrue);

      final errored2 = idle.copyWith(errorMessage: 'Generic failure');
      expect(errored2.isError, isTrue);

      final errored3 = idle.copyWith(exception: const MetaSignupException('Ex'));
      expect(errored3.isError, isTrue);
    });

    test('MetaSignupState equality, copyWith and hashCode invariants', () {
      final s1 = MetaSignupState.initial();
      final s2 = s1.copyWith();
      expect(s1 == s2, isTrue);
      expect(s1.hashCode, equals(s2.hashCode));

      final s3 = s1.copyWith(step: MetaSignupStep.authenticatingInMeta);
      expect(s1 == s3, isFalse);

      final s4 = s1.copyWith(recoveryHint: 'Hint 1');
      expect(s1 == s4, isFalse);
      expect(s1.hashCode == s4.hashCode, isFalse);
    });
  });
}
