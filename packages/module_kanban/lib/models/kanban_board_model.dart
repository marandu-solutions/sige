import 'package:module_kanban/models/kanban_card_model.dart';
import 'package:module_kanban/models/kanban_column_model.dart';

class KanbanBoardModel {
  final List<KanbanColumnModel> columns;
  final List<KanbanCardModel> cards;

  KanbanBoardModel({required this.columns, required this.cards});

  KanbanBoardModel copyWith({
    List<KanbanColumnModel>? columns,
    List<KanbanCardModel>? cards,
  }) {
    return KanbanBoardModel(
      columns: columns ?? this.columns,
      cards: cards ?? this.cards,
    );
  }
}
