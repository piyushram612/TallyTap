import 'package:flutter/material.dart';

class TriplTheme {
  // Mappings for user customizations
  static Map<String, Color> customCategoryColors = {};
  static Map<String, IconData> customCategoryIcons = {};
  static Map<String, Color> customSourceColors = {};

  // Dynamic active theme colors (updated by ThemeNotifier)
  static Color obsidianBg = const Color(0xFF08100E);
  static Color obsidianCard = const Color(0xFF111C18);
  static Color primaryMint = const Color(0xFF4EDEA3); // Active accent color
  static Color primaryViolet = const Color(0xFF3A41C7);
  static Color primarySlate = const Color(0xFF9FB6DF);
  
  static Color textLight = const Color(0xFFF3F4F6);
  static Color textGray = const Color(0xFF9CA3AF);
  static Color borderGreen = const Color(0xFF1D2F28);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        background: obsidianBg,
        primary: primaryMint,
        onPrimary: obsidianBg,
        secondary: primaryMint,
        onSecondary: obsidianBg,
        surface: obsidianCard,
        onSurface: textLight,
        outline: borderGreen,
      ),
      scaffoldBackgroundColor: obsidianBg,
      datePickerTheme: DatePickerThemeData(
        backgroundColor: obsidianBg,
        headerBackgroundColor: obsidianBg,
        headerForegroundColor: primaryMint,
        surfaceTintColor: Colors.transparent,
        dividerColor: borderGreen,
        rangeSelectionBackgroundColor: primaryMint.withOpacity(0.15),
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return obsidianBg;
          }
          if (states.contains(WidgetState.disabled)) {
            return textGray.withOpacity(0.3);
          }
          return textLight;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryMint;
          }
          return null;
        }),
        todayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return obsidianBg;
          }
          return primaryMint;
        }),
        todayBorder: BorderSide(color: primaryMint, width: 1.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: borderGreen, width: 1.0),
        ),
      ),
      cardTheme: CardThemeData(
        color: obsidianCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: borderGreen, width: 1.0),
        ),
        elevation: 0,
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.5,
          color: textLight,
          fontFamily: 'Outfit',
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
          color: textLight,
          fontFamily: 'Outfit',
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textLight,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: textGray,
        ),
      ),
    );
  }

  // Define lightTheme fallback that looks standard but clean
  static ThemeData get lightTheme => darkTheme; // Enforce obsidian mode as default for ultimate premium styling

  // Full palette of 20 visually distinct, curated colors used for auto-assignment
  static List<Color> get categoryPalette => _categoryPalette;

  static const List<Color> _categoryPalette = [
    Color(0xFF4EDEA3), // Mint
    Color(0xFF3A41C7), // Violet
    Color(0xFF9FB6DF), // Slate Blue
    Color(0xFFF59E0B), // Amber
    Color(0xFFEC4899), // Pink
    Color(0xFF8B5CF6), // Purple
    Color(0xFF06B6D4), // Cyan
    Color(0xFF10B981), // Emerald
    Color(0xFFEF4444), // Red
    Color(0xFF3B82F6), // Blue
    Color(0xFFF97316), // Orange
    Color(0xFF84CC16), // Lime
    Color(0xFF14B8A6), // Teal
    Color(0xFFD946EF), // Fuchsia
    Color(0xFFFBBF24), // Yellow
    Color(0xFF6366F1), // Indigo
    Color(0xFF22D3EE), // Sky
    Color(0xFFE879F9), // Orchid
    Color(0xFF34D399), // Sea Green
    Color(0xFFF43F5E), // Rose
  ];

  static Color getColorForCategory(String cat, [int index = 0]) {
    final trimmed = cat.trim();
    if (trimmed.toLowerCase() == 'transfer') {
      return const Color(0xFF94A3B8); // Slate color for transfer
    }
    if (customCategoryColors.containsKey(trimmed)) {
      return customCategoryColors[trimmed]!;
    }
    final hash = trimmed.codeUnits.fold(0, (h, c) => (h * 31 + c) & 0xFFFFFFFF);
    return _categoryPalette[hash % _categoryPalette.length];
  }

  static bool isLight = false;

  /// Ensures category title text is sharp and legible regardless of theme brightness (Light or Dark mode)
  static Color ensureLegibleTextColor(Color color, {bool? isDark}) {
    final dark = isDark ?? !isLight;
    final hsl = HSLColor.fromColor(color);
    if (dark) {
      if (hsl.lightness < 0.65) {
        return hsl.withLightness(0.72).withSaturation(hsl.saturation.clamp(0.3, 0.9)).toColor();
      }
    } else {
      // In Light Mode, light or medium-bright colors on white background must be darkened for crisp contrast
      if (hsl.lightness > 0.38) {
        return hsl.withLightness(0.28).withSaturation(hsl.saturation.clamp(0.4, 1.0)).toColor();
      }
    }
    return color;
  }

  static IconData getIconForCategory(String cat, [bool isIncome = false]) {
    final trimmed = cat.trim();
    if (customCategoryIcons.containsKey(trimmed)) {
      return customCategoryIcons[trimmed]!;
    }
    final clean = trimmed.toLowerCase();

    // Special System Types
    if (clean == 'transfer') {
      return Icons.swap_horiz_rounded;
    }

    // Food, Dining & Beverage
    if (clean.contains('dining') ||
        clean.contains('food') ||
        clean.contains('dinner') ||
        clean.contains('restaurant') ||
        clean.contains('cafe') ||
        clean.contains('coffee') ||
        clean.contains('lunch') ||
        clean.contains('breakfast') ||
        clean.contains('snack') ||
        clean.contains('bakery') ||
        clean.contains('eat') ||
        clean.contains('drink') ||
        clean.contains('bar') ||
        clean.contains('baking')) {
      return Icons.restaurant_outlined;
    }

    // Groceries & Supermarket
    if (clean.contains('groc') ||
        clean.contains('supermarket') ||
        clean.contains('market') ||
        clean.contains('vegetable') ||
        clean.contains('fruit') ||
        clean.contains('provision') ||
        clean.contains('mart')) {
      return Icons.local_grocery_store_outlined;
    }

    // Commute, Transit & Vehicles
    if (clean.contains('commute') ||
        clean.contains('transport') ||
        clean.contains('transit') ||
        clean.contains('car') ||
        clean.contains('cab') ||
        clean.contains('taxi') ||
        clean.contains('auto') ||
        clean.contains('uber') ||
        clean.contains('ola') ||
        clean.contains('bus') ||
        clean.contains('train') ||
        clean.contains('metro') ||
        clean.contains('fuel') ||
        clean.contains('gas') ||
        clean.contains('petrol') ||
        clean.contains('diesel') ||
        clean.contains('parking') ||
        clean.contains('toll') ||
        clean.contains('vehicle') ||
        clean.contains('bike')) {
      return Icons.directions_transit_filled_outlined;
    }

    // Housing & Living
    if (clean.contains('hous') ||
        clean.contains('home') ||
        clean.contains('rent') ||
        clean.contains('mortgage') ||
        clean.contains('lease') ||
        clean.contains('property') ||
        clean.contains('maintenance') ||
        clean.contains('furniture') ||
        clean.contains('appliance') ||
        clean.contains('decor')) {
      return Icons.home_outlined;
    }

    // Health, Medical & Fitness
    if (clean.contains('health') ||
        clean.contains('medical') ||
        clean.contains('doctor') ||
        clean.contains('hospital') ||
        clean.contains('pharmacy') ||
        clean.contains('medicine') ||
        clean.contains('drug') ||
        clean.contains('clinic') ||
        clean.contains('fitness') ||
        clean.contains('gym') ||
        clean.contains('workout') ||
        clean.contains('wellness') ||
        clean.contains('dental')) {
      return Icons.medical_services_outlined;
    }

    // Travel, Tourism & Lodging
    if (clean.contains('travel') ||
        clean.contains('trip') ||
        clean.contains('flight') ||
        clean.contains('plane') ||
        clean.contains('hotel') ||
        clean.contains('resort') ||
        clean.contains('stay') ||
        clean.contains('vacation') ||
        clean.contains('holiday') ||
        clean.contains('luggage') ||
        clean.contains('tour')) {
      return Icons.flight_takeoff_outlined;
    }

    // Shopping, Fashion & Apparel
    if (clean.contains('shop') ||
        clean.contains('clothing') ||
        clean.contains('clothes') ||
        clean.contains('apparel') ||
        clean.contains('fashion') ||
        clean.contains('footwear') ||
        clean.contains('shoes') ||
        clean.contains('wear') ||
        clean.contains('boutique') ||
        clean.contains('store')) {
      return Icons.shopping_bag_outlined;
    }

    // Subscriptions, Streaming & Media
    if (clean.contains('sub') ||
        clean.contains('subscription') ||
        clean.contains('netflix') ||
        clean.contains('spotify') ||
        clean.contains('prime') ||
        clean.contains('youtube') ||
        clean.contains('streaming') ||
        clean.contains('software') ||
        clean.contains('app') ||
        clean.contains('saas')) {
      return Icons.subscriptions_outlined;
    }

    // Utilities & Power
    if (clean.contains('util') ||
        clean.contains('electricity') ||
        clean.contains('water') ||
        clean.contains('power') ||
        clean.contains('trash') ||
        clean.contains('waste') ||
        clean.contains('sewer')) {
      return Icons.bolt_outlined;
    }

    // Telecom, Phone, Internet & Bills
    if (clean.contains('bill') ||
        clean.contains('recharge') ||
        clean.contains('phone') ||
        clean.contains('mobile') ||
        clean.contains('internet') ||
        clean.contains('wifi') ||
        clean.contains('broadband') ||
        clean.contains('cable') ||
        clean.contains('dth') ||
        clean.contains('postpaid') ||
        clean.contains('prepaid')) {
      return Icons.wifi_outlined;
    }

    // Education, Learning & Books
    if (clean.contains('edu') ||
        clean.contains('school') ||
        clean.contains('college') ||
        clean.contains('university') ||
        clean.contains('tuition') ||
        clean.contains('course') ||
        clean.contains('class') ||
        clean.contains('learning') ||
        clean.contains('book') ||
        clean.contains('fee') ||
        clean.contains('exam')) {
      return Icons.school_outlined;
    }

    // Entertainment, Gaming & Hobbies
    if (clean.contains('entertainment') ||
        clean.contains('movie') ||
        clean.contains('cinema') ||
        clean.contains('game') ||
        clean.contains('gaming') ||
        clean.contains('esport') ||
        clean.contains('music') ||
        clean.contains('concert') ||
        clean.contains('show') ||
        clean.contains('event') ||
        clean.contains('party') ||
        clean.contains('hobby') ||
        clean.contains('play')) {
      return Icons.sports_esports_outlined;
    }

    // Investments, Wealth & Crypto
    if (clean.contains('invest') ||
        clean.contains('stock') ||
        clean.contains('share') ||
        clean.contains('crypto') ||
        clean.contains('trading') ||
        clean.contains('fund') ||
        clean.contains('mutual') ||
        clean.contains('equity') ||
        clean.contains('asset') ||
        clean.contains('sip') ||
        clean.contains('wealth')) {
      return Icons.trending_up_outlined;
    }

    // Savings & Piggy Bank
    if (clean.contains('saving') ||
        clean.contains('deposit') ||
        clean.contains('reserve') ||
        clean.contains('piggy')) {
      return Icons.savings_outlined;
    }

    // Income, Salary & Wages
    if (clean.contains('salary') ||
        clean.contains('income') ||
        clean.contains('paycheck') ||
        clean.contains('wage') ||
        clean.contains('stipend') ||
        clean.contains('earn')) {
      return Icons.payments_outlined;
    }

    // Bonus, Dividends, Cashback & Rewards
    if (clean.contains('bonus') ||
        clean.contains('dividend') ||
        clean.contains('reward') ||
        clean.contains('cashback') ||
        clean.contains('interest') ||
        clean.contains('profit') ||
        clean.contains('commission')) {
      return Icons.auto_awesome_outlined;
    }

    // Gifts, Charity & Donations
    if (clean.contains('gift') ||
        clean.contains('present') ||
        clean.contains('donation') ||
        clean.contains('charity') ||
        clean.contains('tip') ||
        clean.contains('offering')) {
      return Icons.card_giftcard_outlined;
    }

    // Pets & Veterinary
    if (clean.contains('pet') ||
        clean.contains('dog') ||
        clean.contains('cat') ||
        clean.contains('vet') ||
        clean.contains('animal')) {
      return Icons.pets_outlined;
    }

    // Personal Care & Salon
    if (clean.contains('personal') ||
        clean.contains('care') ||
        clean.contains('beauty') ||
        clean.contains('salon') ||
        clean.contains('barber') ||
        clean.contains('spa') ||
        clean.contains('grooming') ||
        clean.contains('hair') ||
        clean.contains('cosmetic')) {
      return Icons.spa_outlined;
    }

    // Insurance & Protection
    if (clean.contains('insurance') ||
        clean.contains('policy') ||
        clean.contains('claim') ||
        clean.contains('protection') ||
        clean.contains('safety') ||
        clean.contains('assurance')) {
      return Icons.shield_outlined;
    }

    // Taxes & Government Fees
    if (clean.contains('tax') ||
        clean.contains('duty') ||
        clean.contains('gst') ||
        clean.contains('vat') ||
        clean.contains('fine') ||
        clean.contains('penalty')) {
      return Icons.account_balance_outlined;
    }

    // Electronics & Tech Gadgets
    if (clean.contains('electronic') ||
        clean.contains('tech') ||
        clean.contains('gadget') ||
        clean.contains('computer') ||
        clean.contains('laptop') ||
        clean.contains('hardware') ||
        clean.contains('camera')) {
      return Icons.devices_outlined;
    }

    // Family & Children
    if (clean.contains('family') ||
        clean.contains('kid') ||
        clean.contains('child') ||
        clean.contains('baby') ||
        clean.contains('daycare')) {
      return Icons.family_restroom_outlined;
    }

    // Fallbacks
    if (isIncome || clean == 'income') {
      return Icons.arrow_downward_rounded;
    } else {
      return Icons.category_outlined;
    }
  }

  static Color getIconBgForCategory(String cat, [bool isIncome = false]) {
    final catColor = getColorForCategory(cat);
    return catColor.withOpacity(0.15);
  }

  static Color getColorForSource(String src, [int index = 0]) {
    final trimmed = src.trim();
    if (customSourceColors.containsKey(trimmed)) {
      return customSourceColors[trimmed]!;
    }
    // Stable hash so every source name always maps to a distinct color
    final hash = trimmed.codeUnits.fold(0, (h, c) => (h * 31 + c) & 0xFFFFFFFF);
    return _categoryPalette[hash % _categoryPalette.length];
  }

  static IconData getIconForSource(String src) {
    final clean = src.trim().toLowerCase();
    if (clean.contains('cash') || clean.contains('wallet')) {
      return Icons.account_balance_wallet_outlined;
    } else if (clean.contains('bank') || clean.contains('account') || clean.contains('savings')) {
      return Icons.account_balance_outlined;
    } else if (clean.contains('credit') || clean.contains('card') || clean.contains('debit')) {
      return Icons.credit_card_outlined;
    } else if (clean.contains('paypal') || clean.contains('online') || clean.contains('digital')) {
      return Icons.language_outlined;
    } else if (clean.contains('upi') || clean.contains('gpay') || clean.contains('phonepe') || clean.contains('paytm')) {
      return Icons.qr_code_scanner_outlined;
    } else if (clean.contains('invest') || clean.contains('stock') || clean.contains('mutual')) {
      return Icons.trending_up_outlined;
    } else {
      return Icons.payments_outlined;
    }
  }

  static const List<IconData> availableIcons = [
    // Defaults & Fallbacks
    Icons.local_mall_outlined,
    Icons.arrow_downward_rounded,

    // Food & Drink
    Icons.local_cafe_outlined,
    Icons.restaurant_outlined,
    Icons.fastfood_outlined,
    Icons.lunch_dining_outlined,
    Icons.local_pizza_outlined,
    Icons.icecream_outlined,
    Icons.liquor_outlined,
    
    // Transport & Travel
    Icons.directions_transit_filled_outlined,
    Icons.directions_car_filled_outlined,
    Icons.flight_outlined,
    Icons.pedal_bike_outlined,
    Icons.directions_boat_outlined,
    Icons.luggage_outlined,

    // Shopping & Fashion
    Icons.local_grocery_store_outlined,
    Icons.shopping_bag_outlined,
    Icons.checkroom_outlined,
    Icons.watch_outlined,

    // Bills & Utilities
    Icons.bolt_outlined,
    Icons.water_drop_outlined,
    Icons.phone_android_outlined,
    Icons.wifi_rounded,
    Icons.home_outlined,

    // Health, Care & Fitness
    Icons.local_hospital_outlined,
    Icons.medication_outlined,
    Icons.fitness_center_outlined,
    Icons.spa_outlined,
    Icons.pets_outlined,

    // Entertainment, Hobby & Gifts
    Icons.subscriptions_outlined,
    Icons.sports_esports_outlined,
    Icons.music_note_outlined,
    Icons.movie_outlined,
    Icons.palette_outlined,
    Icons.camera_alt_outlined,
    Icons.card_giftcard_outlined,
    Icons.celebration_outlined,

    // Education, Work & Other
    Icons.school_outlined,
    Icons.work_outline_rounded,
    Icons.payments_outlined,
    Icons.handyman_outlined,
    Icons.star_outline_rounded,
    Icons.favorite_outline_rounded,
  ];
}
