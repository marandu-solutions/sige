import 'package:flutter/material.dart';
import 'sige_button.dart';

class SigeDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final String? confirmLabel;
  final VoidCallback? onConfirm;
  final String cancelLabel;
  final VoidCallback? onCancel;
  final bool isDestructive;
  final bool isLoading;
  final double maxWidth;

  const SigeDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmLabel,
    this.onConfirm,
    this.cancelLabel = 'Cancelar',
    this.onCancel,
    this.isDestructive = false,
    this.isLoading = false,
    this.maxWidth = 500.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    splashRadius: 20,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Body
              Flexible(
                child: SingleChildScrollView(
                  child: content,
                ),
              ),
              const SizedBox(height: 24),
              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SigeButton(
                    label: cancelLabel,
                    variant: SigeButtonVariant.text,
                    onPressed: onCancel ?? () => Navigator.of(context).pop(),
                  ),
                  if (confirmLabel != null) ...[
                    const SizedBox(width: 8),
                    SigeButton(
                      label: confirmLabel!,
                      variant: isDestructive ? SigeButtonVariant.danger : SigeButtonVariant.primary,
                      isLoading: isLoading,
                      onPressed: onConfirm,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
