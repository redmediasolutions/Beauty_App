import 'package:flutter/material.dart';

final Color primary = const Color(0xFF6f0562);
final Color primaryContainer = const Color(0xFF8c277b);
final Color secondary = const Color(0xFFb70b68);

final Color surface = const Color(0xFFfcf9f9);
final Color surfaceLow = const Color(0xFFF7F2F4);
final Color surfaceLowest = const Color(0xFFFFFFFF);

final Color onSurface = const Color(0xFF1b1b1c);
final Color outlineVariant = const Color(0xFFD7C0CD);

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: surface,

  colorScheme: ColorScheme(
    brightness: Brightness.light,
    primary: primary,
    onPrimary: Colors.white,
    primaryContainer: primaryContainer,
    onPrimaryContainer: Colors.white,
    secondary: secondary,
    onSecondary: Colors.white,
    surface: surface,
    onSurface: onSurface,
    error: Colors.red,
    onError: Colors.white,
    outline: outlineVariant,
    outlineVariant: outlineVariant.withValues(alpha: 0.2),
    surfaceContainerHighest: surfaceLow,
    surfaceContainerHigh: surfaceLow,
    surfaceContainer: surfaceLow,
    surfaceContainerLow: surfaceLow,
    surfaceContainerLowest: surfaceLowest,
  ),

  // 🔥 No-Line Rule
  dividerTheme: const DividerThemeData(
    color: Colors.transparent,
    thickness: 0,
  ),

  // ✨ TYPOGRAPHY SYSTEM (LOCAL FONTS)
  textTheme: TextTheme(
  // 🔥 PRIMARY DISPLAY (Hero / Big headings)
  displayLarge: TextStyle(
    fontFamily: 'TenorSans',
    color: onSurface,
    fontSize: 56,
    height: 1.1,
    fontWeight: FontWeight.w400,
  ),

  displayMedium: TextStyle(
    fontFamily: 'TenorSans',
    color: onSurface,
    fontSize: 40,
    height: 1.15,
  ),

  // 🔥 SECTION HEADINGS
  headlineMedium: TextStyle(
    fontFamily: 'TenorSans',
    color: onSurface,
    fontSize: 28,
    height: 1.2,
  ),

  // BODY (unchanged)
  bodyLarge: TextStyle(
    fontFamily: 'Manrope',
    color: onSurface.withValues(alpha: 0.75),
    fontSize: 16,
    height: 1.6,
  ),

  bodyMedium: TextStyle(
    fontFamily: 'Manrope',
    color: onSurface.withValues(alpha: 0.65),
    fontSize: 14,
  ),

  // LABELS
  labelLarge: TextStyle(
    fontFamily: 'Manrope',
    color: onSurface.withValues(alpha: 0.5),
    fontSize: 12,
    letterSpacing: 2,
    fontWeight: FontWeight.w600,
  ),

  // TITLES (buttons, nav)
  titleLarge: TextStyle(
    fontFamily: 'Manrope',
    color: onSurface,
    fontSize: 18,
    fontWeight: FontWeight.w600,
  ),
),

  // 🧴 BUTTONS
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 36),
      shape: const StadiumBorder(),
      elevation: 0,
      backgroundColor: primary,
      foregroundColor: Colors.white,
      textStyle: const TextStyle(
        fontFamily: 'Manrope',
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    ),
  ),

  // ✨ INPUT FIELDS
  inputDecorationTheme: InputDecorationTheme(
    filled: false,
    border: UnderlineInputBorder(
      borderSide: BorderSide(
        color: outlineVariant.withValues(alpha: 0.2),
        width: 1,
      ),
    ),
    enabledBorder: UnderlineInputBorder(
      borderSide: BorderSide(
        color: outlineVariant.withValues(alpha: 0.2),
      ),
    ),
    focusedBorder: UnderlineInputBorder(
      borderSide: BorderSide(
        color: primary,
        width: 2,
      ),
    ),
    labelStyle: TextStyle(
      fontFamily: 'Manrope',
      color: onSurface.withValues(alpha: 0.6),
      fontSize: 12,
      letterSpacing: 1.2,
    ),
  ),

  // 🧊 CARD
  cardTheme: CardThemeData(
    color: surfaceLowest,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  ),

  // ✨ APP BAR
  appBarTheme: AppBarTheme(
    backgroundColor: surface.withValues(alpha: 0.7),
    elevation: 0,
    centerTitle: false,
    titleTextStyle: TextStyle(
      fontFamily: 'Manrope',
      color: onSurface,
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
  ),
);