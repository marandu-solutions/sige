import 'package:module_atendimento/models/atendimento_card_model.dart';
import 'package:module_atendimento/models/atendimento_column_model.dart';

class AtendimentoBoardModel {
  final List<AtendimentoColumnModel> columns;
  final List<AtendimentoCardModel> cards;

  AtendimentoBoardModel({required this.columns, required this.cards});

  AtendimentoBoardModel copyWith({
    List<AtendimentoColumnModel>? columns,
    List<AtendimentoCardModel>? cards,
  }) {
    return AtendimentoBoardModel(
      columns: columns ?? this.columns,
      cards: cards ?? this.cards,
    );
  }
}