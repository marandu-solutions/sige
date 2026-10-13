import 'package:cloud_firestore/cloud_firestore.dart';

/// Seeds pré-configurados para os dois clientes estratégicos mapeados no MD02:
/// 1. Cliente 1 (EPI Forte Equipamentos - Pago): Comércio, Estoque, Atendimento
/// 2. Cliente 2 (Solarium Engenharia Solar - Negociação): Serviços de Alto Ticket, Leads/CRM Consultivo, Atendimento
class TenantSeeds {
  static final Map<String, dynamic> epiTenant = {
    'tenant_id': 'tenant_epi_01',
    'nome_fantasia': 'EPI Forte Equipamentos',
    'documento_fiscal': '12.345.678/0001-90',
    'segmento': 'comercio',
    'status': 'ativo',
    'branding': {
      'logo_url': 'https://images.unsplash.com/photo-1578575437130-527eed3abbec?w=150',
      'cor_primaria': '#F57C00', // Laranja industrial
    },
    'modulos_ativos': [
      'atendimento',
      'estoque',
      'admin_empresa',
    ],
    'ia_config': {
      'system_prompt':
          'Você é a assistente virtual da EPI Forte. Forneça cotações rápidas de luvas, capacetes, botas e óculos com CA válido.',
      'catalogo_ativo': true,
    },
    'kanban_config': {
      'colunas': [
        {'id': 'c1', 'titulo': 'Novas Mensagens', 'cor': '#3B82F6'},
        {'id': 'c2', 'titulo': 'Em Cotação', 'cor': '#F59E0B'},
        {'id': 'c3', 'titulo': 'Pedido Fechado', 'cor': '#10B981'},
        {'id': 'c4', 'titulo': 'Entregue/Concluído', 'cor': '#6B7280'},
      ],
    },
  };

  static final Map<String, dynamic> solarTenant = {
    'tenant_id': 'tenant_solar_02',
    'nome_fantasia': 'Solarium Engenharia Solar',
    'documento_fiscal': '98.765.432/0001-10',
    'segmento': 'servicos_alto_ticket',
    'status': 'ativo',
    'branding': {
      'logo_url': 'https://images.unsplash.com/photo-1509391365360-2e959784a276?w=150',
      'cor_primaria': '#0288D1', // Azul tecnológico solar
    },
    'modulos_ativos': [
      'atendimento',
      'leads',
      'admin_empresa',
    ],
    'ia_config': {
      'system_prompt':
          'Você é o consultor de energia solar da Solarium. Colete o consumo médio em kWh ou valor da conta e solicite a foto da fatura de energia.',
      'catalogo_ativo': false,
    },
    'kanban_config': {
      'colunas': [
        {'id': 's1', 'titulo': 'Lead Recebido', 'cor': '#3B82F6'},
        {'id': 's2', 'titulo': 'Qualificado (Conta de Luz)', 'cor': '#8B5CF6'},
        {'id': 's3', 'titulo': 'Proposta em Elaboração', 'cor': '#F59E0B'},
        {'id': 's4', 'titulo': 'Financiamento Bancário', 'cor': '#EC4899'},
        {'id': 's5', 'titulo': 'Contrato Assinado', 'cor': '#10B981'},
      ],
    },
  };

  /// Semeia ou atualiza os tenants no Firestore
  static Future<void> seedTenants(FirebaseFirestore firestore) async {
    final batch = firestore.batch();

    // 1. EPI Forte
    final epiRef = firestore.collection('tenant').doc(epiTenant['tenant_id']);
    batch.set(epiRef, epiTenant, SetOptions(merge: true));

    // 2. Solarium
    final solarRef = firestore.collection('tenant').doc(solarTenant['tenant_id']);
    batch.set(solarRef, solarTenant, SetOptions(merge: true));

    await batch.commit();
  }
}
