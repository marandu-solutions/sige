import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:module_admin_empresa/src/models/horario_model.dart';
import 'package:module_admin_empresa/src/providers/tenant_provider.dart';
import 'package:module_admin_empresa/src/screens/components/horario_funcionamento_form_dialog.dart';
import 'package:module_admin_empresa/src/services/admin_empresa_service.dart';

class HorariosScreen extends ConsumerWidget {
  final String tenantId;

  const HorariosScreen({super.key, required this.tenantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenantAsync = ref.watch(tenantProvider(tenantId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Horário de Funcionamento'),
      ),
      body: tenantAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erro: $err')),
        data: (tenant) {
          if (tenant == null) {
            return const Center(child: Text('Empresa não encontrada'));
          }

          final horarioConfig = tenant.config['horario_funcionamento'];
          final horariosAtuais = horarioConfig != null
              ? HorarioFuncionamento.fromMap(
                  Map<String, dynamic>.from(horarioConfig))
              : HorarioFuncionamento(horarios: {});

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.clock, size: 32),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Horários Definidos',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Gerencie os horários de abertura e fechamento da sua loja.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildHorariosList(context, horariosAtuais),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => _editarHorarios(context, ref, horariosAtuais),
                          icon: const Icon(LucideIcons.edit),
                          label: const Text('Editar Horários'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHorariosList(
      BuildContext context, HorarioFuncionamento horarios) {
    final dias = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday'
    ];
    final diasNome = {
      'monday': 'Segunda-feira',
      'tuesday': 'Terça-feira',
      'wednesday': 'Quarta-feira',
      'thursday': 'Quinta-feira',
      'friday': 'Sexta-feira',
      'saturday': 'Sábado',
      'sunday': 'Domingo',
    };

    return Column(
      children: dias.map((dia) {
        final ranges = horarios.horarios[dia] ?? [];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  diasNome[dia]!,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: ranges.isEmpty
                      ? [
                          const Text('Fechado',
                              style: TextStyle(color: Colors.grey))
                        ]
                      : ranges
                          .map((r) => Text(r.toString(),
                              style: const TextStyle(fontSize: 16)))
                          .toList(),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _editarHorarios(BuildContext context, WidgetRef ref,
      HorarioFuncionamento horariosAtuais) {
    showDialog(
      context: context,
      builder: (context) => HorarioFuncionamentoFormDialog(
        horariosAtuais: horariosAtuais,
        onSave: (novosHorarios) async {
          try {
            await ref
                .read(adminEmpresaServiceProvider)
                .updateHorarioFuncionamento(tenantId, novosHorarios.toMap());
            ref.invalidate(tenantProvider(tenantId));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Horários atualizados com sucesso!')),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erro ao salvar: $e')),
              );
            }
          }
        },
      ),
    );
  }
}
