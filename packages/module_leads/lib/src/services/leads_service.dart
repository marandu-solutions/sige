import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/core.dart';

final leadsServiceProvider = Provider<LeadsService>((ref) {
  return LeadsService(FirebaseFirestore.instance);
});

class LeadsService {
  final FirebaseFirestore _firestore;

  LeadsService(this._firestore);

  CollectionReference<LeadModel> _leadsRef(String tenantId) {
    return _firestore
        .collection('tenant')
        .doc(tenantId)
        .collection('leads')
        .withConverter<LeadModel>(
          fromFirestore: (snapshot, _) => LeadModel.fromFirestore(snapshot),
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
