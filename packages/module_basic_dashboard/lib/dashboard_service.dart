import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dashboard_model.dart';

final dashboardServiceProvider = FutureProvider<DashboardModel>((ref) async {
  final service = DashboardService();
  return await service.getDashboardData();
});

class DashboardService {
  Future<DashboardModel> getDashboardData() async {
    // Simula uma chamada de API com um atraso
    await Future.delayed(const Duration(seconds: 1));

    // Dados mockados que seriam retornados pela API
    final metrics = [
      DashboardMetrics(icon: LucideIcons.dollarSign, label: 'Faturamento', value: '120.000'),
      DashboardMetrics(icon: LucideIcons.users, label: 'Clientes', value: '1.250'),
      DashboardMetrics(icon: LucideIcons.box, label: 'Produtos', value: '320'),
      DashboardMetrics(icon: LucideIcons.shoppingCart, label: 'Pedidos', value: '980'),
    ];

    final activities = [
      RecentActivity(icon: LucideIcons.userPlus, description: 'Novo cliente cadastrado'),
      RecentActivity(icon: LucideIcons.shoppingBag, description: 'Pedido realizado'),
      RecentActivity(icon: LucideIcons.box, description: 'Produto adicionado ao estoque'),
      RecentActivity(icon: LucideIcons.dollarSign, description: 'Pagamento recebido'),
    ];

    return DashboardModel(metrics: metrics, activities: activities);
  }
}
