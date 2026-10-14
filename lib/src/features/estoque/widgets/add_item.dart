import 'package:flutter/material.dart';
import '../models/stock_item_model.dart';
import 'add_stock_item_dialog.dart';

/// Wrapper de retrocompatibilidade para AddStockItemDialog
class AddEstoqueItemDialog extends StatelessWidget {
  final StockItemModel? item;
  final String tenantId;

  const AddEstoqueItemDialog({
    super.key,
    this.item,
    required this.tenantId,
  });

  @override
  Widget build(BuildContext context) {
    return AddStockItemDialog(
      tenantId: tenantId,
      item: item,
    );
  }
}
