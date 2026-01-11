import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_functions/cloud_functions.dart';
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
import 'package:module_atendimento/widgets/video_player_widget.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

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

  // Gravador de áudio
  late final AudioRecorder _audioRecorder;
  bool _isRecording = false;
  Timer? _timer;
  int _recordDuration = 0;
  bool _isComposing = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    _messageController.addListener(_onMessageChanged);

    // Marca mensagens como lidas ao abrir o chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _marcarComoLidas();
    });
  }

  Future<void> _marcarComoLidas() async {
    try {
      await ref
          .read(mensagensProvider(MensagensParams(
                  tenantId: widget.tenantId,
                  atendimentoId: widget.atendimentoId))
              .notifier)
          .marcarComoLidas(widget.tenantId, widget.atendimentoId);
    } catch (e) {
      print('Erro ao marcar mensagens como lidas: $e');
    }
  }

  void _onMessageChanged() {
    setState(() {
      _isComposing = _messageController.text.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _messageController.removeListener(_onMessageChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _timer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        String? path;

        if (!kIsWeb) {
          final location = await getApplicationDocumentsDirectory();
          final name = 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
          path = '${location.path}/$name';
        } else {
          // Na web, o path é ignorado pelo record, mas precisamos passar algo
          path = '';
        }

        await _audioRecorder.start(const RecordConfig(), path: path);

        setState(() {
          _isRecording = true;
          _recordDuration = 0;
        });

        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _recordDuration++;
          });
        });
      }
    } catch (e) {
      print('Erro ao iniciar gravação: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao iniciar gravação: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();

    // Na web o path retornado pode ser um blob URL
    final path = await _audioRecorder.stop();

    setState(() {
      _isRecording = false;
    });

    if (path != null) {
      await _sendAudioFile(path);
    }
  }

  Future<void> _cancelRecording() async {
    _timer?.cancel();
    await _audioRecorder.stop();
    setState(() {
      _isRecording = false;
      _recordDuration = 0;
    });
  }

  Future<void> _sendAudioFile(String path) async {
    try {
      String base64Audio;

      if (kIsWeb) {
        final response = await http.get(Uri.parse(path));
        final bytes = response.bodyBytes;
        base64Audio = base64Encode(bytes);
      } else {
        final file = File(path);
        final bytes = await file.readAsBytes();
        base64Audio = base64Encode(bytes);
      }

      final user = FirebaseAuth.instance.currentUser;

      final mensagem = MensagemModel(
        id: '',
        tenantId: widget.tenantId,
        atendimentoId: widget.atendimentoId,
        texto: '',
        dataEnvio: DateTime.now(),
        isUsuario: true,
        status: 'pending_send',
        anexoUrl: base64Audio, // Envia Base64 diretamente
        mensagemTipo: 'AudioMessage',
        telefoneDestino: widget.contactPhone,
        remetenteUid: user?.uid,
        remetenteTipo: 'vendedor',
        leadId: widget.leadId,
        messageId: '',
      );

      ref
          .read(mensagensProvider(MensagensParams(
                  tenantId: widget.tenantId,
                  atendimentoId: widget.atendimentoId))
              .notifier)
          .addMensagem(mensagem);
    } catch (e) {
      print('Erro ao enviar áudio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar áudio: $e')),
        );
      }
    }
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
                child: _isRecording
                    ? _buildRecordingUI(isDark)
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.attach_file,
                                color: Colors.grey),
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
                                          child:
                                              _buildFilePreview(_selectedFile!),
                                        ),
                                        Positioned(
                                          right: 0,
                                          top: 0,
                                          child: IconButton(
                                            icon: const Icon(Icons.close,
                                                size: 16),
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
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          CircleAvatar(
                            backgroundColor: _isSending
                                ? Colors.grey
                                : const Color(0xFF075E54),
                            child: IconButton(
                              icon: Icon(
                                  _isComposing || _selectedFile != null
                                      ? Icons.send
                                      : Icons.mic,
                                  color: Colors.white),
                              onPressed: _isSending
                                  ? null
                                  : (_isComposing || _selectedFile != null
                                      ? _sendMessage
                                      : _startRecording),
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

  Widget _buildRecordingUI(bool isDark) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.grey),
          onPressed: _cancelRecording,
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF3D3D3D) : Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              const Icon(Icons.fiber_manual_record,
                  color: Colors.red, size: 12),
              const SizedBox(width: 8),
              Text(
                _formatDuration(_recordDuration),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              // Waveform simulado
              SizedBox(
                height: 20,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(10, (index) {
                    return Container(
                      width: 3,
                      height: 10.0 + (index % 3) * 5,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        CircleAvatar(
          backgroundColor: const Color(0xFF075E54),
          child: IconButton(
            icon: const Icon(Icons.send, color: Colors.white),
            onPressed: _stopRecording,
          ),
        ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
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
    final isVideo = ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext);

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
            ext == 'pdf'
                ? Icons.picture_as_pdf
                : (isVideo ? Icons.videocam : Icons.insert_drive_file),
            color: ext == 'pdf'
                ? Colors.red
                : (isVideo ? Colors.black : Colors.blue),
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
    if (_isSending) return;

    final text = _messageController.text.trim();
    if (text.isEmpty && _selectedFile == null) return;

    setState(() {
      _isSending = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    String? downloadUrl;
    String? messageType;

    try {
      // Se houver arquivo, faz o upload
      if (_selectedFile != null) {
        try {
          final file = _selectedFile!;

          final ext = file.extension?.toLowerCase() ?? '';
          final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);
          final isVideo = ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext);

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
          } else if (isVideo) {
            // Se for vídeo, envia via Cloud Function para contornar limite do Firestore (1MB)
            // e evitar uso do Storage conforme solicitado.
            Uint8List? fileBytes;
            if (kIsWeb) {
              fileBytes = file.bytes;
            } else if (file.path != null) {
              fileBytes = await File(file.path!).readAsBytes();
            }

            if (fileBytes != null) {
              final base64Video = base64Encode(fileBytes);

              try {
                // Envia via function
                await FirebaseFunctions.instance
                    .httpsCallable('sendVideoMessage')
                    .call({
                  'tenantId': widget.tenantId,
                  'atendimentoId': widget.atendimentoId,
                  'text': text,
                  'base64Video': base64Video,
                  'customerPhone': widget.contactPhone,
                  'senderUid': user?.uid,
                  'leadId': widget.leadId,
                });

                _messageController.clear();
                setState(() {
                  _selectedFile = null;
                });
                return; // Envio concluído pela function
              } catch (e) {
                throw 'Erro ao enviar vídeo: $e';
              }
            } else {
              throw 'Não foi possível ler o arquivo de vídeo';
            }
          } else {
            // Se não for imagem/video (Audio, PDF, etc), usa o Firebase Storage
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
          } else if (isVideo) {
            messageType = 'VideoMessage';
          } else if (['mp3', 'wav', 'aac', 'm4a', 'ogg'].contains(ext)) {
            messageType = 'AudioMessage';
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
      } else {
        messageType = 'TextMessage';
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
        messageId: '',
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
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
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
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
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
        constraints: const BoxConstraints(maxWidth: 280),
        child: Builder(
          builder: (context) {
            final content = Column(
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
                      mainAxisSize: MainAxisSize.min,
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
            );
            return !hasAttachment ? IntrinsicWidth(child: content) : content;
          },
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
