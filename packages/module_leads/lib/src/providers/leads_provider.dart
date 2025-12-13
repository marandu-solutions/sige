import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/core.dart';
import '../services/leads_service.dart';

final leadsProvider =
    StreamProvider.autoDispose.family<List<LeadModel>, String>((ref, tenantId) {
  final service = ref.watch(leadsServiceProvider);
  return service.getLeadsStream(tenantId);
});
