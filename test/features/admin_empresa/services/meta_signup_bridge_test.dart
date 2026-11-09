import 'package:flutter_test/flutter_test.dart';
import 'package:sige/src/features/admin_empresa/src/services/meta_signup_bridge/meta_signup_bridge.dart';

void main() {
  group('MetaSignupBridge Multiplatform Tests', () {
    test('createMetaSignupBridge creates a valid instance on current platform', () {
      final bridge = createMetaSignupBridge();
      expect(bridge, isNotNull);
      expect(bridge.platformName, equals('io'));
      expect(bridge.isSupported, isFalse);
    });

    test('IO bridge in simulation mode returns success with mock identifiers', () async {
      final bridge = createMetaSignupBridge();
      final result = await bridge.launchEmbeddedSignup(
        appId: 'test_app_123',
        configId: 'test_config_456',
        simulationMode: true,
      );

      expect(result.isSuccess, isTrue);
      expect(result.status, equals(MetaSignupStatus.success));
      expect(result.code, isNotEmpty);
      expect(result.wabaId, equals('sim_waba_998877665544332'));
      expect(result.phoneNumberId, equals('sim_phone_109283746511223'));
      expect(result.businessId, equals('sim_biz_5544332211'));
      expect(result.rawData?['simulated'], isTrue);
      expect(result.rawData?['platform'], equals('io'));
    });

    test('IO bridge outside simulation mode returns descriptive error', () async {
      final bridge = createMetaSignupBridge();
      final result = await bridge.launchEmbeddedSignup(
        appId: 'test_app_123',
        simulationMode: false,
      );

      expect(result.isError, isTrue);
      expect(result.status, equals(MetaSignupStatus.error));
      expect(result.errorMessage, contains('Facebook JavaScript SDK'));
    });
  });

  group('MetaEmbeddedSignupResult DTO Serialization & Parsing', () {
    test('fromJson parses snake_case Meta payload successfully', () {
      final json = {
        'status': 'SUCCESS',
        'code': 'AQ_test_code_123',
        'waba_id': '99887766',
        'phone_number_id': '10928374',
        'business_id': '55443322',
      };

      final result = MetaEmbeddedSignupResult.fromJson(json);
      expect(result.status, equals(MetaSignupStatus.success));
      expect(result.isSuccess, isTrue);
      expect(result.isCancelled, isFalse);
      expect(result.isError, isFalse);
      expect(result.code, equals('AQ_test_code_123'));
      expect(result.wabaId, equals('99887766'));
      expect(result.phoneNumberId, equals('10928374'));
      expect(result.businessId, equals('55443322'));
    });

    test('fromJson parses camelCase payload successfully', () {
      final json = {
        'status': 'success',
        'code': 'AQ_camel_code',
        'wabaId': 'waba_camel_1',
        'phoneNumberId': 'phone_camel_2',
        'businessId': 'biz_camel_3',
      };

      final result = MetaEmbeddedSignupResult.fromJson(json);
      expect(result.status, equals(MetaSignupStatus.success));
      expect(result.code, equals('AQ_camel_code'));
      expect(result.wabaId, equals('waba_camel_1'));
      expect(result.phoneNumberId, equals('phone_camel_2'));
      expect(result.businessId, equals('biz_camel_3'));
    });

    test('fromJson parses cancelled payload', () {
      final json = {
        'status': 'CANCELLED',
        'error_message': 'Janela fechada pelo usuário.',
      };

      final result = MetaEmbeddedSignupResult.fromJson(json);
      expect(result.status, equals(MetaSignupStatus.cancelled));
      expect(result.isCancelled, isTrue);
      expect(result.isSuccess, isFalse);
      expect(result.isError, isFalse);
      expect(result.errorMessage, equals('Janela fechada pelo usuário.'));
    });

    test('fromJson parses alternative canceled spelling', () {
      final json = {
        'status': 'CANCELED',
        'error_message': 'User dismissed dialog',
      };

      final result = MetaEmbeddedSignupResult.fromJson(json);
      expect(result.status, equals(MetaSignupStatus.cancelled));
      expect(result.isCancelled, isTrue);
      expect(result.errorMessage, equals('User dismissed dialog'));
    });

    test('fromJson gracefully falls back to error for unknown status', () {
      final json = {
        'status': 'UNKNOWN_RANDOM_STATE',
        'error_message': 'Something unexpected happened',
      };

      final result = MetaEmbeddedSignupResult.fromJson(json);
      expect(result.status, equals(MetaSignupStatus.error));
      expect(result.isError, isTrue);
      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, equals('Something unexpected happened'));
    });

    test('factory constructors create valid instances', () {
      final success = MetaEmbeddedSignupResult.success(
        code: 'auth_123',
        wabaId: 'waba_999',
        phoneNumberId: 'phone_888',
        businessId: 'biz_777',
      );
      expect(success.isSuccess, isTrue);
      expect(success.code, equals('auth_123'));

      final cancelled = MetaEmbeddedSignupResult.cancelled(
        reason: 'User cancelled',
      );
      expect(cancelled.isCancelled, isTrue);
      expect(cancelled.errorMessage, equals('User cancelled'));

      final error = MetaEmbeddedSignupResult.error('Popup blocked');
      expect(error.isError, isTrue);
      expect(error.errorMessage, equals('Popup blocked'));
    });

    test('toJson generates structured payload', () {
      final result = MetaEmbeddedSignupResult.success(
        code: 'auth_code',
        wabaId: 'waba_1',
        phoneNumberId: 'phone_1',
        businessId: 'biz_1',
      );

      final map = result.toJson();
      expect(map['status'], equals('SUCCESS'));
      expect(map['code'], equals('auth_code'));
      expect(map['waba_id'], equals('waba_1'));
      expect(map['phone_number_id'], equals('phone_1'));
      expect(map['business_id'], equals('biz_1'));
    });

    test('copyWith, equality, hashCode and toString behave correctly', () {
      final orig = MetaEmbeddedSignupResult.success(
        code: 'code_a',
        wabaId: 'waba_a',
        phoneNumberId: 'phone_a',
      );
      final clone = orig.copyWith();
      expect(clone, equals(orig));
      expect(clone.hashCode, equals(orig.hashCode));

      final modified = orig.copyWith(code: 'code_b');
      expect(modified, isNot(equals(orig)));

      // Code is redacted in toString for security
      expect(orig.toString(), contains('[REDACTED]'));
      expect(orig.toString(), isNot(contains('code_a')));
    });

    test('typedef MetaSignupSessionResult is interchangeable', () {
      final MetaSignupSessionResult alias = MetaEmbeddedSignupResult.success(
        code: 'code',
        wabaId: 'w',
        phoneNumberId: 'p',
      );
      expect(alias.isSuccess, isTrue);
    });
  });

  group('MetaSignupStep & Status Enums', () {
    test('MetaSignupStatus fromString and toApiValue', () {
      expect(MetaSignupStatus.fromString('SUCCESS'), equals(MetaSignupStatus.success));
      expect(MetaSignupStatus.fromString('success'), equals(MetaSignupStatus.success));
      expect(MetaSignupStatus.fromString('CANCELLED'), equals(MetaSignupStatus.cancelled));
      expect(MetaSignupStatus.fromString('canceled'), equals(MetaSignupStatus.cancelled));
      expect(MetaSignupStatus.fromString('ERROR'), equals(MetaSignupStatus.error));
      expect(MetaSignupStatus.fromString('INVALID'), equals(MetaSignupStatus.error));
      expect(MetaSignupStatus.fromString(null), equals(MetaSignupStatus.error));

      expect(MetaSignupStatus.success.toApiValue(), equals('SUCCESS'));
      expect(MetaSignupStatus.cancelled.toApiValue(), equals('CANCELLED'));
      expect(MetaSignupStatus.error.toApiValue(), equals('ERROR'));
    });

    test('indexOrder maps steps sequentially', () {
      expect(MetaSignupStep.idle.indexOrder, equals(0));
      expect(MetaSignupStep.authenticatingInMeta.indexOrder, equals(0));
      expect(MetaSignupStep.capturingSessionIds.indexOrder, equals(1));
      expect(MetaSignupStep.exchangingTokenAndSubscribing.indexOrder, equals(2));
      expect(MetaSignupStep.completed.indexOrder, equals(3));
      expect(MetaSignupStep.error.indexOrder, equals(3));
      expect(MetaSignupStep.cancelled.indexOrder, equals(3));
    });

    test('isInProgress and isProcessing identify intermediate states', () {
      expect(MetaSignupStep.idle.isInProgress, isFalse);
      expect(MetaSignupStep.authenticatingInMeta.isInProgress, isTrue);
      expect(MetaSignupStep.capturingSessionIds.isInProgress, isTrue);
      expect(MetaSignupStep.exchangingTokenAndSubscribing.isInProgress, isTrue);
      expect(MetaSignupStep.completed.isInProgress, isFalse);
      expect(MetaSignupStep.error.isInProgress, isFalse);
      expect(MetaSignupStep.cancelled.isInProgress, isFalse);

      expect(MetaSignupStep.authenticatingInMeta.isProcessing, isTrue);
      expect(MetaSignupStep.capturingSessionIds.isProcessing, isTrue);
      expect(MetaSignupStep.exchangingTokenAndSubscribing.isProcessing, isTrue);
    });

    test('isTerminal identifies finished states', () {
      expect(MetaSignupStep.idle.isTerminal, isFalse);
      expect(MetaSignupStep.authenticatingInMeta.isTerminal, isFalse);
      expect(MetaSignupStep.completed.isTerminal, isTrue);
      expect(MetaSignupStep.error.isTerminal, isTrue);
      expect(MetaSignupStep.cancelled.isTerminal, isTrue);
    });

    test('label returns non-empty Portuguese description', () {
      for (final step in MetaSignupStep.values) {
        expect(step.label, isNotEmpty);
      }
    });
  });

  group('MetaSignupException Architecture', () {
    test('sdkNotLoaded factory initializes expected properties', () {
      final ex = MetaSignupException.sdkNotLoaded();
      expect(ex.errorCode, equals(MetaSignupErrorCode.sdkNotLoaded));
      expect(ex.code, equals(MetaSignupErrorCode.sdkNotLoaded));
      expect(ex.recoveryHint, isNotNull);
      expect(ex.toString(), contains('Dica:'));
    });

    test('popupBlocked factory initializes expected properties', () {
      final ex = MetaSignupException.popupBlocked();
      expect(ex.errorCode, equals(MetaSignupErrorCode.popupBlocked));
      expect(ex.recoveryHint, contains('pop-up'));
    });

    test('userCancelled factory initializes expected properties', () {
      final ex = MetaSignupException.userCancelled();
      expect(ex.errorCode, equals(MetaSignupErrorCode.userCancelled));
      expect(ex.recoveryHint, isNotNull);
    });

    test('missingSessionData factory initializes expected properties', () {
      final ex = MetaSignupException.missingSessionData();
      expect(ex.errorCode, equals(MetaSignupErrorCode.missingSessionData));
    });

    test('invalidAuthCode factory initializes expected properties', () {
      final ex = MetaSignupException.invalidAuthCode();
      expect(ex.errorCode, equals(MetaSignupErrorCode.invalidAuthCode));
    });

    test('networkTimeout factory initializes expected properties', () {
      final ex = MetaSignupException.networkTimeout();
      expect(ex.errorCode, equals(MetaSignupErrorCode.networkTimeout));
    });

    test('unsupportedPlatform factory initializes expected properties', () {
      final ex = MetaSignupException.unsupportedPlatform(platformName: 'macOS');
      expect(ex.errorCode, equals(MetaSignupErrorCode.unsupportedPlatform));
      expect(ex.message, contains('macOS'));
    });

    test('backendExchangeFailed factory initializes expected properties', () {
      final ex = MetaSignupException.backendExchangeFailed(
        message: 'Invalid Graph API token exchange',
      );
      expect(ex.errorCode, equals(MetaSignupErrorCode.backendExchangeFailed));
      expect(ex.message, equals('Invalid Graph API token exchange'));
      expect(ex.recoveryHint, contains('Cloud Functions'));
    });
  });

  group('MetaSignupState UI State Model', () {
    test('initial state begins at idle', () {
      final state = MetaSignupState.initial();
      expect(state.step, equals(MetaSignupStep.idle));
      expect(state.isIdle, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.isCompleted, isFalse);
      expect(state.isCancelled, isFalse);
      expect(state.isError, isFalse);
    });

    test('copyWith updates state correctly', () {
      final initial = MetaSignupState.initial();
      final inProgress = initial.copyWith(step: MetaSignupStep.authenticatingInMeta);
      expect(inProgress.isLoading, isTrue);
      expect(inProgress.isIdle, isFalse);

      final success = inProgress.copyWith(
        step: MetaSignupStep.completed,
        result: MetaEmbeddedSignupResult.success(
          code: 'c',
          wabaId: 'w',
          phoneNumberId: 'p',
        ),
      );
      expect(success.isCompleted, isTrue);
      expect(success.isLoading, isFalse);
      expect(success.result, isNotNull);

      final errorState = inProgress.copyWith(
        step: MetaSignupStep.error,
        errorMessage: 'Something broke',
      );
      expect(errorState.isError, isTrue);
    });

    test('equality and hashcode work as expected', () {
      final s1 = MetaSignupState.initial();
      final s2 = MetaSignupState.initial();
      expect(s1, equals(s2));
      expect(s1.hashCode, equals(s2.hashCode));

      final s3 = s1.copyWith(step: MetaSignupStep.completed);
      expect(s1, isNot(equals(s3)));
    });
  });
}
