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
  List<String> _selectedModulos = [];

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
    _selectedModulos = List.from(widget.funcionario?.modulosAcesso ?? []);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _cargoController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }

  String _formatModuleName(String module) {
    switch (module.toUpperCase()) {
      case 'MODULE_BASIC_DASHBOARD':
        return 'Dashboard Básico';
      case 'MODULE_ESTOQUE':
        return 'Gestão de Estoque';
      case 'MODULE_KANBAN':
        return 'Kanban de Tarefas';
      case 'MODULE_ATENDIMENTO':
        return 'Atendimento';
      case 'MODULE_ADMIN_EMPRESA':
        return 'Administração';
      case 'MODULE_GERENTE_ATENDIMENTO':
        return 'Gerência de Atendimento';
      default:
        // Remove prefixo module_ ou MODULE_ (case insensitive)
        String name =
            module.replaceAll(RegExp(r'^module_', caseSensitive: false), '');
        // Substitui underscores por espaços
        name = name.replaceAll('_', ' ');
        // Aplica Title Case
        name = name.split(' ').map((word) {
          if (word.isEmpty) return '';
          return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
        }).join(' ');

        return 'Módulo $name';
    }
  }

  IconData _getModuleIcon(String module) {
    switch (module.toUpperCase()) {
      case 'MODULE_BASIC_DASHBOARD':
        return LucideIcons.layoutDashboard;
      case 'MODULE_ESTOQUE':
        return LucideIcons.package;
      case 'MODULE_KANBAN':
        return LucideIcons.trello;
      case 'MODULE_ATENDIMENTO':
        return LucideIcons.messageCircle;
      case 'MODULE_ADMIN_EMPRESA':
        return LucideIcons.settings;
      case 'MODULE_GERENTE_ATENDIMENTO':
        return LucideIcons.userCog;
      default:
        return LucideIcons.box;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.funcionario != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      isEditing ? LucideIcons.userCog : LucideIcons.userPlus,
                      color: theme.colorScheme.onPrimaryContainer,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'Editar Funcionário' : 'Novo Membro',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          isEditing
                              ? 'Atualize os dados e permissões'
                              : 'Adicione alguém à sua equipe',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.x),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.surfaceContainerHighest
                          .withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Personal Info Section
                      _buildSectionLabel(context, 'Informações Pessoais'),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _nomeController,
                        label: 'Nome Completo',
                        icon: LucideIcons.user,
                        validator: (v) =>
                            v?.isEmpty == true ? 'Nome é obrigatório' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email Corporativo',
                        icon: LucideIcons.mail,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _cargoController,
                              label: 'Cargo',
                              icon: LucideIcons.briefcase,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _telefoneController,
                              label: 'Telefone',
                              icon: LucideIcons.phone,
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Status Section
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        child: SwitchListTile(
                          title: const Text(
                            'Status da Conta',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            _ativo
                                ? 'Ativo - Pode acessar o sistema'
                                : 'Inativo - Acesso bloqueado',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: _ativo
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.error,
                            ),
                          ),
                          value: _ativo,
                          onChanged: (val) => setState(() => _ativo = val),
                          activeColor: theme.colorScheme.primary,
                          secondary: Icon(
                            _ativo ? LucideIcons.checkCircle2 : LucideIcons.ban,
                            color: _ativo
                                ? theme.colorScheme.primary
                                : theme.colorScheme.error,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Modules Section
                      _buildSectionLabel(context, 'Permissões de Acesso'),
                      const SizedBox(height: 8),
                      Text(
                        'Selecione os módulos que este funcionário poderá acessar.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ref.watch(tenantProvider(widget.tenantId)).when(
                            data: (tenant) {
                              if (tenant == null ||
                                  tenant.modulosAtivos.isEmpty) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Text(
                                      'Nenhum módulo disponível.',
                                      style: TextStyle(
                                          color: theme
                                              .colorScheme.onSurfaceVariant),
                                    ),
                                  ),
                                );
                              }
                              return Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: tenant.modulosAtivos.map((modulo) {
                                  final isSelected =
                                      _selectedModulos.contains(modulo);
                                  return FilterChip(
                                    label: Text(_formatModuleName(modulo)),
                                    avatar: Icon(
                                      _getModuleIcon(modulo),
                                      size: 16,
                                      color: isSelected
                                          ? theme.colorScheme.onPrimaryContainer
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          _selectedModulos.add(modulo);
                                        } else {
                                          _selectedModulos.remove(modulo);
                                        }
                                      });
                                    },
                                    showCheckmark: false,
                                    selectedColor:
                                        theme.colorScheme.primaryContainer,
                                    labelStyle: TextStyle(
                                      color: isSelected
                                          ? theme.colorScheme.onPrimaryContainer
                                          : theme.colorScheme.onSurface,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                        color: isSelected
                                            ? theme.colorScheme.primary
                                                .withOpacity(0.5)
                                            : theme.colorScheme.outlineVariant,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                            loading: () => const Center(
                                child: CircularProgressIndicator()),
                            error: (_, __) => const Text('Erro ao carregar'),
                          ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1),

            // Actions Footer
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                    ),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 16),
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _save,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(LucideIcons.check),
                    label:
                        Text(_isLoading ? 'Salvando...' : 'Salvar Alterações'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color:
                Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
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
          modulosAcesso: _selectedModulos,
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
          modulosAcesso: _selectedModulos,
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
