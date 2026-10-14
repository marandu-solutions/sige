import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/sige_colors.dart';
import '../models/client_model.dart';
import '../providers/client_provider.dart';
import '../widgets/add_client_dialog.dart';
import '../widgets/client_detail_drawer.dart';
import '../widgets/client_filter_pills.dart';
import '../widgets/client_kpi_header.dart';
import '../widgets/client_rich_card.dart';
import '../widgets/client_table_view.dart';

/// Tela Master de Gestão de Clientes & CRM (B2B & B2C)
/// Implementa as Ondas 1, 2, 3 e 4 do MD05 com Cockpit Executivo,
/// Visão Dual (Cards / Tabela Pro), Ficha 360° e Integração Comercial.
class ClientesScreen extends ConsumerStatefulWidget {
  final String tenantId;

  const ClientesScreen({
    super.key,
    required this.tenantId,
  });

  @override
  ConsumerState<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends ConsumerState<ClientesScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  ClientModel? _selectedClientForDrawer;
  bool _isSeeding = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      ref.read(clientSearchQueryProvider.notifier).state =
          _searchController.text;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openClientDrawer(ClientModel client) {
    setState(() {
      _selectedClientForDrawer = client;
    });
    _scaffoldKey.currentState?.openEndDrawer();
  }

  void _showAddClientDialog({ClientModel? client}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddClientDialog(
        tenantId: widget.tenantId,
        client: client,
      ),
    );
  }

  void _handleQuickContact(ClientModel client) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: SigeColors.primaryDefault,
        content: Text('Iniciando contato com ${client.nome} (${client.telefonePrincipal})...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleSeedDemo() async {
    setState(() => _isSeeding = true);
    try {
      final service = ref.read(clientServiceProvider);
      await service.seedDemoClients(widget.tenantId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: SigeColors.success,
            content: Text('Carteira de clientes demonstrativa carregada com sucesso!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: SigeColors.danger,
            content: Text('Erro ao carregar dados demonstrativos: $e'),
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
    final clientsStream = ref.watch(clientsStreamProvider(widget.tenantId));
    final filteredClients = ref.watch(filteredClientsProvider(widget.tenantId));
    final viewMode = ref.watch(clientViewModeProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? SigeColors.darkBg : SigeColors.lightBg,
      endDrawerEnableOpenDragGesture: false,
      endDrawer: _selectedClientForDrawer != null
          ? Drawer(
              width: 520,
              backgroundColor: SigeColors.darkSurface,
              child: ClientDetailDrawer(
                tenantId: widget.tenantId,
                client: _selectedClientForDrawer!,
                onClose: () => Navigator.of(context).pop(),
                onEdit: () {
                  Navigator.of(context).pop();
                  _showAddClientDialog(client: _selectedClientForDrawer);
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
                    // Top Header com Título e Ações
                    _buildTopHeader(isDark),
                    const SizedBox(height: 16),

                    // Cockpit Executivo com 4 Cards de KPI
                    ClientKpiHeader(tenantId: widget.tenantId),
                    const SizedBox(height: 16),

                    // Barra de Busca
                    _buildSearchRow(isDark),
                    const SizedBox(height: 12),

                    // Pílulas de Foco & Alternador Dual View (Cards / Tabela)
                    ClientFilterPills(tenantId: widget.tenantId),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Conteúdo Principal Reativo
            clientsStream.when(
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Carregando carteira de clientes...',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
              error: (error, stack) => SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 24),
                    constraints: const BoxConstraints(maxWidth: 520),
                    decoration: BoxDecoration(
                      color: isDark ? SigeColors.darkCardBg : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: SigeColors.danger.withValues(alpha: 0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: SigeColors.danger.withValues(alpha: 0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: SigeColors.danger.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.error_outline_rounded,
                              size: 38, color: SigeColors.danger),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Atenção ao carregar carteira',
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : SigeColors.lightTextPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$error',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDark
                                ? SigeColors.darkTextSecondary
                                : SigeColors.lightTextSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton.icon(
                          onPressed: () => ref.invalidate(
                              clientsStreamProvider(widget.tenantId)),
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Tentar Novamente'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: SigeColors.primaryDefault,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              data: (allClients) {
                if (allClients.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyClientsState(isDark),
                  );
                }

                if (filteredClients.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildNoSearchResultsState(isDark),
                  );
                }

                // Visualização em Tabela Pro
                if (viewMode == 'table') {
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                    sliver: SliverToBoxAdapter(
                      child: ClientTableView(
                        clients: filteredClients,
                        onClientTap: _openClientDrawer,
                        onQuickContact: _handleQuickContact,
                      ),
                    ),
                  );
                }

                // Visualização em Grid de Cards Ricos
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                  sliver: SliverLayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.crossAxisExtent;
                      int crossAxisCount = 4;
                      double childAspectRatio = 0.88;

                      if (width < 640) {
                        crossAxisCount = 1;
                        childAspectRatio = 1.25;
                      } else if (width < 1040) {
                        crossAxisCount = 2;
                        childAspectRatio = 0.96;
                      } else if (width < 1440) {
                        crossAxisCount = 3;
                        childAspectRatio = 0.90;
                      }

                      return SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: childAspectRatio,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final client = filteredClients[index];
                            return ClientRichCard(
                              client: client,
                              onTapDetail: () => _openClientDrawer(client),
                              onQuickContact: () => _handleQuickContact(client),
                            );
                          },
                          childCount: filteredClients.length,
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
        final isCompact = constraints.maxWidth < 960;

        final titleBlock = Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    SigeColors.primaryDefault,
                    SigeColors.primaryDefault.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: SigeColors.primaryDefault.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.people_alt_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    runSpacing: 4,
                    children: [
                      Text(
                        'Gestão de Clientes & CRM',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white
                              : SigeColors.lightTextPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color:
                              SigeColors.primaryDefault.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: SigeColors.primaryDefault
                                  .withValues(alpha: 0.3)),
                        ),
                        child: const Text(
                          'B2B & B2C',
                          style: TextStyle(
                            color: SigeColors.primaryDefault,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Ficha 360°, enriquecimento via BrasilAPI, organograma corporativo e rastreabilidade NR-06.',
                    style: TextStyle(
                      color: isDark
                          ? SigeColors.darkTextSecondary
                          : SigeColors.lightTextSecondary,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        );

        final actionButtons = Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: _isSeeding ? null : _handleSeedDemo,
              icon: _isSeeding
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_fix_high_rounded, size: 16),
              label: const Text('Carregar Amostras'),
              style: OutlinedButton.styleFrom(
                foregroundColor:
                    isDark ? Colors.white70 : SigeColors.lightTextPrimary,
                side: BorderSide(
                  color: isDark ? SigeColors.darkBorder : SigeColors.lightBorder,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _showAddClientDialog(),
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
              label: const Text('Novo Cliente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: SigeColors.primaryDefault,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 2,
              ),
            ),
          ],
        );

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleBlock,
              const SizedBox(height: 14),
              actionButtons,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: titleBlock),
            const SizedBox(width: 16),
            actionButtons,
          ],
        );
      },
    );
  }

  Widget _buildSearchRow(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? SigeColors.darkCardBg : SigeColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? SigeColors.darkBorder : SigeColors.lightBorder,
        ),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(
          color: isDark ? Colors.white : SigeColors.lightTextPrimary,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText:
              'Buscar por Razão Social, Fantasia, Nome, CNPJ/CPF, Telefone, Cargo ou E-mail...',
          hintStyle: TextStyle(
            color: isDark ? SigeColors.darkTextSecondary : SigeColors.lightTextSecondary,
            fontSize: 13,
          ),
          prefixIcon: const Icon(Icons.search_rounded,
              color: SigeColors.primaryDefault, size: 22),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildEmptyClientsState(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: SigeColors.primaryDefault.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.people_outline_rounded,
                  size: 40,
                  color: SigeColors.primaryDefault,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Nenhum cliente cadastrado no momento',
                style: TextStyle(
                  color: isDark ? Colors.white : SigeColors.lightTextPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Text(
                  'Comece adicionando seu primeiro cliente corporativo (PJ) com busca automática na Receita Federal via BrasilAPI ou carregue a carteira de demonstração.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? SigeColors.darkTextSecondary : SigeColors.lightTextSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    onPressed: _isSeeding ? null : _handleSeedDemo,
                    icon: _isSeeding
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_fix_high_rounded, size: 16),
                    label: const Text('Carregar Demonstração'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  ElevatedButton.icon(
                    onPressed: () => _showAddClientDialog(),
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                    label: const Text('Cadastrar Primeiro Cliente'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SigeColors.primaryDefault,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off_rounded, size: 54, color: Colors.white30),
              const SizedBox(height: 14),
              Text(
                'Nenhum cliente corresponde aos filtros ativos',
                style: TextStyle(
                  color: isDark ? Colors.white : SigeColors.lightTextPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tente alterar o termo de busca ou resetar as pílulas de segmento.',
                style: TextStyle(
                  color: isDark ? SigeColors.darkTextSecondary : SigeColors.lightTextSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  ref.read(clientFilterSegmentProvider.notifier).state = 'TODOS';
                  ref.read(clientFilterTagProvider.notifier).state = 'TODAS';
                },
                icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                label: const Text('Limpar Filtros e Busca'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
