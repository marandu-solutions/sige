import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:module_atendimento/models/mensagem_model.dart';
import 'package:module_atendimento/providers/mensagens_provider.dart';
import 'package:module_atendimento/widgets/atendimento_avatar.dart';
import 'package:module_atendimento/widgets/audio_player_widget.dart';
import 'package:module_atendimento/widgets/video_player_widget.dart';

class ReadOnlyChatPage extends ConsumerStatefulWidget {
  final String tenantId;
  final String atendimentoId;
  final String contactName;
  final String contactPhone;
  final String? fotoUrl;
  final VoidCallback onClose;

  const ReadOnlyChatPage({
    super.key,
    required this.tenantId,
    required this.atendimentoId,
    required this.contactName,
    required this.contactPhone,
    this.fotoUrl,
    required this.onClose,
  });

  @override
  ConsumerState<ReadOnlyChatPage> createState() => _ReadOnlyChatPageState();
}

class _ReadOnlyChatPageState extends ConsumerState<ReadOnlyChatPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
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
    final textColor = isDark ? Colors.white : Colors.black87;

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
                            'Visualização (Apenas Leitura)',
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
              
              // Rodapé informativo
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: Center(
                  child: Text(
                    'Modo de apenas leitura',
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

    final isVideoMessage = mensagem.mensagemTipo == 'VideoMessage' ||
        (hasAttachment &&
            (mensagem.anexoUrl!.endsWith('.mp4') ||
                mensagem.anexoUrl!.endsWith('.mov') ||
                mensagem.anexoUrl!.endsWith('.avi') ||
                mensagem.anexoUrl!.endsWith('.mkv') ||
                mensagem.anexoUrl!.endsWith('.webm')));

    // Se for vídeo, mas anexoUrl for null, significa que está processando
    final isVideoProcessing =
        mensagem.mensagemTipo == 'VideoMessage' && mensagem.anexoUrl == null;

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
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75),
          child: IntrinsicWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  else if (isVideoProcessing)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                    )
                  else if (isVideoMessage)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: GestureDetector(
                        onTap: () {
                          if (mensagem.anexoUrl != null) {
                            showDialog(
                              context: context,
                              barrierColor: Colors.black.withOpacity(0.8),
                              builder: (context) => Dialog(
                                backgroundColor: Colors.transparent,
                                insetPadding: EdgeInsets.zero,
                                child: VideoPlayerWidget(
                                  videoUrl: mensagem.anexoUrl!,
                                  onClose: () => Navigator.of(context).pop(),
                                ),
                              ),
                            );
                          }
                        },
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                if (mensagem.anexoUrl != null)
                                  SizedBox.expand(
                                    child: VideoThumbnailWidget(
                                      videoUrl: mensagem.anexoUrl!,
                                    ),
                                  ),
                                Container(
                                  color: Colors.black26,
                                ),
                                const Icon(Icons.play_circle_outline,
                                    color: Colors.white, size: 50),
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
                                        const Icon(Icons.videocam,
                                            color: Colors.white, size: 10),
                                        const SizedBox(width: 4),
                                        Text(
                                          time,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10),
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
                        ),
                      ),
                    )
                  else if (isImageMessage)
                    Padding(
                      padding: EdgeInsets.zero,
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
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.insert_drive_file,
                                color: Colors.grey),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Arquivo',
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
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
                if (!isImageMessage && !isAudioMessage && !isVideoMessage) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: hasAttachment
                        ? const EdgeInsets.symmetric(horizontal: 4)
                        : EdgeInsets.zero,
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.end,
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
                ],
              ],
            ),
          ),
        ));
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
