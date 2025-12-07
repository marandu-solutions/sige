// lib/Pages/ConfiguracoesPage/Components/funcionario_form.dart
/*
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Mantido, pois é parte da lógica de criação de usuário
import 'package:siga/Model/funcionario.dart'; // Importando seu modelo Funcionario
import 'package:siga/Service/funcionario_service.dart'; // Mantido

class FuncionarioFormDialog extends StatefulWidget {
  final Funcionario? funcionario; // Se for nulo, é modo "Adicionar". Se não, "Editar".
  final String empresaId; // ID da empresa à qual o funcionário pertence.
  final FuncionarioService funcionarioService;

  const FuncionarioFormDialog({
    super.key,
    this.funcionario,
    required this.empresaId,
    required this.funcionarioService,
  });

  @override
  State<FuncionarioFormDialog> createState() => _FuncionarioFormDialogState();
}

class _FuncionarioFormDialogState extends State<FuncionarioFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _emailController;
  final _senhaController = TextEditingController(); // Apenas para criar novos usuários

  final List<String> _cargosDisponiveis = ['operador', 'gerente', 'admin'];
  String? _selectedCargo;

  bool _isEditMode = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true; // NOVO: Para controlar a visibilidade da senha

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.funcionario != null;

    _nomeController = TextEditingController(text: widget.funcionario?.nome ?? '');
    _emailController = TextEditingController(text: widget.funcionario?.email ?? '');
    _selectedCargo = widget.funcionario?.cargo ?? 'operador'; // Padrão 'operador'
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isEditMode) {
        // --- MODO DE EDIÇÃO ---
        final funcionarioAtualizado = Funcionario(
          uid: widget.funcionario!.uid,
          empresaId: widget.funcionario!.empresaId,
          nome: _nomeController.text.trim(),
          email: widget.funcionario!.email, // E-mail não é editável no modo de edição
          cargo: _selectedCargo!,
          ativo: widget.funcionario!.ativo,
        );
        await widget.funcionarioService.updateFuncionario(funcionarioAtualizado);
      } else {
        // --- MODO DE CRIAÇÃO ---
        // 1. Criar usuário no Firebase Authentication
        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _senhaController.text,
        );

        // 2. Se a criação no Auth deu certo, cria o documento no Firestore
        if (userCredential.user != null) {
          final novoFuncionario = Funcionario(
            uid: userCredential.user!.uid, // Usa o UID do Auth como ID do documento
            empresaId: widget.empresaId,
            nome: _nomeController.text.trim(),
            email: _emailController.text.trim(),
            cargo: _selectedCargo!,
          );
          await widget.funcionarioService.createFuncionario(novoFuncionario);
        }
      }
      // Se chegou aqui, deu tudo certo
      Navigator.of(context).pop(true); // Fecha o diálogo e retorna 'true' para indicar sucesso

    } on FirebaseAuthException catch (e) {
      // Trata erros específicos do Firebase Auth
      if (e.code == 'email-already-in-use') {
        _errorMessage = 'Este e-mail já está em uso por outra conta.';
      } else if (e.code == 'weak-password') {
        _errorMessage = 'A senha fornecida é muito fraca.';
      } else {
        _errorMessage = 'Ocorreu um erro de autenticação. Tente novamente.';
      }
    } catch (e) {
      // Trata outros erros
      _errorMessage = 'Ocorreu um erro inesperado: ${e.toString()}';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Configuração da InputDecoration para campos de formulário, seguindo seu tema
    final InputDecoration customInputDecoration = InputDecoration(
      filled: true,
      fillColor: cs.surfaceContainerHighest.withOpacity(0.7),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.primary, width: 2.0),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      labelStyle: TextStyle(color: cs.onSurfaceVariant),
      hintStyle: TextStyle(color: cs.onSurfaceVariant.withOpacity(0.7)),
    );

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        _isEditMode ? 'Editar Funcionário' : 'Adicionar Funcionário',
        style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: customInputDecoration.copyWith(labelText: 'Nome Completo'),
                validator: (value) =>
                    value!.isEmpty ? 'O nome é obrigatório' : null,
                style: TextStyle(color: cs.onSurface),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: customInputDecoration.copyWith(
                  labelText: 'E-mail',
                  // Cor para campo não editável no modo de edição
                  fillColor: _isEditMode ? cs.surfaceContainerHighest.withOpacity(0.3) : cs.surfaceContainerHighest.withOpacity(0.7),
                ),
                keyboardType: TextInputType.emailAddress,
                readOnly: _isEditMode,
                style: _isEditMode ? TextStyle(color: cs.onSurfaceVariant) : TextStyle(color: cs.onSurface),
                validator: (value) {
                  if (value!.isEmpty) return 'O e-mail é obrigatório';
                  if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                    return 'Por favor, insira um e-mail válido';
                  }
                  return null;
                },
              ),
              // Mostra o campo de senha apenas no modo de criação
              if (!_isEditMode) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _senhaController,
                  decoration: customInputDecoration.copyWith(
                    labelText: 'Senha',
                    suffixIcon: IconButton( // NOVO: Ícone para mostrar/esconder senha
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        color: cs.onSurfaceVariant,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscurePassword, // Controla a obscuridade
                  validator: (value) {
                    if (value!.isEmpty) return 'A senha é obrigatória';
                    if (value.length < 6) {
                      return 'A senha deve ter no mínimo 6 caracteres';
                    }
                    return null;
                  },
                  style: TextStyle(color: cs.onSurface),
                ),
              ],
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCargo,
                decoration: customInputDecoration.copyWith(labelText: 'Cargo'),
                items: _cargosDisponiveis
                    .map((cargo) => DropdownMenuItem(
                          value: cargo,
                          child: Text(
                            cargo[0].toUpperCase() + cargo.substring(1), // Capitaliza a primeira letra
                            style: TextStyle(color: cs.onSurface), // Cor do texto do item
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCargo = value;
                    });
                  }
                },
                validator: (value) =>
                    value == null ? 'Selecione um cargo' : null,
                style: TextStyle(color: cs.onSurface), // Cor do texto selecionado no dropdown
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: theme.colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ]
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text('Cancelar', style: textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submitForm,
          child: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: cs.onPrimary, // Cor do spinner para contraste
                  ),
                )
              : Text(_isEditMode ? 'Salvar Alterações' : 'Adicionar Funcionário', style: textTheme.labelLarge), // Texto dinâmico
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }
}
*/