import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sige/src/core/core.dart';

import 'package:sige/src/features/admin_empresa/src/models/usage_finops_model.dart';
import 'package:sige/src/features/admin_empresa/src/models/whatsapp_number_model.dart';
import 'package:sige/src/features/admin_empresa/src/providers/admin_providers.dart';
import 'package:sige/src/features/admin_empresa/src/providers/tenant_provider.dart';
import 'package:sige/src/features/admin_empresa/src/providers/whatsapp_finops_providers.dart';
import 'package:sige/src/features/admin_empresa/src/screens/admin_dashboard_screen.dart';
import 'package:sige/src/features/admin_empresa/src/screens/components/canais_consumo_ia_tab.dart';
import 'package:sige/src/features/admin_empresa/src/services/whatsapp_meta_service.dart';

class _MockWhatsAppMetaService extends Fake implements WhatsAppMetaService {}

void main() {
  const tenantId = 'tenant_nav_test';

  final sampleTenant = TenantModel(
    id: tenantId,
    nomeFantasia: 'Empresa Teste Navegação',
    documentoFiscal: '12.345.678/0001-90',
    status: 'active',
    modulosAtivos: const ['admin', 'atendimento'],
    config: const {},
  );

  Widget createDashboardHost() {
    return ProviderScope(
      overrides: [
        tenantProvider(tenantId).overrideWith((ref) => Future.value(sampleTenant)),
        funcionariosProvider(tenantId).overrideWith((ref) => Future.value(<FuncionarioModel>[])),
        usageFinopsStreamProvider(tenantId).overrideWith(
          (ref) => Stream.value(
            UsageFinopsModel.zeroState(tenantId: tenantId, competencia: '2026_11'),
          ),
        ),
        whatsappNumbersStreamProvider(tenantId).overrideWith(
          (ref) => Stream.value(<WhatsAppNumberModel>[]),
        ),
        whatsappMetaServiceProvider.overrideWithValue(_MockWhatsAppMetaService()),
      ],
      child: const MaterialApp(
        home: AdminDashboardScreen(tenantId: tenantId),
      ),
    );
  }

  group('AdminDashboardScreen Navigation & Tab Upgrade Tests', () {
    void setDesktopSize(WidgetTester tester) {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    }

    testWidgets('1. TabBar renders exactly 3 tabs with proper titles and icons',
        (tester) async {
      setDesktopSize(tester);
      await tester.pumpWidget(createDashboardHost());
      await tester.pumpAndSettle();

      // Verify TabBar
      final tabBarFinder = find.byType(TabBar);
      expect(tabBarFinder, findsOneWidget);

      final TabBar tabBar = tester.widget(tabBarFinder);
      expect(tabBar.tabs.length, equals(3));

      // Tab 1: Equipe & Acessos
      expect(find.text('Equipe & Acessos'), findsOneWidget);
      expect(
        find.descendant(of: find.byType(TabBar), matching: find.byIcon(LucideIcons.users)),
        findsOneWidget,
      );

      // Tab 2: Operação & Loja
      expect(find.text('Operação & Loja'), findsOneWidget);
      expect(
        find.descendant(of: find.byType(TabBar), matching: find.byIcon(LucideIcons.store)),
        findsOneWidget,
      );

      // Tab 3: Canais & Consumo IA
      expect(find.text('Canais & Consumo IA'), findsOneWidget);
      expect(
        find.descendant(of: find.byType(TabBar), matching: find.byIcon(LucideIcons.messageSquareCode)),
        findsOneWidget,
      );
    });

    testWidgets('2. TabBarView contains 3 children including CanaisConsumoIaTab',
        (tester) async {
      setDesktopSize(tester);
      await tester.pumpWidget(createDashboardHost());
      await tester.pumpAndSettle();

      final tabBarViewFinder = find.byType(TabBarView);
      expect(tabBarViewFinder, findsOneWidget);

      final TabBarView tabBarView = tester.widget(tabBarViewFinder);
      expect(tabBarView.children.length, equals(3));

      // 3rd child is of type CanaisConsumoIaTab
      expect(tabBarView.children[2], isA<CanaisConsumoIaTab>());
      final canaisTab = tabBarView.children[2] as CanaisConsumoIaTab;
      expect(canaisTab.tenantId, equals(tenantId));
    });

    testWidgets('3. Switching to Tab 3 activates and displays CanaisConsumoIaTab content',
        (tester) async {
      setDesktopSize(tester);
      await tester.pumpWidget(createDashboardHost());
      await tester.pumpAndSettle();

      // Tap on Tab 3 "Canais & Consumo IA"
      await tester.tap(find.text('Canais & Consumo IA'));
      await tester.pumpAndSettle();

      // Verifies Canais & Consumo IA content is rendered
      expect(find.text('Competência Contábil FinOps'), findsOneWidget);
      expect(find.text('INVESTIMENTO TOTAL'), findsOneWidget);
      expect(find.text('CONSUMO MOTOR IA'), findsOneWidget);
      expect(find.text('MENSAGERIA META API'), findsOneWidget);
      expect(find.text('SAÚDE DO ORÇAMENTO'), findsOneWidget);
    });

    testWidgets('4. Switching back to Tab 1 preserves Equipe & Acessos view with zero regressions',
        (tester) async {
      setDesktopSize(tester);
      await tester.pumpWidget(createDashboardHost());
      await tester.pumpAndSettle();

      // Switch to Tab 3
      await tester.tap(find.text('Canais & Consumo IA'));
      await tester.pumpAndSettle();

      // Switch back to Tab 1 "Equipe & Acessos"
      await tester.tap(find.text('Equipe & Acessos'));
      await tester.pumpAndSettle();

      expect(find.text('Nenhum colaborador encontrado'), findsOneWidget);
    });
  });
}
