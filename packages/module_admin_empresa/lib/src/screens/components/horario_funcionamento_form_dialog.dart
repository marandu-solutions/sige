import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:module_admin_empresa/src/models/horario_model.dart';

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
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;

    return AlertDialog(
      backgroundColor: cs.surface,
      surfaceTintColor: cs.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(LucideIcons.clock, color: cs.primary),
          const SizedBox(width: 10),
          Text(
            "Horário de Funcionamento",
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _diasDaSemana.map((dia) {
              final diaChave = _diaParaChave[dia]!;
              final ranges = _horariosEditaveis[diaChave]!;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 1,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dia,
                        style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold, color: cs.onSurface),
                      ),
                      const SizedBox(height: 8),
                      if (ranges.isEmpty)
                        Text(
                          'Fechado',
                          style: textTheme.bodyMedium?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: cs.onSurfaceVariant),
                        ),
                      ...ranges.asMap().entries.map((entry) {
                        int idx = entry.key;
                        TimeRange range = entry.value;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => _pickTime(
                                    initialTime: range.start,
                                    onTimeSelected: (newTime) {
                                      setState(() {
                                        range.start = newTime;
                                      });
                                    },
                                  ),
                                  child: InputChip(
                                    label: Text(
                                      range.start.format(context),
                                      style: textTheme.bodyLarge?.copyWith(
                                          color: cs.onPrimaryContainer),
                                    ),
                                    backgroundColor: cs.primaryContainer,
                                    onPressed: () => _pickTime(
                                      initialTime: range.start,
                                      onTimeSelected: (newTime) {
                                        setState(() {
                                          range.start = newTime;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('-',
                                  style: textTheme.bodyLarge
                                      ?.copyWith(color: cs.onSurface)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: InkWell(
                                  onTap: () => _pickTime(
                                    initialTime: range.end,
                                    onTimeSelected: (newTime) {
                                      setState(() {
                                        range.end = newTime;
                                      });
                                    },
                                  ),
                                  child: InputChip(
                                    label: Text(
                                      range.end.format(context),
                                      style: textTheme.bodyLarge?.copyWith(
                                          color: cs.onPrimaryContainer),
                                    ),
                                    backgroundColor: cs.primaryContainer,
                                    onPressed: () => _pickTime(
                                      initialTime: range.end,
                                      onTimeSelected: (newTime) {
                                        setState(() {
                                          range.end = newTime;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon:
                                    Icon(LucideIcons.xCircle, color: cs.error),
                                onPressed: () =>
                                    _removeTimeRange(diaChave, idx),
                              ),
                            ],
                          ),
                        );
                      }),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => _addTimeRange(diaChave),
                          icon: Icon(LucideIcons.plus, color: cs.primary),
                          label: Text(
                            'Adicionar Horário',
                            style: textTheme.labelLarge
                                ?.copyWith(color: cs.primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            "Cancelar",
            style: textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
        FilledButton(
          onPressed: _salvarHorarios,
          child: Text(
            "Salvar",
            style: textTheme.labelLarge?.copyWith(color: cs.onPrimary),
          ),
        ),
      ],
    );
  }
}
