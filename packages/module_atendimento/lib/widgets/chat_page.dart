import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:module_atendimento/models/mensagem_model.dart';
import 'package:module_atendimento/providers/mensagens_provider.dart';
import 'package:module_leads/module_leads.dart';

class ChatPage extends ConsumerStatefulWidget {
  final String tenantId;
  final String atendimentoId;
  final String contactName;
  final String contactPhone;
  final String? leadId;
  final VoidCallback onClose;

  const ChatPage({
    super.key,
    required this.tenantId,
    required this.atendimentoId,
    required this.contactName,
    required this.contactPhone,
    this.leadId,
    required this.onClose,
  });

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mensagensAsync = ref.watch(mensagensProvider(
      MensagensParams(
          tenantId: widget.tenantId, atendimentoId: widget.atendimentoId),
    ));

    // Buscar lead para obter a foto
    final leadsAsync = ref.watch(leadsProvider(widget.tenantId));
    final currentLead = widget.leadId != null
        ? leadsAsync.valueOrNull
            ?.where((l) => l.id == widget.leadId)
            .firstOrNull
        : null;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final headerColor = isDark
        ? const Color(0xFF075E54)
        : const Color(0xFF075E54); // Mantém o verde característico
    final inputBackgroundColor =
        isDark ? const Color(0xFF2C2C2C) : Colors.grey[100];
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Material(
      type: MaterialType.transparency,
      child: Align(
        alignment: Alignment.bottomRight,
        child: Container(
          width: 350,
          height: 600,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              // Header com nome do contato e botão fechar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: headerColor,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white,
                      backgroundImage: currentLead?.fotoUrl != null
                          ? NetworkImage(currentLead!.fotoUrl!)
                          : null,
                      child: currentLead?.fotoUrl == null
                          ? const Icon(Icons.person, color: Color(0xFF075E54))
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.contactName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'online',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: widget.onClose,
                    ),
                  ],
                ),
              ),

              // Lista de mensagens
              Expanded(
                child: mensagensAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) {
                    // Imprime o erro no console para que o link de criação de índice possa ser clicado
                    print('Erro no chat: $error');
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Erro: $error',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                  data: (mensagens) {
                    if (mensagens.isEmpty) {
                      return Center(
                        child: Text(
                          'Nenhuma mensagem ainda',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 14,
                          ),
                        ),
                      );
                    }

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollToBottom();
                    });

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(8),
                      itemCount: mensagens.length,
                      itemBuilder: (context, index) {
                        final mensagem = mensagens[index];
                        return _MessageBubble(
                            mensagem: mensagem, isDark: isDark);
                      },
                    );
                  },
                ),
              ),

              // Campo de entrada de mensagem
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: inputBackgroundColor,
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.attach_file, color: Colors.grey),
                      onPressed: () {
                        // TODO: Implementar envio de anexos
                      },
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Digite uma mensagem...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor:
                              isDark ? const Color(0xFF3D3D3D) : Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          hintStyle: TextStyle(
                            color: hintColor,
                          ),
                        ),
                        style: TextStyle(
                          color: textColor,
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: const Color(0xFF075E54),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;

    final mensagem = MensagemModel(
      id: '',
      tenantId: widget.tenantId,
      atendimentoId: widget.atendimentoId,
      texto: text,
      isUsuario: true, // Mensagem enviada pelo usuário do sistema
      dataEnvio: DateTime.now(),
      status: 'pending_send', // Marca para envio via Cloud Function/N8N
      telefoneDestino: widget.contactPhone,
      remetenteUid: user?.uid,
      remetenteTipo: 'vendedor',
      leadId: widget.leadId,
    );

    ref
        .read(mensagensProvider(
          MensagensParams(
              tenantId: widget.tenantId, atendimentoId: widget.atendimentoId),
        ).notifier)
        .addMensagem(mensagem);

    _messageController.clear();
  }
}

class _MessageBubble extends StatelessWidget {
  final MensagemModel mensagem;
  final bool isDark;

  const _MessageBubble({required this.mensagem, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isUsuario = mensagem.isUsuario;
    final time = DateFormat('HH:mm').format(mensagem.dataEnvio);

    // Cores das bolhas
    final userBubbleColor =
        isDark ? const Color(0xFF056162) : const Color(0xFFDCF8C6);
    final otherBubbleColor = isDark ? const Color(0xFF262D31) : Colors.white;
    final userTextColor = isDark ? Colors.white : Colors.black87;
    final otherTextColor = isDark ? Colors.white : Colors.black;
    final timeColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Align(
      alignment: isUsuario ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isUsuario ? userBubbleColor : otherBubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isUsuario ? const Radius.circular(16) : Radius.zero,
            bottomRight: isUsuario ? Radius.zero : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              mensagem.texto,
              style: TextStyle(
                color: isUsuario ? userTextColor : otherTextColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    color: timeColor,
                    fontSize: 10,
                  ),
                ),
                if (isUsuario) ...[
                  const SizedBox(width: 4),
                  _buildStatusIcon(mensagem.status),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(String status) {
    // 1 check (cinza) quando a msg é registrada no bd
    if (status == 'pending_send') {
      return const Icon(
        Icons.check,
        size: 14,
        color: Colors.grey,
      );
    }
    // 2 checks (cinza), quando enviada para o n8n
    else if (status == 'sent') {
      return const Icon(
        Icons.done_all,
        size: 14,
        color: Colors.grey,
      );
    }
    // icone de erro (circulo com ! dentro) quando houver um erro no envio
    else if (status == 'error') {
      return const Icon(
        Icons.error_outline,
        size: 14,
        color: Colors.red,
      );
    }

    // Default fallback (e.g. unknown status)
    return const SizedBox.shrink();
  }
}
