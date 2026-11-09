import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sige/src/core/core.dart';

import '../../models/whatsapp_number_model.dart';
import '../../providers/whatsapp_finops_providers.dart';
import '../../services/meta_signup_bridge/meta_signup_models.dart';

/// Interactive modal dialog implementing the official Meta WhatsApp Embedded Signup
/// 4-stage onboarding Stepper flow with Riverpod integration and FinOps readiness.
///
/// Reference: MD07 §5.2, §6.3, PROJECT.md Feature #20
class WhatsAppEmbeddedSignupDialog extends ConsumerStatefulWidget {
  /// Unique identifier of the tenant connecting the WhatsApp number.
  final String tenantId;

  /// Optional pre-configured Meta App ID.
  final String? initialAppId;

  /// Optional pre-configured Facebook Login Configuration ID.
  final String? initialConfigId;

  /// Whether to default simulation mode to true.
  final bool defaultSimulationMode;

  /// Optional callback invoked when onboarding successfully completes.
  final ValueChanged<WhatsAppNumberModel>? onCompleted;

  const WhatsAppEmbeddedSignupDialog({
    super.key,
    required this.tenantId,
    this.initialAppId,
    this.initialConfigId,
    this.defaultSimulationMode = !kIsWeb,
    this.onCompleted,
  });

  /// Static convenience helper to display the dialog cleanly.
  static Future<WhatsAppNumberModel?> show(
    BuildContext context, {
    required String tenantId,
    String? initialAppId,
    String? initialConfigId,
    bool defaultSimulationMode = !kIsWeb,
    ValueChanged<WhatsAppNumberModel>? onCompleted,
  }) {
    return showDialog<WhatsAppNumberModel>(
      context: context,
      barrierDismissible: false,
      builder: (context) => WhatsAppEmbeddedSignupDialog(
        tenantId: tenantId,
        initialAppId: initialAppId,
        initialConfigId: initialConfigId,
        defaultSimulationMode: defaultSimulationMode,
        onCompleted: onCompleted,
      ),
    );
  }

  @override
  ConsumerState<WhatsAppEmbeddedSignupDialog> createState() =>
      _WhatsAppEmbeddedSignupDialogState();
}

class _WhatsAppEmbeddedSignupDialogState
    extends ConsumerState<WhatsAppEmbeddedSignupDialog> {
  late TextEditingController _appIdController;
  late TextEditingController _configIdController;
  late bool _simulationMode;
  bool _showAdvancedSettings = false;

  @override
  void initState() {
    super.initState();
    _appIdController = TextEditingController(
      text: widget.initialAppId ?? '109283746511223',
    );
    _configIdController = TextEditingController(
      text: widget.initialConfigId ?? '',
    );
    // Set initial simulation mode from widget configuration
    _simulationMode = widget.defaultSimulationMode;
  }

  @override
  void dispose() {
    _appIdController.dispose();
    _configIdController.dispose();
    super.dispose();
  }

  Future<void> _startSignup() async {
    final appId = _appIdController.text.trim();
    final configId = _configIdController.text.trim().isEmpty
        ? null
        : _configIdController.text.trim();

    await ref.read(embeddedSignupControllerProvider.notifier).startOnboarding(
          tenantId: widget.tenantId,
          appId: appId.isNotEmpty ? appId : '109283746511223',
          configId: configId,
          simulationMode: _simulationMode,
        );
  }

  void _resetFlow() {
    ref.read(embeddedSignupControllerProvider.notifier).reset();
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copiado para a área de transferência!'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final signupState = ref.watch(embeddedSignupControllerProvider);

    // Primary palette
    const primaryColor = Color(0xFF2563EB);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580, maxHeight: 820),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : const Color(0xFFE2E8F0),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.6)
                      : primaryColor.withValues(alpha: 0.14),
                  blurRadius: 36,
                  offset: const Offset(0, 16),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Executive Dialog Header
                  _buildHeader(context, isDark, signupState.isBusy),

                  // 2. Interactive Stepper Navigation Bar
                  _buildStepperHeader(signupState.step, isDark),

                  // 3. Dynamic Step Content (Scrollable)
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 26,
                        vertical: 20,
                      ),
                      child: _buildStepBody(context, signupState, isDark),
                    ),
                  ),

                  // 4. Modal Actions Footer
                  _buildFooter(context, signupState, isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. EXECUTIVE DIALOG HEADER
  // ===========================================================================
  Widget _buildHeader(BuildContext context, bool isDark, bool isBusy) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFFF8FAFC), Colors.white],
        ),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Row(
        children: [
          // Logo Badge
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF25D366), Color(0xFF128C7E)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF25D366).withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(LucideIcons.messageSquare, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),

          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      'Conectar WhatsApp Oficial',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                        letterSpacing: -0.3,
                        color: isDark ? Colors.white : SigeColors.lightTextPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0866FF).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFF0866FF).withValues(alpha: 0.3),
                          width: 0.8,
                        ),
                      ),
                      child: const Text(
                        'Meta v21.0',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0866FF),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Cadastro Incorporado Oficial com troca segura de tokens',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : SigeColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Close Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isBusy ? null : () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Icon(
                  LucideIcons.x,
                  size: 16,
                  color: isBusy
                      ? (isDark ? Colors.grey[700] : Colors.grey[400])
                      : (isDark ? Colors.grey[300] : Colors.grey[600]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. INTERACTIVE STEPPER NAVIGATION BAR (4 STAGES)
  // ===========================================================================
  Widget _buildStepperHeader(MetaSignupStep currentStep, bool isDark) {
    const steps = [
      {'title': 'Meta Login', 'icon': LucideIcons.userCheck},
      {'title': 'Identificadores', 'icon': LucideIcons.key},
      {'title': 'Webhooks', 'icon': LucideIcons.webhook},
      {'title': 'Operacional', 'icon': LucideIcons.checkCircle2},
    ];

    final currentIdx = currentStep.indexOrder;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D2E) : const Color(0xFFF1F5F9),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            final stepBefore = index ~/ 2;
            final isConnectorCompleted = currentStep == MetaSignupStep.completed ||
                (stepBefore < currentIdx && !currentStep.isTerminal);
            return Expanded(
              child: Container(
                height: 2,
                color: isConnectorCompleted
                    ? const Color(0xFF16A34A)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : const Color(0xFFCBD5E1)),
              ),
            );
          }

          final stepIndex = index ~/ 2;
          final isCompleted = currentStep == MetaSignupStep.completed ||
              (stepIndex < currentIdx && !currentStep.isTerminal);
          final isActive = stepIndex == currentIdx && currentStep.isProcessing;
          final isFailed = stepIndex == currentIdx &&
              (currentStep == MetaSignupStep.error ||
                  currentStep == MetaSignupStep.cancelled);

          Color circleBg;
          Color circleBorder;
          Color contentColor;

          if (isCompleted) {
            circleBg = const Color(0xFF16A34A);
            circleBorder = const Color(0xFF16A34A);
            contentColor = Colors.white;
          } else if (isFailed) {
            final isCancelled = currentStep == MetaSignupStep.cancelled;
            circleBg = isCancelled ? const Color(0xFFF59E0B) : const Color(0xFFEF4444);
            circleBorder = circleBg;
            contentColor = Colors.white;
          } else if (isActive) {
            circleBg = const Color(0xFF2563EB);
            circleBorder = const Color(0xFF2563EB);
            contentColor = Colors.white;
          } else {
            circleBg = isDark ? const Color(0xFF1E293B) : Colors.white;
            circleBorder = isDark
                ? Colors.white.withValues(alpha: 0.2)
                : const Color(0xFFCBD5E1);
            contentColor = isDark ? Colors.grey[400]! : const Color(0xFF64748B);
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: circleBg,
                  border: Border.all(color: circleBorder, width: 1.5),
                  boxShadow: (isActive || isCompleted)
                      ? [
                          BoxShadow(
                            color: circleBg.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(LucideIcons.check, size: 16, color: Colors.white)
                      : isFailed
                          ? Icon(
                              currentStep == MetaSignupStep.cancelled
                                  ? LucideIcons.alertCircle
                                  : LucideIcons.alertTriangle,
                              size: 15,
                              color: Colors.white,
                            )
                          : isActive
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  '${stepIndex + 1}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: contentColor,
                                  ),
                                ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                steps[stepIndex]['title'] as String,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: (isActive || isCompleted)
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: isCompleted
                      ? const Color(0xFF16A34A)
                      : (isActive
                          ? const Color(0xFF2563EB)
                          : (isDark ? Colors.grey[400] : const Color(0xFF64748B))),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ===========================================================================
  // 3. DYNAMIC STEP BODY CONTENT
  // ===========================================================================
  Widget _buildStepBody(
    BuildContext context,
    EmbeddedSignupState state,
    bool isDark,
  ) {
    if (state.isCancelled) {
      return _buildCancelledView(context, state, isDark);
    }

    if (state.isError) {
      return _buildErrorView(context, state, isDark);
    }

    switch (state.step) {
      case MetaSignupStep.idle:
        return _buildIdleView(context, isDark);

      case MetaSignupStep.authenticatingInMeta:
        return _buildProcessingStepView(
          stageNumber: 1,
          title: 'Autenticando com a Meta...',
          subtitle:
              'Uma janela pop-up oficial do Facebook foi aberta para login da sua empresa.',
          hint:
              'Caso o pop-up não abra automaticamente, verifique se o navegador bloqueou janelas pop-up e clique em permitir.',
          icon: LucideIcons.externalLink,
          isDark: isDark,
        );

      case MetaSignupStep.capturingSessionIds:
        return _buildProcessingStepView(
          stageNumber: 2,
          title: 'Capturando identificadores oficiais...',
          subtitle:
              'Evento seguro WA_EMBEDDED_SIGNUP recebido. Extraindo WABA ID e Phone Number ID.',
          hint:
              'Sua Conta WhatsApp Business oficial está sendo vinculada ao aplicativo.',
          icon: LucideIcons.key,
          isDark: isDark,
        );

      case MetaSignupStep.exchangingTokenAndSubscribing:
        return _buildProcessingStepView(
          stageNumber: 3,
          title: 'Trocando credenciais e ativando webhooks...',
          subtitle:
              'A Cloud Function do SIGE está trocando o token definitivo na Graph API v21.0 e registrando o webhook.',
          hint:
              'Persistência atômica no cofre seguro e tabela global de roteamento em andamento.',
          icon: LucideIcons.webhook,
          isDark: isDark,
        );

      case MetaSignupStep.completed:
        return _buildCompletedView(context, state.connectedNumber, isDark);

      default:
        return _buildIdleView(context, isDark);
    }
  }

  // ===========================================================================
  // VIEW: IDLE / CONFIGURATION
  // ===========================================================================
  Widget _buildIdleView(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Informational introduction
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E293B).withValues(alpha: 0.6)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.shieldCheck, size: 18, color: Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  Text(
                    'Permissões Oficiais Requeridas',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: isDark ? Colors.white : SigeColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildCheckItem(
                'whatsapp_business_management: Permite gerenciar a conta WABA e números.',
                isDark,
              ),
              const SizedBox(height: 6),
              _buildCheckItem(
                'whatsapp_business_messaging: Permite envio e recebimento de mensagens oficiais.',
                isDark,
              ),
              const SizedBox(height: 6),
              _buildCheckItem(
                'Webhooks Automáticos: O SIGE inscreve o número diretamente em subscribed_apps.',
                isDark,
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Simulation Mode Toggle Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _simulationMode
                ? (isDark
                    ? const Color(0xFF1E3A8A).withValues(alpha: 0.25)
                    : const Color(0xFFEFF6FF))
                : (isDark
                    ? const Color(0xFF1E293B).withValues(alpha: 0.4)
                    : const Color(0xFFF8FAFC)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _simulationMode
                  ? const Color(0xFF3B82F6)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFE2E8F0)),
              width: _simulationMode ? 1.4 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _simulationMode
                      ? const Color(0xFF2563EB).withValues(alpha: 0.15)
                      : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  LucideIcons.sliders,
                  size: 20,
                  color: _simulationMode
                      ? const Color(0xFF2563EB)
                      : (isDark ? Colors.grey[400] : const Color(0xFF64748B)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 2,
                      children: [
                        Text(
                          'Modo Homologação / Simulação',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: isDark ? Colors.white : SigeColors.lightTextPrimary,
                          ),
                        ),
                        if (_simulationMode)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'ATIVO',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Testa o fluxo completo e persistência local sem necessidade de Meta App ID ao vivo.',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[400] : SigeColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _simulationMode,
                activeThumbColor: const Color(0xFF2563EB),
                onChanged: (val) {
                  setState(() => _simulationMode = val);
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Advanced Settings Collapsible (App ID / Config ID)
        InkWell(
          onTap: () {
            setState(() => _showAdvancedSettings = !_showAdvancedSettings);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(
              children: [
                Icon(
                  _showAdvancedSettings
                      ? LucideIcons.chevronDown
                      : LucideIcons.chevronRight,
                  size: 16,
                  color: const Color(0xFF2563EB),
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Configurações Avançadas da Meta API (Opcional)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        if (_showAdvancedSettings) ...[
          const SizedBox(height: 10),
          _buildTextField(
            controller: _appIdController,
            label: 'Meta Tech Provider App ID',
            hint: 'Ex: 109283746511223',
            icon: LucideIcons.key,
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _buildTextField(
            controller: _configIdController,
            label: 'Facebook Login Configuration ID (Opcional)',
            hint: 'Ex: 998877665544332',
            icon: LucideIcons.sliders,
            isDark: isDark,
          ),
        ],
      ],
    );
  }

  // ===========================================================================
  // VIEW: PROCESSING STAGES (1, 2, 3)
  // ===========================================================================
  Widget _buildProcessingStepView({
    required int stageNumber,
    required String title,
    required String subtitle,
    required String hint,
    required IconData icon,
    required bool isDark,
  }) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 90,
              height: 90,
              child: CircularProgressIndicator(
                strokeWidth: 3.5,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : SigeColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            color: isDark ? Colors.grey[300] : SigeColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E293B).withValues(alpha: 0.6)
                : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.info, size: 16, color: Color(0xFF2563EB)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hint,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[400] : SigeColors.lightTextSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ===========================================================================
  // VIEW: COMPLETED / CONNECTED NUMBER CARD (STAGE 4)
  // ===========================================================================
  Widget _buildCompletedView(
    BuildContext context,
    WhatsAppNumberModel? number,
    bool isDark,
  ) {
    if (number == null) {
      return Center(
        child: Text(
          'Número conectado com sucesso!',
          style: TextStyle(
            color: isDark ? Colors.white : SigeColors.lightTextPrimary,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Success Celebration Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      const Color(0xFF065F46).withValues(alpha: 0.35),
                      const Color(0xFF064E3B).withValues(alpha: 0.2),
                    ]
                  : [
                      const Color(0xFFDCFCE7),
                      const Color(0xFFF0FDF4),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF16A34A).withValues(alpha: 0.4),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFF16A34A),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.check, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Número Oficial Conectado com Sucesso!',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: isDark ? Colors.white : const Color(0xFF14532D),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'O webhook da Meta está ativo e a IA está pronta para responder.',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[300] : const Color(0xFF166534),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Connected Number Details Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display phone & official badge
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          number.displayPhoneNumber,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.4,
                            color: isDark ? Colors.white : SigeColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          number.verifiedName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.grey[300] : SigeColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF16A34A).withValues(alpha: 0.35),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.checkCircle2, size: 12, color: Color(0xFF16A34A)),
                        SizedBox(width: 4),
                        Text(
                          'OFICIAL META ✓',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const Divider(height: 24),

              // Badges Strip
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Quality Rating Chip
                  _buildMetaBadge(
                    label: number.qualityRating.badgeLabel,
                    color: number.qualityRating.color,
                    bgColor: number.qualityRating.backgroundColor,
                  ),

                  // Tier Limit Chip
                  _buildMetaBadge(
                    label: number.messagingLimitTier.badgeText,
                    color: const Color(0xFF2563EB),
                    bgColor: const Color(0xFFEFF6FF),
                  ),

                  // Webhook Status
                  _buildMetaBadge(
                    label: number.webhookSubscribed
                        ? '🟢 Webhook Ativo'
                        : '🔴 Webhook Inativo',
                    color: number.webhookSubscribed
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFDC2626),
                    bgColor: number.webhookSubscribed
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFFEE2E2),
                  ),

                  // IA Status
                  _buildMetaBadge(
                    label: number.iaAtivaNesteNumero
                        ? '🤖 IA 24/7 Ativa'
                        : '⏸️ IA Pausada',
                    color: const Color(0xFF7C3AED),
                    bgColor: const Color(0xFFF5F3FF),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Identifiers Chips (WABA ID & Phone Number ID)
              _buildIdentifierRow(
                label: 'WABA ID',
                value: number.wabaId,
                onCopy: () => _copyToClipboard(context, number.wabaId, 'WABA ID'),
                isDark: isDark,
              ),
              const SizedBox(height: 6),
              _buildIdentifierRow(
                label: 'Phone ID',
                value: number.phoneNumberId,
                onCopy: () => _copyToClipboard(
                  context,
                  number.phoneNumberId,
                  'Phone Number ID',
                ),
                isDark: isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // VIEW: CANCELLED STATE
  // ===========================================================================
  Widget _buildCancelledView(
    BuildContext context,
    EmbeddedSignupState state,
    bool isDark,
  ) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
            border: Border.all(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: const Icon(LucideIcons.alertCircle, color: Color(0xFFF59E0B), size: 30),
        ),
        const SizedBox(height: 18),
        Text(
          'Conexão Cancelada pelo Usuário',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : SigeColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          state.errorMessage ??
              'A janela de autenticação da Meta foi fechada antes da confirmação do número.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            height: 1.4,
            color: isDark ? Colors.grey[300] : SigeColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E293B).withValues(alpha: 0.5)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.info, size: 16, color: Color(0xFFF59E0B)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Nenhuma alteração foi realizada. Você pode reiniciar o fluxo quando desejar.',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[400] : SigeColors.lightTextSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // VIEW: ERROR STATE
  // ===========================================================================
  Widget _buildErrorView(
    BuildContext context,
    EmbeddedSignupState state,
    bool isDark,
  ) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFEF4444).withValues(alpha: 0.15),
            border: Border.all(
              color: const Color(0xFFEF4444).withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: const Icon(LucideIcons.alertTriangle, color: Color(0xFFEF4444), size: 30),
        ),
        const SizedBox(height: 18),
        Text(
          'Falha na Conexão com a Meta',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : SigeColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF7F1D1D).withValues(alpha: 0.25)
                : const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFEF4444).withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state.errorMessage ?? 'Ocorreu um erro inesperado durante o cadastro.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Dica: Verifique se o bloqueador de anúncios/pop-ups está ativo no navegador ou ative o Modo Simulação para testar localmente.',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey[400] : const Color(0xFF7F1D1D),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 4. MODAL ACTIONS FOOTER
  // ===========================================================================
  Widget _buildFooter(
    BuildContext context,
    EmbeddedSignupState state,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D2E) : const Color(0xFFF8FAFC),
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 8,
        children: [
          // Cancel / Close Button
          if (!state.isBusy)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(state.connectedNumber);
              },
              style: TextButton.styleFrom(
                foregroundColor:
                    isDark ? Colors.grey[300] : SigeColors.lightTextSecondary,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                state.isCompleted ? 'Fechar' : 'Cancelar',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),

          // Action Button based on state
          if (state.isCancelled || state.isError) ...[
            if (!_simulationMode && state.isError) ...[
              OutlinedButton.icon(
                onPressed: () {
                  setState(() => _simulationMode = true);
                  _resetFlow();
                },
                icon: const Icon(LucideIcons.sliders, size: 14),
                label: const Text('Modo Simulação'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                  side: const BorderSide(color: Color(0xFF2563EB)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            ElevatedButton.icon(
              onPressed: _resetFlow,
              icon: const Icon(LucideIcons.refreshCw, size: 14),
              label: const Text('Tentar Novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ] else if (state.isCompleted) ...[
            ElevatedButton.icon(
              onPressed: () {
                widget.onCompleted?.call(state.connectedNumber!);
                Navigator.of(context).pop(state.connectedNumber);
              },
              icon: const Icon(LucideIcons.check, size: 16),
              label: const Text('Concluir & Ir ao Painel'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ] else if (state.step == MetaSignupStep.idle) ...[
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _startSignup,
                icon: const Icon(LucideIcons.arrowRight, size: 15),
                label: const Text(
                  'Iniciar Cadastro Incorporado',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // HELPER WIDGETS
  // ===========================================================================
  Widget _buildCheckItem(String text, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(LucideIcons.checkCircle2, size: 14, color: Color(0xFF16A34A)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.35,
              color: isDark ? Colors.grey[300] : const Color(0xFF334155),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.grey[300] : const Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white : SigeColors.lightTextPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            prefixIcon: Icon(icon, size: 14, color: const Color(0xFF2563EB)),
            filled: true,
            fillColor: isDark
                ? const Color(0xFF1E293B)
                : const Color(0xFFF8FAFC),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetaBadge({
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildIdentifierRow({
    required String label,
    required String value,
    required VoidCallback onCopy,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0F172A).withValues(alpha: 0.6)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : SigeColors.lightTextPrimary,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.copy, size: 13),
            onPressed: onCopy,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Copiar $label',
          ),
        ],
      ),
    );
  }
}
