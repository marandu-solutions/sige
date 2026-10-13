import 'package:flutter/material.dart';

enum SigeButtonVariant { primary, secondary, outline, danger, text }
enum SigeButtonSize { small, medium, large }

class SigeButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final SigeButtonVariant variant;
  final SigeButtonSize size;
  final bool isFullWidth;

  const SigeButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.variant = SigeButtonVariant.primary,
    this.size = SigeButtonSize.medium,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Dimensões conforme tamanho
    final padding = switch (size) {
      SigeButtonSize.small => const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      SigeButtonSize.medium => const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      SigeButtonSize.large => const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    };

    final fontSize = switch (size) {
      SigeButtonSize.small => 12.0,
      SigeButtonSize.medium => 14.0,
      SigeButtonSize.large => 16.0,
    };

    final textStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
    );

    Widget content = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: fontSize + 2,
            height: fontSize + 2,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                variant == SigeButtonVariant.outline || variant == SigeButtonVariant.text
                    ? cs.primary
                    : Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ] else if (icon != null) ...[
          Icon(icon, size: fontSize + 4),
          const SizedBox(width: 8),
        ],
        Text(label, style: textStyle),
      ],
    );

    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(10));

    Widget button;
    switch (variant) {
      case SigeButtonVariant.primary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: cs.primary,
            foregroundColor: Colors.white,
            padding: padding,
            shape: shape,
            elevation: 0,
          ),
          child: content,
        );
      case SigeButtonVariant.secondary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: cs.surfaceVariant,
            foregroundColor: cs.onSurfaceVariant,
            padding: padding,
            shape: shape,
            elevation: 0,
          ),
          child: content,
        );
      case SigeButtonVariant.outline:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: cs.primary,
            side: BorderSide(color: cs.primary),
            padding: padding,
            shape: shape,
          ),
          child: content,
        );
      case SigeButtonVariant.danger:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: cs.error,
            foregroundColor: Colors.white,
            padding: padding,
            shape: shape,
            elevation: 0,
          ),
          child: content,
        );
      case SigeButtonVariant.text:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: cs.primary,
            padding: padding,
            shape: shape,
          ),
          child: content,
        );
    }

    if (isFullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}
