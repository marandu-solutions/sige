import 'package:flutter/material.dart';

enum SigeBadgeVariant { primary, success, warning, danger, info, neutral }

class SigeBadge extends StatelessWidget {
  final String text;
  final SigeBadgeVariant variant;
  final IconData? icon;
  final Color? customColor;

  const SigeBadge({
    super.key,
    required this.text,
    this.variant = SigeBadgeVariant.primary,
    this.icon,
    this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    Color color;
    if (customColor != null) {
      color = customColor!;
    } else {
      color = switch (variant) {
        SigeBadgeVariant.primary => cs.primary,
        SigeBadgeVariant.success => const Color(0xFF10B981),
        SigeBadgeVariant.warning => const Color(0xFFF59E0B),
        SigeBadgeVariant.danger => const Color(0xFFEF4444),
        SigeBadgeVariant.info => const Color(0xFF3B82F6),
        SigeBadgeVariant.neutral => const Color(0xFF64748B),
      };
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
