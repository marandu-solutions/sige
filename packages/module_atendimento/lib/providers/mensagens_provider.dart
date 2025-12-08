import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:module_atendimento/models/mensagem_model.dart';
import 'package:module_atendimento/services/atendimento_service.dart';

final mensagensProvider = StreamNotifierProvider.autoDispose
    .family<MensagensNotifier, List<MensagemModel>, MensagensParams>(() {
  return MensagensNotifier();
});

class MensagensParams {
  final String tenantId;
  final String atendimentoId;

  MensagensParams({required this.tenantId, required this.atendimentoId});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MensagensParams &&
        other.tenantId == tenantId &&
        other.atendimentoId == atendimentoId;
  }

  @override
  int get hashCode => tenantId.hashCode ^ atendimentoId.hashCode;
}

class MensagensNotifier
    extends AutoDisposeFamilyStreamNotifier<List<MensagemModel>, MensagensParams> {
  @override
  Stream<List<MensagemModel>> build(MensagensParams params) {
    final atendimentoService = ref.read(atendimentoServiceProvider);
    return atendimentoService.getMensagensStream(params.tenantId, params.atendimentoId);
  }

  Future<void> addMensagem(MensagemModel mensagem) async {
    final atendimentoService = ref.read(atendimentoServiceProvider);

    // Com Stream, não precisamos atualizar o estado local manualmente para a maioria dos casos,
    // pois o Firestore SDK tem "latency compensation" e vai emitir um novo evento no stream
    // quase imediatamente com o dado local.
    try {
      await atendimentoService.addMensagem(mensagem);
    } catch (e) {
      print('Erro ao enviar mensagem: $e');
      // Opcional: Tratar erro de envio na UI
    }
  }

  Future<void> marcarComoLidas(String tenantId, String atendimentoId) async {
    final atendimentoService = ref.read(atendimentoServiceProvider);
    await atendimentoService.marcarMensagensComoLidas(tenantId, atendimentoId);
  }
}