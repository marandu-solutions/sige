import 'package:sige/src/core/models/funcionario_model.dart';
import 'package:sige/src/features/atendimento/models/atendimento_model.dart';
import 'package:sige/src/features/atendimento/models/config_atendimento_model.dart';

class AtendenteMetrics {
  final FuncionarioModel funcionario;
  final List<AtendimentoModel> cardsAtivos;
  final int capacidadeMaxima;
  final List<AtendimentoModel> cardsEmVacuo;
  final double pipelineTotalReais;
  final int totalVipCards;
  final double tmrMedioMinutos;

  const AtendenteMetrics({
    required this.funcionario,
    required this.cardsAtivos,
    required this.capacidadeMaxima,
    required this.cardsEmVacuo,
    required this.pipelineTotalReais,
    required this.totalVipCards,
    required this.tmrMedioMinutos,
  });

  int get totalAtivos => cardsAtivos.length;

  double get percentualOcupacao =>
      capacidadeMaxima > 0 ? (totalAtivos / capacidadeMaxima) * 100 : 0.0;

  bool get isSobrecarregado => totalAtivos >= capacidadeMaxima;

  bool get isAtencao =>
      !isSobrecarregado && (totalAtivos >= (capacidadeMaxima * 0.75));

  bool get isDisponivel => !isSobrecarregado && !isAtencao;

  int get excessoCards =>
      isSobrecarregado ? (totalAtivos - capacidadeMaxima) : 0;
}

class TelemetriaGlobalCentral {
  final double tmrMedioMinutos;
  final double ocupacaoGlobalPercentual;
  final int totalSlotsCapacidade;
  final int totalAtendimentosAtivos;
  final int totalClientesEmVacuo;
  final int totalFilaEspera;
  final double pipelineTotalCentralReais;
  final int totalAtendentesOnline;
  final int totalAtendentesSobrecarregados;

  const TelemetriaGlobalCentral({
    required this.tmrMedioMinutos,
    required this.ocupacaoGlobalPercentual,
    required this.totalSlotsCapacidade,
    required this.totalAtendimentosAtivos,
    required this.totalClientesEmVacuo,
    required this.totalFilaEspera,
    required this.pipelineTotalCentralReais,
    required this.totalAtendentesOnline,
    required this.totalAtendentesSobrecarregados,
  });
}

class AtendimentoMetricsHelper {
  static AtendenteMetrics calcularMetricasAtendente({
    required FuncionarioModel funcionario,
    required List<AtendimentoModel> todosCards,
    required ConfigAtendimentoModel config,
    DateTime? now,
  }) {
    final momentoAtual = now ?? DateTime.now();
    final cardsAtivos = todosCards.where((c) {
      return c.funcionarioResponsavelId == funcionario.id &&
          c.status != 'arquivado';
    }).toList();

    final capacidade = config.getCapacidadeParaFuncionario(
      funcionarioId: funcionario.id,
      cargo: funcionario.cargo,
    );

    final limiteVacuo = Duration(minutes: config.slaVacuoAlertaMinutos);
    final cardsEmVacuo = <AtendimentoModel>[];
    double somaMinutosEspera = 0;
    double somaPipeline = 0;
    int vips = 0;

    for (final card in cardsAtivos) {
      somaPipeline += card.valorEstimadoCalculado;
      if (card.isB2BVip) vips++;

      // Checa tempo desde a última interação
      final refTime = card.ultimoFollowUpEm ?? card.ultimaMensagemData ?? card.dataUltimaAtualizacao;
      final diff = momentoAtual.difference(refTime);

      somaMinutosEspera += diff.inMinutes;

      // Se a última mensagem não teve resposta do atendente dentro do SLA de vácuo
      if (diff > limiteVacuo) {
        cardsEmVacuo.add(card);
      }
    }

    final tmrMedio = cardsAtivos.isNotEmpty
        ? (somaMinutosEspera / cardsAtivos.length).clamp(1.0, 180.0)
        : 2.5;

    return AtendenteMetrics(
      funcionario: funcionario,
      cardsAtivos: cardsAtivos,
      capacidadeMaxima: capacidade,
      cardsEmVacuo: cardsEmVacuo,
      pipelineTotalReais: somaPipeline,
      totalVipCards: vips,
      tmrMedioMinutos: tmrMedio,
    );
  }

  static TelemetriaGlobalCentral calcularTelemetriaGlobal({
    required List<FuncionarioModel> atendentes,
    required List<AtendimentoModel> todosCards,
    required ConfigAtendimentoModel config,
  }) {
    int totalSlots = 0;
    int totalAtivos = 0;
    int totalVacuo = 0;
    double somaTmr = 0;
    double pipelineTotal = 0;
    int sobrecarregados = 0;

    for (final f in atendentes) {
      final m = calcularMetricasAtendente(
        funcionario: f,
        todosCards: todosCards,
        config: config,
      );

      totalSlots += m.capacidadeMaxima;
      totalAtivos += m.totalAtivos;
      totalVacuo += m.cardsEmVacuo.length;
      somaTmr += m.tmrMedioMinutos;
      pipelineTotal += m.pipelineTotalReais;
      if (m.isSobrecarregado) sobrecarregados++;
    }

    final filaEspera = todosCards.where((c) {
      return (c.funcionarioResponsavelId == null ||
              c.funcionarioResponsavelId!.isEmpty) &&
          c.status != 'arquivado';
    }).length;

    final ocupacao = totalSlots > 0 ? (totalAtivos / totalSlots) * 100 : 0.0;
    final mediaTmr = atendentes.isNotEmpty ? (somaTmr / atendentes.length) : 3.0;

    return TelemetriaGlobalCentral(
      tmrMedioMinutos: mediaTmr,
      ocupacaoGlobalPercentual: ocupacao,
      totalSlotsCapacidade: totalSlots,
      totalAtendimentosAtivos: totalAtivos,
      totalClientesEmVacuo: totalVacuo,
      totalFilaEspera: filaEspera,
      pipelineTotalCentralReais: pipelineTotal,
      totalAtendentesOnline: atendentes.length,
      totalAtendentesSobrecarregados: sobrecarregados,
    );
  }

  static String formatarMinutosTempo(double minutos) {
    if (minutos < 1) return '< 1 min';
    final m = minutos.floor();
    final s = ((minutos - m) * 60).round();
    if (m >= 60) {
      final h = m ~/ 60;
      final restM = m % 60;
      return '${h}h ${restM}m';
    }
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }
}
