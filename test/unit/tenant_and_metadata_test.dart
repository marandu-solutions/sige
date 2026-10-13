import 'package:flutter_test/flutter_test.dart';
import 'package:sige/src/core/core.dart';
import 'package:sige/src/core/utils/tenant_seeds.dart';

void main() {
  group('TenantModel & TenantSeeds - MD02 Verification', () {
    test('EPI Forte tenant seed should configure correct branding and active modules', () {
      final epiMap = TenantSeeds.epiTenant;
      final tenant = TenantModel.fromMap(epiMap);

      expect(tenant.id, equals('tenant_epi_01'));
      expect(tenant.nomeFantasia, equals('EPI Forte Equipamentos'));
      expect(tenant.corPrimaria, equals('#F57C00'));
      expect(tenant.hasModulo('atendimento'), isTrue);
      expect(tenant.hasModulo('estoque'), isTrue);
      expect(tenant.hasModulo('admin_empresa'), isTrue);
      expect(tenant.hasModulo('leads'), isFalse);

      final colunas = tenant.kanbanConfig['colunas'] as List;
      expect(colunas.length, equals(4));
      expect(colunas[0]['titulo'], equals('Novas Mensagens'));
      expect(colunas[1]['titulo'], equals('Em Cotação'));
    });

    test('Solarium Solar tenant seed should configure correct branding and active modules', () {
      final solarMap = TenantSeeds.solarTenant;
      final tenant = TenantModel.fromMap(solarMap);

      expect(tenant.id, equals('tenant_solar_02'));
      expect(tenant.nomeFantasia, equals('Solarium Engenharia Solar'));
      expect(tenant.corPrimaria, equals('#0288D1'));
      expect(tenant.hasModulo('atendimento'), isTrue);
      expect(tenant.hasModulo('leads'), isTrue);
      expect(tenant.hasModulo('admin_empresa'), isTrue);
      expect(tenant.hasModulo('estoque'), isFalse);

      final colunas = tenant.kanbanConfig['colunas'] as List;
      expect(colunas.length, equals(5));
      expect(colunas[0]['titulo'], equals('Lead Recebido'));
      expect(colunas[1]['titulo'], equals('Qualificado (Conta de Luz)'));
    });
  });

  group('Flexible Metadata (EPI & Solar) in Models', () {
    test('LeadModel preserves and parses custom fields for Solar consulting', () {
      final rawMap = {
        'id': 'lead_solar_1',
        'tenant_id': 'tenant_solar_02',
        'nome': 'Carlos Silva',
        'telefone': '11999998888',
        'consumo_kwh': 850,
        'valor_fatura': 920.50,
        'distribuidora': 'Neoenergia',
      };

      final lead = LeadModel.fromMap(rawMap);
      expect(lead.nome, equals('Carlos Silva'));
      expect(lead.metadata['consumo_kwh'], equals(850));
      expect(lead.metadata['distribuidora'], equals('Neoenergia'));

      final serialized = lead.toMap();
      expect(serialized['consumo_kwh'], equals(850));
      expect(serialized['distribuidora'], equals('Neoenergia'));
    });

    test('LeadModel preserves and parses custom fields for EPI commerce', () {
      final rawMap = {
        'id': 'lead_epi_1',
        'tenant_id': 'tenant_epi_01',
        'nome': 'Obra Construtora Alpha',
        'telefone': '11988887777',
        'tamanho_calcado': '42',
        'ca_numero': '12345',
      };

      final lead = LeadModel.fromMap(rawMap);
      expect(lead.nome, equals('Obra Construtora Alpha'));
      expect(lead.getMeta<String>('tamanho_calcado'), equals('42'));
      expect(lead.getMeta<String>('ca_numero'), equals('12345'));
    });
  });
}
