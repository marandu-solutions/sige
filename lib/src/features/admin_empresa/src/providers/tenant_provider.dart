import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sige/src/core/core.dart';
import 'package:sige/src/features/admin_empresa/src/services/admin_empresa_service.dart';

final tenantProvider =
    FutureProvider.family<TenantModel?, String>((ref, tenantId) async {
  final service = ref.watch(adminEmpresaServiceProvider);
  return service.getTenant(tenantId);
});
