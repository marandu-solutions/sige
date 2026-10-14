import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sige/src/core/theme/sige_colors.dart';
import '../models/client_model.dart';
import '../providers/client_provider.dart';
import 'add_client_dialog.dart';

/// Modal Rápido de Atendimento/Kanban para identificar, vincular a empresa B2B
/// ou fundir número telefônico com cliente existente.
class LinkClientDialog extends ConsumerStatefulWidget {
  final String tenantId;
  final String telefone;
  final String? nomeContato;
  final String? leadOrAtendimentoId;
  final void Function(ClientModel client)? onClientLinked;

  const LinkClientDialog({
    super.key,
    required this.tenantId,
    required this.telefone,
    this.nomeContato,
    this.leadOrAtendimentoId,
    this.onClientLinked,
  });

  @override
  ConsumerState<LinkClientDialog> createState() => _LinkClientDialogState();
}

class _LinkClientDialogState extends ConsumerState<LinkClientDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  // Tab 1: Vincular a Empresa B2B
  String? _selectedEmpresaId;
  String? _selectedEmpresaNome;
  final TextEditingController _cargoController =
      TextEditingController(text: 'Comprador');
  final TextEditingController _nomeContatoController = TextEditingController();

  // Tab 2: Fusão de Contato (Adicionar a Cliente Existente)
  ClientModel? _selectedExistingClient;
  final TextEditingController _searchExistingController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _nomeContatoController.text = widget.nomeContato ?? '';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cargoController.dispose();
    _nomeContatoController.dispose();
    _searchExistingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsStreamProvider(widget.tenantId));
    final clients = clientsAsync.valueOrNull ?? [];
    final empresasPj = clients.where((c) => c.isPj).toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 680,
        constraints: const BoxConstraints(maxHeight: 700),
        decoration: BoxDecoration(
          color: SigeColors.darkSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: SigeColors.darkBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            _buildContactContextBar(),
            _buildTabBar(),
            Flexible(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildVincularEmpresaTab(empresasPj),
                  _buildFundirContatoTab(clients),
                ],
              ),
            ),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: SigeColors.darkBorder)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: SigeColors.primaryDefault.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.link_rounded,
              color: SigeColors.primaryDefault,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Identificação & Vínculo de Cliente',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Atribua este número a uma empresa B2B, funda a um cadastro ou crie uma nova conta.',
                  style: TextStyle(
                    color: SigeColors.darkTextSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: Colors.white70),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildContactContextBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SigeColors.darkCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: SigeColors.primaryDefault.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.phone_iphone_rounded,
            color: Color(0xFF25D366),
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            widget.telefone,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          if (widget.nomeContato != null && widget.nomeContato!.isNotEmpty) ...[
            const SizedBox(width: 12),
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: Colors.white38,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Nome Detectado: ${widget.nomeContato}',
                style: const TextStyle(
                  color: SigeColors.darkTextSecondary,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: SigeColors.darkCardBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: SigeColors.primaryDefault,
          borderRadius: BorderRadius.circular(8),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: SigeColors.darkTextSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        tabs: const [
          Tab(
            icon: Icon(Icons.business_rounded, size: 18),
            text: 'Vincular a Empresa (B2B)',
          ),
          Tab(
            icon: Icon(Icons.merge_type_rounded, size: 18),
            text: 'Adicionar a Cliente Existente',
          ),
        ],
      ),
    );
  }

  Widget _buildVincularEmpresaTab(List<ClientModel> empresasPj) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selecione a Empresa Mãe (PJ):',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (empresasPj.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SigeColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: SigeColors.warning.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: SigeColors.warning, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Nenhuma empresa PJ cadastrada ainda. Cadastre uma empresa primeiro.',
                      style: TextStyle(color: SigeColors.warning, fontSize: 12),
                    ),
                  ),
                ],
              ),
            )
          else
            DropdownButtonFormField<String>(
              initialValue: _selectedEmpresaId,
              dropdownColor: SigeColors.darkCardBg,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                filled: true,
                fillColor: SigeColors.darkCardBg,
                hintText: 'Selecione uma empresa PJ cadastrada...',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                prefixIcon: const Icon(Icons.domain_rounded,
                    color: SigeColors.primaryDefault, size: 20),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: SigeColors.darkBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: SigeColors.darkBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: SigeColors.primaryDefault),
                ),
              ),
              items: empresasPj.map((empresa) {
                return DropdownMenuItem<String>(
                  value: empresa.id,
                  child: Text(
                    '${empresa.nome} ${empresa.documento != null ? "(${empresa.documento})" : ""}',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedEmpresaId = val;
                  _selectedEmpresaNome =
                      empresasPj.firstWhere((e) => e.id == val).nome;
                });
              },
            ),
          const SizedBox(height: 16),
          const Text(
            'Nome do Contato / Colaborador:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nomeContatoController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              filled: true,
              fillColor: SigeColors.darkCardBg,
              hintText: 'Ex: Carlos Oliveira',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
              prefixIcon: const Icon(Icons.person_outline_rounded,
                  color: Colors.white54, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: SigeColors.darkBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: SigeColors.darkBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: SigeColors.primaryDefault),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Cargo ou Função na Empresa:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _cargoController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              filled: true,
              fillColor: SigeColors.darkCardBg,
              hintText:
                  'Ex: Comprador, Engenheiro de Segurança, Almoxarife...',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
              prefixIcon: const Icon(Icons.badge_outlined,
                  color: Colors.white54, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: SigeColors.darkBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: SigeColors.darkBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: SigeColors.primaryDefault),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Dica informativa
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SigeColors.info.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: SigeColors.info.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: SigeColors.info, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Ao vincular, este contato aparecerá no organograma da empresa com acesso direto ao histórico de atendimentos e compras.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: (_isLoading || _selectedEmpresaId == null)
                ? null
                : _handleVincularEmpresa,
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check_rounded, size: 18),
            label: const Text('Confirmar Vínculo B2B'),
            style: ElevatedButton.styleFrom(
              backgroundColor: SigeColors.primaryDefault,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFundirContatoTab(List<ClientModel> allClients) {
    final query = _searchExistingController.text.trim().toLowerCase();
    final matchingClients = query.isEmpty
        ? allClients.take(5).toList()
        : allClients.where((c) {
            final matchNome = c.nome.toLowerCase().contains(query);
            final matchDoc = c.documento != null &&
                c.documento!.toLowerCase().contains(query);
            final matchTel = c.telefones.any((t) => t.contains(query));
            return matchNome || matchDoc || matchTel;
          }).take(10).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Buscar Cliente Existente:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _searchExistingController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              filled: true,
              fillColor: SigeColors.darkCardBg,
              hintText: 'Digite nome, CNPJ/CPF ou telefone...',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded,
                  color: Colors.white54, size: 20),
              suffixIcon: _searchExistingController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded,
                          color: Colors.white54),
                      onPressed: () {
                        setState(() {
                          _searchExistingController.clear();
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: SigeColors.darkBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: SigeColors.darkBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: SigeColors.primaryDefault),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Selecione o cliente para adicionar este número:',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              color: SigeColors.darkCardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: SigeColors.darkBorder),
            ),
            child: matchingClients.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'Nenhum cliente encontrado com os termos pesquisados.',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: matchingClients.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: SigeColors.darkBorder, height: 1),
                    itemBuilder: (context, index) {
                      final item = matchingClients[index];
                      final isSelected =
                          _selectedExistingClient?.id == item.id;
                      return ListTile(
                        dense: true,
                        selected: isSelected,
                        selectedTileColor:
                            SigeColors.primaryDefault.withValues(alpha: 0.12),
                        leading: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: item.isPj
                                ? SigeColors.primaryDefault
                                    .withValues(alpha: 0.2)
                                : item.isContatoPj
                                    ? Colors.cyan.withValues(alpha: 0.2)
                                    : SigeColors.success.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item.isPj
                                ? Icons.business_rounded
                                : item.isContatoPj
                                    ? Icons.badge_rounded
                                    : Icons.person_rounded,
                            size: 16,
                            color: item.isPj
                                ? SigeColors.primaryDefault
                                : item.isContatoPj
                                    ? Colors.cyanAccent
                                    : SigeColors.success,
                          ),
                        ),
                        title: Text(
                          item.nome,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          '${item.documento ?? "Sem documento"} • Tel: ${item.telefonePrincipal}',
                          style: const TextStyle(
                            color: SigeColors.darkTextSecondary,
                            fontSize: 11,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded,
                                color: SigeColors.primaryDefault, size: 20)
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedExistingClient = item;
                          });
                        },
                      );
                    },
                  ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: (_isLoading || _selectedExistingClient == null)
                ? null
                : _handleFundirContato,
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.merge_type_rounded, size: 18),
            label: Text(
              _selectedExistingClient == null
                  ? 'Selecione um cliente acima'
                  : 'Fundir Telefone com "${_selectedExistingClient!.nome}"',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: SigeColors.primaryDefault,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: SigeColors.darkBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Ação C: Cadastrar Novo Cliente do Zero
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              showDialog(
                context: context,
                builder: (_) => AddClientDialog(
                  tenantId: widget.tenantId,
                  initialPhone: widget.telefone,
                  initialName: widget.nomeContato,
                ),
              );
            },
            icon: const Icon(Icons.person_add_alt_1_rounded,
                size: 18, color: SigeColors.secondaryDefault),
            label: const Text(
              'Cadastrar Como Novo Cliente Completo',
              style: TextStyle(
                color: SigeColors.secondaryDefault,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar',
                style: TextStyle(color: Colors.white60)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleVincularEmpresa() async {
    if (_selectedEmpresaId == null) return;
    setState(() => _isLoading = true);

    try {
      final service = ref.read(clientServiceProvider);
      final nome = _nomeContatoController.text.trim().isNotEmpty
          ? _nomeContatoController.text.trim()
          : (widget.nomeContato ?? 'Contato B2B');

      // 1. Cria ou atualiza o contato como CONTATO_PJ
      final newContact = ClientModel(
        id: '',
        tenantId: widget.tenantId,
        nome: nome,
        tipo: 'CONTATO_PJ',
        telefones: [widget.telefone],
        telefonePrincipal: widget.telefone,
        empresaId: _selectedEmpresaId,
        empresaNome: _selectedEmpresaNome,
        cargo: _cargoController.text.trim(),
        statusCiclo: 'ATIVO',
        origem: 'WHATSAPP_ATENDIMENTO',
        criadoEm: DateTime.now(),
        atualizadoEm: DateTime.now(),
      );

      final contactId = await service.addClient(widget.tenantId, newContact);
      final finalClient = newContact.copyWith(id: contactId);

      widget.onClientLinked?.call(finalClient);

      if (mounted) {
        Navigator.of(context).pop(finalClient);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: SigeColors.success,
            content: Text(
              'Contato "$nome" vinculado à empresa "$_selectedEmpresaNome" com sucesso!',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: SigeColors.danger,
            content: Text('Erro ao vincular contato: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleFundirContato() async {
    if (_selectedExistingClient == null) return;
    setState(() => _isLoading = true);

    try {
      final service = ref.read(clientServiceProvider);
      await service.adicionarTelefoneACliente(
        tenantId: widget.tenantId,
        clienteId: _selectedExistingClient!.id,
        novoTelefone: widget.telefone,
      );

      final updatedClient = _selectedExistingClient!.copyWith(
        telefones: [..._selectedExistingClient!.telefones, widget.telefone],
      );

      widget.onClientLinked?.call(updatedClient);

      if (mounted) {
        Navigator.of(context).pop(updatedClient);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: SigeColors.success,
            content: Text(
              'Telefone ${widget.telefone} adicionado ao cliente "${_selectedExistingClient!.nome}"!',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: SigeColors.danger,
            content: Text('Erro ao fundir número de telefone: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
