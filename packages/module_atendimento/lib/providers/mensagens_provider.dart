import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:module_atendimento/models/mensagem_model.dart';
import 'package:module_atendimento/services/atendimento_service.dart';

final mensagensProvider = AsyncNotifierProvider.autoDispose
    .family<MensagensNotifier, List<MensagemModel>, MensagensParams>(() {
  return MensagensNotifier();
});

class MensagensParams {
  final String tenantId;
  final String atendimentoId;

  MensagensParams({required this.tenantId, required this.atendimentoId});
}

class MensagensNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<MensagemModel>, MensagensParams> {
  @override
  FutureOr<List<MensagemModel>> build(MensagensParams params) {
    return _getMensagens(params.tenantId, params.atendimentoId);
  }

  Future<List<MensagemModel>> _getMensagens(String tenantId, String atendimentoId) {
    final atendimentoService = ref.read(atendimentoServiceProvider);
    return atendimentoService.getMensagens(tenantId, atendimentoId);
  }

  Future<void> addMensagem(MensagemModel mensagem) async {
    final atendimentoService = ref.read(atendimentoServiceProvider);

    // Atualiza o estado localmente
    final currentMensagens = state.valueOrNull ?? [];
    final updatedMensagens = [...currentMensagens, mensagem];
    state = AsyncValue.data(updatedMensagens);

    // Atualiza no Firebase em background
    try {
      await atendimentoService.addMensagem(mensagem);
    } catch (e) {
      // Se houver erro, recarrega as mensagens
      state = await AsyncValue.guard(() => _getMensagens(mensagem.tenantId, mensagem.atendimentoId));
    }
  }

  Future<void> marcarComoLidas(String tenantId, String atendimentoId) async {
    final atendimentoService = ref.read(atendimentoServiceProvider);
    await atendimentoService.marcarMensagensComoLidas(tenantId, atendimentoId);
  }
}