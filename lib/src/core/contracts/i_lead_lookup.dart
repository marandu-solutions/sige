/// Item resumido de Lead para preenchimento automático no Atendimento
class LeadLookupItem {
  final String id;
  final String nome;
  final String telefone;
  final String? email;
  final String? fotoUrl;
  final Map<String, dynamic> metadata;

  const LeadLookupItem({
    required this.id,
    required this.nome,
    required this.telefone,
    this.email,
    this.fotoUrl,
    this.metadata = const {},
  });
}

/// Contrato desacoplado para busca de Leads
/// Se a empresa contratar o módulo de Leads/CRM, a feature registra essa implementação.
abstract class ILeadLookupProvider {
  Future<List<LeadLookupItem>> searchLeads(String tenantId, String query);
  Future<LeadLookupItem?> getLeadById(String tenantId, String leadId);
}
