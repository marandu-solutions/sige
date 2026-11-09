/// Abstract contract for the platform-specific Meta Signup Bridge.
library;

import 'meta_signup_models.dart';

/// Abstract contract for the platform-specific Meta Signup Bridge.
abstract class MetaSignupBridge {
  /// Launches the Meta WhatsApp Embedded Signup popup/modal.
  ///
  /// - [appId]: Meta Tech Provider App ID.
  /// - [configId]: Optional Facebook Login Configuration ID.
  /// - [simulationMode]: When true, simulates a realistic onboarding flow
  ///   without launching external popups (ideal for local testing/homologation).
  Future<MetaEmbeddedSignupResult> launchEmbeddedSignup({
    required String appId,
    String? configId,
    bool simulationMode = false,
  });

  /// Whether the current platform natively supports launching the Meta JS popup.
  bool get isSupported;

  /// Identifier of the current platform bridge ('web', 'io', or 'stub').
  String get platformName;
}

/// Fallback factory for unsupported platforms.
MetaSignupBridge createMetaSignupBridge() =>
    throw UnsupportedError('MetaSignupBridge is not supported on this platform.');
