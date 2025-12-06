/*import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../Model/estoque.dart';
import 'Components/add_item.dart';
import 'Components/estoque_card.dart';


class EstoquePage extends StatefulWidget {
  const EstoquePage({super.key});

  @override
  State<EstoquePage> createState() => _EstoquePageState();
}

class _EstoquePageState extends State<EstoquePage> {
  // ✅ ADICIONADO: Controlador e estado para a busca.
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Dados de exemplo para a UI.
  final List<EstoqueItem> _itensEstoque = [
    EstoqueItem(id: '1', nome: 'Farinha de Trigo', quantidade: 15.5, unidade: 'kg', nivelAlerta: 5.0),
    EstoqueItem(id: '2', nome: 'Queijo Muçarela', quantidade: 3.2, unidade: 'kg', nivelAlerta: 5.0),
    EstoqueItem(id: '3', nome: 'Tomate', quantidade: 20.0, unidade: 'un', nivelAlerta: 10.0),
    EstoqueItem(id: '4', nome: 'Carne Moída', quantidade: 1.8, unidade: 'kg', nivelAlerta: 2.0),
    EstoqueItem(id: '5', nome: 'Refrigerante 2L', quantidade: 30.0, unidade: 'un', nivelAlerta: 12.0),
  ];

  @override
  void initState() {
    super.initState();
    // ✅ ADICIONADO: Listener para atualizar a UI quando o texto de busca mudar.
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Função para abrir o diálogo de adicionar/editar item.
  void _showAddItemDialog({EstoqueItem? item}) {
    showDialog(
      context: context,
      builder: (context) {
        return AddEstoqueItemDialog(
          item: item,
          onSave: (novoItem) {
            setState(() {
              if (item == null) {
                _itensEstoque.add(novoItem);
              } else {
                final index = _itensEstoque.indexWhere((i) => i.id == item.id);
                if (index != -1) {
                  _itensEstoque[index] = novoItem;
                }
              }
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ✅ CORREÇÃO: A lógica de filtro agora é aplicada aqui.
    final List<EstoqueItem> filteredItems = _itensEstoque.where((item) {
      final query = _searchQuery.toLowerCase();
      return item.nome.toLowerCase().contains(query);
    }).toList();

    // A sua excelente lógica de ordenação foi mantida.
    filteredItems.sort((a, b) {
      bool aAlerta = a.quantidade <= a.nivelAlerta;
      bool bAlerta = b.quantidade <= b.nivelAlerta;
      if (aAlerta && !bAlerta) return -1;
      if (!aAlerta && bAlerta) return 1;
      return a.nome.compareTo(b.nome);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text("Controle de Estoque"),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            // Barra de busca
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
              child: TextField(
                // ✅ ADICIONADO: Conectando o controlador ao TextField.
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Pesquisar insumo...',
                  prefixIcon: const Icon(LucideIcons.search),
                ),
              ),
            ),
            // Lista de itens do estoque
            Expanded(
              child: filteredItems.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                padding: const EdgeInsets.only(bottom: 80), // Espaço para o FAB
                itemCount: filteredItems.length,
                itemBuilder: (context, index) {
                  final item = filteredItems[index];
                  return EstoqueCard(
                    item: item,
                    onTap: () => _showAddItemDialog(item: item),
                    onDelete: () {
                      setState(() {
                        _itensEstoque.removeWhere((i) => i.id == item.id);
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddItemDialog(),
        tooltip: 'Adicionar Insumo',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Constrói o widget para o estado vazio.
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.search, color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'Seu estoque está vazio.' : 'Nenhum item encontrado.',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty ? 'Adicione seu primeiro insumo para começar.' : 'Tente uma busca diferente.',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}*/