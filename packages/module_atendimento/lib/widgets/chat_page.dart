import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    
    // Lógica para encontrar o Lead atual
    final currentLead = widget.leadId != null
        ? leadsAsync.valueOrNull
            ?.where((l) => l.id == widget.leadId)
            .firstOrNull
        : null;

    // --- DEBUG LOGS (Verifique seu console) ---
    if (widget.leadId != null) {
       print('--- DEBUG AVATAR ---');
       print('Procurando Lead ID: ${widget.leadId}');
       print('Status leadsAsync: ${leadsAsync.isLoading ? "Carregando" : "Carregado"}');
       print('Lead Encontrado? ${currentLead != null ? "SIM" : "NÃO"}');
       if (currentLead != null) {
         print('URL da Foto no Lead: "${currentLead.fotoUrl}"');
       }
       print('--------------------');
    }
    // ------------------------------------------

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final headerColor = isDark ? const Color(0xFF075E54) : const Color(0xFF075E54);
    final inputBackgroundColor = isDark ? const Color(0xFF2C2C2C) : Colors.grey[100];
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
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: headerColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    // AQUI ESTÁ O WIDGET DO AVATAR
                    _LeadAvatar(fotoUrl: currentLead?.fotoUrl),
                    
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
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) {
                    print('Erro no chat: $error');
                    return Center(child: Text('Erro: $error'));
                  },
                  data: (mensagens) {
                    if (mensagens.isEmpty) {
                      return Center(
                        child: Text(
                          'Nenhuma mensagem ainda',
                          style: TextStyle(color: textColor, fontSize: 14),
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
                        return _MessageBubble(mensagem: mensagem, isDark: isDark);
                      },
                    );
                  },
                ),
              ),

              // Campo de input
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: inputBackgroundColor,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.attach_file, color: Colors.grey),
                      onPressed: () {},
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
                          fillColor: isDark ? const Color(0xFF3D3D3D) : Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          hintStyle: TextStyle(color: hintColor),
                        ),
                        style: TextStyle(color: textColor),
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
      isUsuario: true,
      dataEnvio: DateTime.now(),
      status: 'pending_send',
      telefoneDestino: widget.contactPhone,
      remetenteUid: user?.uid,
      remetenteTipo: 'vendedor',
      leadId: widget.leadId,
    );

    ref.read(mensagensProvider(
      MensagensParams(tenantId: widget.tenantId, atendimentoId: widget.atendimentoId),
    ).notifier).addMensagem(mensagem);

    _messageController.clear();
  }
}

// ---------------------------------------------
// CLASSE LEAD AVATAR CORRIGIDA
// ---------------------------------------------
class _LeadAvatar extends StatefulWidget {
  final String? fotoUrl;

  const _LeadAvatar({this.fotoUrl});

  @override
  State<_LeadAvatar> createState() => _LeadAvatarState();
}

class _LeadAvatarState extends State<_LeadAvatar> {
  String? _downloadUrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _checkAndLoad();
  }

  @override
  void didUpdateWidget(covariant _LeadAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fotoUrl != widget.fotoUrl) {
      _checkAndLoad();
    }
  }

  Future<void> _checkAndLoad() async {
    final url = widget.fotoUrl;

    // Se nulo ou vazio, reseta
    if (url == null || url.isEmpty) {
      if (mounted) setState(() => _downloadUrl = null);
      return;
    }

    // Se já for HTTP (Google/Facebook/Link externo)
    if (url.startsWith('http')) {
      if (mounted) setState(() => _downloadUrl = url);
      return;
    }

    // Se for caminho do Storage
    await _loadImageFromStorage(url);
  }

  Future<void> _loadImageFromStorage(String path) async {
    if (_loading) return; // Evita chamadas duplicadas

    setState(() {
      _loading = true;
      _downloadUrl = null; // Limpa url anterior enquanto carrega a nova
    });

    print('Storage: Tentando baixar imagem do caminho: $path');

    try {
      // Cria a referência baseada no caminho salvo no Firestore (ex: Leads_Photos/teste.jpg)
      final ref = FirebaseStorage.instance.ref().child(path);
      
      final url = await ref.getDownloadURL();
      print('Storage: URL gerada com sucesso: $url');

      if (mounted) {
        setState(() {
          _downloadUrl = url;
          _loading = false;
        });
      }
    } catch (e) {
      print('Storage ERRO: Falha ao baixar imagem: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _downloadUrl = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Loading
    if (_loading) {
      return const CircleAvatar(
        radius: 20,
        backgroundColor: Colors.white,
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    // 2. Imagem Carregada
    if (_downloadUrl != null) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: Colors.white,
        backgroundImage: NetworkImage(_downloadUrl!),
        onBackgroundImageError: (exception, stackTrace) {
           print('Erro ao renderizar NetworkImage: $exception');
        },
      );
    }

    // 3. Fallback (Ícone Padrão)
    return const CircleAvatar(
      radius: 20,
      backgroundColor: Colors.white,
      child: Icon(Icons.person, color: Color(0xFF075E54)),
    );
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

    final userBubbleColor = isDark ? const Color(0xFF056162) : const Color(0xFFDCF8C6);
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
                  style: TextStyle(color: timeColor, fontSize: 10),
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
    if (status == 'pending_send') {
      return const Icon(Icons.check, size: 14, color: Colors.grey);
    } else if (status == 'sent') {
      return const Icon(Icons.done_all, size: 14, color: Colors.grey);
    } else if (status == 'error') {
      return const Icon(Icons.error_outline, size: 14, color: Colors.red);
    }
    return const SizedBox.shrink();
  }
}