import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sige/src/core/core.dart';

final leadsServiceProvider = Provider<LeadsService>((ref) {
  final service = LeadsService(FirebaseFirestore.instance);
  // Registra o contrato para que o Atendimento possa buscar leads sem acoplamento rígido
  ServiceRegistry().register<ILeadLookupProvider>(service);
  return service;
});

class LeadsService implements ILeadLookupProvider {
  final FirebaseFirestore _firestore;

  LeadsService(this._firestore);

  @override
  Future<List<LeadLookupItem>> searchLeads(String tenantId, String query) async {
    try {
      final queryLower = query.toLowerCase();
      final snapshot = await _firestore
          .collection('tenant')
          .doc(tenantId)
          .collection('leads')
          .limit(20)
          .get();

      return snapshot.docs
          .map((doc) => LeadModel.fromMap(doc.data(), doc.id))
          .where((lead) =>
              lead.nome.toLowerCase().contains(queryLower) ||
              lead.telefone.contains(query))
          .map((lead) => LeadLookupItem(
                id: lead.id,
                nome: lead.nome,
                telefone: lead.telefone,
                email: lead.getMeta<String>('email'),
                fotoUrl: lead.fotoUrl,
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<LeadLookupItem?> getLeadById(String tenantId, String leadId) async {
    try {
      final doc = await _firestore
          .collection('tenant')
          .doc(tenantId)
          .collection('leads')
          .doc(leadId)
          .get();
      if (!doc.exists || doc.data() == null) return null;
      final lead = LeadModel.fromMap(doc.data()!, doc.id);
      return LeadLookupItem(
        id: lead.id,
        nome: lead.nome,
        telefone: lead.telefone,
        email: lead.getMeta<String>('email'),
        fotoUrl: lead.fotoUrl,
      );
    } catch (_) {
      return null;
    }
  }

  CollectionReference<LeadModel> _leadsRef(String tenantId) {
    return _firestore
        .collection('tenant')
        .doc(tenantId)
        .collection('leads')
        .withConverter<LeadModel>(
          fromFirestore: (snapshot, _) =>
              LeadModel.fromMap(snapshot.data()!, snapshot.id),
          toFirestore: (lead, _) => lead.toMap(),
        );
  }

  Stream<List<LeadModel>> getLeadsStream(String tenantId) {
    return _leadsRef(tenantId)
        .orderBy('data_criacao', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<void> addLead(LeadModel lead) async {
    await _leadsRef(lead.tenantId).add(lead);
  }

  Future<void> updateLead(LeadModel lead) async {
    await _leadsRef(lead.tenantId).doc(lead.id).set(lead);
  }

  Future<void> deleteLead(String tenantId, String leadId) async {
    await _leadsRef(tenantId).doc(leadId).delete();
  }
}
