import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/core.dart';
import 'package:module_admin_empresa/src/services/admin_empresa_service.dart';

final funcionariosProvider =
    FutureProvider.family<List<FuncionarioModel>, String>((ref, tenantId) async {
  final service = ref.watch(adminEmpresaServiceProvider);
  return service.getFuncionarios(tenantId);
});
