import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/lead_model.dart';
import '../services/leads_service.dart';

final leadsProvider = StreamProvider.family<List<LeadModel>, String>((ref, tenantId) {
  final service = ref.watch(leadsServiceProvider);
  return service.getLeadsStream(tenantId);
});
