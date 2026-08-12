import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import '../../core/theme.dart';
import '../../providers/theme_provider.dart';
import '../../providers/currency_provider.dart';
import '../../widgets/tripl_badge.dart';
import '../../widgets/tripl_button.dart';
import '../../widgets/tripl_card.dart';
import '../../widgets/tripl_section_header.dart';
import '../../widgets/tripl_sheet.dart';

class ManageThemeSheet extends ConsumerStatefulWidget {
  const ManageThemeSheet({super.key});

  @override
  ConsumerState<ManageThemeSheet> createState() => _ManageThemeSheetState();
}

class _ManageThemeSheetState extends ConsumerState<ManageThemeSheet> {
  final List<Color> _accentSwatches = const [
    Color(0xFF4EDEA3), // Mint Green
    Color(0xFF8B5CF6), // Electric Violet
    Color(0xFF38BDF8), // Sky Cyan
    Color(0xFFF59E0B), // Golden Amber
    Color(0xFFF43F5E), // Rose Pink
    Color(0xFF22C55E), // Electric Lime
    Color(0xFF0D9488), // Ocean Teal
    Color(0xFF6366F1), // Indigo
    Color(0xFFFBBF24), // Neon Yellow
    Color(0xFFF97316), // Coral Orange
    Color(0xFFEC4899), // Hot Pink
    Color(0xFF9FB6DF), // Slate Blue
    Color(0xFF94A3B8), // Pure Slate
    Color(0xFF10B981), // Emerald
  ];

  void _showCustomColorPicker(BuildContext context, AppThemeConfig currentConfig) {
    Color selectedColor = currentConfig.primaryAccent;
    final controller = TextEditingController(
      text: selectedColor.value.toRadixString(16).substring(2).toUpperCase(),
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: currentConfig.cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: currentConfig.cardBorder),
              ),
              title: Text(
                'Custom Accent Color',
                style: TextStyle(
                  color: currentConfig.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Outfit',
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 50,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: selectedColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: currentConfig.cardBorder),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '#${selectedColor.value.toRadixString(16).substring(2).toUpperCase()}',
                      style: TextStyle(
                        color: selectedColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    style: TextStyle(color: currentConfig.textPrimary),
                    maxLength: 6,
                    decoration: InputDecoration(
                      prefixText: '# ',
                      prefixStyle: TextStyle(color: currentConfig.primaryAccent, fontWeight: FontWeight.bold),
                      labelText: 'Enter Hex Color',
                      labelStyle: TextStyle(color: currentConfig.textMuted),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: currentConfig.cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: currentConfig.primaryAccent),
                      ),
                    ),
                    onChanged: (val) {
                      if (val.length == 6) {
                        final hex = int.tryParse('FF$val', radix: 16);
                        if (hex != null) {
                          setDialogState(() {
                            selectedColor = Color(hex);
                          });
                        }
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TriplButton.ghost(
                  label: 'Cancel',
                  onPressed: () => Navigator.pop(dialogCtx),
                ),
                TriplButton.primary(
                  label: 'Apply Accent',
                  color: selectedColor,
                  onPressed: () {
                    ref.read(themeProvider.notifier).setPrimaryAccent(selectedColor);
                    Navigator.pop(dialogCtx);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeConfig = ref.watch(themeProvider);
    final currency = ref.watch(currencyProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return TriplSheet(
          title: 'App Theme & Colors',
          subtitle: 'Personalize look & feel across all screens',
          icon: Icons.palette_rounded,
          child: ListView(
            controller: scrollController,
            children: [
              TriplSectionHeader(title: 'LIVE PREVIEW'),
              TriplCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'MONTHLY BUDGET',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: activeConfig.textMuted,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: activeConfig.primaryAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: activeConfig.primaryAccent.withOpacity(0.4), width: 0.5),
                          ),
                          child: Text(
                            activeConfig.presetId != null
                                ? CuratedPreset.fromId(activeConfig.presetId!)?.name ?? 'Custom Theme'
                                : 'Custom Combination',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: activeConfig.primaryAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$currency 1,240.50',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: activeConfig.textPrimary,
                            fontFamily: 'Outfit',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'of $currency 2,000.00 spent',
                          style: TextStyle(fontSize: 12, color: activeConfig.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Sample Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: 0.62,
                        minHeight: 8,
                        backgroundColor: activeConfig.cardBorder.withOpacity(0.6),
                        valueColor: AlwaysStoppedAnimation<Color>(activeConfig.primaryAccent),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Sample Transaction Chip & Action Pill
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: activeConfig.bgBase,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: activeConfig.cardBorder, width: 0.5),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: activeConfig.primaryAccent.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.local_cafe_outlined, color: activeConfig.primaryAccent, size: 16),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Morning Coffee',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: activeConfig.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        'Dining • Cash',
                                        style: TextStyle(fontSize: 10, color: activeConfig.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '-$currency 4.50',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: activeConfig.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Option A: Curated Theme Presets ──────────────────────────
              Text(
                'CURATED THEME PRESETS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: activeConfig.primaryAccent,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 110,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: CuratedPreset.allPresets.length,
                  itemBuilder: (ctx, index) {
                    final preset = CuratedPreset.allPresets[index];
                    final isSelected = activeConfig.presetId == preset.id;

                    return GestureDetector(
                      onTap: () {
                        ref.read(themeProvider.notifier).selectPreset(preset);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 140,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: preset.baseMode.cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? preset.primaryAccent : preset.baseMode.cardBorder,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: preset.primaryAccent.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : [],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Mini Swatch Dots
                                Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: preset.baseMode.bgBase,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: preset.baseMode.cardBorder, width: 0.5),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: preset.primaryAccent,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ),
                                if (isSelected)
                                  Icon(Icons.check_circle_rounded, color: preset.primaryAccent, size: 16),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  preset.name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: preset.baseMode.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  preset.baseMode.name,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: preset.baseMode.textMuted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 28),

              // ── Option B: Custom Theme Controls ──────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CUSTOM THEME SELECTOR',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: activeConfig.primaryAccent,
                    ),
                  ),
                  if (activeConfig.presetId == null)
                    Text(
                      'Custom Mode Active',
                      style: TextStyle(fontSize: 10, color: activeConfig.primaryAccent, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // 1. Base Modes Row
              Text(
                '1. Select Base Surface Mode',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: activeConfig.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: BaseMode.allModes.map((mode) {
                    final isSelected = activeConfig.baseMode.id == mode.id;

                    return GestureDetector(
                      onTap: () {
                        ref.read(themeProvider.notifier).setBaseMode(mode);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: mode.cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? activeConfig.primaryAccent : mode.cardBorder,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: mode.bgBase,
                                shape: BoxShape.circle,
                                border: Border.all(color: mode.cardBorder, width: 0.5),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              mode.name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: mode.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // 2. Accent Color Palette Grid
              Text(
                '2. Select Primary Accent Color',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: activeConfig.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ..._accentSwatches.map((color) {
                    final isSelected = activeConfig.primaryAccent.value == color.value;

                    return GestureDetector(
                      onTap: () {
                        ref.read(themeProvider.notifier).setPrimaryAccent(color);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? activeConfig.textPrimary : Colors.transparent,
                            width: isSelected ? 3 : 0,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withOpacity(0.4),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : [],
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check_rounded,
                                color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                                size: 20,
                              )
                            : null,
                      ),
                    );
                  }),

                  // Custom Color Picker Button
                  GestureDetector(
                    onTap: () => _showCustomColorPicker(context, activeConfig),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: activeConfig.cardBg,
                        shape: BoxShape.circle,
                        border: Border.all(color: activeConfig.cardBorder, width: 1.5),
                      ),
                      child: Icon(Icons.colorize_rounded, color: activeConfig.primaryAccent, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
