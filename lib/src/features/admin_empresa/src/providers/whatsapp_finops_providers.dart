import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/usage_finops_model.dart';
import '../models/whatsapp_number_model.dart';
import '../services/meta_signup_bridge/meta_signup_bridge.dart';
import '../services/whatsapp_meta_service.dart';

// Re-export core service and bridge providers for convenient single-import consumption
export '../services/whatsapp_meta_service.dart'
    show metaSignupBridgeProvider, whatsappMetaServiceProvider;

// =============================================================================
// Competence State Management
// =============================================================================

/// Selected monthly FinOps billing competence (format: `YYYY_MM`, e.g. `2026_11`),
/// scoped per tenant. Defaults to the current calendar year and month.
final selectedCompetenciaProvider =
    StateProvider.family<String, String>((ref, tenantId) {
  final now = DateTime.now();
  final year = now.year.toString();
  final month = now.month.toString().padLeft(2, '0');
  return '${year}_$month';
});

// =============================================================================
// Reactive Stream Providers
// =============================================================================

/// Real-time stream of connected WhatsApp Business accounts for the given [tenantId].
/// Listens to Firestore subcollection `tenant/{tenantId}/whatsapp_numbers`.
final whatsappNumbersStreamProvider =
    StreamProvider.family<List<WhatsAppNumberModel>, String>((ref, tenantId) {
  final service = ref.watch(whatsappMetaServiceProvider);
  return service.watchNumbers(tenantId);
});

/// Alias matching MD07 §6.2 specification nomenclature.
final connectedWhatsAppNumbersProvider = whatsappNumbersStreamProvider;

/// Real-time stream of FinOps monthly rollup telemetry for the given [tenantId].
/// Automatically tracks the competence selected in [selectedCompetenciaProvider(tenantId)].
/// Listens to single document `tenant/{tenantId}/usage_metrics/{YYYY_MM}` ($O(1)$ read).
final usageFinopsStreamProvider =
    StreamProvider.family<UsageFinopsModel?, String>((ref, tenantId) {
  final service = ref.watch(whatsappMetaServiceProvider);
  final competencia = ref.watch(selectedCompetenciaProvider(tenantId));
  return service.watchMonthlyUsage(tenantId, competencia);
});

/// Alias matching MD07 §6.2 specification nomenclature.
final usageFinOpsProvider = usageFinopsStreamProvider;

// =============================================================================
// FinOps Budget Helper Providers
// =============================================================================

/// Helper provider computing whether the current spending has reached or exceeded
/// the warning threshold (e.g. 80%) defined for the tenant's monthly budget.
final finopsBudgetAlertProvider = Provider.family<bool, String>((ref, tenantId) {
  final finopsAsync = ref.watch(usageFinopsStreamProvider(tenantId));
  return finopsAsync.maybeWhen(
    data: (finops) {
      if (finops == null) return false;
      return finops.isAlertThresholdReached;
    },
    orElse: () => false,
  );
});

/// Helper provider computing whether the current spending strictly exceeded (100%+)
/// the total monthly budget limit in BRL.
final finopsBudgetExceededProvider = Provider.family<bool, String>((ref, tenantId) {
  final finopsAsync = ref.watch(usageFinopsStreamProvider(tenantId));
  return finopsAsync.maybeWhen(
    data: (finops) {
      if (finops == null) return false;
      return finops.isBudgetExceeded;
    },
    orElse: () => false,
  );
});

// =============================================================================
// Interactive Stepper Modal Controller & State
// =============================================================================

/// State model representing the interactive Embedded Signup dialog flow.
class EmbeddedSignupState {
  final MetaSignupStep step;
  final String? errorMessage;
  final WhatsAppNumberModel? connectedNumber;
  final bool isBusy;

  const EmbeddedSignupState({
    this.step = MetaSignupStep.idle,
    this.errorMessage,
    this.connectedNumber,
    this.isBusy = false,
  });

  bool get isCompleted => step == MetaSignupStep.completed;
  bool get isCancelled => step == MetaSignupStep.cancelled;
  bool get isError => step == MetaSignupStep.error;

  EmbeddedSignupState copyWith({
    MetaSignupStep? step,
    String? errorMessage,
    WhatsAppNumberModel? connectedNumber,
    bool? isBusy,
    bool clearError = false,
  }) {
    return EmbeddedSignupState(
      step: step ?? this.step,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      connectedNumber: connectedNumber ?? this.connectedNumber,
      isBusy: isBusy ?? this.isBusy,
    );
  }
}

/// Controller managing the 4-stage interactive Stepper state during onboarding.
class EmbeddedSignupController extends StateNotifier<EmbeddedSignupState> {
  final WhatsAppMetaService _service;

  EmbeddedSignupController(this._service) : super(const EmbeddedSignupState());

  /// Initiates the onboarding sequence with automated step progression.
  Future<void> startOnboarding({
    required String tenantId,
    required String appId,
    String? configId,
    bool simulationMode = false,
  }) async {
    state = state.copyWith(
      step: MetaSignupStep.authenticatingInMeta,
      isBusy: true,
      clearError: true,
    );

    try {
      final number = await _service.completeOnboarding(
        tenantId: tenantId,
        appId: appId,
        configId: configId,
        simulationMode: simulationMode,
        onStepChanged: (step) {
          if (!mounted) return;
          state = state.copyWith(step: step);
        },
      );

      if (!mounted) return;
      state = state.copyWith(
        step: MetaSignupStep.completed,
        connectedNumber: number,
        isBusy: false,
      );
    } on MetaSignupException catch (e) {
      if (!mounted) return;
      final isCancelled = e.errorCode == MetaSignupErrorCode.userCancelled ||
          e.message.toLowerCase().contains('cancel') ||
          e.message.toLowerCase().contains('fechada');
      state = state.copyWith(
        step: isCancelled ? MetaSignupStep.cancelled : MetaSignupStep.error,
        errorMessage: e.message,
        isBusy: false,
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      final isCancelled = msg.toLowerCase().contains('cancel') ||
          msg.toLowerCase().contains('fechada');
      state = state.copyWith(
        step: isCancelled ? MetaSignupStep.cancelled : MetaSignupStep.error,
        errorMessage: msg,
        isBusy: false,
      );
    }
  }

  /// Resets dialog state to idle for a new attempt.
  void reset() {
    if (!mounted) return;
    state = const EmbeddedSignupState();
  }
}

/// Provider managing the stateful stepper flow in [WhatsAppEmbeddedSignupDialog].
final embeddedSignupControllerProvider = StateNotifierProvider.autoDispose<
    EmbeddedSignupController, EmbeddedSignupState>((ref) {
  final service = ref.watch(whatsappMetaServiceProvider);
  return EmbeddedSignupController(service);
});
