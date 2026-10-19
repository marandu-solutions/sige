import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sige/src/features/atendimento/models/config_atendimento_model.dart';

final configAtendimentoProvider =
    StreamProvider.family<ConfigAtendimentoModel, String>((ref, tenantId) {
  final docRef = FirebaseFirestore.instance
      .collection('tenant')
      .doc(tenantId)
      .collection('configuracoes')
      .doc('atendimento_empresa');

  return docRef.snapshots().map((snapshot) {
    if (!snapshot.exists || snapshot.data() == null) {
      return const ConfigAtendimentoModel();
    }
    return ConfigAtendimentoModel.fromFirestore(snapshot);
  });
});

final configAtendimentoServiceProvider = Provider((ref) => ConfigAtendimentoService());

class ConfigAtendimentoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> salvarConfiguracoes({
    required String tenantId,
    required ConfigAtendimentoModel config,
  }) async {
    final docRef = _firestore
        .collection('tenant')
        .doc(tenantId)
        .collection('configuracoes')
        .doc('atendimento_empresa');

    await docRef.set(config.toMap(), SetOptions(merge: true));
  }
}
