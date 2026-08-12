import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_theme.dart';
import '../core/theme.dart';

class ThemeNotifier extends StateNotifier<AppThemeConfig> {
  ThemeNotifier()
      : super(
          const AppThemeConfig(
            presetId: 'emerald_obsidian',
            baseMode: BaseMode.obsidianDark,
            primaryAccent: Color(0xFF4EDEA3),
          ),
        ) {
    loadTheme();
  }

  static const String _keyPreset = 'tripl_theme_preset_id';
  static const String _keyBaseMode = 'tripl_theme_base_mode_id';
  static const String _keyAccentColor = 'tripl_theme_accent_color';

  static const String _keyBgBase = 'tripl_theme_bg_base';
  static const String _keyCardBg = 'tripl_theme_card_bg';
  static const String _keyCardBorder = 'tripl_theme_card_border';
  static const String _keyTextPrimary = 'tripl_theme_text_primary';
  static const String _keyTextMuted = 'tripl_theme_text_muted';
  static const String _keyIsLight = 'tripl_theme_is_light';

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final presetId = prefs.getString(_keyPreset);
    final baseModeId = prefs.getString(_keyBaseMode) ?? BaseMode.obsidianDark.id;
    final accentValue = prefs.getInt(_keyAccentColor);

    AppThemeConfig loaded;

    if (presetId != null && presetId != 'custom') {
      final preset = CuratedPreset.fromId(presetId);
      if (preset != null) {
        loaded = AppThemeConfig(
          presetId: preset.id,
          baseMode: preset.baseMode,
          primaryAccent: preset.primaryAccent,
        );
      } else {
        loaded = _resolveConfig(baseModeId, accentValue, presetId);
      }
    } else {
      loaded = _resolveConfig(baseModeId, accentValue, 'custom');
    }

    state = loaded;
    _syncLegacyTheme(loaded);
    _saveToPrefs(loaded);
  }

  AppThemeConfig _resolveConfig(String baseModeId, int? accentValue, String? savedPresetId) {
    final baseMode = BaseMode.fromId(baseModeId);
    final primaryAccent = accentValue != null ? Color(accentValue) : const Color(0xFF4EDEA3);

    // Check if this combination matches a known preset
    for (final p in CuratedPreset.allPresets) {
      if (p.baseMode.id == baseMode.id && p.primaryAccent.value == primaryAccent.value) {
        return AppThemeConfig(
          presetId: p.id,
          baseMode: p.baseMode,
          primaryAccent: p.primaryAccent,
        );
      }
    }

    return AppThemeConfig(
      presetId: null,
      baseMode: baseMode,
      primaryAccent: primaryAccent,
    );
  }

  Future<void> selectPreset(CuratedPreset preset) async {
    final config = AppThemeConfig(
      presetId: preset.id,
      baseMode: preset.baseMode,
      primaryAccent: preset.primaryAccent,
    );
    state = config;
    _syncLegacyTheme(config);
    await _saveToPrefs(config);
  }

  Future<void> setBaseMode(BaseMode baseMode) async {
    final config = _checkPresetMatch(baseMode, state.primaryAccent);
    state = config;
    _syncLegacyTheme(config);
    await _saveToPrefs(config);
  }

  Future<void> setPrimaryAccent(Color accent) async {
    final config = _checkPresetMatch(state.baseMode, accent);
    state = config;
    _syncLegacyTheme(config);
    await _saveToPrefs(config);
  }

  Future<void> _saveToPrefs(AppThemeConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPreset, config.presetId ?? 'custom');
    await prefs.setString(_keyBaseMode, config.baseMode.id);
    await prefs.setInt(_keyAccentColor, config.primaryAccent.value);
    await prefs.setInt(_keyBgBase, config.bgBase.value);
    await prefs.setInt(_keyCardBg, config.cardBg.value);
    await prefs.setInt(_keyCardBorder, config.cardBorder.value);
    await prefs.setInt(_keyTextPrimary, config.textPrimary.value);
    await prefs.setInt(_keyTextMuted, config.textMuted.value);
    await prefs.setBool(_keyIsLight, config.baseMode.brightness == Brightness.light);
  }

  AppThemeConfig _checkPresetMatch(BaseMode mode, Color accent) {
    for (final p in CuratedPreset.allPresets) {
      if (p.baseMode.id == mode.id && p.primaryAccent.value == accent.value) {
        return AppThemeConfig(
          presetId: p.id,
          baseMode: p.baseMode,
          primaryAccent: p.primaryAccent,
        );
      }
    }
    return AppThemeConfig(
      presetId: null,
      baseMode: mode,
      primaryAccent: accent,
    );
  }

  void _syncLegacyTheme(AppThemeConfig config) {
    TriplTheme.obsidianBg = config.bgBase;
    TriplTheme.obsidianCard = config.cardBg;
    TriplTheme.primaryMint = config.primaryAccent;
    TriplTheme.borderGreen = config.cardBorder;
    TriplTheme.textLight = config.textPrimary;
    TriplTheme.textGray = config.textMuted;
    TriplTheme.isLight = config.baseMode.brightness == Brightness.light;
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeConfig>((ref) {
  return ThemeNotifier();
});
