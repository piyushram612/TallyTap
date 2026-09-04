import 'package:flutter/material.dart';

class BaseMode {
  final String id;
  final String name;
  final Color bgBase;
  final Color cardBg;
  final Color cardBorder;
  final Color textPrimary;
  final Color textMuted;
  final Brightness brightness;

  const BaseMode({
    required this.id,
    required this.name,
    required this.bgBase,
    required this.cardBg,
    required this.cardBorder,
    required this.textPrimary,
    required this.textMuted,
    required this.brightness,
  });

  static const BaseMode obsidianDark = BaseMode(
    id: 'obsidian_dark',
    name: 'Obsidian Dark',
    bgBase: Color(0xFF08100E),
    cardBg: Color(0xFF111C18),
    cardBorder: Color(0xFF1D2F28),
    textPrimary: Color(0xFFF3F4F6),
    textMuted: Color(0xFF9CA3AF),
    brightness: Brightness.dark,
  );

  static const BaseMode deepNavy = BaseMode(
    id: 'deep_navy',
    name: 'Deep Navy',
    bgBase: Color(0xFF0A0E1A),
    cardBg: Color(0xFF13192B),
    cardBorder: Color(0xFF232D47),
    textPrimary: Color(0xFFF3F4F6),
    textMuted: Color(0xFF9CA3AF),
    brightness: Brightness.dark,
  );

  static const BaseMode coolSlate = BaseMode(
    id: 'cool_slate',
    name: 'Cool Slate',
    bgBase: Color(0xFF0F172A),
    cardBg: Color(0xFF1E293B),
    cardBorder: Color(0xFF334155),
    textPrimary: Color(0xFFF8FAFC),
    textMuted: Color(0xFF94A3B8),
    brightness: Brightness.dark,
  );

  static const BaseMode warmCharcoal = BaseMode(
    id: 'warm_charcoal',
    name: 'Warm Charcoal',
    bgBase: Color(0xFF14120E),
    cardBg: Color(0xFF1E1B15),
    cardBorder: Color(0xFF362F22),
    textPrimary: Color(0xFFF5F5F4),
    textMuted: Color(0xFFA8A29E),
    brightness: Brightness.dark,
  );

  static const BaseMode darkBurgundy = BaseMode(
    id: 'dark_burgundy',
    name: 'Dark Burgundy',
    bgBase: Color(0xFF180C11),
    cardBg: Color(0xFF24131A),
    cardBorder: Color(0xFF3D1F2C),
    textPrimary: Color(0xFFFDF2F8),
    textMuted: Color(0xFF9F8A95),
    brightness: Brightness.dark,
  );

  static const BaseMode pitchBlack = BaseMode(
    id: 'pitch_black',
    name: 'Pitch Black (OLED)',
    bgBase: Color(0xFF000000),
    cardBg: Color(0xFF121212),
    cardBorder: Color(0xFF262626),
    textPrimary: Color(0xFFFFFFFF),
    textMuted: Color(0xFFA3A3A3),
    brightness: Brightness.dark,
  );

  static const BaseMode pureLight = BaseMode(
    id: 'pure_light',
    name: 'Pure Light',
    bgBase: Color(0xFFF8FAFC),
    cardBg: Color(0xFFFFFFFF),
    cardBorder: Color(0xFFE2E8F0),
    textPrimary: Color(0xFF0F172A),
    textMuted: Color(0xFF64748B),
    brightness: Brightness.light,
  );

  static const List<BaseMode> allModes = [
    obsidianDark,
    deepNavy,
    coolSlate,
    warmCharcoal,
    darkBurgundy,
    pitchBlack,
    pureLight,
  ];

  static BaseMode fromId(String id) {
    return allModes.firstWhere(
      (m) => m.id == id,
      orElse: () => obsidianDark,
    );
  }
}

class CuratedPreset {
  final String id;
  final String name;
  final String description;
  final BaseMode baseMode;
  final Color primaryAccent;

  const CuratedPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.baseMode,
    required this.primaryAccent,
  });

  static const CuratedPreset emeraldObsidian = CuratedPreset(
    id: 'emerald_obsidian',
    name: 'Emerald Obsidian',
    description: 'Classic bio-tech forest green',
    baseMode: BaseMode.obsidianDark,
    primaryAccent: Color(0xFF4EDEA3),
  );

  static const CuratedPreset midnightViolet = CuratedPreset(
    id: 'midnight_violet',
    name: 'Midnight Violet',
    description: 'Cyberpunk neon violet',
    baseMode: BaseMode.deepNavy,
    primaryAccent: Color(0xFF8B5CF6),
  );

  static const CuratedPreset nordicIce = CuratedPreset(
    id: 'nordic_ice',
    name: 'Nordic Ice',
    description: 'Arctic cyan & cool slate',
    baseMode: BaseMode.coolSlate,
    primaryAccent: Color(0xFF38BDF8),
  );

  static const CuratedPreset solarAmber = CuratedPreset(
    id: 'solar_amber',
    name: 'Solar Amber',
    description: 'Warm gold & charcoal luxury',
    baseMode: BaseMode.warmCharcoal,
    primaryAccent: Color(0xFFF59E0B),
  );

  static const CuratedPreset crimsonMidnight = CuratedPreset(
    id: 'crimson_midnight',
    name: 'Crimson Midnight',
    description: 'Midnight velvet & rose',
    baseMode: BaseMode.darkBurgundy,
    primaryAccent: Color(0xFFF43F5E),
  );

  static const CuratedPreset pureOled = CuratedPreset(
    id: 'pure_oled',
    name: 'Pure OLED',
    description: 'Pitch black & lime efficiency',
    baseMode: BaseMode.pitchBlack,
    primaryAccent: Color(0xFF22C55E),
  );

  static const CuratedPreset solarisDaylight = CuratedPreset(
    id: 'solaris_daylight',
    name: 'Solaris Daylight',
    description: 'Crisp light mode & ocean teal',
    baseMode: BaseMode.pureLight,
    primaryAccent: Color(0xFF0D9488),
  );

  static const List<CuratedPreset> allPresets = [
    emeraldObsidian,
    midnightViolet,
    nordicIce,
    solarAmber,
    crimsonMidnight,
    pureOled,
    solarisDaylight,
  ];

  static CuratedPreset? fromId(String id) {
    for (final p in allPresets) {
      if (p.id == id) return p;
    }
    return null;
  }
}

class AppThemeConfig {
  final String? presetId; // Null if custom combination
  final BaseMode baseMode;
  final Color primaryAccent;

  const AppThemeConfig({
    this.presetId,
    required this.baseMode,
    required this.primaryAccent,
  });

  Color get bgBase => baseMode.bgBase;
  Color get cardBg => baseMode.cardBg;
  Color get cardBorder => baseMode.cardBorder;
  Color get textPrimary => baseMode.textPrimary;
  Color get textMuted => baseMode.textMuted;
  Brightness get brightness => baseMode.brightness;

  ThemeData toThemeData() {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primaryAccent,
      onPrimary: isDark ? Colors.black : Colors.white,
      secondary: primaryAccent,
      onSecondary: isDark ? Colors.black : Colors.white,
      error: const Color(0xFFEF4444),
      onError: Colors.white,
      surface: cardBg,
      onSurface: textPrimary,
      outline: cardBorder,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bgBase,
      datePickerTheme: DatePickerThemeData(
        backgroundColor: bgBase,
        headerBackgroundColor: bgBase,
        headerForegroundColor: primaryAccent,
        surfaceTintColor: Colors.transparent,
        dividerColor: cardBorder,
        rangeSelectionBackgroundColor: primaryAccent.withValues(alpha: 0.15),
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return isDark ? Colors.black : Colors.white;
          }
          if (states.contains(WidgetState.disabled)) {
            return textMuted.withValues(alpha: 0.3);
          }
          return textPrimary;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryAccent;
          }
          return null;
        }),
        todayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return isDark ? Colors.black : Colors.white;
          }
          return primaryAccent;
        }),
        todayBorder: BorderSide(color: primaryAccent, width: 1.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: cardBorder, width: 1.0),
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: cardBorder, width: 1.0),
        ),
        elevation: 0,
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.5,
          color: textPrimary,
          fontFamily: 'Outfit',
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
          color: textPrimary,
          fontFamily: 'Outfit',
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: textMuted,
        ),
      ),
    );
  }
}

extension AppThemeContextExtension on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => theme.colorScheme;
  Color get bgBase => theme.scaffoldBackgroundColor;
  Color get cardBg => theme.cardTheme.color ?? theme.colorScheme.surface;
  Color get cardBorder => theme.colorScheme.outline;
  Color get primaryAccent => theme.colorScheme.primary;
  Color get textPrimary => theme.colorScheme.onSurface;
  Color get textMuted => theme.brightness == Brightness.dark ? const Color(0xFF9CA3AF) : const Color(0xFF64748B);
  bool get isDark => theme.brightness == Brightness.dark;
}
