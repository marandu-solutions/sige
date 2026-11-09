import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sige/src/core/theme/sige_colors.dart';
import 'package:sige/src/features/admin_empresa/src/providers/tenant_provider.dart';
import 'package:sige/src/features/admin_empresa/src/services/admin_empresa_service.dart';
import 'package:sige/src/features/atendimento/models/config_atendimento_model.dart';
import 'package:sige/src/features/atendimento/providers/atendimento_provider.dart';
import 'package:sige/src/features/atendimento/providers/config_atendimento_provider.dart';

class PoliticasTransbordoDialog extends ConsumerStatefulWidget {
  final String tenantId;
  final ConfigAtendimentoModel configAtual;

  const PoliticasTransbordoDialog({
    super.key,
    required this.tenantId,
    required this.configAtual,
  });

  static Future<void> show(
    BuildContext context, {
    required String tenantId,
    required ConfigAtendimentoModel configAtual,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => PoliticasTransbordoDialog(
        tenantId: tenantId,
        configAtual: configAtual,
      ),
    );
  }

  @override
  ConsumerState<PoliticasTransbordoDialog> createState() =>
      _PoliticasTransbordoDialogState();
}

class _PoliticasTransbordoDialogState
    extends ConsumerState<PoliticasTransbordoDialog> {
  late int _capacidadePadrao;
  late int _capJunior;
  late int _capPleno;
  late int _capSenior;
  late int _slaVacuo;
  late String _destinoTransbordo;
  late TextEditingController _msgAcolhimentoController;
  bool _salvando = false;

  bool _expiracaoAtiva = false;
  int _horasExpiracao = 24;
  bool _expiracaoInitialized = false;

  @override
  void initState() {
    super.initState();
    _capacidadePadrao = widget.configAtual.capacidadeMaximaPadrao;
    _capJunior = widget.configAtual.capacidadePorNivel['junior'] ?? 5;
    _capPleno = widget.configAtual.capacidadePorNivel['pleno'] ?? 8;
    _capSenior = widget.configAtual.capacidadePorNivel['senior'] ?? 12;
    _slaVacuo = widget.configAtual.slaVacuoAlertaMinutos;
    _destinoTransbordo = widget.configAtual.destinoTransbordo;
    _msgAcolhimentoController = TextEditingController(
      text: widget.configAtual.mensagemAcolhimentoTransbordo,
    );
  }

  @override
  void dispose() {
    _msgAcolhimentoController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    setState(() => _salvando = true);
    try {
      final novaConfig = widget.configAtual.copyWith(
        capacidadeMaximaPadrao: _capacidadePadrao,
        capacidadePorNivel: {
          'junior': _capJunior,
          'pleno': _capPleno,
          'senior': _capSenior,
        },
        destinoTransbordo: _destinoTransbordo,
        slaVacuoAlertaMinutos: _slaVacuo,
        mensagemAcolhimentoTransbordo: _msgAcolhimentoController.text.trim(),
      );

      // 1. Salva políticas de transbordo e capacidades
      await ref.read(configAtendimentoServiceProvider).salvarConfiguracoes(
            tenantId: widget.tenantId,
            config: novaConfig,
          );

      // 2. Salva tempo de expiração / encerramento automático no tenant
      final int tempoSalvar = _expiracaoAtiva ? _horasExpiracao : 0;
      await ref.read(adminEmpresaServiceProvider).updateTempoAtendimento(
            widget.tenantId,
            tempoSalvar,
          );

      // Invalida os providers para atualizar toda a torre e boards
      ref.invalidate(tenantProvider(widget.tenantId));
      ref.invalidate(configAtendimentoProvider(widget.tenantId));
      ref.invalidate(globalAtendimentoProvider(widget.tenantId));

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Políticas de Atendimento salvas com sucesso!'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar políticas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Inicializa o tempo de expiração do atendimento a partir do tenant
    final tenantAsync = ref.watch(tenantProvider(widget.tenantId));
    final tenant = tenantAsync.valueOrNull;
    if (!_expiracaoInitialized && tenant != null) {
      if (tenant.tempoAtendimento > 0) {
        _expiracaoAtiva = true;
        _horasExpiracao = tenant.tempoAtendimento;
      } else {
        _expiracaoAtiva = false;
        _horasExpiracao = 24;
      }
      _expiracaoInitialized = true;
    }

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 760),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.sliders,
                      color: Color(0xFF2563EB),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Governança de Transbordo, Capacidades & Expiração',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : SigeColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Defina capacidades máximas, limites de vácuo, regras de transbordo e tempo de expiração',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey[400] : SigeColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 32),

              // Conteúdo rolável
              Expanded(
                child: ListView(
                  children: [
                    // Seção 1: Capacidade por Nível
                    _buildSectionHeader(
                      icon: LucideIcons.users,
                      title: 'Capacidade Máxima Simultânea por Atendente',
                      subtitle: 'Quantidade máxima de conversas ativas antes de disparar sobrecarga',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildCapacityRow(
                      nivel: 'Vendedor Sênior / Key Account',
                      descricao: 'Focado em cotações complexas e alto volume',
                      valor: _capSenior,
                      min: 5,
                      max: 20,
                      cor: const Color(0xFF10B981),
                      onChanged: (v) => setState(() => _capSenior = v),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 10),
                    _buildCapacityRow(
                      nivel: 'Vendedor Pleno',
                      descricao: 'Atendimento geral e demandas comerciais padrão',
                      valor: _capPleno,
                      min: 3,
                      max: 15,
                      cor: const Color(0xFF2563EB),
                      onChanged: (v) => setState(() => _capPleno = v),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 10),
                    _buildCapacityRow(
                      nivel: 'Vendedor Júnior / Balcão',
                      descricao: 'Pedidos rápidos, balcão e consumidores avulsos',
                      valor: _capJunior,
                      min: 2,
                      max: 10,
                      cor: const Color(0xFFF59E0B),
                      onChanged: (v) => setState(() => _capJunior = v),
                      isDark: isDark,
                    ),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Seção 2: Política de Transbordo
                    _buildSectionHeader(
                      icon: LucideIcons.shuffle,
                      title: 'Destino do Excedente (Política de Transbordo)',
                      subtitle: 'Quando o atendente atinge a capacidade máxima, para onde vai o próximo cliente?',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 14),
                    _buildDestinoRadioTile(
                      id: 'vendedor_ocioso',
                      titulo: 'Transbordar para Vendedor Mais Ocioso',
                      subtitulo: 'Entrega automática para o colega online com menor taxa de ocupação da equipe.',
                      icone: LucideIcons.userCheck,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    _buildDestinoRadioTile(
                      id: 'ia_omnicanal',
                      titulo: 'Reter na IA Omnichannel 24/7',
                      subtitulo: 'A IA assume imediatamente, colhe a demanda e adianta o orçamento até um vendedor liberar.',
                      icone: LucideIcons.bot,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    _buildDestinoRadioTile(
                      id: 'fila_espera',
                      titulo: 'Fila Geral de Espera com Mensagem de SLA',
                      subtitulo: 'O cliente aguarda com mensagem automática estimando tempo de atendimento.',
                      icone: LucideIcons.clock,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Seção 3: Alerta de Vácuo / SLA
                    _buildSectionHeader(
                      icon: LucideIcons.alertTriangle,
                      title: 'Tolerância de Vácuo (Tempo Máximo Sem Resposta)',
                      subtitle: 'Dispara alerta vermelho pulsante na cabine se o cliente ficar sem retorno',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: _slaVacuo.toDouble(),
                            min: 3,
                            max: 30,
                            divisions: 27,
                            activeColor: const Color(0xFFEF4444),
                            onChanged: (v) => setState(() => _slaVacuo = v.round()),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFEF4444)),
                          ),
                          child: Text(
                            '$_slaVacuo minutos',
                            style: const TextStyle(
                              color: Color(0xFFEF4444),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Seção 4: Tempo de Expiração & Encerramento Automático
                    _buildSectionHeader(
                      icon: LucideIcons.timerReset,
                      title: 'Tempo de Expiração & Encerramento Automático',
                      subtitle: 'Encerre e arquive conversas inativas para liberar a esteira e evitar atendimentos fantasmas',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildExpiracaoSection(isDark: isDark),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Botões de ação
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _salvando ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _salvando ? null : _salvar,
                    icon: _salvando
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(LucideIcons.save, size: 16),
                    label: Text(_salvando ? 'Salvando...' : 'Salvar Políticas da Central'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF2563EB)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : SigeColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : SigeColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCapacityRow({
    required String nivel,
    required String descricao,
    required int valor,
    required int min,
    required int max,
    required Color cor,
    required ValueChanged<int> onChanged,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      nivel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : SigeColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  descricao,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[400] : SigeColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.minus, size: 16),
            onPressed: valor > min ? () => onChanged(valor - 1) : null,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$valor simultâneos',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: cor,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.plus, size: 16),
            onPressed: valor < max ? () => onChanged(valor + 1) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDestinoRadioTile({
    required String id,
    required String titulo,
    required String subtitulo,
    required IconData icone,
    required bool isDark,
  }) {
    final isSelected = _destinoTransbordo == id;

    return InkWell(
      onTap: () => setState(() => _destinoTransbordo = id),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2563EB).withValues(alpha: isDark ? 0.2 : 0.08)
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2563EB)
                : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icone,
              color: isSelected ? const Color(0xFF2563EB) : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isDark ? Colors.white : SigeColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitulo,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey[400] : SigeColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: id,
              groupValue: _destinoTransbordo,
              activeColor: const Color(0xFF2563EB),
              onChanged: (v) {
                if (v != null) setState(() => _destinoTransbordo = v);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpiracaoSection({required bool isDark}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _expiracaoAtiva
              ? const Color(0xFF2563EB).withValues(alpha: 0.35)
              : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Encerrar atendimentos inativos automaticamente',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : SigeColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Libera a esteira arquivando conversas sem nova mensagem após o período limite.',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[400] : SigeColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _expiracaoAtiva,
                activeThumbColor: Colors.white,
                activeTrackColor: const Color(0xFF2563EB),
                onChanged: (val) {
                  setState(() => _expiracaoAtiva = val);
                },
              ),
            ],
          ),
          if (_expiracaoAtiva) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Chips de atalho rápido
            Row(
              children: [
                Text(
                  'Atalhos:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[400] : SigeColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [6, 12, 24, 48, 72].map((horas) {
                      final isSelected = _horasExpiracao == horas;
                      return InkWell(
                        onTap: () => setState(() => _horasExpiracao = horas),
                        borderRadius: BorderRadius.circular(8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF2563EB)
                                : (isDark ? const Color(0xFF1E293B) : Colors.white),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF2563EB)
                                  : (isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                            ),
                          ),
                          child: Text(
                            '$horas h${horas == 24 ? " (1 dia)" : horas == 48 ? " (2 dias)" : horas == 72 ? " (3 dias)" : ""}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.grey[300] : const Color(0xFF334155)),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Slider e display
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _horasExpiracao.toDouble().clamp(1.0, 72.0),
                    min: 1,
                    max: 72,
                    divisions: 71,
                    activeColor: const Color(0xFF2563EB),
                    label: '$_horasExpiracao h',
                    onChanged: (v) => setState(() => _horasExpiracao = v.round()),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF2563EB)),
                  ),
                  child: Text(
                    '$_horasExpiracao ${_horasExpiracao == 1 ? "hora" : "horas"}',
                    style: const TextStyle(
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Info note
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.info, size: 14, color: Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Atendimentos sem novas mensagens há mais de $_horasExpiracao horas serão arquivados automaticamente na esteira.',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
