import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:module_admin_empresa/src/models/tenant_model.dart';
import 'package:module_admin_empresa/src/services/admin_empresa_service.dart';

final tenantProvider = FutureProvider.family<TenantModel?, String>((ref, tenantId) async {
  final service = ref.watch(adminEmpresaServiceProvider);
  return service.getTenant(tenantId);
});
