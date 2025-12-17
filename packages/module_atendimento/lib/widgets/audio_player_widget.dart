import 'dart:math';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  final bool isDark;
  final String time;
  final String? photoUrl;

  const AudioPlayerWidget({
    Key? key,
    required this.audioUrl,
    required this.isDark,
    required this.time,
    this.photoUrl,
  }) : super(key: key);

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late AudioPlayer _audioPlayer;
  bool _isLoading = true;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  final List<double> _waveforms = [];

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _generateWaveforms();
    _initAudio();
  }

  void _generateWaveforms() {
    final random = Random();
    for (int i = 0; i < 30; i++) {
      // Gera alturas aleatórias para simular a onda sonora
      _waveforms.add(0.3 + random.nextDouble() * 0.7);
    }
  }

  Future<void> _initAudio() async {
    try {
      // Carrega o áudio via URL (o just_audio gerencia cache/streaming)
      // O await aqui espera carregar os metadados e duração
      final duration = await _audioPlayer.setUrl(widget.audioUrl);

      if (mounted) {
        setState(() {
          _duration = duration ?? Duration.zero;
          // Se já temos duração e o player está pronto (ou quase), liberamos a UI
          // O just_audio entra em 'ready' quando tem dados suficientes para tocar
        });
      }

      // Listeners
      _audioPlayer.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
            // Verifica se está carregando/bufferizando
            if (state.processingState == ProcessingState.loading ||
                state.processingState == ProcessingState.buffering) {
              _isLoading = true;
            } else {
              _isLoading = false;
            }

            if (state.processingState == ProcessingState.completed) {
              _isPlaying = false;
              _position = Duration.zero;
              _audioPlayer.seek(Duration.zero);
              _audioPlayer.pause();
            }
          });
        }
      });

      _audioPlayer.positionStream.listen((position) {
        if (mounted) {
          setState(() {
            _position = position;
          });
        }
      });
    } catch (e) {
      debugPrint("Erro ao carregar áudio: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_isPlaying) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.play();
    }
  }

  void _seek(double progress) {
    final position =
        Duration(milliseconds: (progress * _duration.inMilliseconds).round());
    _audioPlayer.seek(position);
  }

  @override
  Widget build(BuildContext context) {
    // Cores
    final iconColor = widget.isDark ? Colors.white : Colors.black87;
    final activeColor = Colors.blue;
    final inactiveColor = Colors.grey;
    final timeColor = widget.isDark ? Colors.grey[400] : Colors.grey[600];

    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(8),
        child: const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final progress = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;

    return Container(
      width: 260, // Aumentei um pouco para caber a foto
      padding: EdgeInsets.zero,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Botão Play/Pause
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _togglePlay,
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: iconColor,
                size: 30,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Área da linha / ondas + Hora
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ondas
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (details) {
                      // O LayoutBuilder abaixo resolve o tamanho
                    },
                    onHorizontalDragUpdate: (details) {
                      // O LayoutBuilder abaixo resolve o tamanho
                    },
                    child: SizedBox(
                      height: 24,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;

                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapUp: (details) {
                              final dx = details.localPosition.dx;
                              final p = (dx / width).clamp(0.0, 1.0);
                              _seek(p);
                            },
                            onHorizontalDragUpdate: (details) {
                              final dx = details.localPosition.dx;
                              final p = (dx / width).clamp(0.0, 1.0);
                              _seek(p);
                            },
                            child: Stack(
                              alignment: Alignment.centerLeft,
                              children: [
                                // Ondas (Sempre visíveis agora)
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children:
                                      List.generate(_waveforms.length, (index) {
                                    final barHeight = 20 * _waveforms[index];
                                    final isPlayed =
                                        (index / _waveforms.length) <= progress;
                                    return Container(
                                      width: (width / _waveforms.length) * 0.6,
                                      height: barHeight,
                                      decoration: BoxDecoration(
                                        color: isPlayed
                                            ? activeColor
                                            : inactiveColor,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    );
                                  }),
                                ),

                                // Círculo Azul (Slider Thumb - Sempre visível)
                                Positioned(
                                  left: (width * progress) - 6,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // Hora
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    widget.time,
                    style: TextStyle(
                      color: timeColor,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Foto do Contato (se houver)
          if (widget.photoUrl != null && widget.photoUrl!.isNotEmpty) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(widget.photoUrl!),
              onBackgroundImageError: (_, __) {},
              child: widget.photoUrl == null
                  ? const Icon(Icons.person, size: 20)
                  : null,
            ),
          ],
        ],
      ),
    );
  }
}
