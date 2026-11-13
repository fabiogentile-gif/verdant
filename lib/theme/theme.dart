import 'package:flutter/material.dart';

const _lightScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF677D6A),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFE6EBE3),
  onPrimaryContainer: Color(0xFF40534C),
  secondary: Color(0xFFD6BD98),
  onSecondary: Color(0xFF1A3636),
  secondaryContainer: Color(0xFFEDE3D3),
  onSecondaryContainer: Color(0xFF40534C),
  tertiary: Color(0xFFA66A4A),
  onTertiary: Color(0xFFFFFFFF),
  tertiaryContainer: Color(0xFFF3DDD0),
  onTertiaryContainer: Color(0xFF3A1E10),
  error: Color(0xFFBA3B2E),
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFFF9DAD6),
  onErrorContainer: Color(0xFF410E0B),
  surface: Color(0xFFFFFDFA),
  onSurface: Color(0xFF1A3636),
  onSurfaceVariant: Color(0xFF77847B),
  surfaceContainerLowest: Color(0xFFFFFDFA),
  surfaceContainerLow: Color(0xFFF6F3ED),
  surfaceContainer: Color(0xFFF0ECE2),
  surfaceContainerHigh: Color(0xFFEBE7DC),
  surfaceContainerHighest: Color(0xFFE5E1D5),
  outline: Color(0xFF8A978F),
  outlineVariant: Color(0xFFDEDFD5),
  inverseSurface: Color(0xFF1A3636),
  onInverseSurface: Color(0xFFF6F3ED),
  inversePrimary: Color(0xFFA9C2AC),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  surfaceTint: Color(0xFF677D6A),
);

const _darkScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFF677D6A),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFF3E5342),
  onPrimaryContainer: Color(0xFFD3E4D5),
  secondary: Color(0xFFD6BD98),
  onSecondary: Color(0xFF1A3636),
  secondaryContainer: Color(0xFF5E4E34),
  onSecondaryContainer: Color(0xFFEDE3D3),
  tertiary: Color(0xFFE0A98B),
  onTertiary: Color(0xFF3A1E10),
  tertiaryContainer: Color(0xFF7A4A30),
  onTertiaryContainer: Color(0xFFF9DFD0),
  error: Color(0xFFF2B8B5),
  onError: Color(0xFF601410),
  errorContainer: Color(0xFF8C1D18),
  onErrorContainer: Color(0xFFF9DEDC),
  surface: Color(0xFF40534C),
  onSurface: Color(0xFFF6F3ED),
  onSurfaceVariant: Color(0xFFC9D1C5),
  surfaceContainerLowest: Color(0xFF1A3636),
  surfaceContainerLow: Color(0xFF2E4540),
  surfaceContainer: Color(0xFF40534C),
  surfaceContainerHigh: Color(0xFF4A5E56),
  surfaceContainerHighest: Color(0xFF55695F),
  outline: Color(0xFF8FA095),
  outlineVariant: Color(0xFF566B62),
  inverseSurface: Color(0xFFF6F3ED),
  onInverseSurface: Color(0xFF1A3636),
  inversePrimary: Color(0xFF4E6552),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  surfaceTint: Color(0xFF677D6A),
);

class AppTheme {
  static final light = _build(_lightScheme, const Color(0xFFF6F3ED));
  static final dark = _build(_darkScheme, const Color(0xFF1A3636));

  /// Inter everywhere; Lora for the display and headline roles (DESIGN.md:
  /// "The One Serif Rule"). Fonts are bundled in assets/fonts.
  static ThemeData _build(ColorScheme scheme, Color background) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      fontFamily: 'Inter',
    );
    final t = base.textTheme;
    TextStyle? serif(TextStyle? s) => s?.copyWith(fontFamily: 'Lora');

    return base.copyWith(
      textTheme: t.copyWith(
        displayLarge: serif(t.displayLarge),
        displayMedium: serif(t.displayMedium),
        displaySmall: serif(t.displaySmall),
        headlineLarge: serif(t.headlineLarge),
        headlineMedium: serif(t.headlineMedium),
        headlineSmall: serif(t.headlineSmall),
      ),
    );
  }
}

/// Shadow tokens (DESIGN.md, Elevation & Depth).
abstract final class AppShadows {
  /// "Card soft": resting cards. Tinted with forest ink, barely there
  /// ("The Whisper Shadow Rule"). Deeper on dark so it still separates.
  static List<BoxShadow> cardSoft(ColorScheme scheme) => [
    BoxShadow(
      color: scheme.brightness == Brightness.light
          ? const Color(0x0F1A3636) // forest ink at 6%
          : const Color(0x40000000),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
}
