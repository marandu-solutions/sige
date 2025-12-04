import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 8,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMetricsGrid(context),
            const SizedBox(height: 32),
            _buildPerformanceChart(context),
            const SizedBox(height: 32),
            _buildRecentActivity(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context) {
    final metrics = [
      {'icon': LucideIcons.dollarSign, 'label': 'Faturamento', 'value': 'R\$ 120.000'},
      {'icon': LucideIcons.users, 'label': 'Clientes', 'value': '1.250'},
      {'icon': LucideIcons.box, 'label': 'Produtos', 'value': '320'},
      {'icon': LucideIcons.shoppingCart, 'label': 'Pedidos', 'value': '980'},
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        final item = metrics[index];
        return Card(
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          color: Theme.of(context).colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                  child: Icon(item['icon'] as IconData, color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(width: 18),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(item['label'] as String, style: Theme.of(context).textTheme.labelLarge),
                    Text(item['value'] as String, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPerformanceChart(BuildContext context) {
    // Placeholder para gráfico. Pode ser substituído por um pacote de gráficos futuramente.
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Desempenho Mensal', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: Center(
                child: Text('Gráfico de desempenho aqui', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    final activities = [
      {'icon': LucideIcons.userPlus, 'desc': 'Novo cliente cadastrado'},
      {'icon': LucideIcons.shoppingBag, 'desc': 'Pedido realizado'},
      {'icon': LucideIcons.box, 'desc': 'Produto adicionado ao estoque'},
      {'icon': LucideIcons.dollarSign, 'desc': 'Pagamento recebido'},
    ];
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Atividades Recentes', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            ...activities.map((item) => ListTile(
              leading: Icon(item['icon'] as IconData, color: Theme.of(context).colorScheme.primary),
              title: Text(item['desc'] as String),
            )),
          ],
        ),
      ),
    );
  }
}
