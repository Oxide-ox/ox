import 'package0:flutter/material.dart';

final ValueNotifier<int> themeModeNotifier = ValueNotifier<int>(0);

class AppTheme {
  static final ThemeData classic = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF090212),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFE6007E),
      secondary: Color(0xFF8E00C7),
      surface: Color(0xFF17092C),
      tertiary: Color(0xFFA0A0AB),
    ),
    cardTheme: CardTheme(
      color: const Color(0xFF17092C),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
    ),
  );

  static final ThemeData neoDarkNeon = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0F0A1C),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFA855F7),
      secondary: Color(0xFFEC4899),
      surface: Color(0xFF1D1135),
      tertiary: Colors.white,
    ),
    cardTheme: CardTheme(
      color: const Color(0xFF1D1135),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Colors.black, width: 3),
      ),
    ),
  );

  static final ThemeData neoCreamPastel = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFFEFCE8),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFFFACC15),
      secondary: Color(0xFF86EFAC),
      surface: Color(0xFFFEF08A),
      tertiary: Colors.black,
    ),
    cardTheme: CardTheme(
      color: const Color(0xFFFEF08A),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Colors.black, width: 3),
      ),
    ),
  );
}
