import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:module_atendimento/models/atendimento_model.dart';
import 'package:module_atendimento/services/atendimento_service.dart';
import 'package:intl/intl.dart';

final historyAtendimentoProvider = FutureProvider.family<List<AtendimentoModel>, String>((ref, tenantId) async {
  final service = ref.read(atendimentoServiceProvider);
  // Buscar todos os cards e filtrar os inativos (isAtivo == false) ou arquivados localmente.
  // Note: O service getAllCards já filtra arquivados e inativos, precisamos de um método novo.
  // Criaremos getHistoryCards no service, ou faremos uma query direta aqui por simplicidade.
  // Como é recomendável manter a lógica no service, vou assumir que você implementará getHistoryCards no service.
  // Para agora, vamos fazer a query aqui ou chamar um novo método do service.
  return service.getHistoryCards(tenantId);
});
