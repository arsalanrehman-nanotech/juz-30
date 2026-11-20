import 'package:flutter/material.dart';

/// Colour palette: deep emerald, white/ivory and subtle gold.
class HifzColors {
  const HifzColors({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.primary,
    required this.onPrimary,
    required this.gold,
    required this.text,
    required this.textMuted,
    required this.border,
    required this.success,
    required this.warning,
    required this.revealBg,
    required this.heroStart,
    required this.heroEnd,
  });

  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color primary;
  final Color onPrimary;
  final Color gold;
  final Color text;
  final Color textMuted;
  final Color border;
  final Color success;
  final Color warning;
  final Color revealBg;
  final Color heroStart;
  final Color heroEnd;

  static const HifzColors light = HifzColors(
    background: Color(0xFFF7F4EC),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFEDF4F0),
    primary: Color(0xFF0B5D4A),
    onPrimary: Color(0xFFFFFFFF),
    gold: Color(0xFFB8903A),
    text: Color(0xFF14231E),
    textMuted: Color(0xFF5C6B65),
    border: Color(0xFFE3DFD2),
    success: Color(0xFF1E8E5A),
    warning: Color(0xFFB86E0B),
    revealBg: Color(0xFFFBF5E4),
    heroStart: Color(0xFF0B5D4A),
    heroEnd: Color(0xFF0E7A60),
  );

  static const HifzColors dark = HifzColors(
    background: Color(0xFF0A1714),
    surface: Color(0xFF12231F),
    surfaceAlt: Color(0xFF183029),
    primary: Color(0xFF1B8F6B),
    onPrimary: Color(0xFFFFFFFF),
    gold: Color(0xFFD8B35A),
    text: Color(0xFFEAF2EE),
    textMuted: Color(0xFF9DB1A9),
    border: Color(0xFF24413A),
    success: Color(0xFF3CC68A),
    warning: Color(0xFFE0A33C),
    revealBg: Color(0xFF262312),
    heroStart: Color(0xFF0B4A3B),
    heroEnd: Color(0xFF0F6B54),
  );

  static HifzColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

/// Font family of the bundled KFGQPC Uthmanic Script (Hafs).
const String kQuranFont = 'KFGQPC';

ThemeData buildTheme(Brightness brightness) {
  final HifzColors c = brightness == Brightness.dark ? HifzColors.dark : HifzColors.light;
  final ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF0B5D4A),
    brightness: brightness,
  ).copyWith(
    primary: c.primary,
    onPrimary: c.onPrimary,
    secondary: c.gold,
    surface: c.surface,
    onSurface: c.text,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.background,
    dividerColor: c.border,
    appBarTheme: AppBarTheme(
      backgroundColor: c.background,
      foregroundColor: c.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
