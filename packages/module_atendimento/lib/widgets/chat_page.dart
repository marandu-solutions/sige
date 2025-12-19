import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:module_atendimento/models/mensagem_model.dart';
import 'package:module_atendimento/providers/mensagens_provider.dart';
import 'package:module_atendimento/widgets/atendimento_avatar.dart';
import 'package:module_atendimento/widgets/audio_player_widget.dart';

class ChatPage extends ConsumerStatefulWidget {
  final String tenantId;
  final String atendimentoId;
  final String contactName;
  final String contactPhone;
  final String? leadId;
  final String? fotoUrl;
  final VoidCallback onClose;

  const ChatPage({
    super.key,
    required this.tenantId,
    required this.atendimentoId,
    required this.contactName,
    required this.contactPhone,
    this.leadId,
    this.fotoUrl,
    required this.onClose,
  });

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  PlatformFile? _selectedFile;

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

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final headerColor =
        isDark ? const Color(0xFF075E54) : const Color(0xFF075E54);
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
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: headerColor,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    // AQUI ESTÁ O WIDGET DO AVATAR
                    AtendimentoAvatar(fotoUrl: widget.fotoUrl),

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
                        return _MessageBubble(
                          mensagem: mensagem,
                          isDark: isDark,
                          fotoUrl: widget.fotoUrl,
                        );
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
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.attach_file, color: Colors.grey),
                      onPressed: _pickFile,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_selectedFile != null) ...[
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF3D3D3D)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.grey[700]!
                                      : Colors.grey[300]!,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: _buildFilePreview(_selectedFile!),
                                  ),
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: IconButton(
                                      icon: const Icon(Icons.close, size: 16),
                                      onPressed: _removeAttachment,
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: 'Digite uma mensagem...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF3D3D3D)
                                  : Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              hintStyle: TextStyle(color: hintColor),
                            ),
                            style: TextStyle(color: textColor),
                            maxLines: null,
                            textCapitalization: TextCapitalization.sentences,
                          ),
                        ],
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

  Widget _buildFilePreview(PlatformFile file) {
    final ext = file.extension?.toLowerCase() ?? '';
    final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);

    if (isImage) {
      if (kIsWeb) {
        if (file.bytes != null) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              file.bytes!,
              height: 100,
              width: 100,
              fit: BoxFit.cover,
            ),
          );
        }
      } else {
        if (file.path != null) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(file.path!),
              height: 100,
              width: 100,
              fit: BoxFit.cover,
            ),
          );
        }
      }
    }

    // Preview genérico para outros arquivos
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ext == 'pdf' ? Icons.picture_as_pdf : Icons.insert_drive_file,
            color: ext == 'pdf' ? Colors.red : Colors.blue,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              file.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles();

      if (result == null || result.files.isEmpty) return;

      setState(() {
        _selectedFile = result.files.first;
      });
    } catch (e) {
      print('Erro ao selecionar arquivo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao selecionar arquivo: $e')),
        );
      }
    }
  }

  void _removeAttachment() {
    setState(() {
      _selectedFile = null;
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty && _selectedFile == null) return;

    final user = FirebaseAuth.instance.currentUser;
    String? downloadUrl;
    String? messageType;

    // Se houver arquivo, faz o upload
    if (_selectedFile != null) {
      try {
        final file = _selectedFile!;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enviando mensagem...')),
        );

        final ext = file.extension?.toLowerCase() ?? '';
        final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);

        // Se for imagem, converte para Base64
        if (isImage) {
          Uint8List? fileBytes;
          if (kIsWeb) {
            fileBytes = file.bytes;
          } else if (file.path != null) {
            fileBytes = await File(file.path!).readAsBytes();
          }

          if (fileBytes != null) {
            downloadUrl = base64Encode(fileBytes);
          } else {
            throw 'Não foi possível ler o arquivo de imagem';
          }
        } else {
          // Se não for imagem (Audio, Video, etc), usa o Firebase Storage
          final fileName =
              '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('uploads/${widget.tenantId}/$fileName');

          if (kIsWeb) {
            if (file.bytes != null) {
              await storageRef.putData(file.bytes!);
            } else {
              throw 'Bytes não disponíveis para upload web';
            }
          } else {
            if (file.path != null) {
              await storageRef.putFile(File(file.path!));
            } else if (file.bytes != null) {
              await storageRef.putData(file.bytes!);
            } else {
              throw 'Arquivo inválido';
            }
          }
          downloadUrl = await storageRef.getDownloadURL();
        }

        // Determinar tipo
        messageType = 'FileMessage';
        if (isImage) {
          messageType = 'ImageMessage';
        } else if (['mp3', 'wav', 'aac', 'm4a', 'ogg'].contains(ext)) {
          messageType = 'AudioMessage';
        } else if (['mp4', 'mov', 'avi'].contains(ext)) {
          messageType = 'VideoMessage';
        }
      } catch (e) {
        print('Erro no upload: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao enviar arquivo: $e')),
          );
        }
        return;
      }
    }

    final mensagem = MensagemModel(
      id: '',
      tenantId: widget.tenantId,
      atendimentoId: widget.atendimentoId,
      texto: text,
      dataEnvio: DateTime.now(),
      isUsuario: true,
      status: 'pending_send',
      anexoUrl: downloadUrl,
      mensagemTipo: messageType,
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
    setState(() {
      _selectedFile = null;
    });
  }
}

class _MessageBubble extends StatelessWidget {
  final MensagemModel mensagem;
  final bool isDark;
  final String? fotoUrl;

  const _MessageBubble({
    required this.mensagem,
    required this.isDark,
    this.fotoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final isUsuario = mensagem.isUsuario;
    final time = DateFormat('HH:mm').format(mensagem.dataEnvio);
    final hasAttachment =
        mensagem.anexoUrl != null && mensagem.anexoUrl!.isNotEmpty;

    // Melhor detecção de imagem: pelo tipo ou pela extensão na URL
    bool isImageMessage = mensagem.mensagemTipo == 'ImageMessage';
    if (!isImageMessage && hasAttachment) {
      final urlLower = mensagem.anexoUrl!.toLowerCase();
      if (urlLower.contains('.jpg') ||
          urlLower.contains('.jpeg') ||
          urlLower.contains('.png') ||
          urlLower.contains('.gif') ||
          urlLower.contains('.webp')) {
        isImageMessage = true;
      }
    }

    final isAudioMessage = mensagem.mensagemTipo == 'AudioMessage' ||
        (hasAttachment &&
            (mensagem.anexoUrl!.endsWith('.mp3') ||
                mensagem.anexoUrl!.endsWith('.aac') ||
                mensagem.anexoUrl!.endsWith('.wav') ||
                mensagem.anexoUrl!.endsWith('.ogg')));

    // Verifica se a URL já é válida (http/https) ou se ainda é Base64 (pendente)
    final isImageUrlValid = hasAttachment &&
        isImageMessage &&
        (mensagem.anexoUrl!.startsWith('http') ||
            mensagem.anexoUrl!.startsWith('https'));

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
        padding: hasAttachment
            ? const EdgeInsets.all(4)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasAttachment) ...[
              if (isAudioMessage)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: AudioPlayerWidget(
                    audioUrl: mensagem.anexoUrl!,
                    isDark: isDark,
                    time: time,
                    photoUrl: fotoUrl,
                  ),
                )
              else
                Padding(
                  padding: isImageMessage
                      ? EdgeInsets.zero
                      : const EdgeInsets.only(bottom: 4.0),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: isImageUrlValid
                            ? Image.network(
                                mensagem.anexoUrl!,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return SizedBox(
                                    width: 200,
                                    height: 200,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                            : null,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 200,
                                    height: 200,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.broken_image,
                                        size: 50),
                                  );
                                },
                              )
                            : Container(
                                width: 200,
                                height: 200,
                                color: Colors.black12,
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                      ),
                      if (isImageMessage)
                        Positioned(
                          bottom: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black38,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  time,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 10),
                                ),
                                if (isUsuario) ...[
                                  const SizedBox(width: 4),
                                  _buildStatusIcon(mensagem.status,
                                      forceWhite: true),
                                ],
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
            if (mensagem.texto.isNotEmpty)
              Padding(
                padding: hasAttachment
                    ? const EdgeInsets.symmetric(horizontal: 4)
                    : EdgeInsets.zero,
                child: Text(
                  mensagem.texto,
                  style: TextStyle(
                    color: isUsuario ? userTextColor : otherTextColor,
                    fontSize: 14,
                  ),
                ),
              ),
            if (!isImageMessage && !isAudioMessage) ...[
              const SizedBox(height: 4),
              Padding(
                padding: hasAttachment
                    ? const EdgeInsets.symmetric(horizontal: 4)
                    : EdgeInsets.zero,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Row(
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
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(String status, {bool forceWhite = false}) {
    final color = forceWhite
        ? Colors.white
        : (status == 'error' ? Colors.red : Colors.grey);
    if (status == 'pending_send') {
      return Icon(Icons.check, size: 14, color: color);
    } else if (status == 'sent') {
      return Icon(Icons.done_all, size: 14, color: color);
    } else if (status == 'error') {
      return Icon(Icons.error_outline, size: 14, color: color);
    }
    return const SizedBox.shrink();
  }
}
