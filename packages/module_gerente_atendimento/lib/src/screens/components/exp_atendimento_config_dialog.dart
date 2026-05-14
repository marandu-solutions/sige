import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:module_admin_empresa/src/providers/tenant_provider.dart';
import 'package:module_admin_empresa/module_admin_empresa.dart';

class ExpAtendimentoConfigDialog extends ConsumerStatefulWidget {
  final String tenantId;

  const ExpAtendimentoConfigDialog({
    super.key,
    required this.tenantId,
  });

  @override
  ConsumerState<ExpAtendimentoConfigDialog> createState() =>
      _ExpAtendimentoConfigDialogState();
}

class _ExpAtendimentoConfigDialogState
    extends ConsumerState<ExpAtendimentoConfigDialog> {
  bool _noExpiration = true;
  double _hours = 24;
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _saveConfig(int hours) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final service = ref.read(adminEmpresaServiceProvider);
      await service.updateTempoAtendimento(widget.tenantId, hours);
      ref.invalidate(tenantProvider(widget.tenantId));
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Configuração de expiração salva com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar configuração: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenantAsync = ref.watch(tenantProvider(widget.tenantId));

    return AlertDialog(
      title: const Text('Tempo de Expiração'),
      content: tenantAsync.when(
        loading: () => const SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (err, stack) => Text('Erro ao carregar configurações: $err'),
        data: (tenant) {
          if (tenant == null) return const Text('Empresa não encontrada');

          if (!_isInitialized) {
            final configHours = tenant.tempoAtendimento;
            if (configHours > 0) {
              _noExpiration = false;
              _hours = configHours.toDouble();
            } else {
              _noExpiration = true;
            }
            // Use Future.microtask or just set it directly before building
            _isInitialized = true;
          }

          return StatefulBuilder(
            builder: (context, setStateBuilder) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Configure o tempo de expiração padrão para os atendimentos. Após este tempo, o atendimento será encerrado automaticamente.',
                  ),
                  const SizedBox(height: 24),
                  SwitchListTile(
                    title: const Text('Não possuir tempo de expiração'),
                    value: _noExpiration,
                    onChanged: (value) {
                      setStateBuilder(() {
                        _noExpiration = value;
                      });
                    },
                  ),
                  if (!_noExpiration) ...[
                    const SizedBox(height: 16),
                    Text('Tempo de expiração: ${_hours.toInt()} horas'),
                    Slider(
                      value: _hours,
                      min: 1,
                      max: 24,
                      divisions: 23,
                      label: '${_hours.toInt()}h',
                      onChanged: (value) {
                        setStateBuilder(() {
                          _hours = value;
                        });
                      },
                    ),
                  ],
                ],
              );
            },
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () => _saveConfig(_noExpiration ? 0 : _hours.toInt()),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Salvar'),
        ),
      ],
    );
  }
}
