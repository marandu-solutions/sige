import 'package:flutter/material.dart';

/// Paleta de Tokens de Cor Central do SIGE (Design System)
/// Fornece cores semânticas e superfícies consistentes para os modos Claro e Escuro.
class SigeColors {
  // Cores de Destaque Padrão (Default)
  static const Color primaryDefault = Color(0xFF3F51B5); // Índigo Profissional
  static const Color secondaryDefault = Color(0xFF10B981); // Esmeralda

  // Status Semânticos
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Prioridades de Atendimento / Tarefas (Cores Base)
  static const Color priorityLow = Color(0xFF10B981);
  static const Color priorityMedium = Color(0xFFF59E0B);
  static const Color priorityHigh = Color(0xFFEF4444);
  static const Color priorityUrgent = Color(0xFF8B5CF6);

  // Prioridades - Badges Suaves Modo Claro (Pastel + Texto Saturado)
  static const Color priorityLowBgLight = Color(0xFFDCFCE7); // Emerald 100
  static const Color priorityLowTextLight = Color(0xFF15803D); // Emerald 700
  static const Color priorityMediumBgLight = Color(0xFFFEF3C7); // Amber 100
  static const Color priorityMediumTextLight = Color(0xFFB45309); // Amber 700
  static const Color priorityHighBgLight = Color(0xFFFEE2E2); // Rose 100
  static const Color priorityHighTextLight = Color(0xFFB91C1C); // Rose 700
  static const Color priorityUrgentBgLight = Color(0xFFF3E8FF); // Purple 100
  static const Color priorityUrgentTextLight = Color(0xFF6B21A8); // Purple 700

  // Tons Neutros - Modo Claro
  static const Color lightBg = Color(0xFFF8FAFC); // Slate 50
  static const Color lightSurface = Colors.white;
  static const Color lightCardBg = Colors.white;
  static const Color lightColumnBg = Color(0xFFF1F5F9); // Slate 100
  static const Color lightBorder = Color(0xFFE2E8F0); // Slate 200
  static const Color lightBorderSubtle = Color(0xFFF1F5F9);
  static const Color lightTextPrimary = Color(0xFF0F172A); // Slate 900
  static const Color lightTextSecondary = Color(0xFF64748B); // Slate 500
  static const Color lightTextMuted = Color(0xFF94A3B8); // Slate 400

  // Tons Neutros - Modo Escuro
  static const Color darkBg = Color(0xFF0F172A); // Slate 900
  static const Color darkSurface = Color(0xFF1E293B); // Slate 800
  static const Color darkCardBg = Color(0xFF1E293B);
  static const Color darkColumnBg = Color(0xFF161F30);
  static const Color darkBorder = Color(0xFF334155); // Slate 700
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);

  // Sombras Suaves
  static const List<BoxShadow> lightCardShadow = [
    BoxShadow(
      color: Color(0x0A0F172A),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> lightElevatedShadow = [
    BoxShadow(
      color: Color(0x140F172A),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  /// Converte string hexadecimal para Color
  static Color fromHex(String? hexString, {Color fallback = primaryDefault}) {
    if (hexString == null || hexString.isEmpty) return fallback;
    final cleanHex = hexString.replaceAll('#', '').trim();
    if (cleanHex.length == 6) {
      final val = int.tryParse('FF$cleanHex', radix: 16);
      return val != null ? Color(val) : fallback;
    } else if (cleanHex.length == 8) {
      final val = int.tryParse(cleanHex, radix: 16);
      return val != null ? Color(val) : fallback;
    }
    return fallback;
  }
}
