import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/sige_colors.dart';
import '../models/stock_item_model.dart';
import '../providers/stock_provider.dart';
import '../widgets/add_stock_item_dialog.dart';
import '../widgets/stock_filter_pills.dart';
import '../widgets/stock_item_detail_drawer.dart';
import '../widgets/stock_item_rich_card.dart';
import '../widgets/stock_kpi_header.dart';
import '../widgets/stock_movement_dialog.dart';
import '../widgets/stock_table_view.dart';

/// Tela Master de Controle de Estoque Inteligente e Homologação de EPIs (NR-06)
/// Implementa as Ondas 1, 2, 3 e 4 do MD04 com Cockpit Executivo, Dual View e Drawer 360°.
class EstoqueScreen extends ConsumerStatefulWidget {
  final String tenantId;

  const EstoqueScreen({
    super.key,
    required this.tenantId,
  });

  @override
  ConsumerState<EstoqueScreen> createState() => _EstoqueScreenState();
}

class _EstoqueScreenState extends ConsumerState<EstoqueScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  StockItemModel? _selectedItemForDrawer;
  bool _isSeeding = false;

  final List<String> _categories = [
    'TODOS',
    'EPIs',
    'Proteção Auditiva',
    'Proteção Respiratória',
    'Proteção Ocular',
    'Mãos e Braços (Luvas)',
    'Pés e Pernas (Calçados)',
    'Visual e Facial',
    'Ferramentas & Insumos',
    'Geral',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      ref.read(stockSearchQueryProvider.notifier).state = _searchController.text;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openItemDrawer(StockItemModel item) {
    setState(() {
      _selectedItemForDrawer = item;
    });
    _scaffoldKey.currentState?.openEndDrawer();
  }

  void _showAddDialog({StockItemModel? item}) {
    showDialog(
      context: context,
      builder: (ctx) => AddStockItemDialog(
        tenantId: widget.tenantId,
        item: item,
      ),
    );
  }

  void _showMovementDialog(StockItemModel item) {
    showDialog(
      context: context,
      builder: (ctx) => StockMovementDialog(
        tenantId: widget.tenantId,
        item: item,
      ),
    );
  }

  Future<void> _handleSeedDemo() async {
    setState(() => _isSeeding = true);
    try {
      await ref.read(stockServiceProvider).seedDemoData(widget.tenantId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Catálogo de EPIs e NR-06 populado com sucesso!'),
            backgroundColor: SigeColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar dados demonstrativos: $e'),
            backgroundColor: SigeColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSeeding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final stockStream = ref.watch(stockStreamProvider(widget.tenantId));
    final filteredItems = ref.watch(filteredStockProvider(widget.tenantId));
    final viewMode = ref.watch(stockViewModeProvider);
    final selectedCategory = ref.watch(stockFilterCategoryProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? SigeColors.darkBg : SigeColors.lightBg,
      endDrawerEnableOpenDragGesture: false,
      endDrawer: _selectedItemForDrawer != null
          ? Drawer(
              width: 500,
              child: StockItemDetailDrawer(
                tenantId: widget.tenantId,
                item: _selectedItemForDrawer!,
                onClose: () => Navigator.of(context).pop(),
                onEditItem: () {
                  Navigator.of(context).pop();
                  _showAddDialog(item: _selectedItemForDrawer);
                },
              ),
            )
          : null,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Top Bar & Cockpit Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Superior com Título e Ações Principais
                    _buildTopHeader(isDark),
                    const SizedBox(height: 16),

                    // Cockpit Executivo de 4 KPIs
                    StockKpiHeader(tenantId: widget.tenantId),
                    const SizedBox(height: 16),

                    // Barra de Busca e Filtros de Categoria
                    _buildSearchAndCategoryRow(isDark, selectedCategory),
                    const SizedBox(height: 12),

                    // Barra de Pílulas de Foco e Alternador de Visão Dual
                    StockFilterPills(tenantId: widget.tenantId),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Conteúdo Principal (Grid de Cards ou Tabela Pro)
            stockStream.when(
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Carregando inventário em tempo real...',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
              error: (error, stack) => SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 48, color: SigeColors.danger),
                      const SizedBox(height: 12),
                      Text(
                        'Erro ao conectar com estoque: $error',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(stockStreamProvider),
                        child: const Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (allItems) {
                if (allItems.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyStockState(isDark),
                  );
                }

                if (filteredItems.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildNoSearchResultsState(isDark),
                  );
                }

                if (viewMode == 'table') {
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                    sliver: SliverToBoxAdapter(
                      child: StockTableView(
                        items: filteredItems,
                        onItemTap: _openItemDrawer,
                        onQuickMovement: _showMovementDialog,
                      ),
                    ),
                  );
                }

                // Grid View Mode
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                  sliver: SliverLayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.crossAxisExtent;
                      int crossAxisCount = 4;
                      double childAspectRatio = 0.85;

                      if (width < 640) {
                        crossAxisCount = 1;
                        childAspectRatio = 1.15;
                      } else if (width < 980) {
                        crossAxisCount = 2;
                        childAspectRatio = 0.95;
                      } else if (width < 1440) {
                        crossAxisCount = 3;
                        childAspectRatio = 0.88;
                      } else {
                        crossAxisCount = 4;
                        childAspectRatio = 0.82;
                      }

                      return SliverGrid(
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: childAspectRatio,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = filteredItems[index];
                            return StockItemRichCard(
                              item: item,
                              onTapDetail: () => _openItemDrawer(item),
                              onQuickMovement: () =>
                                  _showMovementDialog(item),
                            );
                          },
                          childCount: filteredItems.length,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 680;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Estoque Inteligente & EPIs',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: SigeColors.primaryDefault.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: SigeColors.primaryDefault.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Text(
                          'NR-06 COMPLIANT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: SigeColors.primaryDefault,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Controle de inventário, conformidade de CAs, lotes físicos e régua de reposição WhatsApp',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? SigeColors.darkTextSecondary
                          : SigeColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (!isMobile) ...[
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: _isSeeding ? null : _handleSeedDemo,
                icon: _isSeeding
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome_rounded, size: 16),
                label: const Text('Carregar Amostras'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () => _showAddDialog(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Novo Insumo / EPI'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SigeColors.primaryDefault,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSearchAndCategoryRow(bool isDark, String currentCategory) {
    return Row(
      children: [
        // Campo de Pesquisa Textual
        Expanded(
          flex: 4,
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: isDark ? SigeColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? SigeColors.darkBorder : SigeColors.lightBorder,
              ),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText:
                    'Pesquise por nome, SKU, número do CA ou código EAN...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? SigeColors.darkTextMuted
                      : SigeColors.lightTextMuted,
                ),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Filtro Dropdown de Categoria
        Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? SigeColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? SigeColors.darkBorder : SigeColors.lightBorder,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _categories.contains(currentCategory)
                  ? currentCategory
                  : 'TODOS',
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? SigeColors.darkTextPrimary
                    : SigeColors.lightTextPrimary,
              ),
              dropdownColor:
                  isDark ? SigeColors.darkSurface : SigeColors.lightCardBg,
              items: _categories.map((cat) {
                return DropdownMenuItem<String>(
                  value: cat,
                  child: Text(cat == 'TODOS' ? 'Todas as Categorias' : cat),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  ref.read(stockFilterCategoryProvider.notifier).state = val;
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyStockState(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: SigeColors.primaryDefault.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  size: 32,
                  color: SigeColors.primaryDefault,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Nenhum item cadastrado no estoque',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Gerencie insumos, produtos de revenda e EPIs com rastreio de Certificado de Aprovação (CA) e validade NR-06.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? SigeColors.darkTextSecondary
                      : SigeColors.lightTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _isSeeding ? null : _handleSeedDemo,
                    icon: _isSeeding
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome_rounded, size: 16),
                    label: const Text('Carregar Amostras EPI'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddDialog(),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Cadastrar Insumo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SigeColors.primaryDefault,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoSearchResultsState(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_list_off_rounded,
              size: 44,
              color: isDark
                  ? SigeColors.darkTextMuted
                  : SigeColors.lightTextMuted,
            ),
            const SizedBox(height: 14),
            const Text(
              'Nenhum item corresponde aos filtros selecionados',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Tente limpar os termos de busca ou redefinir a pílula de foco ativo.',
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? SigeColors.darkTextSecondary
                    : SigeColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                _searchController.clear();
                ref.read(stockFilterCategoryProvider.notifier).state = 'TODOS';
                ref.read(stockFilterStatusProvider.notifier).state = 'todos';
              },
              icon: const Icon(Icons.restart_alt_rounded, size: 16),
              label: const Text('Redefinir Filtros'),
            ),
          ],
        ),
      ),
    );
  }
}
