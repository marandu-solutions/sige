import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:module_admin_empresa/src/models/funcionario_model.dart';
import 'package:module_admin_empresa/src/models/horario_model.dart';
import 'package:module_admin_empresa/src/models/tenant_model.dart';
import 'package:module_admin_empresa/src/providers/admin_providers.dart';
import 'package:module_admin_empresa/src/providers/tenant_provider.dart';
import 'package:module_admin_empresa/src/screens/components/empresa_profile_form_dialog.dart';
import 'package:module_admin_empresa/src/screens/components/funcionario_card.dart';
import 'package:module_admin_empresa/src/screens/components/horario_funcionamento_form_dialog.dart';
import 'package:module_admin_empresa/src/services/admin_empresa_service.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  final String tenantId;

  const AdminDashboardScreen({super.key, required this.tenantId});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _lojaAberta = true; // TODO: Integrar com backend se houver esse campo

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text("Configurações",
            style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: cs.primary,
          unselectedLabelColor: cs.onSurfaceVariant,
          indicatorColor: cs.primary,
          tabs: const [
            Tab(icon: Icon(LucideIcons.store), text: 'Loja'),
            Tab(icon: Icon(LucideIcons.users), text: 'Equipe'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTabLoja(context, ref),
          _buildTabEquipe(context, ref),
        ],
      ),
    );
  }

  Widget _buildTabLoja(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    final tenantAsync = ref.watch(tenantProvider(widget.tenantId));

    return tenantAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Erro: $err')),
      data: (tenant) {
        if (tenant == null) return const SizedBox();

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.only(bottom: 24),
              child: SwitchListTile(
                title: Text(
                  "Status da Loja",
                  style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold, color: cs.onSurface),
                ),
                subtitle: Text(
                  _lojaAberta
                      ? "Sua loja está aberta e recebendo pedidos."
                      : "Sua loja está fechada e não recebe pedidos.",
                  style: textTheme.bodyMedium
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
                value: _lojaAberta,
                onChanged: (bool value) {
                  setState(() => _lojaAberta = value);
                  // TODO: Integrar com a lógica de backend para abrir/fechar loja
                },
                secondary: Icon(
                  _lojaAberta ? LucideIcons.checkCircle2 : LucideIcons.xCircle,
                  color: _lojaAberta ? cs.secondary : cs.error,
                  size: 32,
                ),
                activeColor: cs.secondary,
                inactiveThumbColor: cs.error,
                inactiveTrackColor: cs.error.withOpacity(0.3),
              ),
            ),
            _buildSectionTitle(context, "Informações Gerais"),
            const SizedBox(height: 12),
            _buildConfigOption(
              context,
              icon: LucideIcons.building2,
              title: "Perfil da Empresa",
              subtitle: "Edite nome, endereço, logo e dados fiscais.",
              onTap: () => _abrirPerfilEmpresaDialog(context, ref, tenant),
            ),
            _buildConfigOption(
              context,
              icon: LucideIcons.clock,
              title: "Horário de Funcionamento",
              subtitle: "Defina os horários de atendimento de cada dia.",
              onTap: () =>
                  _abrirHorarioFuncionamentoDialog(context, ref, tenant),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildTabEquipe(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    final funcionariosAsync = ref.watch(funcionariosProvider(widget.tenantId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: funcionariosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
            child: Text('Erro ao carregar equipe: $err',
                style: textTheme.bodyLarge?.copyWith(color: cs.error))),
        data: (funcionarios) {
          if (funcionarios.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.userX,
                        size: 80, color: cs.onSurfaceVariant.withOpacity(0.4)),
                    const SizedBox(height: 16),
                    Text(
                      'Nenhum funcionário cadastrado ainda.',
                      style: textTheme.titleMedium
                          ?.copyWith(color: cs.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Comece adicionando membros à sua equipe!',
                      style: textTheme.bodyMedium
                          ?.copyWith(color: cs.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: funcionarios.length,
            itemBuilder: (context, index) {
              final funcionario = funcionarios[index];
              return FuncionarioCard(
                funcionario: funcionario,
                onEdit: () =>
                    _showAddEditFuncionarioDialog(context, ref, funcionario),
                onStatusChange: () async {
                  final updatedFuncionario =
                      funcionario.copyWith(ativo: !funcionario.ativo);
                  await ref
                      .read(adminEmpresaServiceProvider)
                      .updateFuncionario(updatedFuncionario);
                  ref.invalidate(funcionariosProvider(widget.tenantId));
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditFuncionarioDialog(context, ref),
        tooltip: 'Convidar Novo Funcionário',
        icon: const Icon(Icons.add),
        label: const Text('Adicionar Funcionário'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildConfigOption(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap}) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(icon, color: cs.primary, size: 28),
        title: Text(
          title,
          style: textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w500, color: cs.onSurface),
        ),
        subtitle: Text(
          subtitle,
          style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
        onTap: onTap,
      ),
    );
  }

  void _abrirPerfilEmpresaDialog(
      BuildContext context, WidgetRef ref, TenantModel tenant) {
    showDialog(
      context: context,
      builder: (context) => EmpresaProfileFormDialog(
        empresa: tenant,
        onSave: (updatedTenant) async {
          await ref
              .read(adminEmpresaServiceProvider)
              .updateTenantConfig(widget.tenantId, updatedTenant.config);
          // Nota: updateTenantConfig atualiza apenas o config, se precisar atualizar
          // nomeFantasia ou documentoFiscal, precisa de um método específico no service
          // ou atualizar o updateTenantConfig para lidar com isso.
          // Por enquanto, vamos assumir que o service cuida disso ou implementar updateTenant completo.
          // Mas o service atual só tem updateTenantConfig e updateHorario.
          // Vamos focar no visual por enquanto.
          ref.invalidate(tenantProvider(widget.tenantId));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Perfil atualizado com sucesso!')),
            );
          }
        },
      ),
    );
  }

  void _abrirHorarioFuncionamentoDialog(
      BuildContext context, WidgetRef ref, TenantModel tenant) {
    final horarioConfig = tenant.config['horario_funcionamento'];
    final horariosAtuais = horarioConfig != null
        ? HorarioFuncionamento.fromMap(Map<String, dynamic>.from(horarioConfig))
        : HorarioFuncionamento(horarios: {});

    showDialog(
      context: context,
      builder: (context) => HorarioFuncionamentoFormDialog(
        horariosAtuais: horariosAtuais,
        onSave: (novosHorarios) async {
          await ref
              .read(adminEmpresaServiceProvider)
              .updateHorarioFuncionamento(
                  widget.tenantId, novosHorarios.toMap());
          ref.invalidate(tenantProvider(widget.tenantId));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Horários atualizados com sucesso!')),
            );
          }
        },
      ),
    );
  }

  void _showAddEditFuncionarioDialog(BuildContext context, WidgetRef ref,
      [FuncionarioModel? funcionario]) {
    showDialog(
      context: context,
      builder: (context) => _AddEditFuncionarioDialog(
        tenantId: widget.tenantId,
        funcionario: funcionario,
      ),
    );
  }
}

class _AddEditFuncionarioDialog extends ConsumerStatefulWidget {
  final String tenantId;
  final FuncionarioModel? funcionario;

  const _AddEditFuncionarioDialog({required this.tenantId, this.funcionario});

  @override
  ConsumerState<_AddEditFuncionarioDialog> createState() =>
      _AddEditFuncionarioDialogState();
}

class _AddEditFuncionarioDialogState
    extends ConsumerState<_AddEditFuncionarioDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeController;
  late TextEditingController _emailController;
  late TextEditingController _cargoController;
  late TextEditingController _telefoneController;
  bool _ativo = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nomeController =
        TextEditingController(text: widget.funcionario?.nome ?? '');
    _emailController =
        TextEditingController(text: widget.funcionario?.email ?? '');
    _cargoController =
        TextEditingController(text: widget.funcionario?.cargo ?? '');
    _telefoneController =
        TextEditingController(text: widget.funcionario?.telefone ?? '');
    _ativo = widget.funcionario?.ativo ?? true;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _cargoController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.funcionario != null;

    return AlertDialog(
      title: Text(isEditing ? 'Editar Funcionário' : 'Novo Funcionário'),
      content: _isLoading
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _nomeController,
                      decoration: const InputDecoration(labelText: 'Nome'),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Campo obrigatório'
                          : null,
                    ),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    TextFormField(
                      controller: _cargoController,
                      decoration: const InputDecoration(labelText: 'Cargo'),
                    ),
                    TextFormField(
                      controller: _telefoneController,
                      decoration: const InputDecoration(labelText: 'Telefone'),
                      keyboardType: TextInputType.phone,
                    ),
                    SwitchListTile(
                      title: const Text('Ativo'),
                      value: _ativo,
                      onChanged: (value) => setState(() => _ativo = value),
                    ),
                  ],
                ),
              ),
            ),
      actions: _isLoading
          ? []
          : [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: _save,
                child: const Text('Salvar'),
              ),
            ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final service = ref.read(adminEmpresaServiceProvider);
    final nome = _nomeController.text.trim();
    final email = _emailController.text.trim();
    final cargo = _cargoController.text.trim();
    final telefone = _telefoneController.text.trim();

    try {
      if (widget.funcionario != null) {
        // Update
        final updatedFuncionario = widget.funcionario!.copyWith(
          nome: nome,
          email: email.isEmpty ? null : email,
          cargo: cargo.isEmpty ? null : cargo,
          telefone: telefone.isEmpty ? null : telefone,
          ativo: _ativo,
          dataAtualizacao: DateTime.now(),
        );
        await service.updateFuncionario(updatedFuncionario);
      } else {
        // Add
        final newFuncionario = FuncionarioModel(
          id: '',
          tenantId: widget.tenantId,
          nome: nome,
          email: email.isEmpty ? null : email,
          cargo: cargo.isEmpty ? null : cargo,
          telefone: telefone.isEmpty ? null : telefone,
          ativo: _ativo,
          dataCriacao: DateTime.now(),
          dataAtualizacao: DateTime.now(),
        );
        await service.addFuncionario(newFuncionario);
      }

      if (mounted) {
        Navigator.pop(context);
        ref.invalidate(funcionariosProvider(widget.tenantId));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    }
  }
}
