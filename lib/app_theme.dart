import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

final ValueNotifier<int> themeModeNotifier = ValueNotifier<int>(0);

final ValueNotifier<Color> neoBgNotifier = ValueNotifier<Color>(const Color(0xFF0F0A1C));
final ValueNotifier<Color> neoPrimaryNotifier = ValueNotifier<Color>(const Color(0xFFFF2B7A));
final ValueNotifier<Color> neoSecondaryNotifier = ValueNotifier<Color>(const Color(0xFFFFE600));
final ValueNotifier<Color> neoBorderNotifier = ValueNotifier<Color>(const Color(0xFF000000));

final ValueNotifier<Color> popBgNotifier = ValueNotifier<Color>(const Color(0xFF180161));
final ValueNotifier<Color> popPrimaryNotifier = ValueNotifier<Color>(const Color(0xFF00E5FF));
final ValueNotifier<Color> popSecondaryNotifier = ValueNotifier<Color>(const Color(0xFFEC4899));
final ValueNotifier<Color> popBorderNotifier = ValueNotifier<Color>(const Color(0xFFFFFFFF));

class AppTheme {
  static bool _isInitializing = false;

  static Future<void> init() async {
    _isInitializing = true;
    final prefs = await SharedPreferences.getInstance();

    // Load Mode Tema
    themeModeNotifier.value = prefs.getInt('theme_mode') ?? 0;

    neoBgNotifier.value = Color(prefs.getInt('neo_bg') ?? 0xFF0F0A1C);
    neoPrimaryNotifier.value = Color(prefs.getInt('neo_primary') ?? 0xFFFF2B7A);
    neoSecondaryNotifier.value = Color(prefs.getInt('neo_secondary') ?? 0xFFFFE600);
    neoBorderNotifier.value = Color(prefs.getInt('neo_border') ?? 0xFF000000);

    popBgNotifier.value = Color(prefs.getInt('pop_bg') ?? 0xFF180161);
    popPrimaryNotifier.value = Color(prefs.getInt('pop_primary') ?? 0xFF00E5FF);
    popSecondaryNotifier.value = Color(prefs.getInt('pop_secondary') ?? 0xFFEC4899);
    popBorderNotifier.value = Color(prefs.getInt('pop_border') ?? 0xFFFFFFFF);

    _isInitializing = false;


    themeModeNotifier.addListener(_saveThemePreferences);
    neoBgNotifier.addListener(_saveThemePreferences);
    neoPrimaryNotifier.addListener(_saveThemePreferences);
    neoSecondaryNotifier.addListener(_saveThemePreferences);
    neoBorderNotifier.addListener(_saveThemePreferences);
    popBgNotifier.addListener(_saveThemePreferences);
    popPrimaryNotifier.addListener(_saveThemePreferences);
    popSecondaryNotifier.addListener(_saveThemePreferences);
    popBorderNotifier.addListener(_saveThemePreferences);
  }


  static Future<void> _saveThemePreferences() async {
    if (_isInitializing) return;
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt('theme_mode', themeModeNotifier.value);

    await prefs.setInt('neo_bg', neoBgNotifier.value.value);
    await prefs.setInt('neo_primary', neoPrimaryNotifier.value.value);
    await prefs.setInt('neo_secondary', neoSecondaryNotifier.value.value);
    await prefs.setInt('neo_border', neoBorderNotifier.value.value);

    await prefs.setInt('pop_bg', popBgNotifier.value.value);
    await prefs.setInt('pop_primary', popPrimaryNotifier.value.value);
    await prefs.setInt('pop_secondary', popSecondaryNotifier.value.value);
    await prefs.setInt('pop_border', popBorderNotifier.value.value);
  }

  static void applyNeoPreset({required bool isDark}) {
    if (isDark) {
      neoBgNotifier.value = const Color(0xFF0F0A1C);
      neoPrimaryNotifier.value = const Color(0xFFFF2B7A);
      neoSecondaryNotifier.value = const Color(0xFFFFE600);
      neoBorderNotifier.value = const Color(0xFF000000);
    } else {
      neoBgNotifier.value = const Color(0xFFFEFCE8);
      neoPrimaryNotifier.value = const Color(0xFFFF0055);
      neoSecondaryNotifier.value = const Color(0xFF00E5FF);
      neoBorderNotifier.value = const Color(0xFF000000);
    }
    themeModeNotifier.notifyListeners();
  }

  static void applyPopArtPreset({required bool isDark}) {
    if (isDark) {
      popBgNotifier.value = const Color(0xFF180161);
      popPrimaryNotifier.value = const Color(0xFF00E5FF);
      popSecondaryNotifier.value = const Color(0xFFEC4899);
      popBorderNotifier.value = const Color(0xFFFFFFFF);
    } else {
      popBgNotifier.value = const Color(0xFFFFF5F5);
      popPrimaryNotifier.value = const Color(0xFFA855F7);
      popSecondaryNotifier.value = const Color(0xFF86EFAC);
      popBorderNotifier.value = const Color(0xFF18181B);
    }
    themeModeNotifier.notifyListeners();
  }

  static ThemeData get currentTheme {
    final mode = themeModeNotifier.value;

    if (mode == 1) {
      
      return ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: neoBgNotifier.value,
        colorScheme: ColorScheme.dark(
          primary: neoPrimaryNotifier.value,
          secondary: neoSecondaryNotifier.value,
          surface: neoBgNotifier.value,
          outline: neoBorderNotifier.value,
        ),
      );
    } else if (mode == 2) {
      
      return ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: popBgNotifier.value,
        colorScheme: ColorScheme.dark(
          primary: popPrimaryNotifier.value,
          secondary: popSecondaryNotifier.value,
          surface: popBgNotifier.value,
          outline: popBorderNotifier.value,
        ),
      );
    }

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF090212),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFE6007E),
        secondary: Color(0xFF673AB7),
        surface: Color(0xFF17092C),
        outline: Color(0xFFE6007E),
      ),
    );
  }
}
