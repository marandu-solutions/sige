import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class AtendimentoAvatar extends StatefulWidget {
  final String? fotoUrl;
  final double radius;
  final Color? backgroundColor;
  final Color? iconColor;

  const AtendimentoAvatar({
    super.key,
    this.fotoUrl,
    this.radius = 20,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  State<AtendimentoAvatar> createState() => _AtendimentoAvatarState();
}

class _AtendimentoAvatarState extends State<AtendimentoAvatar> {
  String? _downloadUrl;
  bool _loading = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant AtendimentoAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fotoUrl != widget.fotoUrl) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    final url = widget.fotoUrl;

    if (url == null || url.isEmpty) {
      if (mounted) {
        setState(() {
          _downloadUrl = null;
          _error = false;
          _loading = false;
        });
      }
      return;
    }

    if (url.startsWith('http')) {
      if (mounted) {
        setState(() {
          _downloadUrl = url;
          _error = false;
          _loading = false;
        });
      }
      return;
    }

    setState(() {
      _loading = true;
      _error = false;
    });

    try {
      Reference ref;
      if (url.startsWith('gs://')) {
        ref = FirebaseStorage.instance.refFromURL(url);
      } else {
        ref = FirebaseStorage.instance.ref().child(url);
      }

      final downloadUrl = await ref.getDownloadURL();

      if (!mounted) return;

      setState(() {
        _downloadUrl = downloadUrl;
        _loading = false;
        _error = false;
      });
    } catch (e) {
      debugPrint('Erro ao baixar imagem: $e');

      if (!mounted) return;
      setState(() {
        _downloadUrl = null;
        _loading = false;
        _error = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = widget.backgroundColor ?? theme.colorScheme.surfaceContainerHighest;
    final iColor = widget.iconColor ?? theme.colorScheme.onSurfaceVariant;

    if (_loading) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundColor: bgColor,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircularProgressIndicator(strokeWidth: 2, color: iColor),
        ),
      );
    }

    if (_downloadUrl != null) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundColor: bgColor,
        backgroundImage: NetworkImage(_downloadUrl!),
        onBackgroundImageError: (exception, stackTrace) {
          debugPrint('Erro ao renderizar NetworkImage: $exception');
        },
      );
    }

    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: bgColor,
      child: Icon(Icons.person, color: iColor, size: widget.radius * 1.2),
    );
  }
}
