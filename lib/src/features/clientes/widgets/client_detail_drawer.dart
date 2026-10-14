import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sige/src/core/theme/sige_colors.dart';
import '../models/client_model.dart';
import '../providers/client_provider.dart';

/// Drawer Lateral 360° do Cliente e Conta Corporativa (Sally UX)
/// Painel com 5 abas de inteligência: Ficha & Fiscal, Organograma B2B, Atendimentos, EPIs e Notas.
class ClientDetailDrawer extends ConsumerStatefulWidget {
  final String tenantId;
  final ClientModel client;
  final VoidCallback onClose;
  final VoidCallback onEdit;

  const ClientDetailDrawer({
    super.key,
    required this.tenantId,
    required this.client,
    required this.onClose,
    required this.onEdit,
  });

  @override
  ConsumerState<ClientDetailDrawer> createState() => _ClientDetailDrawerState();
}

class _ClientDetailDrawerState extends ConsumerState<ClientDetailDrawer>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddPhoneDialog() {
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Adicionar Novo Telefone'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'O número será vinculado à ficha de ${widget.client.nome}. Mensagens futuras recebidas deste número abrirão este cliente automaticamente.',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Telefone / WhatsApp',
                hintText: 'Ex: (11) 98888-7766',
                prefixIcon: Icon(Icons.phone_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final text = phoneController.text.trim();
              if (text.isEmpty) return;

              final nav = Navigator.of(ctx);
              final messenger = ScaffoldMessenger.of(context);

              await ref.read(clientServiceProvider).adicionarTelefoneACliente(
                    tenantId: widget.tenantId,
                    clienteId: widget.client.id,
                    novoTelefone: text,
                  );

              if (mounted) {
                nav.pop();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Novo telefone vinculado com sucesso!'),
                    backgroundColor: SigeColors.success,
                  ),
                );
              }
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormatter =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFormatter = DateFormat('dd/MM/yyyy');

    Color typeColor = theme.colorScheme.primary;
    String typeLabel = 'PESSOA FÍSICA';
    IconData typeIcon = Icons.person_rounded;

    if (widget.client.isPj) {
      typeColor = SigeColors.info;
      typeLabel = 'EMPRESA (PJ)';
      typeIcon = Icons.corporate_fare_rounded;
    } else if (widget.client.isContatoPj) {
      typeColor = Colors.purple;
      typeLabel = 'CONTATO B2B';
      typeIcon = Icons.badge_rounded;
    }

    return Container(
      width: 500,
      decoration: BoxDecoration(
        color: isDark ? SigeColors.darkBg : SigeColors.lightBg,
        border: Border(
          left: BorderSide(
            color: isDark ? SigeColors.darkBorder : SigeColors.lightBorder,
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(-5, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Superior do Drawer
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
            color: isDark ? SigeColors.darkSurface : Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: typeColor.withValues(alpha: 0.12),
                          child: Icon(typeIcon, color: typeColor, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: typeColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                typeLabel,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: typeColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Ficha 360° do Cliente',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          tooltip: 'Editar Cliente',
                          onPressed: widget.onEdit,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          tooltip: 'Fechar',
                          onPressed: widget.onClose,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.client.nome,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.client.isContatoPj && widget.client.empresaNome != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.business_rounded, size: 14, color: Colors.purple),
                      const SizedBox(width: 6),
                      Text(
                        '${widget.client.cargo ?? 'Colaborador'} • ${widget.client.empresaNome}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.purple),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                // Botões de Ação Rápida
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.phone_in_talk_rounded, size: 16),
                        label: const Text('Novo Telefone'),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _showAddPhoneDialog,
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.tune_rounded, size: 16),
                      label: const Text('Editar Dados'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: widget.onEdit,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Abas de Navegação 360°
          Container(
            color: isDark ? SigeColors.darkSurface : Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: isDark
                  ? SigeColors.darkTextSecondary
                  : SigeColors.lightTextSecondary,
              indicatorColor: theme.colorScheme.primary,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(text: 'Ficha & Fiscal'),
                Tab(text: 'Organograma B2B'),
                Tab(text: 'Atendimentos'),
                Tab(text: 'Compras & EPIs'),
                Tab(text: 'Notas & CRM'),
              ],
            ),
          ),

          const Divider(height: 1),

          // Conteúdo das Abas
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAbaFiscal(context, currencyFormatter, dateFormatter),
                _buildAbaOrganograma(context),
                _buildAbaAtendimentos(context, dateFormatter),
                _buildAbaComprasEpis(context, currencyFormatter, dateFormatter),
                _buildAbaNotas(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- ABA 1: FICHA GERAL & DADOS FISCAIS ---
  Widget _buildAbaFiscal(
    BuildContext context,
    NumberFormat currency,
    DateFormat date,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.badge_rounded, 'Identificação & Dados Cadastrais'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? SigeColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? SigeColors.darkBorder : SigeColors.lightBorder,
              ),
            ),
            child: Column(
              children: [
                _buildDetailRow('Nome Fantasia / Principal', widget.client.nome, isBold: true),
                if (widget.client.razaoSocial != null)
                  _buildDetailRow('Razão Social', widget.client.razaoSocial!),
                _buildDetailRow(
                  widget.client.isPj ? 'CNPJ' : 'CPF',
                  widget.client.documentoFormatado,
                  isBold: true,
                ),
                if (widget.client.inscricaoEstadual != null)
                  _buildDetailRow('Inscrição Estadual', widget.client.inscricaoEstadual!),
                _buildDetailRow('Status do Ciclo', widget.client.statusCiclo),
                _buildDetailRow('Origem do Cadastro', widget.client.origem),
              ],
            ),
          ),

          const SizedBox(height: 20),

          _buildSectionHeader(Icons.phone_rounded, 'Contatos & Comunicação'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? SigeColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? SigeColors.darkBorder : SigeColors.lightBorder,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Telefones Vinculados:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 8),
                ...widget.client.telefones.map((t) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 14, color: SigeColors.success),
                          const SizedBox(width: 8),
                          Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    )),
                const Divider(height: 16),
                if (widget.client.emails.isNotEmpty) ...[
                  const Text('E-mails:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 6),
                  ...widget.client.emails.map((e) => Text(e, style: const TextStyle(fontSize: 12))),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          _buildSectionHeader(Icons.location_on_rounded, 'Endereço Fiscal / Entrega'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? SigeColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? SigeColors.darkBorder : SigeColors.lightBorder,
              ),
            ),
            child: Text(
              widget.client.endereco?.formatado ?? 'Nenhum endereço cadastrado.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? SigeColors.darkTextPrimary : SigeColors.lightTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- ABA 2: ORGANOGRAMA & CONTATOS B2B ---
  Widget _buildAbaOrganograma(BuildContext context) {
    final clientsAsync = ref.watch(clientsStreamProvider(widget.tenantId));

    if (!widget.client.isPj && !widget.client.isContatoPj) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Este cliente é uma Pessoa Física autônoma (B2C), sem organograma corporativo associado.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return clientsAsync.when(
      data: (allClients) {
        // Se for PJ, busca todos os CONTATO_PJ cujo empresaId seja este cliente
        final targetEmpresaId = widget.client.isPj ? widget.client.id : widget.client.empresaId;
        final contatos = allClients
            .where((c) => c.isContatoPj && c.empresaId == targetEmpresaId)
            .toList();

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Colaboradores Autorizados (${contatos.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (contatos.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('Nenhum colaborador adicional vinculado a esta empresa.'),
                ),
              )
            else
              ...contatos.map((contato) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? SigeColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? SigeColors.darkBorder : SigeColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.purple,
                        child: Icon(Icons.person, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              contato.nome,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              contato.cargo ?? 'Colaborador',
                              style: const TextStyle(fontSize: 11, color: Colors.purple),
                            ),
                            Text(
                              contato.telefoneFormatado,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? SigeColors.darkTextMuted : SigeColors.lightTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro ao carregar contatos: $e')),
    );
  }

  // --- ABA 3: HISTÓRICO DE ATENDIMENTOS ---
  Widget _buildAbaAtendimentos(BuildContext context, DateFormat date) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.forum_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 14),
            Text(
              '${widget.client.totalAtendimentos} Atendimentos Registrados',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            const Text(
              'As conversas deste cliente no WhatsApp ficam integradas ao Kanban de Atendimento.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // --- ABA 4: HISTÓRICO DE COMPRAS & EPIS NR-06 ---
  Widget _buildAbaComprasEpis(
    BuildContext context,
    NumberFormat currency,
    DateFormat date,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? SigeColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? SigeColors.darkBorder : SigeColors.lightBorder,
              ),
            ),
            child: Column(
              children: [
                _buildDetailRow('Volume Total Faturado (LTV)', currency.format(widget.client.ltvTotal), isBold: true),
                _buildDetailRow('Tabela de Preço Ativa', widget.client.tabelaPreco ?? 'PADRÃO'),
                if (widget.client.limiteCredito != null)
                  _buildDetailRow('Limite de Crédito Aprovado', currency.format(widget.client.limiteCredito!)),
                if (widget.client.ultimaCompraData != null)
                  _buildDetailRow('Última Compra Realizada', date.format(widget.client.ultimaCompraData!)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionHeader(Icons.verified_user_rounded, 'EPIs NR-06 Fornecidos & Rastreio'),
          const SizedBox(height: 10),
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Os registros de entrega de EPIs com validade em uso são monitorados pelo Módulo de Estoque e pela régua de recompra automática no WhatsApp.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- ABA 5: NOTAS INTERNAS & CRM ---
  Widget _buildAbaNotas(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.notes_rounded, 'Observações & Regras da Conta'),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? SigeColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? SigeColors.darkBorder : SigeColors.lightBorder,
              ),
            ),
            child: Text(
              widget.client.observacoesInternas ?? 'Nenhuma observação confidencial registrada.',
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: isDark ? SigeColors.darkTextPrimary : SigeColors.lightTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? SigeColors.darkTextSecondary : SigeColors.lightTextSecondary,
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: isDark ? SigeColors.darkTextPrimary : SigeColors.lightTextPrimary,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
