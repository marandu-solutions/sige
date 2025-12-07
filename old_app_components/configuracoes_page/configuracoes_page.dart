// lib/pages/configuracoes/configuracoes_page.dart

/*import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:siga/Model/empresa.dart';

// Seus imports existentes
import 'package:siga/Model/funcionario.dart';
import 'package:siga/Pages/ConfiguracoesPage/Components/empresa_profile_form_dialog.dart';
import 'package:siga/Pages/ConfiguracoesPage/Components/funcionario_form.dart';
import 'package:siga/Pages/ConfiguracoesPage/Components/horario_funcionamento_form_dialog.dart';
import 'package:siga/Service/auth_service.dart';
import 'package:siga/Service/funcionario_service.dart';
import 'Components/funcionario_card.dart';


class ConfiguracoesPage extends StatefulWidget {
  const ConfiguracoesPage({super.key});

  @override
  State<ConfiguracoesPage> createState() => _ConfiguracoesPageState();
}

class _ConfiguracoesPageState extends State<ConfiguracoesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FuncionarioService _funcionarioService = FuncionarioService();

  bool _lojaAberta = true; // Estado de exemplo para a UI

  // DADOS DA EMPRESA: AGORA USANDO SEU MODELO Empresa REAL
  // **ATENÇÃO:** Este é um DADO MOCKADO APENAS PARA TESTES LOCAIS DA UI.
  // SEU COLEGA DE BD DEVERÁ FORNECER A EMPRESA REAL DO USUÁRIO LOGADO.
  Empresa _empresaAtual = Empresa(
    id: "empresa_mock_id",
    nomeEmpresa: "Minha Loja de Doces Ltda.",
    proprietario: "João Silva",
    email: "contato@minhalojadedoces.com",
    telefone: "(84) 99999-8888",
    cpf: "123.456.789-00",
    createdAt: Timestamp.now(),
  );

  HorarioFuncionamento _horariosMock = HorarioFuncionamento( // <--- O TIPO CORRETO É HorarioFuncionamento
    horarios: {
      'monday': [
        TimeRange(start: const TimeOfDay(hour: 9, minute: 0), end: const TimeOfDay(hour: 12, minute: 0)),
        TimeRange(start: const TimeOfDay(hour: 14, minute: 0), end: const TimeOfDay(hour: 18, minute: 0)),
      ],
      'tuesday': [
        TimeRange(start: const TimeOfDay(hour: 9, minute: 0), end: const TimeOfDay(hour: 18, minute: 0)),
      ],
      'wednesday': [],
      'thursday': [
        TimeRange(start: const TimeOfDay(hour: 9, minute: 0), end: const TimeOfDay(hour: 18, minute: 0)),
      ],
      'friday': [
        TimeRange(start: const TimeOfDay(hour: 9, minute: 0), end: const TimeOfDay(hour: 20, minute: 0)),
      ],
      'saturday': [
        TimeRange(start: const TimeOfDay(hour: 10, minute: 0), end: const TimeOfDay(hour: 16, minute: 0)),
      ],
      'sunday': [],
    },
  );

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

  Future<void> _abrirFormularioFuncionario({
    Funcionario? funcionario,
    required String empresaId,
  }) async {
    final bool? sucesso = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return FuncionarioFormDialog(
          funcionario: funcionario,
          empresaId: empresaId,
          funcionarioService: _funcionarioService,
        );
      },
    );

    if (!mounted) return;

    if (sucesso == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(funcionario == null
              ? 'Funcionário adicionado com sucesso!'
              : 'Funcionário atualizado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // MÉTODO: Abrir diálogo de Perfil da Empresa (usando seu modelo real)
  void _abrirPerfilEmpresaDialog() async {
    await showDialog(
      context: context,
      builder: (context) => EmpresaProfileFormDialog(
        empresa: _empresaAtual, // Passa os dados da sua Empresa real mockada
        onSave: (updatedEmpresa) {
          setState(() {
            _empresaAtual = updatedEmpresa; // Atualiza os dados locais
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Perfil da empresa salvo com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          // TODO: SEU COLEGA DE BD IRÁ INTEGRAR O SALVAMENTO COM O FIRESTORE AQUI
          // Ex: empresaService.updateEmpresa(_empresaAtual);
        },
      ),
    );
  }

  // MÉTODO: Abrir diálogo de Horário de Funcionamento
  void _abrirHorarioFuncionamentoDialog() async {
    await showDialog(
      context: context,
      builder: (context) => HorarioFuncionamentoFormDialog(
        horariosAtuais: _horariosMock,
        onSave: (updatedHorarios) {
          setState(() {
            _horariosMock = updatedHorarios;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Horário de funcionamento salvo com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          // TODO: SEU COLEGA DE BD IRÁ INTEGRAR O SALVAMENTO COM O FIRESTORE AQUI
          // Ex: empresaService.updateHorarios(_horariosMock);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final authService = Provider.of<AuthService>(context);
    final String? empresaId = authService.empresaAtual?.id;

    if (empresaId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text("Configurações", style: TextStyle(fontWeight: FontWeight.bold)),
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
          _buildTabLoja(context),
          _buildTabEquipe(context, empresaId),
        ],
      ),
    );
  }

  // --- WIDGETS DAS ABAS ---

  Widget _buildTabLoja(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.only(bottom: 24),
          child: SwitchListTile(
            title: Text(
              "Status da Loja",
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurface),
            ),
            subtitle: Text(
                _lojaAberta
                    ? "Sua loja está aberta e recebendo pedidos."
                    : "Sua loja está fechada e não recebe pedidos.",
                style: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
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
        // Seção de Informações Gerais
        _buildSectionTitle(context, "Informações Gerais"),
        const SizedBox(height: 12),
        _buildConfigOption(
          context,
          icon: LucideIcons.building2,
          title: "Perfil da Empresa",
          subtitle: "Edite nome, endereço, logo e dados fiscais.",
          onTap: _abrirPerfilEmpresaDialog, // CHAMA O NOVO DIÁLOGO
        ),
        _buildConfigOption(
          context,
          icon: LucideIcons.clock,
          title: "Horário de Funcionamento",
          subtitle: "Defina os horários de atendimento de cada dia.",
          onTap: _abrirHorarioFuncionamentoDialog, // CHAMA O NOVO DIÁLOGO
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTabEquipe(BuildContext context, String empresaId) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      body: StreamBuilder<List<Funcionario>>(
        stream: _funcionarioService.getFuncionariosByEmpresa(empresaId, incluirInativos: true),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Erro ao carregar equipe: ${snapshot.error}', style: textTheme.bodyLarge?.copyWith(color: cs.error)));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.userX, size: 80, color: cs.onSurfaceVariant.withOpacity(0.4)),
                    const SizedBox(height: 16),
                    Text(
                      'Nenhum funcionário cadastrado ainda.',
                      style: textTheme.titleMedium?.copyWith(color: cs.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Comece adicionando membros à sua equipe!',
                      style: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final funcionarios = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: funcionarios.length,
            itemBuilder: (context, index) {
              final funcionario = funcionarios[index];
              return FuncionarioCard(
                funcionario: funcionario,
                onEdit: () => _abrirFormularioFuncionario(
                    funcionario: funcionario, empresaId: empresaId),
                onStatusChange: () {
                  if (funcionario.ativo) {
                    _funcionarioService.deactivateFuncionario(funcionario.uid);
                  } else {
                    _funcionarioService.activateFuncionario(funcionario.uid);
                  }
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormularioFuncionario(empresaId: empresaId),
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

  // --- WIDGET AUXILIAR: Título de Seção ---
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

  // --- WIDGET AUXILIAR: Opção de Configuração ---
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
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500, color: cs.onSurface),
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
}
*/