import 'package:flutter/material.dart';
import 'package:sige/src/features/clientes/screens/clientes_screen.dart';

/// LeadsScreen (Legado / Retrocompatibilidade)
/// Redireciona de forma transparente para a nova suíte de Clientes (MD05).
class LeadsScreen extends StatelessWidget {
  final String tenantId;

  const LeadsScreen({super.key, required this.tenantId});

  @override
  Widget build(BuildContext context) {
    return ClientesScreen(tenantId: tenantId);
  }
}
