/// Web implementation of MetaSignupBridge utilizing dart:js_interop.
library;

import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'meta_signup_bridge_stub.dart';
import 'meta_signup_models.dart';

export 'meta_signup_bridge_stub.dart' show MetaSignupBridge;

/// Static interop binding for `window.sigeLaunchWhatsAppEmbeddedSignup`.
@JS('sigeLaunchWhatsAppEmbeddedSignup')
external JSPromise<JSString>? _rawLaunchWhatsAppEmbeddedSignup(
  JSString appId, [
  JSString? configId,
]);

/// Web implementation of [MetaSignupBridge] utilizing `dart:js_interop`.
class MetaSignupBridgeWeb implements MetaSignupBridge {
  @override
  bool get isSupported => true;

  @override
  String get platformName => 'web';

  bool _isGlobalFunctionAvailable() {
    try {
      return globalContext.hasProperty('sigeLaunchWhatsAppEmbeddedSignup'.toJS).toDart;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<MetaEmbeddedSignupResult> launchEmbeddedSignup({
    required String appId,
    String? configId,
    bool simulationMode = false,
  }) async {
    // 1. Simulation / Homologation Mode
    if (simulationMode) {
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return MetaEmbeddedSignupResult.success(
        code: 'sim_web_auth_code_$timestamp',
        wabaId: 'sim_waba_998877665544332',
        phoneNumberId: 'sim_phone_109283746511223',
        businessId: 'sim_biz_5544332211',
        rawData: {
          'status': 'SUCCESS',
          'code': 'sim_web_auth_code_$timestamp',
          'waba_id': 'sim_waba_998877665544332',
          'phone_number_id': 'sim_phone_109283746511223',
          'business_id': 'sim_biz_5544332211',
          'simulated': true,
          'platform': 'web',
        },
      );
    }

    final sanitizedAppId = appId.trim();
    if (sanitizedAppId.isEmpty) {
      return MetaEmbeddedSignupResult.error('Meta App ID não pode ser vazio.');
    }

    // 2. Defensive check for global JavaScript function in window
    if (!_isGlobalFunctionAvailable()) {
      return MetaEmbeddedSignupResult.error(
        'Função "sigeLaunchWhatsAppEmbeddedSignup" não encontrada no escopo global (window). '
        'Verifique se o script da Meta foi injetado em web/index.html e desative bloqueadores de popup/anúncios.',
      );
    }

    try {
      final jsAppId = sanitizedAppId.toJS;
      final jsConfigId = (configId != null && configId.trim().isNotEmpty)
          ? configId.trim().toJS
          : null;

      final jsPromise = jsConfigId != null
          ? _rawLaunchWhatsAppEmbeddedSignup(jsAppId, jsConfigId)
          : _rawLaunchWhatsAppEmbeddedSignup(jsAppId);

      if (jsPromise == null) {
        return MetaEmbeddedSignupResult.error(
          'A chamada ao SDK Meta retornou nula inesperadamente.',
        );
      }

      // 3. Await JavaScript Promise and convert JSString to Dart String
      final jsResult = await jsPromise.toDart;
      final jsonStr = jsResult.toDart;

      if (jsonStr.isEmpty) {
        return MetaEmbeddedSignupResult.error(
          'O SDK Meta retornou uma resposta vazia.',
        );
      }

      // 4. Decode JSON payload
      final decoded = jsonDecode(jsonStr);
      if (decoded is! Map<String, dynamic>) {
        return MetaEmbeddedSignupResult.error(
          'Formato de resposta inesperado do SDK Meta (não é JSON Object).',
        );
      }

      return MetaEmbeddedSignupResult.fromJson(decoded);
    } catch (e) {
      return MetaEmbeddedSignupResult.error(
        'Falha na execução do cadastro incorporado Meta: $e',
      );
    }
  }
}

/// Factory function instantiating the Web bridge.
MetaSignupBridge createMetaSignupBridge() => MetaSignupBridgeWeb();
