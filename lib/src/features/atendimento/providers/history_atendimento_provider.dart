import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sige/src/features/atendimento/models/atendimento_model.dart';
import 'package:sige/src/features/atendimento/services/atendimento_service.dart';

final historyAtendimentoProvider =
    FutureProvider.family<List<AtendimentoModel>, String>((ref, tenantId) async {
  final service = ref.read(atendimentoServiceProvider);
  return service.getHistoryCards(tenantId);
});
