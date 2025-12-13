import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:core/core.dart';
import 'package:module_leads/src/providers/leads_provider.dart';
import 'package:module_leads/src/providers/leads_filter_provider.dart';
import 'package:module_leads/src/services/leads_service.dart';
import 'package:module_leads/src/widgets/add_edit_lead_dialog.dart';
import 'package:module_leads/src/widgets/leads_filter_widget.dart';

class LeadsScreen extends ConsumerStatefulWidget {
  final String tenantId;

  const LeadsScreen({super.key, required this.tenantId});

  @override
  ConsumerState<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends ConsumerState<LeadsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final leadsAsync = ref.watch(filteredLeadsProvider(widget.tenantId));
    final filter = ref.watch(leadsFilterProvider);
    final theme = Theme.of(context);

    return Scaffold(
      endDrawer: const LeadsFilterWidget(),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildHeader(context, filter),
          Expanded(
            child: leadsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Erro: $error')),
              data: (leads) {
                if (leads.isEmpty) {
                  if (filter.hasFilters) {
                    return _buildEmptyFilterState();
                  }
                  return _buildEmptyState();
                }

                return Theme(
                  data: theme.copyWith(
                    dividerColor: theme.dividerColor,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Card(
                      color: theme.cardColor,
                      elevation: 0,
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: theme.dividerColor),
                      ),
                      child: DataTable2(
                        columnSpacing: 24,
                        horizontalMargin: 24,
                        headingRowHeight: 60,
                        dataRowHeight: 72,
                        minWidth: 800,
                        headingTextStyle: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                        columns: [
                          DataColumn2(label: Text('LEAD'), size: ColumnSize.L),
                          DataColumn2(
                              label: Text('CONTATO'), size: ColumnSize.M),
                          DataColumn2(
                              label: Text('ORIGEM'), size: ColumnSize.S),
                          DataColumn2(
                              label: Text('STATUS'), size: ColumnSize.S),
                          DataColumn2(label: Text('DATA'), size: ColumnSize.S),
                          DataColumn2(label: Text(''), fixedWidth: 100),
                        ],
                        rows: leads
                            .map((lead) => _buildLeadRow(context, lead))
                            .toList(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, LeadsFilter filter) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gestão de Leads',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gerencie e acompanhe seus leads em um só lugar',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _showAddLeadDialog(context),
                icon: const Icon(LucideIcons.plus, size: 18),
                label: const Text('Novo Lead'),
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    ref
                        .read(leadsFilterProvider.notifier)
                        .setSearchQuery(value);
                  },
                  decoration: InputDecoration(
                    hintText: 'Buscar por nome ou telefone...',
                    prefixIcon: Icon(LucideIcons.search,
                        size: 20, color: theme.colorScheme.onSurfaceVariant),
                    filled: true,
                    fillColor: theme.inputDecorationTheme.fillColor ??
                        theme.colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.dividerColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.colorScheme.primary),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Badge(
                isLabelVisible: filter.hasFilters,
                label: const Text('!'),
                smallSize: 8,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Scaffold.of(context).openEndDrawer();
                  },
                  icon: Icon(
                    LucideIcons.filter,
                    size: 18,
                    color: filter.hasFilters
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  label: Text(
                    'Filtros',
                    style: TextStyle(
                      color: filter.hasFilters
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    backgroundColor: filter.hasFilters
                        ? theme.colorScheme.primary.withOpacity(0.05)
                        : theme.colorScheme.surface,
                    side: BorderSide(
                      color: filter.hasFilters
                          ? theme.colorScheme.primary
                          : theme.dividerColor,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  DataRow _buildLeadRow(BuildContext context, LeadModel lead) {
    final theme = Theme.of(context);
    return DataRow(
      cells: [
        DataCell(
          Row(
            children: [
              _buildAvatar(context, lead.nome),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    lead.nome,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  if (lead.observacoes != null && lead.observacoes!.isNotEmpty)
                    SizedBox(
                      width: 150,
                      child: Text(
                        lead.observacoes!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (lead.telefone.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(LucideIcons.phone,
                        size: 12, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(lead.telefone, style: theme.textTheme.bodySmall),
                  ],
                ),
              ],
            ],
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _getSourceIcon(lead.origem),
              const SizedBox(width: 8),
              Text(lead.origem, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(lead.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _getStatusColor(lead.status).withOpacity(0.2),
              ),
            ),
            child: Text(
              lead.status,
              style: TextStyle(
                color: _getStatusColor(lead.status),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        DataCell(
          Text(
            _formatDate(lead.dataCriacao),
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        DataCell(
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: Icon(LucideIcons.edit2,
                    size: 18, color: theme.colorScheme.onSurfaceVariant),
                onPressed: () => _showEditLeadDialog(context, lead),
                tooltip: 'Editar',
              ),
              IconButton(
                icon: Icon(LucideIcons.trash2,
                    size: 18, color: theme.colorScheme.error),
                onPressed: () => _confirmDelete(context, lead),
                tooltip: 'Excluir',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.users,
                size: 48, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 24),
          Text(
            'Nenhum lead cadastrado',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Adicione seu primeiro lead para começar a gerenciar',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _showAddLeadDialog(context),
            icon: const Icon(LucideIcons.plus),
            label: const Text('Adicionar Lead'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFilterState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.searchX,
              size: 64, color: theme.colorScheme.outline.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'Nenhum resultado encontrado',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tente ajustar seus filtros de busca',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () {
              ref.read(leadsFilterProvider.notifier).clearFilters();
              _searchController.clear();
            },
            child: const Text('Limpar Filtros'),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, String name) {
    final theme = Theme.of(context);
    final initials = name.isNotEmpty
        ? name
            .trim()
            .split(' ')
            .take(2)
            .map((e) => e.isNotEmpty ? e[0] : '')
            .join()
            .toUpperCase()
        : '?';

    // Generate a consistent color based on the name
    final color = Colors.primaries[name.hashCode % Colors.primaries.length];

    return CircleAvatar(
      radius: 18,
      backgroundColor: color.withOpacity(0.1),
      child: Text(
        initials,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _getSourceIcon(String source) {
    IconData icon;
    Color color;

    switch (source.toLowerCase()) {
      case 'facebook':
        icon = LucideIcons.facebook;
        color = const Color(0xFF1877F2);
        break;
      case 'instagram':
        icon = LucideIcons.instagram;
        color = const Color(0xFFE4405F);
        break;
      case 'whatsapp':
        icon =
            LucideIcons.messageCircle; // Lucide doesn't have whatsapp usually
        color = const Color(0xFF25D366);
        break;
      case 'site':
        icon = LucideIcons.globe;
        color = Colors.blueGrey;
        break;
      case 'indicação':
        icon = LucideIcons.userPlus;
        color = Colors.orange;
        break;
      default:
        icon = LucideIcons.link;
        color = Colors.grey;
    }

    return Icon(icon, size: 16, color: color);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Novo':
        return Colors.blue;
      case 'Em Andamento':
        return Colors.orange;
      case 'Convertido':
        return Colors.green;
      case 'Perdido':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _showAddLeadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddEditLeadDialog(
        tenantId: widget.tenantId,
        onSave: (lead) {
          ref.read(leadsServiceProvider).addLead(lead);
        },
      ),
    );
  }

  void _showEditLeadDialog(BuildContext context, LeadModel lead) {
    showDialog(
      context: context,
      builder: (context) => AddEditLeadDialog(
        tenantId: widget.tenantId,
        lead: lead,
        onSave: (updatedLead) {
          ref.read(leadsServiceProvider).updateLead(updatedLead);
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, LeadModel lead) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Lead'),
        content: Text('Tem certeza que deseja excluir "${lead.nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(leadsServiceProvider).deleteLead(lead.tenantId, lead.id);
              Navigator.of(context).pop();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}
