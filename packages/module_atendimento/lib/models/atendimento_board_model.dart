import 'package:module_atendimento/models/atendimento_model.dart';
import 'package:module_atendimento/models/atendimento_column_model.dart';

class AtendimentoBoardModel {
  final List<AtendimentoColumnModel> columns;
  final List<AtendimentoModel> cards;

  AtendimentoBoardModel({required this.columns, required this.cards});

  AtendimentoBoardModel copyWith({
    List<AtendimentoColumnModel>? columns,
    List<AtendimentoModel>? cards,
  }) {
    return AtendimentoBoardModel(
      columns: columns ?? this.columns,
      cards: cards ?? this.cards,
    );
  }
}
