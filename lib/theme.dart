import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';

/// Pure black and white. No accent colours anywhere.
class Mono {
  static const black = Color(0xFF000000);
  static const white = Color(0xFFFFFFFF);
  static const dim = Color(0xFF8A8A8A);
  static const line = Color(0xFF2A2A2A);
  static const surface = Color(0xFF0D0D0D);
  static const font = 'monospace';
}

ThemeData buildTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Mono.white,
    onPrimary: Mono.black,
    secondary: Mono.white,
    onSecondary: Mono.black,
    error: Mono.white,
    onError: Mono.black,
    surface: Mono.black,
    onSurface: Mono.white,
    surfaceContainerHighest: Mono.surface,
    outline: Mono.line,
    outlineVariant: Mono.line,
  );
  const border = OutlineInputBorder(
    borderRadius: BorderRadius.zero,
    borderSide: BorderSide(color: Mono.line),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Mono.black,
    fontFamily: Mono.font,
    splashFactory: NoSplash.splashFactory,
    appBarTheme: const AppBarTheme(
      backgroundColor: Mono.black,
      foregroundColor: Mono.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: Mono.font,
        fontSize: 18,
        letterSpacing: 2,
        color: Mono.white,
      ),
      shape: Border(bottom: BorderSide(color: Mono.line)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Mono.black,
      indicatorColor: Mono.white,
      indicatorShape: const RoundedRectangleBorder(),
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
            color: s.contains(WidgetState.selected) ? Mono.black : Mono.white,
          )),
      labelTextStyle: const WidgetStatePropertyAll(
        TextStyle(fontFamily: Mono.font, fontSize: 11, letterSpacing: 1),
      ),
    ),
    cardTheme: const CardThemeData(
      color: Mono.black,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(side: BorderSide(color: Mono.line)),
    ),
    dividerTheme: const DividerThemeData(color: Mono.line, space: 1),
    inputDecorationTheme: const InputDecorationTheme(
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: Mono.white),
      ),
      labelStyle: TextStyle(color: Mono.dim),
      floatingLabelStyle: TextStyle(color: Mono.white),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Mono.white,
        foregroundColor: Mono.black,
        shape: const RoundedRectangleBorder(),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Mono.white,
        side: const BorderSide(color: Mono.white),
        shape: const RoundedRectangleBorder(),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Mono.white,
        shape: const RoundedRectangleBorder(),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Mono.white,
      foregroundColor: Mono.black,
      shape: RoundedRectangleBorder(),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: Mono.black,
      shape: RoundedRectangleBorder(side: BorderSide(color: Mono.white)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Mono.black,
      shape: Border(top: BorderSide(color: Mono.white)),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Mono.white,
      contentTextStyle: TextStyle(fontFamily: Mono.font, color: Mono.black),
      shape: RoundedRectangleBorder(),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? Mono.black : Mono.dim),
      trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? Mono.white : Mono.black),
      trackOutlineColor: const WidgetStatePropertyAll(Mono.dim),
    ),
    progressIndicatorTheme:
        const ProgressIndicatorThemeData(color: Mono.white),
  );
}

/// Greyscale terminal palette: ANSI colours map to shades of grey so output
/// stays legible while the app stays monochrome.
const monoTerminalTheme = TerminalTheme(
  cursor: Mono.white,
  selection: Color(0x80FFFFFF),
  foreground: Color(0xFFE6E6E6),
  background: Mono.black,
  black: Color(0xFF000000),
  red: Color(0xFFBDBDBD),
  green: Color(0xFFD9D9D9),
  yellow: Color(0xFFCCCCCC),
  blue: Color(0xFF9E9E9E),
  magenta: Color(0xFFB0B0B0),
  cyan: Color(0xFFC4C4C4),
  white: Color(0xFFE6E6E6),
  brightBlack: Color(0xFF6E6E6E),
  brightRed: Color(0xFFE0E0E0),
  brightGreen: Color(0xFFF2F2F2),
  brightYellow: Color(0xFFEBEBEB),
  brightBlue: Color(0xFFC8C8C8),
  brightMagenta: Color(0xFFD6D6D6),
  brightCyan: Color(0xFFE3E3E3),
  brightWhite: Color(0xFFFFFFFF),
  searchHitBackground: Color(0xFF6E6E6E),
  searchHitBackgroundCurrent: Mono.white,
  searchHitForeground: Mono.black,
);
