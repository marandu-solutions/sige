import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sige/src/core/theme/sige_colors.dart';
import '../models/client_model.dart';
import '../models/client_address_model.dart';
import '../providers/client_provider.dart';

/// Modal Dialog para Cadastro e Edição de Clientes com Autocomplete BrasilAPI (CNPJ & CEP)
class AddClientDialog extends ConsumerStatefulWidget {
  final String tenantId;
  final ClientModel? client;
  final String? initialPhone;
  final String? initialName;

  const AddClientDialog({
    super.key,
    required this.tenantId,
    this.client,
    this.initialPhone,
    this.initialName,
  });

  @override
  ConsumerState<AddClientDialog> createState() => _AddClientDialogState();
}

class _AddClientDialogState extends ConsumerState<AddClientDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;

  // Controladores Comuns
  late TextEditingController _nomeController;
  late TextEditingController _documentoController;
  late TextEditingController _telefoneController;
  late TextEditingController _emailController;
  late TextEditingController _tagsController;

  // Controladores PJ
  late TextEditingController _razaoSocialController;
  late TextEditingController _inscricaoEstadualController;
  late TextEditingController _limiteCreditoController;
  String _tabelaPreco = 'PADRAO';

  // Controladores Endereço
  late TextEditingController _cepController;
  late TextEditingController _logradouroController;
  late TextEditingController _numeroController;
  late TextEditingController _complementoController;
  late TextEditingController _bairroController;
  late TextEditingController _cidadeController;
  late TextEditingController _ufController;

  // Controladores Contato B2B
  String? _selectedEmpresaId;
  String? _selectedEmpresaNome;
  late TextEditingController _cargoController;

  bool _isConsultingCnpj = false;
  bool _isConsultingCep = false;

  @override
  void initState() {
    super.initState();
    final c = widget.client;
    int initialTabIndex = 0;
    if (c != null) {
      if (c.isPj) initialTabIndex = 0;
      if (c.isPf) initialTabIndex = 1;
      if (c.isContatoPj) initialTabIndex = 2;
    }
    _tabController = TabController(length: 3, vsync: this, initialIndex: initialTabIndex);

    _nomeController = TextEditingController(text: c?.nome ?? widget.initialName ?? '');
    _documentoController = TextEditingController(text: c?.documento ?? '');
    _telefoneController = TextEditingController(text: c?.telefonePrincipal ?? widget.initialPhone ?? '');
    _emailController = TextEditingController(text: c?.emails.isNotEmpty == true ? c!.emails.first : '');
    _tagsController = TextEditingController(text: c?.tags.join(', ') ?? '');

    _razaoSocialController = TextEditingController(text: c?.razaoSocial ?? '');
    _inscricaoEstadualController = TextEditingController(text: c?.inscricaoEstadual ?? '');
    _limiteCreditoController = TextEditingController(
        text: c?.limiteCredito != null ? c!.limiteCredito.toString() : '');
    _tabelaPreco = c?.tabelaPreco ?? 'PADRAO';

    final end = c?.endereco;
    _cepController = TextEditingController(text: end?.cep ?? '');
    _logradouroController = TextEditingController(text: end?.logradouro ?? '');
    _numeroController = TextEditingController(text: end?.numero ?? '');
    _complementoController = TextEditingController(text: end?.complemento ?? '');
    _bairroController = TextEditingController(text: end?.bairro ?? '');
    _cidadeController = TextEditingController(text: end?.cidade ?? '');
    _ufController = TextEditingController(text: end?.uf ?? '');

    _selectedEmpresaId = c?.empresaId;
    _selectedEmpresaNome = c?.empresaNome;
    _cargoController = TextEditingController(text: c?.cargo ?? '');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nomeController.dispose();
    _documentoController.dispose();
    _telefoneController.dispose();
    _emailController.dispose();
    _tagsController.dispose();
    _razaoSocialController.dispose();
    _inscricaoEstadualController.dispose();
    _limiteCreditoController.dispose();
    _cepController.dispose();
    _logradouroController.dispose();
    _numeroController.dispose();
    _complementoController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    _ufController.dispose();
    _cargoController.dispose();
    super.dispose();
  }

  Future<void> _consultarCnpj() async {
    final cnpj = _documentoController.text.trim();
    if (cnpj.replaceAll(RegExp(r'\D'), '').length != 14) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um CNPJ válido com 14 dígitos')),
      );
      return;
    }

    setState(() => _isConsultingCnpj = true);
    final data = await ref.read(clientServiceProvider).consultarCnpjBrasilApi(cnpj);
    setState(() => _isConsultingCnpj = false);

    if (data != null && mounted) {
      setState(() {
        _razaoSocialController.text = data['razao_social'] as String? ?? '';
        _nomeController.text = data['nome_fantasia'] as String? ?? '';
        if (_telefoneController.text.isEmpty && data['telefone'] != null) {
          _telefoneController.text = data['telefone'] as String;
        }
        if (_emailController.text.isEmpty && data['email'] != null) {
          _emailController.text = data['email'] as String;
        }

        final end = data['endereco'] as ClientAddressModel?;
        if (end != null) {
          _cepController.text = end.cep;
          _logradouroController.text = end.logradouro;
          _numeroController.text = end.numero;
          _complementoController.text = end.complemento ?? '';
          _bairroController.text = end.bairro;
          _cidadeController.text = end.cidade;
          _ufController.text = end.uf;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dados da empresa preenchidos via Receita Federal!'),
          backgroundColor: SigeColors.success,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível obter dados automáticos do CNPJ')),
      );
    }
  }

  Future<void> _consultarCep() async {
    final cep = _cepController.text.trim();
    if (cep.replaceAll(RegExp(r'\D'), '').length != 8) return;

    setState(() => _isConsultingCep = true);
    final end = await ref.read(clientServiceProvider).consultarCepBrasilApi(cep);
    setState(() => _isConsultingCep = false);

    if (end != null && mounted) {
      setState(() {
        _logradouroController.text = end.logradouro;
        _bairroController.text = end.bairro;
        _cidadeController.text = end.cidade;
        _ufController.text = end.uf;
      });
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    String tipo = 'PJ';
    if (_tabController.index == 1) tipo = 'PF';
    if (_tabController.index == 2) tipo = 'CONTATO_PJ';

    List<String> tagsList = [];
    if (_tagsController.text.trim().isNotEmpty) {
      tagsList = _tagsController.text
          .split(',')
          .map((t) => t.trim().toUpperCase())
          .where((t) => t.isNotEmpty)
          .toList();
    }

    ClientAddressModel? address;
    if (_logradouroController.text.trim().isNotEmpty || _cepController.text.trim().isNotEmpty) {
      address = ClientAddressModel(
        cep: _cepController.text.trim(),
        logradouro: _logradouroController.text.trim(),
        numero: _numeroController.text.trim(),
        complemento: _complementoController.text.trim(),
        bairro: _bairroController.text.trim(),
        cidade: _cidadeController.text.trim(),
        uf: _ufController.text.trim().toUpperCase(),
      );
    }

    final double? limite = double.tryParse(_limiteCreditoController.text.replaceAll(',', '.'));
    final telPrincipal = _telefoneController.text.trim();
    final tels = widget.client?.telefones ?? [telPrincipal];
    if (!tels.contains(telPrincipal) && telPrincipal.isNotEmpty) {
      tels.insert(0, telPrincipal);
    }

    final newClient = ClientModel(
      id: widget.client?.id ?? '',
      tenantId: widget.tenantId,
      tipo: tipo,
      nome: _nomeController.text.trim(),
      razaoSocial: tipo == 'PJ' ? _razaoSocialController.text.trim() : null,
      documento: _documentoController.text.replaceAll(RegExp(r'\D'), ''),
      inscricaoEstadual: tipo == 'PJ' ? _inscricaoEstadualController.text.trim() : null,
      telefones: tels,
      telefonePrincipal: telPrincipal,
      emails: _emailController.text.trim().isNotEmpty ? [_emailController.text.trim()] : [],
      empresaId: tipo == 'CONTATO_PJ' ? _selectedEmpresaId : null,
      empresaNome: tipo == 'CONTATO_PJ' ? _selectedEmpresaNome : null,
      cargo: tipo == 'CONTATO_PJ' ? _cargoController.text.trim() : null,
      statusCiclo: widget.client?.statusCiclo ?? 'ATIVO',
      tags: tagsList,
      origem: widget.client?.origem ?? 'WHATSAPP',
      limiteCredito: limite,
      tabelaPreco: _tabelaPreco,
      ltvTotal: widget.client?.ltvTotal ?? 0.0,
      totalAtendimentos: widget.client?.totalAtendimentos ?? 0,
      endereco: address,
      criadoEm: widget.client?.criadoEm ?? DateTime.now(),
      atualizadoEm: DateTime.now(),
    );

    final service = ref.read(clientServiceProvider);
    if (widget.client == null || widget.client!.id.isEmpty) {
      await service.addClient(widget.tenantId, newClient);
    } else {
      await service.updateClient(widget.tenantId, newClient);
    }

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.client == null ? 'Cliente cadastrado com sucesso!' : 'Cliente atualizado!'),
          backgroundColor: SigeColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEdit = widget.client != null;
    final clientsAsync = ref.watch(clientsStreamProvider(widget.tenantId));

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 680,
        constraints: const BoxConstraints(maxHeight: 760),
        decoration: BoxDecoration(
          color: isDark ? SigeColors.darkCardBg : SigeColors.lightCardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? SigeColors.darkBorder : SigeColors.lightBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: BoxDecoration(
                color: isDark ? SigeColors.darkBg : SigeColors.lightBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? SigeColors.darkBorder : SigeColors.lightBorder,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.person_add_alt_1_rounded, color: theme.colorScheme.primary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdit ? 'Editar Cliente' : 'Novo Cliente / Conta B2B',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Cadastre contas corporativas (PJ), contatos vinculados ou consumidores PF',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? SigeColors.darkTextSecondary : SigeColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),

            // Tab Bar
            TabBar(
              controller: _tabController,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: isDark ? SigeColors.darkTextSecondary : SigeColors.lightTextSecondary,
              indicatorColor: theme.colorScheme.primary,
              indicatorWeight: 3,
              tabs: const [
                Tab(icon: Icon(Icons.corporate_fare_rounded, size: 16), text: '1. Empresa (PJ)'),
                Tab(icon: Icon(Icons.person_rounded, size: 16), text: '2. Pessoa Física (PF)'),
                Tab(icon: Icon(Icons.badge_rounded, size: 16), text: '3. Contato B2B Vinculado'),
              ],
            ),

            // Form Content
            Expanded(
              child: Form(
                key: _formKey,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPjTab(isDark),
                    _buildPfTab(isDark),
                    _buildContatoB2bTab(isDark, clientsAsync),
                  ],
                ),
              ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? SigeColors.darkBg : SigeColors.lightBg,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                border: Border(
                  top: BorderSide(
                    color: isDark ? SigeColors.darkBorder : SigeColors.lightBorder,
                  ),
                ),
              ),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text('Cancelar'),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    label: Text(isEdit ? 'Salvar Alterações' : 'Salvar Cadastro'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 1: PESSOA JURÍDICA (PJ) ---
  Widget _buildPjTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Campo CNPJ com botão de consulta BrasilAPI
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: TextFormField(
                  controller: _documentoController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecor(
                    label: 'CNPJ da Empresa *',
                    hint: 'Ex: 12.345.678/0001-90',
                    icon: Icons.business_rounded,
                    isDark: isDark,
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'CNPJ obrigatório para PJ' : null,
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _isConsultingCnpj ? null : _consultarCnpj,
                icon: _isConsultingCnpj
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.search_rounded, size: 16),
                label: const Text('Buscar na Receita'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SigeColors.info,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Nome Fantasia e Razão Social
          TextFormField(
            controller: _nomeController,
            decoration: _inputDecor(
              label: 'Nome Fantasia *',
              hint: 'Ex: Construtora Metrópole',
              icon: Icons.store_rounded,
              isDark: isDark,
            ),
            validator: (v) => v == null || v.trim().isEmpty ? 'Informe o Nome Fantasia' : null,
          ),
          const SizedBox(height: 14),

          TextFormField(
            controller: _razaoSocialController,
            decoration: _inputDecor(
              label: 'Razão Social',
              hint: 'Ex: Construtora Metrópole Obras Ltda',
              icon: Icons.gavel_rounded,
              isDark: isDark,
            ),
          ),
          const SizedBox(height: 14),

          // Telefone e E-mail
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _telefoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecor(
                    label: 'Telefone Principal / WhatsApp *',
                    hint: 'Ex: (11) 3344-5500',
                    icon: Icons.phone_rounded,
                    isDark: isDark,
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Informe o telefone' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecor(
                    label: 'E-mail Comercial',
                    hint: 'compras@empresa.com.br',
                    icon: Icons.email_rounded,
                    isDark: isDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Inscrição Estadual e Limite de Crédito
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _inscricaoEstadualController,
                  decoration: _inputDecor(
                    label: 'Inscrição Estadual',
                    icon: Icons.receipt_long_rounded,
                    isDark: isDark,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _limiteCreditoController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _inputDecor(
                    label: 'Limite de Crédito (R\$)',
                    hint: '0,00',
                    icon: Icons.attach_money_rounded,
                    isDark: isDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          _buildEnderecoSection(isDark),
        ],
      ),
    );
  }

  // --- TAB 2: PESSOA FÍSICA (PF) ---
  Widget _buildPfTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _nomeController,
            decoration: _inputDecor(
              label: 'Nome Completo do Cliente *',
              hint: 'Ex: Dr. Roberto Albuquerque',
              icon: Icons.person_rounded,
              isDark: isDark,
            ),
            validator: (v) => v == null || v.trim().isEmpty ? 'Nome é obrigatório' : null,
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _documentoController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecor(
                    label: 'CPF (opcional)',
                    hint: '000.000.000-00',
                    icon: Icons.badge_rounded,
                    isDark: isDark,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _telefoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecor(
                    label: 'WhatsApp / Telefone *',
                    hint: 'Ex: (11) 98888-7777',
                    icon: Icons.phone_rounded,
                    isDark: isDark,
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Telefone é obrigatório' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: _inputDecor(
              label: 'E-mail do Cliente',
              hint: 'roberto@email.com',
              icon: Icons.email_rounded,
              isDark: isDark,
            ),
          ),
          const SizedBox(height: 14),

          TextFormField(
            controller: _tagsController,
            decoration: _inputDecor(
              label: 'Tags / Segmentos (separadas por vírgula)',
              hint: 'Ex: RECORRENTE, VIP, PROFISSIONAL_LIBERAL',
              icon: Icons.label_important_rounded,
              isDark: isDark,
            ),
          ),
          const SizedBox(height: 18),

          _buildEnderecoSection(isDark),
        ],
      ),
    );
  }

  // --- TAB 3: CONTATO B2B VINCULADO ---
  Widget _buildContatoB2bTab(bool isDark, AsyncValue<List<ClientModel>> clientsAsync) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Colors.purple, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Cadastre um comprador, engenheiro ou almoxarife com seu WhatsApp próprio, vinculado à Empresa Mãe compradora.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // Seletor da Empresa Mãe
          clientsAsync.when(
            data: (clients) {
              final empresas = clients.where((c) => c.isPj).toList();

              return DropdownButtonFormField<String>(
                initialValue: _selectedEmpresaId,
                decoration: _inputDecor(
                  label: 'Empresa Mãe (PJ) *',
                  icon: Icons.corporate_fare_rounded,
                  isDark: isDark,
                ),
                hint: const Text('Selecione a empresa contratante...'),
                items: empresas.map((emp) {
                  return DropdownMenuItem<String>(
                    value: emp.id,
                    child: Text(emp.nome, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedEmpresaId = val;
                    final found = empresas.firstWhere((e) => e.id == val);
                    _selectedEmpresaNome = found.nome;
                  });
                },
                validator: (v) {
                  if (_tabController.index == 2 && (v == null || v.isEmpty)) {
                    return 'Selecione a Empresa Mãe';
                  }
                  return null;
                },
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const Text('Erro ao carregar lista de empresas'),
          ),
          const SizedBox(height: 14),

          // Nome do Colaborador
          TextFormField(
            controller: _nomeController,
            decoration: _inputDecor(
              label: 'Nome do Colaborador / Comprador *',
              hint: 'Ex: Eng. Marcos Vinícius',
              icon: Icons.person_rounded,
              isDark: isDark,
            ),
            validator: (v) => v == null || v.trim().isEmpty ? 'Informe o nome' : null,
          ),
          const SizedBox(height: 14),

          // Cargo e Telefone
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _cargoController,
                  decoration: _inputDecor(
                    label: 'Cargo / Função na Empresa *',
                    hint: 'Ex: Comprador / Mestre de Obra',
                    icon: Icons.work_outline_rounded,
                    isDark: isDark,
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Informe o cargo' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _telefoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecor(
                    label: 'WhatsApp do Colaborador *',
                    hint: 'Ex: (11) 98888-1122',
                    icon: Icons.phone_rounded,
                    isDark: isDark,
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Informe o telefone' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: _inputDecor(
              label: 'E-mail Corporativo do Colaborador',
              hint: 'marcos@metropole.com.br',
              icon: Icons.email_rounded,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnderecoSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Endereço', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: _cepController,
                keyboardType: TextInputType.number,
                decoration: _inputDecor(
                  label: 'CEP',
                  hint: '00000-000',
                  icon: Icons.markunread_mailbox_rounded,
                  isDark: isDark,
                ),
                onChanged: (val) {
                  if (val.replaceAll(RegExp(r'\D'), '').length == 8) {
                    _consultarCep();
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            if (_isConsultingCep)
              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            else
              TextButton(onPressed: _consultarCep, child: const Text('Buscar CEP')),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              flex: 4,
              child: TextFormField(
                controller: _logradouroController,
                decoration: _inputDecor(label: 'Logradouro / Rua', icon: Icons.streetview_rounded, isDark: isDark),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _numeroController,
                decoration: _inputDecor(label: 'Número', icon: Icons.numbers_rounded, isDark: isDark),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _bairroController,
                decoration: _inputDecor(label: 'Bairro', icon: Icons.map_rounded, isDark: isDark),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _cidadeController,
                decoration: _inputDecor(label: 'Cidade', icon: Icons.location_city_rounded, isDark: isDark),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 70,
              child: TextFormField(
                controller: _ufController,
                decoration: _inputDecor(label: 'UF', icon: Icons.flag_rounded, isDark: isDark),
              ),
            ),
          ],
        ),
      ],
    );
  }

  InputDecoration _inputDecor({
    required String label,
    String? hint,
    required IconData icon,
    required bool isDark,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: isDark ? SigeColors.darkBg : SigeColors.lightBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? SigeColors.darkBorder : SigeColors.lightBorder,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? SigeColors.darkBorder : SigeColors.lightBorder,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}
