import 'package:cloud_firestore/cloud_firestore.dart';

class ConfigAtendimentoModel {
  final int capacidadeMaximaPadrao;
  final Map<String, int> capacidadePorNivel;
  final String destinoTransbordo; // 'vendedor_ocioso', 'ia_omnicanal', 'fila_espera'
  final int slaVacuoAlertaMinutos;
  final bool pausasHabilitadas;
  final String mensagemAcolhimentoTransbordo;
  final Map<String, int> capacidadesEspecificas;
  final DateTime? updatedAt;

  const ConfigAtendimentoModel({
    this.capacidadeMaximaPadrao = 8,
    this.capacidadePorNivel = const {
      'junior': 5,
      'pleno': 8,
      'senior': 12,
    },
    this.destinoTransbordo = 'vendedor_ocioso',
    this.slaVacuoAlertaMinutos = 10,
    this.pausasHabilitadas = true,
    this.mensagemAcolhimentoTransbordo =
        'Nossa equipe de consultoria técnica está em atendimento. Já recebi seus dados e em instantes um especialista falará com você!',
    this.capacidadesEspecificas = const {},
    this.updatedAt,
  });

  int getCapacidadeParaFuncionario({
    required String funcionarioId,
    String? cargo,
  }) {
    if (capacidadesEspecificas.containsKey(funcionarioId)) {
      return capacidadesEspecificas[funcionarioId]!;
    }
    final c = (cargo ?? '').toLowerCase();
    if (c.contains('sênior') || c.contains('senior') || c.contains('key account')) {
      return capacidadePorNivel['senior'] ?? 12;
    }
    if (c.contains('júnior') || c.contains('junior') || c.contains('estagiário')) {
      return capacidadePorNivel['junior'] ?? 5;
    }
    return capacidadePorNivel['pleno'] ?? capacidadeMaximaPadrao;
  }

  factory ConfigAtendimentoModel.fromMap(Map<String, dynamic> map) {
    return ConfigAtendimentoModel(
      capacidadeMaximaPadrao: map['capacidadeMaximaPadrao'] as int? ?? 8,
      capacidadePorNivel: map['capacidadePorNivel'] != null
          ? Map<String, int>.from(map['capacidadePorNivel'] as Map)
          : const {'junior': 5, 'pleno': 8, 'senior': 12},
      destinoTransbordo: map['destinoTransbordo'] as String? ?? 'vendedor_ocioso',
      slaVacuoAlertaMinutos: map['slaVacuoAlertaMinutos'] as int? ?? 10,
      pausasHabilitadas: map['pausasHabilitadas'] as bool? ?? true,
      mensagemAcolhimentoTransbordo: map['mensagemAcolhimentoTransbordo'] as String? ??
          'Nossa equipe de consultoria técnica está em atendimento. Já recebi seus dados e em instantes um especialista falará com você!',
      capacidadesEspecificas: map['capacidadesEspecificas'] != null
          ? Map<String, int>.from(map['capacidadesEspecificas'] as Map)
          : const {},
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  factory ConfigAtendimentoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ConfigAtendimentoModel.fromMap(data);
  }

  Map<String, dynamic> toMap() {
    return {
      'capacidadeMaximaPadrao': capacidadeMaximaPadrao,
      'capacidadePorNivel': capacidadePorNivel,
      'destinoTransbordo': destinoTransbordo,
      'slaVacuoAlertaMinutos': slaVacuoAlertaMinutos,
      'pausasHabilitadas': pausasHabilitadas,
      'mensagemAcolhimentoTransbordo': mensagemAcolhimentoTransbordo,
      'capacidadesEspecificas': capacidadesEspecificas,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  ConfigAtendimentoModel copyWith({
    int? capacidadeMaximaPadrao,
    Map<String, int>? capacidadePorNivel,
    String? destinoTransbordo,
    int? slaVacuoAlertaMinutos,
    bool? pausasHabilitadas,
    String? mensagemAcolhimentoTransbordo,
    Map<String, int>? capacidadesEspecificas,
    DateTime? updatedAt,
  }) {
    return ConfigAtendimentoModel(
      capacidadeMaximaPadrao:
          capacidadeMaximaPadrao ?? this.capacidadeMaximaPadrao,
      capacidadePorNivel: capacidadePorNivel ?? this.capacidadePorNivel,
      destinoTransbordo: destinoTransbordo ?? this.destinoTransbordo,
      slaVacuoAlertaMinutos:
          slaVacuoAlertaMinutos ?? this.slaVacuoAlertaMinutos,
      pausasHabilitadas: pausasHabilitadas ?? this.pausasHabilitadas,
      mensagemAcolhimentoTransbordo:
          mensagemAcolhimentoTransbordo ?? this.mensagemAcolhimentoTransbordo,
      capacidadesEspecificas:
          capacidadesEspecificas ?? this.capacidadesEspecificas,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
