import 'package:flutter/material.dart';
import 'sige_colors.dart';
import 'sige_typography.dart';

/// Construtor de Temas Dinâmicos Multi-Tenant do SIGE (Design System)
/// Garante alto contraste, tipografia elegante e previne problemas de texto escuro em fundo escuro.
class SigeTheme {
  /// Gera o tema claro a partir de uma cor semente (seedColor) configurada no Tenant
  static ThemeData light({Color? seedColor}) {
    final primary = seedColor ?? SigeColors.primaryDefault;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      surface: SigeColors.lightSurface,
      onSurface: SigeColors.lightTextPrimary,
      error: SigeColors.danger,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: SigeColors.lightBg,
      cardColor: SigeColors.lightSurface,
      dividerColor: SigeColors.lightBorder,
      cardTheme: CardThemeData(
        color: SigeColors.lightSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: SigeColors.lightBorder, width: 0.8),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: SigeColors.lightColumnBg,
        disabledColor: SigeColors.lightBorder,
        selectedColor: primary,
        secondarySelectedColor: primary,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        labelStyle: WidgetStateTextStyle.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }
          return const TextStyle(
            color: SigeColors.lightTextPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          );
        }),
        secondaryLabelStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: SigeColors.lightBorder, width: 0.8),
        ),
        color: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return SigeColors.lightBorder;
          }
          if (states.contains(WidgetState.selected)) {
            return primary;
          }
          return SigeColors.lightColumnBg;
        }),
        iconTheme: const IconThemeData(size: 16),
        checkmarkColor: Colors.white,
      ),
      textTheme: SigeTypography.createTextTheme(
        SigeColors.lightTextPrimary,
        SigeColors.lightTextSecondary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: SigeColors.lightSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: const TextStyle(
          color: SigeColors.lightTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: SigeColors.lightTextPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SigeColors.lightSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: SigeColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: SigeColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: SigeColors.danger),
        ),
        labelStyle: const TextStyle(color: SigeColors.lightTextSecondary),
        hintStyle: const TextStyle(color: SigeColors.lightTextMuted),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: SigeColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          iconColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          iconColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: SigeColors.lightTextSecondary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
    );
  }

  /// Gera o tema escuro a partir de uma cor semente (seedColor) configurada no Tenant
  static ThemeData dark({Color? seedColor}) {
    final primary = seedColor ?? SigeColors.primaryDefault;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
      primary: primary,
      onPrimary: Colors.white,
      surface: SigeColors.darkSurface,
      onSurface: SigeColors.darkTextPrimary,
      error: SigeColors.danger,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: SigeColors.darkBg,
      cardColor: SigeColors.darkSurface,
      dividerColor: SigeColors.darkBorder,
      cardTheme: CardThemeData(
        color: SigeColors.darkSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: SigeColors.darkBorder, width: 0.8),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: SigeColors.darkSurface,
        disabledColor: SigeColors.darkBorder,
        selectedColor: primary,
        secondarySelectedColor: primary,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        labelStyle: WidgetStateTextStyle.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }
          return const TextStyle(
            color: SigeColors.darkTextPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          );
        }),
        secondaryLabelStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: SigeColors.darkBorder, width: 0.8),
        ),
        color: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return SigeColors.darkBorder;
          }
          if (states.contains(WidgetState.selected)) {
            return primary;
          }
          return SigeColors.darkSurface;
        }),
        iconTheme: const IconThemeData(size: 16),
        checkmarkColor: Colors.white,
      ),
      textTheme: SigeTypography.createTextTheme(
        SigeColors.darkTextPrimary,
        SigeColors.darkTextSecondary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: SigeColors.darkSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: const TextStyle(
          color: SigeColors.darkTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: SigeColors.darkTextPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SigeColors.darkSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: SigeColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: SigeColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: SigeColors.danger),
        ),
        labelStyle: const TextStyle(color: SigeColors.darkTextSecondary),
        hintStyle: const TextStyle(color: SigeColors.darkTextMuted),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: SigeColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          iconColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          iconColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: SigeColors.darkTextSecondary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
    );
  }
}
