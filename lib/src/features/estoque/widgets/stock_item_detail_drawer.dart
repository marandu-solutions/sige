import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sige/src/core/theme/sige_colors.dart';
import '../models/stock_item_model.dart';
import '../models/stock_lote_model.dart';
import '../providers/stock_provider.dart';
import 'stock_movement_dialog.dart';

/// Drawer Lateral 360° do Produto (Sally UX)
/// Painel deslizante com abas: Ficha Técnica & CA, Lotes Físicos, Auditoria e Régua CRM.
class StockItemDetailDrawer extends ConsumerStatefulWidget {
  final String tenantId;
  final StockItemModel item;
  final VoidCallback onClose;
  final VoidCallback onEditItem;

  const StockItemDetailDrawer({
    super.key,
    required this.tenantId,
    required this.item,
    required this.onClose,
    required this.onEditItem,
  });

  @override
  ConsumerState<StockItemDetailDrawer> createState() =>
      _StockItemDetailDrawerState();
}

class _StockItemDetailDrawerState extends ConsumerState<StockItemDetailDrawer>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddLoteDialog() {
    final loteCodigoController = TextEditingController();
    final qtdController = TextEditingController();
    final precoController = TextEditingController();
    final fornecedorController = TextEditingController();
    DateTime? dataValidade;
    DateTime? dataFabricacao = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final dateFormatter = DateFormat('dd/MM/yyyy');
          return AlertDialog(
            title: const Text('Cadastrar Novo Lote'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: loteCodigoController,
                    decoration: const InputDecoration(
                      labelText: 'Código do Lote',
                      hintText: 'Ex: LOT-2026-10B',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: qtdController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantidade Inicial',
                      hintText: 'Ex: 100',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: precoController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Preço de Aquisição (R\$)',
                      hintText: 'Ex: 12.50',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: fornecedorController,
                    decoration: const InputDecoration(
                      labelText: 'Fornecedor',
                      hintText: 'Ex: Distribuidora Nacional',
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today_rounded, size: 14),
                          label: Text(
                            dataValidade != null
                                ? 'Val: ${dateFormatter.format(dataValidade!)}'
                                : 'Definir Validade',
                            style: const TextStyle(fontSize: 11),
                          ),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().add(const Duration(days: 365)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2040),
                            );
                            if (picked != null) {
                              setDialogState(() => dataValidade = picked);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () async {
                  if (loteCodigoController.text.trim().isEmpty) return;
                  final qtd = double.tryParse(qtdController.text.replaceAll(',', '.')) ?? 0.0;
                  final preco = double.tryParse(precoController.text.replaceAll(',', '.')) ?? 0.0;

                  final novoLote = StockLoteModel(
                    id: '',
                    tenantId: widget.tenantId,
                    itemId: widget.item.id,
                    loteCodigo: loteCodigoController.text.trim(),
                    dataFabricacao: dataFabricacao,
                    dataValidade: dataValidade,
                    qtdInicial: qtd,
                    qtdAtual: qtd,
                    precoAquisicao: preco,
                    fornecedor: fornecedorController.text.trim(),
                  );

                  final nav = Navigator.of(ctx);
                  final messenger = ScaffoldMessenger.of(context);

                  await ref.read(stockServiceProvider).addLote(
                        widget.tenantId,
                        widget.item.id,
                        novoLote,
                      );

                  if (mounted) {
                    nav.pop();
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Lote adicionado com sucesso!')),
                    );
                  }
                },
                child: const Text('Salvar Lote'),
              ),
            ],
          );
        },
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

    return Container(
      width: 480,
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
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            widget.item.isEpi
                                ? Icons.verified_user_rounded
                                : Icons.inventory_2_rounded,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ficha 360° do Produto',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'SKU: ${widget.item.sku}',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                color: isDark
                                    ? SigeColors.darkTextSecondary
                                    : SigeColors.lightTextSecondary,
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
                          tooltip: 'Editar Produto',
                          onPressed: widget.onEditItem,
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
                  widget.item.nomeProduto,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),
                // Botões de Ação no Topo do Drawer
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.sync_alt_rounded, size: 16),
                        label: const Text('Movimentar'),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => StockMovementDialog(
                              tenantId: widget.tenantId,
                              item: widget.item,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.add_box_rounded, size: 16),
                      label: const Text('Novo Lote'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _showAddLoteDialog,
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
                Tab(text: 'Ficha & CA'),
                Tab(text: 'Lotes Físicos'),
                Tab(text: 'Movimentações'),
                Tab(text: 'Régua CRM WhatsApp'),
              ],
            ),
          ),

          const Divider(height: 1),

          // Conteúdo das Abas
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAbaFichaTecnica(context, currencyFormatter, dateFormatter),
                _buildAbaLotes(context, dateFormatter),
                _buildAbaMovimentacoes(context, dateFormatter),
                _buildAbaReguaCrm(context, dateFormatter),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- ABA 1: FICHA TÉCNICA E CERTIFICADO DE APROVAÇÃO ---
  Widget _buildAbaFichaTecnica(
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
          // Seção de EPI & Conformidade NR-06
          if (widget.item.isEpi) ...[
            _buildSectionHeader(Icons.security_rounded, 'Conformidade Legal (NR-06 / MTE)'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? SigeColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.item.isCaVencido
                      ? SigeColors.danger
                      : (isDark ? SigeColors.darkBorder : SigeColors.lightBorder),
                ),
              ),
              child: Column(
                children: [
                  _buildDetailRow('Certificado de Aprovação (CA)', widget.item.caNumero ?? 'Não informado', isBold: true),
                  _buildDetailRow(
                    'Validade do CA',
                    widget.item.caValidade != null
                        ? date.format(widget.item.caValidade!)
                        : 'Indeterminada',
                    textColor: widget.item.isCaVencido ? SigeColors.danger : SigeColors.success,
                  ),
                  _buildDetailRow('Situação no MTE', widget.item.caSituacao),
                  _buildDetailRow('Vida Útil Recomendada', '${widget.item.diasVidaUtilUso ?? 60} dias em uso'),
                  if (widget.item.tipoProtecao != null)
                    _buildDetailRow('Tipo de Proteção', widget.item.tipoProtecao!),
                  if (widget.item.normasAtendidas.isNotEmpty)
                    _buildDetailRow('Normas Técnicas', widget.item.normasAtendidas.join(', ')),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Seção Financeira e Estoque
          _buildSectionHeader(Icons.monetization_on_rounded, 'Valores e Parâmetros'),
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
                _buildDetailRow('Saldo Atual', '${widget.item.qtdAtual.toInt()} ${widget.item.unidadeMedida}', isBold: true),
                _buildDetailRow('Estoque Mínimo', '${widget.item.estoqueMinimo.toInt()} ${widget.item.unidadeMedida}'),
                _buildDetailRow('Nível de Alerta', '${widget.item.nivelAlerta.toInt()} ${widget.item.unidadeMedida}'),
                _buildDetailRow('Preço de Venda', currency.format(widget.item.precoVenda), isBold: true),
                _buildDetailRow('Preço de Custo', currency.format(widget.item.precoCusto)),
                _buildDetailRow('Localização', widget.item.localizacao ?? 'Geral'),
                _buildDetailRow('Código de Barras / EAN', widget.item.codigoBarrasEan ?? 'Não cadastrado'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- ABA 2: GESTÃO DE LOTES FÍSICOS ---
  Widget _buildAbaLotes(BuildContext context, DateFormat date) {
    final lotesAsync = ref.watch(stockItemLotesProvider((
      tenantId: widget.tenantId,
      itemId: widget.item.id,
    )));

    return lotesAsync.when(
      data: (lotes) {
        if (lotes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.qr_code_scanner_rounded, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                const Text('Nenhum lote específico registrado.'),
                const SizedBox(height: 8),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Cadastrar Primeiro Lote'),
                  onPressed: _showAddLoteDialog,
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: lotes.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final lote = lotes[index];
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? SigeColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: lote.isVencido
                      ? SigeColors.danger
                      : (lote.isPertoVencer
                          ? SigeColors.warning
                          : (isDark ? SigeColors.darkBorder : SigeColors.lightBorder)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        lote.loteCodigo,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: lote.isVencido
                              ? SigeColors.danger.withValues(alpha: 0.15)
                              : SigeColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          lote.status,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: lote.isVencido ? SigeColors.danger : SigeColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Saldo: ${lote.qtdAtual.toInt()} un (Inicial: ${lote.qtdInicial.toInt()})'),
                      if (lote.dataValidade != null)
                        Text(
                          'Val: ${date.format(lote.dataValidade!)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: lote.isVencido
                                ? SigeColors.danger
                                : (lote.isPertoVencer ? SigeColors.warning : null),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro ao carregar lotes: $e')),
    );
  }

  // --- ABA 3: HISTÓRICO DE MOVIMENTAÇÕES ---
  Widget _buildAbaMovimentacoes(BuildContext context, DateFormat date) {
    final movsAsync = ref.watch(stockMovimentacoesProvider(widget.tenantId));

    return movsAsync.when(
      data: (movs) {
        final itemMovs = movs.where((m) => m.itemId == widget.item.id).toList();

        if (itemMovs.isEmpty) {
          return const Center(child: Text('Nenhuma movimentação registrada para este item.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: itemMovs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final mov = itemMovs[index];
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final isEntrada = mov.isEntrada;

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? SigeColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? SigeColors.darkBorder : SigeColors.lightBorder,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (isEntrada ? SigeColors.success : SigeColors.danger)
                          .withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isEntrada ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                      color: isEntrada ? SigeColors.success : SigeColors.danger,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mov.motivo,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          '${date.format(mov.timestamp)} • Saldo: ${mov.saldoAnterior.toInt()} -> ${mov.saldoPosterior.toInt()}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? SigeColors.darkTextMuted : SigeColors.lightTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${isEntrada ? '+' : '-'}${mov.quantidade.toInt()}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isEntrada ? SigeColors.success : SigeColors.danger,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro ao carregar histórico: $e')),
    );
  }

  // --- ABA 4: RÉGUA DE ATENDIMENTO OMNICHANNEL (WHATSAPP) ---
  Widget _buildAbaReguaCrm(BuildContext context, DateFormat date) {
    final entregasAsync = ref.watch(stockEpiEntregasProvider(widget.tenantId));

    return entregasAsync.when(
      data: (entregas) {
        final itemEntregas = entregas.where((e) => e.itemId == widget.item.id).toList();

        if (itemEntregas.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.mark_chat_read_rounded, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text(
                    'Nenhum rastreio ativo para este EPI.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Ao registrar uma Saída/Entrega informando o WhatsApp do cliente, a régua preventiva automática de recompra será ativada.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: itemEntregas.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final entrega = itemEntregas[index];
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? SigeColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: entrega.isUsoVencido
                      ? SigeColors.danger
                      : (entrega.isUsoPertoVencer
                          ? SigeColors.warning
                          : (isDark ? SigeColors.darkBorder : SigeColors.lightBorder)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entrega.clienteNome,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: entrega.isUsoVencido
                              ? SigeColors.danger.withValues(alpha: 0.15)
                              : SigeColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          entrega.isUsoVencido
                              ? 'VENCIDO'
                              : '${entrega.diasRestantes}d restantes',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: entrega.isUsoVencido ? SigeColors.danger : SigeColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'WhatsApp: ${entrega.clienteTelefone} • Qtd: ${entrega.quantidadeEntregue.toInt()} un',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? SigeColors.darkTextSecondary : SigeColors.lightTextSecondary,
                    ),
                  ),
                  Text(
                    'Troca obrigatória prevista: ${date.format(entrega.dataVencimentoUso)}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      FilledButton.tonalIcon(
                        icon: const Icon(Icons.send_rounded, size: 14),
                        label: const Text('Disparar WhatsApp (D-15)'),
                        style: FilledButton.styleFrom(
                          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                        onPressed: () async {
                          final ok = await ref.read(stockServiceProvider).dispararReguaPreventiva(
                                tenantId: widget.tenantId,
                                entrega: entrega,
                                gatilho: 'D-15',
                              );
                          if (ok && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Alerta enviado para o Atendimento / WhatsApp!'),
                                backgroundColor: SigeColors.success,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro ao carregar rastreio CRM: $e')),
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

  Widget _buildDetailRow(String label, String value, {bool isBold = false, Color? textColor}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
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
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: textColor ?? (isDark ? SigeColors.darkTextPrimary : SigeColors.lightTextPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
