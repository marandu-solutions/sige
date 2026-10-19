import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sige/src/core/theme/sige_colors.dart';
import 'package:sige/src/features/atendimento/models/config_atendimento_model.dart';
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

      await ref.read(configAtendimentoServiceProvider).salvarConfiguracoes(
            tenantId: widget.tenantId,
            config: novaConfig,
          );

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

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 720),
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
                          'Governança de Sobrecarga e Transbordo',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : SigeColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Defina capacidades máximas, limites de vácuo e destino do excedente da central',
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
}
