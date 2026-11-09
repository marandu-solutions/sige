/// Safe fallback implementation of MetaSignupBridge for Mobile and Desktop (IO).
library;

import 'meta_signup_bridge_stub.dart';
import 'meta_signup_models.dart';

export 'meta_signup_bridge_stub.dart' show MetaSignupBridge;

/// Safe fallback implementation of [MetaSignupBridge] for Mobile and Desktop (IO).
class MetaSignupBridgeIo implements MetaSignupBridge {
  @override
  bool get isSupported => false;

  @override
  String get platformName => 'io';

  @override
  Future<MetaEmbeddedSignupResult> launchEmbeddedSignup({
    required String appId,
    String? configId,
    bool simulationMode = false,
  }) async {
    // 1. Homologation / Simulation Mode
    if (simulationMode) {
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return MetaEmbeddedSignupResult.success(
        code: 'sim_io_auth_code_$timestamp',
        wabaId: 'sim_waba_998877665544332',
        phoneNumberId: 'sim_phone_109283746511223',
        businessId: 'sim_biz_5544332211',
        rawData: {
          'status': 'SUCCESS',
          'code': 'sim_io_auth_code_$timestamp',
          'waba_id': 'sim_waba_998877665544332',
          'phone_number_id': 'sim_phone_109283746511223',
          'business_id': 'sim_biz_5544332211',
          'simulated': true,
          'platform': 'io',
        },
      );
    }

    // 2. Informative fallback for non-web runtime
    return MetaEmbeddedSignupResult.error(
      'O WhatsApp Embedded Signup oficial da Meta requer o Facebook JavaScript SDK '
      'e opera exclusivamente em ambiente Web (navegador seguro HTTPS). '
      'Para testes ou homologação em Mobile/Desktop, ative o modo de simulação (simulationMode = true).',
    );
  }
}

/// Factory function instantiating the IO bridge.
MetaSignupBridge createMetaSignupBridge() => MetaSignupBridgeIo();
