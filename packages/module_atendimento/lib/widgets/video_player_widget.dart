import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final VoidCallback onClose;

  const VideoPlayerWidget({
    Key? key,
    required this.videoUrl,
    required this.onClose,
  }) : super(key: key);

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      _videoPlayerController =
          VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));

      await _videoPlayerController.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoPlayerController.value.aspectRatio,
        allowFullScreen: false, // Controlado manualmente se necessário
        allowMuting: true,
        showControls: true,
        placeholder: const Center(
          child: CircularProgressIndicator(),
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              'Erro ao carregar vídeo',
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
      );

      setState(() {});
    } catch (e) {
      debugPrint("Erro ao inicializar vídeo: $e");
      setState(() {
        _isError = true;
      });
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Erro ao carregar vídeo',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: widget.onClose,
              child: const Text('Fechar'),
            ),
          ],
        ),
      );
    }

    if (_chewieController == null ||
        !_videoPlayerController.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Calculando dimensões para o player suspenso
    // Limitando a largura a 90% da tela ou 800px (o que for menor)
    // e altura proporcional, mas limitada também
    final size = MediaQuery.of(context).size;
    final videoRatio = _videoPlayerController.value.aspectRatio;

    double width = size.width * 0.9;
    if (width > 800) width = 800;

    double height = width / videoRatio;
    if (height > size.height * 0.8) {
      height = size.height * 0.8;
      width = height * videoRatio;
    }

    return Center(
      child: GestureDetector(
        onTap: () {
          // Captura o clique para não fechar o dialog se clicar no vídeo
        },
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                Chewie(controller: _chewieController!),
                // Botão de fechar discreto no canto
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: widget.onClose,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class VideoThumbnailWidget extends StatefulWidget {
  final String videoUrl;

  const VideoThumbnailWidget({Key? key, required this.videoUrl})
      : super(key: key);

  @override
  State<VideoThumbnailWidget> createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<VideoThumbnailWidget> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _controller.initialize();
      // Ensure the video is at the beginning
      await _controller.seekTo(Duration.zero);
      // Don't play, just show first frame
      setState(() {
        _initialized = true;
      });
    } catch (e) {
      debugPrint('Error loading video thumbnail: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void didUpdateWidget(VideoThumbnailWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _controller.dispose();
      _controller =
          VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      _initialized = false;
      _hasError = false;
      _initialize();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Icon(Icons.error, color: Colors.white54, size: 50),
        ),
      );
    }

    if (!_initialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white54,
          ),
        ),
      );
    }

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: _controller.value.size.width,
        height: _controller.value.size.height,
        child: VideoPlayer(_controller),
      ),
    );
  }
}
