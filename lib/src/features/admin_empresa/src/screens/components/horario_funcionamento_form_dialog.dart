import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sige/src/core/core.dart';
import 'package:sige/src/features/admin_empresa/src/models/horario_model.dart';

class HorarioFuncionamentoFormDialog extends StatefulWidget {
  final HorarioFuncionamento horariosAtuais;
  final Function(HorarioFuncionamento) onSave;

  const HorarioFuncionamentoFormDialog({
    super.key,
    required this.horariosAtuais,
    required this.onSave,
  });

  @override
  State<HorarioFuncionamentoFormDialog> createState() =>
      _HorarioFuncionamentoFormDialogState();
}

class _HorarioFuncionamentoFormDialogState
    extends State<HorarioFuncionamentoFormDialog> {
  late Map<String, List<TimeRange>> _horariosEditaveis;
  final List<String> _diasDaSemana = [
    'Segunda-feira',
    'Terça-feira',
    'Quarta-feira',
    'Quinta-feira',
    'Sexta-feira',
    'Sábado',
    'Domingo',
  ];

  // Mapeamento para chaves internas (em inglês)
  final Map<String, String> _diaParaChave = {
    'Segunda-feira': 'monday',
    'Terça-feira': 'tuesday',
    'Quarta-feira': 'wednesday',
    'Quinta-feira': 'thursday',
    'Sexta-feira': 'friday',
    'Sábado': 'saturday',
    'Domingo': 'sunday',
  };

  @override
  void initState() {
    super.initState();
    // Cria uma cópia profunda para edição
    _horariosEditaveis = {};
    widget.horariosAtuais.horarios.forEach((key, value) {
      _horariosEditaveis[key] =
          value.map((tr) => TimeRange(start: tr.start, end: tr.end)).toList();
    });

    // Garante que todos os dias da semana estejam no mapa, mesmo que vazios
    for (var dia in _diasDaSemana) {
      final chave = _diaParaChave[dia]!;
      _horariosEditaveis.putIfAbsent(chave, () => []);
    }
  }

  Future<void> _pickTime(
      {required TimeOfDay initialTime,
      required Function(TimeOfDay) onTimeSelected}) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null) {
      onTimeSelected(picked);
    }
  }

  void _addTimeRange(String diaChave) {
    setState(() {
      _horariosEditaveis[diaChave]!.add(
        TimeRange(start: TimeOfDay.now(), end: TimeOfDay.now()),
      );
    });
  }

  void _removeTimeRange(String diaChave, int index) {
    setState(() {
      _horariosEditaveis[diaChave]!.removeAt(index);
    });
  }

  void _salvarHorarios() {
    // TODO: Adicionar validação de sobreposição de horários se necessário
    final updatedHorarios = HorarioFuncionamento(
      horarios: _horariosEditaveis,
    );
    widget.onSave(updatedHorarios);
    Navigator.of(context).pop(); // Fecha o diálogo
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = const Color(0xFF2563EB);

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
                color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE2E8F0),
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
                  // Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(26, 24, 20, 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                            : [const Color(0xFFF8FAFC), Colors.white],
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(LucideIcons.clock, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Horário de Funcionamento',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  letterSpacing: -0.4,
                                  color: isDark ? Colors.white : SigeColors.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Defina as faixas de atendimento e operação para cada dia',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.grey[400] : SigeColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.pop(context),
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
                                size: 18,
                                color: isDark ? Colors.grey[300] : Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Lista de Dias da Semana
                  Flexible(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                      itemCount: _diasDaSemana.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final dia = _diasDaSemana[index];
                        final diaChave = _diaParaChave[dia]!;
                        final ranges = _horariosEditaveis[diaChave]!;
                        final isAberto = ranges.isNotEmpty;

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isAberto
                                  ? const Color(0xFF2563EB).withValues(alpha: isDark ? 0.35 : 0.25)
                                  : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    dia,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13.5,
                                      color: isDark ? Colors.white : SigeColors.lightTextPrimary,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: isAberto
                                          ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                          : Colors.grey.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isAberto ? 'ABERTO' : 'FECHADO',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.4,
                                        color: isAberto ? const Color(0xFF10B981) : Colors.grey,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    onPressed: () => _addTimeRange(diaChave),
                                    icon: const Icon(LucideIcons.plus, size: 13),
                                    label: const Text('Horário', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFF2563EB),
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    ),
                                  ),
                                ],
                              ),
                              if (ranges.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                ...ranges.asMap().entries.map((entry) {
                                  final idx = entry.key;
                                  final range = entry.value;

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 6.0),
                                    child: Row(
                                      children: [
                                        _buildTimeBox(
                                          time: range.start,
                                          isDark: isDark,
                                          onTap: () => _pickTime(
                                            initialTime: range.start,
                                            onTimeSelected: (t) => setState(() => range.start = t),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                          child: Text('às', style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.bold)),
                                        ),
                                        _buildTimeBox(
                                          time: range.end,
                                          isDark: isDark,
                                          onTap: () => _pickTime(
                                            initialTime: range.end,
                                            onTimeSelected: (t) => setState(() => range.end = t),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        IconButton(
                                          tooltip: 'Remover faixa',
                                          icon: const Icon(LucideIcons.trash2, size: 15, color: Color(0xFFEF4444)),
                                          onPressed: () => _removeTimeRange(diaChave, idx),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Actions Footer
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF131D2E) : const Color(0xFFF8FAFC),
                      border: Border(
                        top: BorderSide(
                          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: isDark ? Colors.grey[300] : SigeColors.lightTextSecondary,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: _salvarHorarios,
                            icon: const Icon(LucideIcons.check, size: 16),
                            label: const Text('Salvar Horários', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeBox({
    required TimeOfDay time,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final hora = time.hour.toString().padLeft(2, '0');
    final minuto = time.minute.toString().padLeft(2, '0');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF2563EB).withValues(alpha: 0.5),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.clock, size: 13, color: Color(0xFF2563EB)),
            const SizedBox(width: 6),
            Text(
              '$hora:$minuto',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 0.5,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

