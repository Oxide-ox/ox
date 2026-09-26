import 'package:flutter/material.dart';

// Notifier Indeks Tema (0: Original, 1: Neo Brutalism, 2: Pop Art)
final ValueNotifier<int> themeModeNotifier = ValueNotifier<int>(0);

final ValueNotifier<Color> neoBgNotifier = ValueNotifier<Color>(const Color(0xFF0F0A1C));
final ValueNotifier<Color> neoPrimaryNotifier = ValueNotifier<Color>(const Color(0xFFA855F7));
final ValueNotifier<Color> neoSecondaryNotifier = ValueNotifier<Color>(const Color(0xFFEC4899));
final ValueNotifier<Color> neoBorderNotifier = ValueNotifier<Color>(const Color(0xFF000000));


final ValueNotifier<Color> popBgNotifier = ValueNotifier<Color>(const Color(0xFFFFE600));
final ValueNotifier<Color> popPrimaryNotifier = ValueNotifier<Color>(const Color(0xFFFF0055));
final ValueNotifier<Color> popSecondaryNotifier = ValueNotifier<Color>(const Color(0xFF00E5FF));
final ValueNotifier<Color> popBorderNotifier = ValueNotifier<Color>(const Color(0xFF000000));

class AppTheme {

  static void applyNeoPreset({required bool isDark}) {
    if (isDark) {
      neoBgNotifier.value = const Color(0xFF0F0A1C);
      neoPrimaryNotifier.value = const Color(0xFFA855F7);
      neoSecondaryNotifier.value = const Color(0xFFEC4899);
      neoBorderNotifier.value = const Color(0xFF000000);
    } else {
      neoBgNotifier.value = const Color(0xFFFEFCE8);
      neoPrimaryNotifier.value = const Color(0xFFFACC15);
      neoSecondaryNotifier.value = const Color(0xFF86EFAC);
      neoBorderNotifier.value = const Color(0xFF000000);
    }
    themeModeNotifier.notifyListeners();
  }

  static void applyPopArtPreset({required bool isDark}) {
    if (isDark) {
      popBgNotifier.value = const Color(0xFF181824);
      popPrimaryNotifier.value = const Color(0xFFFF0055);
      popSecondaryNotifier.value = const Color(0xFF00E5FF);
      popBorderNotifier.value = const Color(0xFFFFFFFF);
    } else {
      popBgNotifier.value = const Color(0xFFFFE600);
      popPrimaryNotifier.value = const Color(0xFFFF0055);
      popSecondaryNotifier.value = const Color(0xFF00E5FF);
      popBorderNotifier.value = const Color(0xFF000000);
    }
    themeModeNotifier.notifyListeners();
  }


  static ThemeData get currentTheme {
    switch (themeModeNotifier.value) {
      case 1:
        // TEMA 2: NEO BRUTALISM
        return ThemeData(
          brightness: neoBgNotifier.value.computeLuminance() > 0.5
              ? Brightness.light
              : Brightness.dark,
          scaffoldBackgroundColor: neoBgNotifier.value,
          colorScheme: ColorScheme.dark(
            primary: neoPrimaryNotifier.value,
            secondary: neoSecondaryNotifier.value,
            surface: neoBgNotifier.value,
          ),
          cardTheme: CardTheme(
            color: neoBgNotifier.value,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: neoBorderNotifier.value, width: 3),
            ),
          ),
        );

      case 2:
        // TEMA 3: POP ART
        return ThemeData(
          brightness: popBgNotifier.value.computeLuminance() > 0.5
              ? Brightness.light
              : Brightness.dark,
          scaffoldBackgroundColor: popBgNotifier.value,
          colorScheme: ColorScheme.light(
            primary: popPrimaryNotifier.value,
            secondary: popSecondaryNotifier.value,
            surface: Colors.white,
          ),
          cardTheme: CardTheme(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: popBorderNotifier.value, width: 3.5),
            ),
          ),
        );

      default:
        // TEMA 1: ORIGINAL (CYBERPUNK DARK)
        return ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF090212),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFE6007E),
            secondary: Color(0xFF8E00C7),
            surface: Color(0xFF17092C),
          ),
          cardTheme: CardTheme(
            color: const Color(0xFF17092C),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
          ),
        );
    }
  }
}
