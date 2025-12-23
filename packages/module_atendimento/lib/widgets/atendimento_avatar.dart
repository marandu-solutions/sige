import 'dart:typed_data';
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
  Future<Uint8List?>? _imageFuture;

  @override
  void initState() {
    super.initState();
    _updateFuture();
  }

  @override
  void didUpdateWidget(covariant AtendimentoAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.fotoUrl != oldWidget.fotoUrl) {
      _updateFuture();
    }
  }

  void _updateFuture() {
    if (widget.fotoUrl != null &&
        widget.fotoUrl!.isNotEmpty &&
        !widget.fotoUrl!.startsWith('http') &&
        !widget.fotoUrl!.startsWith('https')) {
      _imageFuture = _fetchImage(widget.fotoUrl!);
    } else {
      _imageFuture = null;
    }
  }

  Future<Uint8List?> _fetchImage(String path) async {
    try {
      // 10MB max size
      final ref = FirebaseStorage.instance.ref().child(path);
      return await ref.getData(10 * 1024 * 1024);
    } catch (e) {
      debugPrint('Erro ao carregar imagem: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor =
        widget.backgroundColor ?? theme.colorScheme.surfaceContainerHighest;
    final iColor = widget.iconColor ?? theme.colorScheme.onSurfaceVariant;

    final fallback = Center(
      child: Icon(Icons.person, color: iColor, size: widget.radius * 1.2),
    );

    Widget content = fallback;

    if (widget.fotoUrl != null && widget.fotoUrl!.isNotEmpty) {
      if (widget.fotoUrl!.startsWith('http') ||
          widget.fotoUrl!.startsWith('https')) {
        content = Image.network(
          widget.fotoUrl!,
          fit: BoxFit.cover,
          width: widget.radius * 2,
          height: widget.radius * 2,
          errorBuilder: (context, error, stackTrace) {
            return fallback;
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: iColor,
              ),
            );
          },
        );
      } else {
        // Storage path
        content = FutureBuilder<Uint8List?>(
          future: _imageFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: iColor,
                ),
              );
            }
            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data == null) {
              return fallback;
            }
            return Image.memory(
              snapshot.data!,
              fit: BoxFit.cover,
              width: widget.radius * 2,
              height: widget.radius * 2,
              errorBuilder: (context, error, stackTrace) => fallback,
            );
          },
        );
      }
    }

    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: bgColor,
      child: ClipOval(
        child: SizedBox(
          width: widget.radius * 2,
          height: widget.radius * 2,
          child: content,
        ),
      ),
    );
  }
}
