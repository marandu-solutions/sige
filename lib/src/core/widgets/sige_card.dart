import 'package:flutter/material.dart';

class SigeCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final double borderRadius;
  final Border? border;

  const SigeCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.backgroundColor,
    this.onTap,
    this.borderRadius = 12.0,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final cardBorder = border ??
        Border.all(
          color: theme.dividerColor.withValues(alpha: 0.8),
          width: 1.0,
        );

    Widget cardContent = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? cs.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: cardBorder,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onTap,
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}
