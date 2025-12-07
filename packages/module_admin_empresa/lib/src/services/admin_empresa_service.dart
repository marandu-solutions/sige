import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:module_admin_empresa/src/models/funcionario_model.dart';
import 'package:module_admin_empresa/src/models/tenant_model.dart';

final adminEmpresaServiceProvider = Provider<AdminEmpresaService>((ref) {
  return AdminEmpresaService(FirebaseFirestore.instance);
});

class AdminEmpresaService {
  final FirebaseFirestore _firestore;

  AdminEmpresaService(this._firestore);

  // --- Tenant ---

  CollectionReference<TenantModel> _tenantsRef() =>
      _firestore.collection('tenant').withConverter<TenantModel>(
            fromFirestore: (snapshot, _) => TenantModel.fromFirestore(snapshot),
            toFirestore: (tenant, _) => tenant.toMap(),
          );

  Future<TenantModel?> getTenant(String tenantId) async {
    final doc = await _tenantsRef().doc(tenantId).get();
    return doc.data();
  }

  Future<void> updateTenantConfig(
      String tenantId, Map<String, dynamic> config) async {
    await _tenantsRef().doc(tenantId).update({'config': config});
  }

  Future<void> updateHorarioFuncionamento(
      String tenantId, Map<String, dynamic> horario) async {
    // Atualiza o horário dentro da configuração do tenant
    await _firestore.collection('tenant').doc(tenantId).update({
      'config.horario_funcionamento': horario,
    });
  }

  // --- Funcionários ---

  CollectionReference<FuncionarioModel> _funcionariosRef(String tenantId) =>
      _firestore
          .collection('tenant')
          .doc(tenantId)
          .collection('funcionarios')
          .withConverter<FuncionarioModel>(
            fromFirestore: (snapshot, _) =>
                FuncionarioModel.fromFirestore(snapshot),
            toFirestore: (funcionario, _) => funcionario.toMap(),
          );

  Future<List<FuncionarioModel>> getFuncionarios(String tenantId) async {
    final snapshot = await _funcionariosRef(tenantId).get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> addFuncionario(FuncionarioModel funcionario,
      {String senha = '123456'}) async {
    FirebaseApp? secondaryApp;
    try {
      // 1. Criar uma instância secundária do Firebase App para não deslogar o usuário atual
      secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp',
        options: Firebase.app().options,
      );

      // 2. Criar o usuário no Authentication usando a instância secundária
      final auth = FirebaseAuth.instanceFor(app: secondaryApp);
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: funcionario
            .email!, // Assumindo que email é obrigatório para criar auth
        password: senha,
      );

      // 3. Atualizar o nome do usuário
      await userCredential.user?.updateDisplayName(funcionario.nome);

      // 4. Salvar no Firestore usando o UID do Authentication como ID do documento
      final funcionarioComId =
          funcionario.copyWith(id: userCredential.user!.uid);

      await _funcionariosRef(funcionario.tenantId)
          .doc(userCredential.user!.uid)
          .set(funcionarioComId);
    } catch (e) {
      rethrow;
    } finally {
      // 5. Deletar a instância secundária para liberar recursos
      await secondaryApp?.delete();
    }
  }

  Future<void> updateFuncionario(FuncionarioModel funcionario) async {
    await _funcionariosRef(funcionario.tenantId)
        .doc(funcionario.id)
        .set(funcionario);
  }

  Future<void> deleteFuncionario(String tenantId, String funcionarioId) async {
    await _funcionariosRef(tenantId).doc(funcionarioId).delete();
  }
}
