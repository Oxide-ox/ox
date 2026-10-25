import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

// =============================================================================
// 1. EXTENSION & HELPER RGB COLOR
// =============================================================================
extension ColorRgbUtils on Color {
  static Color fromRgb(int r, int g, int b, [double opacity = 1.0]) {
    return Color.fromRGBO(
      r.clamp(0, 255),
      g.clamp(0, 255),
      b.clamp(0, 255),
      opacity.clamp(0.0, 1.0),
    );
  }

  Map<String, dynamic> toRgbMap() {
    return {
      'r': red,
      'g': green,
      'b': blue,
      'a': alpha,
      'opacity': opacity,
    };
  }

  String toRgbString() => 'rgb($red, $green, $blue)';
  String toRgbaString() => 'rgba($red, $green, $blue, ${opacity.toStringAsFixed(2)})';
}

// =============================================================================
// 2. VALUE NOTIFIERS UNTUK TEMA & WARNA (0 - 5)
// =============================================================================
final ValueNotifier<int> themeModeNotifier = ValueNotifier<int>(0);

// --- Mode 0: Default / Cyberpunk Notifiers ---
final ValueNotifier<Color> defaultBgNotifier = ValueNotifier<Color>(const Color(0xFF090212));
final ValueNotifier<Color> defaultPrimaryNotifier = ValueNotifier<Color>(const Color(0xFFE6007E));
final ValueNotifier<Color> defaultSecondaryNotifier = ValueNotifier<Color>(const Color(0xFF673AB7));
final ValueNotifier<Color> defaultBorderNotifier = ValueNotifier<Color>(const Color(0xFFE6007E));
final ValueNotifier<Color> defaultTextPrimaryNotifier = ValueNotifier<Color>(const Color(0xFFFFFFFF));
final ValueNotifier<Color> defaultTextSecondaryNotifier = ValueNotifier<Color>(const Color(0xB3FFFFFF));

// --- Mode 1: Neo Brutalist Notifiers ---
final ValueNotifier<Color> neoBgNotifier = ValueNotifier<Color>(const Color(0xFF0F0A1C));
final ValueNotifier<Color> neoPrimaryNotifier = ValueNotifier<Color>(const Color(0xFFFF2B7A));
final ValueNotifier<Color> neoSecondaryNotifier = ValueNotifier<Color>(const Color(0xFFFFE600));
final ValueNotifier<Color> neoBorderNotifier = ValueNotifier<Color>(const Color(0xFF000000));
final ValueNotifier<Color> neoTextPrimaryNotifier = ValueNotifier<Color>(const Color(0xFFFFFFFF));
final ValueNotifier<Color> neoTextSecondaryNotifier = ValueNotifier<Color>(const Color(0xB3FFFFFF));

// --- Mode 2: PopArt Notifiers ---
final ValueNotifier<Color> popBgNotifier = ValueNotifier<Color>(const Color(0xFF180161));
final ValueNotifier<Color> popPrimaryNotifier = ValueNotifier<Color>(const Color(0xFF00E5FF));
final ValueNotifier<Color> popSecondaryNotifier = ValueNotifier<Color>(const Color(0xFFEC4899));
final ValueNotifier<Color> popBorderNotifier = ValueNotifier<Color>(const Color(0xFFFFFFFF));
final ValueNotifier<Color> popTextPrimaryNotifier = ValueNotifier<Color>(const Color(0xFFFFFFFF));
final ValueNotifier<Color> popTextSecondaryNotifier = ValueNotifier<Color>(const Color(0xB3FFFFFF));

// --- Mode 3: 3D Holographic UI Notifiers ---
final ValueNotifier<Color> holoBgNotifier = ValueNotifier<Color>(const Color(0xFF051129));
final ValueNotifier<Color> holoPrimaryNotifier = ValueNotifier<Color>(const Color(0xFF00F0FF));
final ValueNotifier<Color> holoSecondaryNotifier = ValueNotifier<Color>(const Color(0xFF7B2CBF));
final ValueNotifier<Color> holoBorderNotifier = ValueNotifier<Color>(const Color(0x8000F0FF));
final ValueNotifier<Color> holoTextPrimaryNotifier = ValueNotifier<Color>(const Color(0xFFFFFFFF));
final ValueNotifier<Color> holoTextSecondaryNotifier = ValueNotifier<Color>(const Color(0xB380E0FF));

// --- Mode 4: Retro Futurism Notifiers ---
final ValueNotifier<Color> retroBgNotifier = ValueNotifier<Color>(const Color(0xFF1A0B2E));
final ValueNotifier<Color> retroPrimaryNotifier = ValueNotifier<Color>(const Color(0xFFFF007F));
final ValueNotifier<Color> retroSecondaryNotifier = ValueNotifier<Color>(const Color(0xFFFF9900));
final ValueNotifier<Color> retroBorderNotifier = ValueNotifier<Color>(const Color(0xFF9D4EDD));
final ValueNotifier<Color> retroTextPrimaryNotifier = ValueNotifier<Color>(const Color(0xFFFFF0F5));
final ValueNotifier<Color> retroTextSecondaryNotifier = ValueNotifier<Color>(const Color(0xB3FFB7C5));

// --- Mode 5: Style Komik / Comic Book Notifiers ---
final ValueNotifier<Color> comicBgNotifier = ValueNotifier<Color>(const Color(0xFF181818));
final ValueNotifier<Color> comicPrimaryNotifier = ValueNotifier<Color>(const Color(0xFFFFD700));
final ValueNotifier<Color> comicSecondaryNotifier = ValueNotifier<Color>(const Color(0xFFFF2A2A));
final ValueNotifier<Color> comicBorderNotifier = ValueNotifier<Color>(const Color(0xFFFFFFFF));
final ValueNotifier<Color> comicTextPrimaryNotifier = ValueNotifier<Color>(const Color(0xFFFFFFFF));
final ValueNotifier<Color> comicTextSecondaryNotifier = ValueNotifier<Color>(const Color(0xB3CCCCCC));

// =============================================================================
// 3. BACKGROUND NOTIFIER (Custom Gambar, Video, & Warna Solid)
// =============================================================================
enum BgType { color, image, video }

class BgConfig {
  final BgType type;
  final String? path;

  BgConfig({required this.type, this.path});
}

class BackgroundNotifier extends ValueNotifier<BgConfig> {
  BackgroundNotifier() : super(BgConfig(type: BgType.color));

  Future<void> loadBackground() async {
    final prefs = await SharedPreferences.getInstance();
    final typeIndex = prefs.getInt('bg_type') ?? 0;
    final path = prefs.getString('bg_path');

    value = BgConfig(
      type: BgType.values[typeIndex],
      path: path,
    );
  }

  Future<void> setSolidColor() async {
    value = BgConfig(type: BgType.color);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('bg_type', BgType.color.index);
    await prefs.remove('bg_path');
  }

  Future<void> setCustomImage(String path) async {
    value = BgConfig(type: BgType.image, path: path);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('bg_type', BgType.image.index);
    await prefs.setString('bg_path', path);
  }

  Future<void> setCustomVideo(String path) async {
    value = BgConfig(type: BgType.video, path: path);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('bg_type', BgType.video.index);
    await prefs.setString('bg_path', path);
  }
}

final backgroundNotifier = BackgroundNotifier();

// =============================================================================
// 4. DYNAMIC DASHBOARD LAYOUT NOTIFIER (Bisa Geser Kotak & Toggle On/Off)
// =============================================================================
class LayoutItem {
  final String id;
  final String title;
  final IconData icon;
  bool isVisible;

  LayoutItem({
    required this.id,
    required this.title,
    required this.icon,
    this.isVisible = true,
  });
}

class DashboardLayoutNotifier extends ValueNotifier<List<LayoutItem>> {
  static final List<LayoutItem> _defaultLayout = [
    LayoutItem(id: 'story', title: 'Story Section', icon: Icons.history_edu_rounded),
    LayoutItem(id: 'news_carousel', title: 'Banner News Carousel', icon: Icons.view_carousel_rounded),
    LayoutItem(id: 'user_card', title: 'User Profile Card', icon: Icons.badge_rounded),
    LayoutItem(id: 'quick_actions', title: 'Quick Actions Bar', icon: Icons.bolt_rounded),
    LayoutItem(id: 'feature_grid', title: '4 Feature Grid (Oxfy, NF, AM, Spam)', icon: Icons.grid_view_rounded),
    LayoutItem(id: 'kompas_news', title: 'Berita Kompas Auto Update', icon: Icons.newspaper_rounded),
    LayoutItem(id: 'bottom_cards', title: 'Channel Info & Tq To Cards', icon: Icons.web_rounded),
  ];

  DashboardLayoutNotifier() : super(List.from(_defaultLayout));

  Future<void> loadLayout() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedOrder = prefs.getString('dashboard_layout_order');
    final String? savedVisibility = prefs.getString('dashboard_layout_visibility');

    if (savedOrder != null) {
      List<String> orderList = List<String>.from(jsonDecode(savedOrder));
      Map<String, bool> visibilityMap = savedVisibility != null
          ? Map<String, bool>.from(jsonDecode(savedVisibility))
          : {};

      List<LayoutItem> newList = [];
      for (String id in orderList) {
        final defaultItem = _defaultLayout.firstWhere(
          (item) => item.id == id,
          orElse: () => LayoutItem(id: id, title: id, icon: Icons.widgets_rounded),
        );
        defaultItem.isVisible = visibilityMap[id] ?? true;
        newList.add(defaultItem);
      }

      for (var defItem in _defaultLayout) {
        if (!newList.any((element) => element.id == defItem.id)) {
          newList.add(defItem);
        }
      }

      value = newList;
    }
  }

  Future<void> _saveLayout() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> orderList = value.map((e) => e.id).toList();
    Map<String, bool> visibilityMap = {for (var e in value) e.id: e.isVisible};

    await prefs.setString('dashboard_layout_order', jsonEncode(orderList));
    await prefs.setString('dashboard_layout_visibility', jsonEncode(visibilityMap));
  }

  void reorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final List<LayoutItem> list = List.from(value);
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    value = list;
    _saveLayout();
  }

  void toggleVisibility(String id) {
    final List<LayoutItem> list = List.from(value);
    final index = list.indexWhere((item) => item.id == id);
    if (index != -1) {
      list[index].isVisible = !list[index].isVisible;
      value = list;
      _saveLayout();
    }
  }

  void resetLayout() {
    value = List.from(_defaultLayout.map((e) => LayoutItem(
          id: e.id,
          title: e.title,
          icon: e.icon,
          isVisible: true,
        )));
    _saveLayout();
  }
}

final dashboardLayoutNotifier = DashboardLayoutNotifier();

// =============================================================================
// 5. CLASS UTAMA APPTHEME
// =============================================================================
class AppTheme {
  static bool _isInitializing = false;

  static Future<void> init() async {
    _isInitializing = true;
    final prefs = await SharedPreferences.getInstance();

    themeModeNotifier.value = prefs.getInt('theme_mode') ?? 0;

    await backgroundNotifier.loadBackground();
    await dashboardLayoutNotifier.loadLayout();

    // Default
    defaultBgNotifier.value = Color(prefs.getInt('default_bg') ?? 0xFF090212);
    defaultPrimaryNotifier.value = Color(prefs.getInt('default_primary') ?? 0xFFE6007E);
    defaultSecondaryNotifier.value = Color(prefs.getInt('default_secondary') ?? 0xFF673AB7);
    defaultBorderNotifier.value = Color(prefs.getInt('default_border') ?? 0xFFE6007E);
    defaultTextPrimaryNotifier.value = Color(prefs.getInt('default_text_primary') ?? 0xFFFFFFFF);
    defaultTextSecondaryNotifier.value = Color(prefs.getInt('default_text_secondary') ?? 0xB3FFFFFF);

    // Neo
    neoBgNotifier.value = Color(prefs.getInt('neo_bg') ?? 0xFF0F0A1C);
    neoPrimaryNotifier.value = Color(prefs.getInt('neo_primary') ?? 0xFFFF2B7A);
    neoSecondaryNotifier.value = Color(prefs.getInt('neo_secondary') ?? 0xFFFFE600);
    neoBorderNotifier.value = Color(prefs.getInt('neo_border') ?? 0xFF000000);
    neoTextPrimaryNotifier.value = Color(prefs.getInt('neo_text_primary') ?? 0xFFFFFFFF);
    neoTextSecondaryNotifier.value = Color(prefs.getInt('neo_text_secondary') ?? 0xB3FFFFFF);

    // PopArt
    popBgNotifier.value = Color(prefs.getInt('pop_bg') ?? 0xFF180161);
    popPrimaryNotifier.value = Color(prefs.getInt('pop_primary') ?? 0xFF00E5FF);
    popSecondaryNotifier.value = Color(prefs.getInt('pop_secondary') ?? 0xFFEC4899);
    popBorderNotifier.value = Color(prefs.getInt('pop_border') ?? 0xFFFFFFFF);
    popTextPrimaryNotifier.value = Color(prefs.getInt('pop_text_primary') ?? 0xFFFFFFFF);
    popTextSecondaryNotifier.value = Color(prefs.getInt('pop_text_secondary') ?? 0xB3FFFFFF);

    // Holographic
    holoBgNotifier.value = Color(prefs.getInt('holo_bg') ?? 0xFF051129);
    holoPrimaryNotifier.value = Color(prefs.getInt('holo_primary') ?? 0xFF00F0FF);
    holoSecondaryNotifier.value = Color(prefs.getInt('holo_secondary') ?? 0xFF7B2CBF);
    holoBorderNotifier.value = Color(prefs.getInt('holo_border') ?? 0x8000F0FF);
    holoTextPrimaryNotifier.value = Color(prefs.getInt('holo_text_primary') ?? 0xFFFFFFFF);
    holoTextSecondaryNotifier.value = Color(prefs.getInt('holo_text_secondary') ?? 0xB380E0FF);

    // Retro
    retroBgNotifier.value = Color(prefs.getInt('retro_bg') ?? 0xFF1A0B2E);
    retroPrimaryNotifier.value = Color(prefs.getInt('retro_primary') ?? 0xFFFF007F);
    retroSecondaryNotifier.value = Color(prefs.getInt('retro_secondary') ?? 0xFFFF9900);
    retroBorderNotifier.value = Color(prefs.getInt('retro_border') ?? 0xFF9D4EDD);
    retroTextPrimaryNotifier.value = Color(prefs.getInt('retro_text_primary') ?? 0xFFFFF0F5);
    retroTextSecondaryNotifier.value = Color(prefs.getInt('retro_text_secondary') ?? 0xB3FFB7C5);

    // Comic
    comicBgNotifier.value = Color(prefs.getInt('comic_bg') ?? 0xFF181818);
    comicPrimaryNotifier.value = Color(prefs.getInt('comic_primary') ?? 0xFFFFD700);
    comicSecondaryNotifier.value = Color(prefs.getInt('comic_secondary') ?? 0xFFFF2A2A);
    comicBorderNotifier.value = Color(prefs.getInt('comic_border') ?? 0xFFFFFFFF);
    comicTextPrimaryNotifier.value = Color(prefs.getInt('comic_text_primary') ?? 0xFFFFFFFF);
    comicTextSecondaryNotifier.value = Color(prefs.getInt('comic_text_secondary') ?? 0xB3CCCCCC);

    _isInitializing = false;

    themeModeNotifier.addListener(_saveThemePreferences);

    defaultBgNotifier.addListener(_saveThemePreferences);
    defaultPrimaryNotifier.addListener(_saveThemePreferences);
    defaultSecondaryNotifier.addListener(_saveThemePreferences);
    defaultBorderNotifier.addListener(_saveThemePreferences);
    defaultTextPrimaryNotifier.addListener(_saveThemePreferences);
    defaultTextSecondaryNotifier.addListener(_saveThemePreferences);

    neoBgNotifier.addListener(_saveThemePreferences);
    neoPrimaryNotifier.addListener(_saveThemePreferences);
    neoSecondaryNotifier.addListener(_saveThemePreferences);
    neoBorderNotifier.addListener(_saveThemePreferences);
    neoTextPrimaryNotifier.addListener(_saveThemePreferences);
    neoTextSecondaryNotifier.addListener(_saveThemePreferences);

    popBgNotifier.addListener(_saveThemePreferences);
    popPrimaryNotifier.addListener(_saveThemePreferences);
    popSecondaryNotifier.addListener(_saveThemePreferences);
    popBorderNotifier.addListener(_saveThemePreferences);
    popTextPrimaryNotifier.addListener(_saveThemePreferences);
    popTextSecondaryNotifier.addListener(_saveThemePreferences);

    holoBgNotifier.addListener(_saveThemePreferences);
    holoPrimaryNotifier.addListener(_saveThemePreferences);
    holoSecondaryNotifier.addListener(_saveThemePreferences);
    holoBorderNotifier.addListener(_saveThemePreferences);
    holoTextPrimaryNotifier.addListener(_saveThemePreferences);
    holoTextSecondaryNotifier.addListener(_saveThemePreferences);

    retroBgNotifier.addListener(_saveThemePreferences);
    retroPrimaryNotifier.addListener(_saveThemePreferences);
    retroSecondaryNotifier.addListener(_saveThemePreferences);
    retroBorderNotifier.addListener(_saveThemePreferences);
    retroTextPrimaryNotifier.addListener(_saveThemePreferences);
    retroTextSecondaryNotifier.addListener(_saveThemePreferences);

    comicBgNotifier.addListener(_saveThemePreferences);
    comicPrimaryNotifier.addListener(_saveThemePreferences);
    comicSecondaryNotifier.addListener(_saveThemePreferences);
    comicBorderNotifier.addListener(_saveThemePreferences);
    comicTextPrimaryNotifier.addListener(_saveThemePreferences);
    comicTextSecondaryNotifier.addListener(_saveThemePreferences);
  }

  static Future<void> _saveThemePreferences() async {
    if (_isInitializing) return;
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt('theme_mode', themeModeNotifier.value);

    await prefs.setInt('default_bg', defaultBgNotifier.value.value);
    await prefs.setInt('default_primary', defaultPrimaryNotifier.value.value);
    await prefs.setInt('default_secondary', defaultSecondaryNotifier.value.value);
    await prefs.setInt('default_border', defaultBorderNotifier.value.value);
    await prefs.setInt('default_text_primary', defaultTextPrimaryNotifier.value.value);
    await prefs.setInt('default_text_secondary', defaultTextSecondaryNotifier.value.value);

    await prefs.setInt('neo_bg', neoBgNotifier.value.value);
    await prefs.setInt('neo_primary', neoPrimaryNotifier.value.value);
    await prefs.setInt('neo_secondary', neoSecondaryNotifier.value.value);
    await prefs.setInt('neo_border', neoBorderNotifier.value.value);
    await prefs.setInt('neo_text_primary', neoTextPrimaryNotifier.value.value);
    await prefs.setInt('neo_text_secondary', neoTextSecondaryNotifier.value.value);

    await prefs.setInt('pop_bg', popBgNotifier.value.value);
    await prefs.setInt('pop_primary', popPrimaryNotifier.value.value);
    await prefs.setInt('pop_secondary', popSecondaryNotifier.value.value);
    await prefs.setInt('pop_border', popBorderNotifier.value.value);
    await prefs.setInt('pop_text_primary', popTextPrimaryNotifier.value.value);
    await prefs.setInt('pop_text_secondary', popTextSecondaryNotifier.value.value);

    await prefs.setInt('holo_bg', holoBgNotifier.value.value);
    await prefs.setInt('holo_primary', holoPrimaryNotifier.value.value);
    await prefs.setInt('holo_secondary', holoSecondaryNotifier.value.value);
    await prefs.setInt('holo_border', holoBorderNotifier.value.value);
    await prefs.setInt('holo_text_primary', holoTextPrimaryNotifier.value.value);
    await prefs.setInt('holo_text_secondary', holoTextSecondaryNotifier.value.value);

    await prefs.setInt('retro_bg', retroBgNotifier.value.value);
    await prefs.setInt('retro_primary', retroPrimaryNotifier.value.value);
    await prefs.setInt('retro_secondary', retroSecondaryNotifier.value.value);
    await prefs.setInt('retro_border', retroBorderNotifier.value.value);
    await prefs.setInt('retro_text_primary', retroTextPrimaryNotifier.value.value);
    await prefs.setInt('retro_text_secondary', retroTextSecondaryNotifier.value.value);

    await prefs.setInt('comic_bg', comicBgNotifier.value.value);
    await prefs.setInt('comic_primary', comicPrimaryNotifier.value.value);
    await prefs.setInt('comic_secondary', comicSecondaryNotifier.value.value);
    await prefs.setInt('comic_border', comicBorderNotifier.value.value);
    await prefs.setInt('comic_text_primary', comicTextPrimaryNotifier.value.value);
    await prefs.setInt('comic_text_secondary', comicTextSecondaryNotifier.value.value);
  }

  static void setRgbColor(ValueNotifier<Color> notifier, int r, int g, int b, [double opacity = 1.0]) {
    notifier.value = ColorRgbUtils.fromRgb(r, g, b, opacity);
    themeModeNotifier.notifyListeners();
  }

  static void applyNeoPreset({required bool isDark}) {
    if (isDark) {
      neoBgNotifier.value = const Color(0xFF0F0A1C);
      neoPrimaryNotifier.value = const Color(0xFFFF2B7A);
      neoSecondaryNotifier.value = const Color(0xFFFFE600);
      neoBorderNotifier.value = const Color(0xFF000000);
      neoTextPrimaryNotifier.value = const Color(0xFFFFFFFF);
      neoTextSecondaryNotifier.value = const Color(0xB3FFFFFF);
    } else {
      neoBgNotifier.value = const Color(0xFFFEFCE8);
      neoPrimaryNotifier.value = const Color(0xFFFF0055);
      neoSecondaryNotifier.value = const Color(0xFF00E5FF);
      neoBorderNotifier.value = const Color(0xFF000000);
      neoTextPrimaryNotifier.value = const Color(0xFF000000);
      neoTextSecondaryNotifier.value = const Color(0x99000000);
    }
    themeModeNotifier.notifyListeners();
  }

  static void applyPopArtPreset({required bool isDark}) {
    if (isDark) {
      popBgNotifier.value = const Color(0xFF180161);
      popPrimaryNotifier.value = const Color(0xFF00E5FF);
      popSecondaryNotifier.value = const Color(0xFFEC4899);
      popBorderNotifier.value = const Color(0xFFFFFFFF);
      popTextPrimaryNotifier.value = const Color(0xFFFFFFFF);
      popTextSecondaryNotifier.value = const Color(0xB3FFFFFF);
    } else {
      popBgNotifier.value = const Color(0xFFFFF5F5);
      popPrimaryNotifier.value = const Color(0xFFA855F7);
      popSecondaryNotifier.value = const Color(0xFF86EFAC);
      popBorderNotifier.value = const Color(0xFF18181B);
      popTextPrimaryNotifier.value = const Color(0xFF18181B);
      popTextSecondaryNotifier.value = const Color(0x9918181B);
    }
    themeModeNotifier.notifyListeners();
  }

  static void applyHoloPreset({required bool isDark}) {
    if (isDark) {
      holoBgNotifier.value = const Color(0xFF051129);
      holoPrimaryNotifier.value = const Color(0xFF00F0FF);
      holoSecondaryNotifier.value = const Color(0xFF7B2CBF);
      holoBorderNotifier.value = const Color(0x8000F0FF);
      holoTextPrimaryNotifier.value = const Color(0xFFFFFFFF);
      holoTextSecondaryNotifier.value = const Color(0xB380E0FF);
    } else {
      holoBgNotifier.value = const Color(0xFFE0F7FA);
      holoPrimaryNotifier.value = const Color(0xFF00838F);
      holoSecondaryNotifier.value = const Color(0xFF8E24AA);
      holoBorderNotifier.value = const Color(0xFF00838F);
      holoTextPrimaryNotifier.value = const Color(0xFF00363A);
      holoTextSecondaryNotifier.value = const Color(0x99006064);
    }
    themeModeNotifier.notifyListeners();
  }

  static void applyRetroPreset({required bool isDark}) {
    if (isDark) {
      retroBgNotifier.value = const Color(0xFF1A0B2E);
      retroPrimaryNotifier.value = const Color(0xFFFF007F);
      retroSecondaryNotifier.value = const Color(0xFFFF9900);
      retroBorderNotifier.value = const Color(0xFF9D4EDD);
      retroTextPrimaryNotifier.value = const Color(0xFFFFF0F5);
      retroTextSecondaryNotifier.value = const Color(0xB3FFB7C5);
    } else {
      retroBgNotifier.value = const Color(0xFFFFF0F5);
      retroPrimaryNotifier.value = const Color(0xFFD80067);
      retroSecondaryNotifier.value = const Color(0xFFE65100);
      retroBorderNotifier.value = const Color(0xFF7B2CBF);
      retroTextPrimaryNotifier.value = const Color(0xFF2A002A);
      retroTextSecondaryNotifier.value = const Color(0x995C005C);
    }
    themeModeNotifier.notifyListeners();
  }

  static void applyComicPreset({required bool isDark}) {
    if (isDark) {
      comicBgNotifier.value = const Color(0xFF181818);
      comicPrimaryNotifier.value = const Color(0xFFFFD700);
      comicSecondaryNotifier.value = const Color(0xFFFF2A2A);
      comicBorderNotifier.value = const Color(0xFFFFFFFF);
      comicTextPrimaryNotifier.value = const Color(0xFFFFFFFF);
      comicTextSecondaryNotifier.value = const Color(0xB3CCCCCC);
    } else {
      comicBgNotifier.value = const Color(0xFFFFFDF0);
      comicPrimaryNotifier.value = const Color(0xFFFFCC00);
      comicSecondaryNotifier.value = const Color(0xFFE60000);
      comicBorderNotifier.value = const Color(0xFF000000);
      comicTextPrimaryNotifier.value = const Color(0xFF000000);
      comicTextSecondaryNotifier.value = const Color(0x99333333);
    }
    themeModeNotifier.notifyListeners();
  }

  static ThemeData get currentTheme {
    final mode = themeModeNotifier.value;

    Color bg, primary, secondary, border, textPrimary, textSecondary;

    if (mode == 1) {
      bg = neoBgNotifier.value;
      primary = neoPrimaryNotifier.value;
      secondary = neoSecondaryNotifier.value;
      border = neoBorderNotifier.value;
      textPrimary = neoTextPrimaryNotifier.value;
      textSecondary = neoTextSecondaryNotifier.value;
    } else if (mode == 2) {
      bg = popBgNotifier.value;
      primary = popPrimaryNotifier.value;
      secondary = popSecondaryNotifier.value;
      border = popBorderNotifier.value;
      textPrimary = popTextPrimaryNotifier.value;
      textSecondary = popTextSecondaryNotifier.value;
    } else if (mode == 3) {
      bg = holoBgNotifier.value;
      primary = holoPrimaryNotifier.value;
      secondary = holoSecondaryNotifier.value;
      border = holoBorderNotifier.value;
      textPrimary = holoTextPrimaryNotifier.value;
      textSecondary = holoTextSecondaryNotifier.value;
    } else if (mode == 4) {
      bg = retroBgNotifier.value;
      primary = retroPrimaryNotifier.value;
      secondary = retroSecondaryNotifier.value;
      border = retroBorderNotifier.value;
      textPrimary = retroTextPrimaryNotifier.value;
      textSecondary = retroTextSecondaryNotifier.value;
    } else if (mode == 5) {
      bg = comicBgNotifier.value;
      primary = comicPrimaryNotifier.value;
      secondary = comicSecondaryNotifier.value;
      border = comicBorderNotifier.value;
      textPrimary = comicTextPrimaryNotifier.value;
      textSecondary = comicTextSecondaryNotifier.value;
    } else {
      bg = defaultBgNotifier.value;
      primary = defaultPrimaryNotifier.value;
      secondary = defaultSecondaryNotifier.value;
      border = defaultBorderNotifier.value;
      textPrimary = defaultTextPrimaryNotifier.value;
      textSecondary = defaultTextSecondaryNotifier.value;
    }

    final isLight = bg.computeLuminance() > 0.5;

    return ThemeData(
      brightness: isLight ? Brightness.light : Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme(
        brightness: isLight ? Brightness.light : Brightness.dark,
        primary: primary,
        secondary: secondary,
        surface: bg,
        outline: border,
        onPrimary: isLight ? Colors.black : Colors.white,
        onSecondary: isLight ? Colors.black : Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
        error: Colors.redAccent,
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: textPrimary),
        bodyMedium: TextStyle(color: textSecondary),
        bodySmall: TextStyle(color: textSecondary),
        titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        titleSmall: TextStyle(color: textSecondary),
        labelLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
      ),
      iconTheme: IconThemeData(color: primary),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: primary),
        titleTextStyle: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: bg,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
      ),
      cardColor: bg,
      dialogBackgroundColor: bg,
    );
  }
}

// =============================================================================
// 6. WIDGET PEMBUNGKUS UTAMA (BACKGROUND WRAPPER)
// =============================================================================
class BackgroundWrapper extends StatelessWidget {
  final Widget child;
  final double overlayOpacity;

  const BackgroundWrapper({
    super.key,
    required this.child,
    this.overlayOpacity = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder<BgConfig>(
      valueListenable: backgroundNotifier,
      builder: (context, bgConfig, _) {
        return Stack(
          children: [
            Positioned.fill(
              child: _buildBackgroundWidget(bgConfig, theme.scaffoldBackgroundColor),
            ),
            if (bgConfig.type != BgType.color)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(overlayOpacity),
                ),
              ),
            Positioned.fill(child: child),
          ],
        );
      },
    );
  }

  Widget _buildBackgroundWidget(BgConfig config, Color fallbackColor) {
    if (config.type == BgType.image && config.path != null && File(config.path!).existsSync()) {
      return Image.file(
        File(config.path!),
        fit: BoxFit.cover,
      );
    }

    if (config.type == BgType.video && config.path != null && File(config.path!).existsSync()) {
      return BackgroundVideoPlayer(videoPath: config.path!);
    }

    return Container(color: fallbackColor);
  }
}

class BackgroundVideoPlayer extends StatefulWidget {
  final String videoPath;

  const BackgroundVideoPlayer({super.key, required this.videoPath});

  @override
  State<BackgroundVideoPlayer> createState() => _BackgroundVideoPlayerState();
}

class _BackgroundVideoPlayerState extends State<BackgroundVideoPlayer> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  @override
  void didUpdateWidget(covariant BackgroundVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoPath != widget.videoPath) {
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    _controller?.dispose();
    _controller = VideoPlayerController.file(File(widget.videoPath));

    try {
      await _controller!.initialize();
      _controller!.setLooping(true);
      _controller!.setVolume(0.0);
      _controller!.play();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Error init bg video: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller != null && _controller!.value.isInitialized) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller!.value.size.width,
          height: _controller!.value.size.height,
          child: VideoPlayer(_controller!),
        ),
      );
    }
    return Container(color: Colors.black);
  }
}

// =============================================================================
// 7. WIDGET BOTTOMSHEET LAYOUT SETTINGS (Drag & Drop Kotak)
// =============================================================================
class LayoutSettingsSheet extends StatelessWidget {
  const LayoutSettingsSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LayoutSettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNeo = themeModeNotifier.value != 0;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(
          color: isNeo ? Colors.black : theme.colorScheme.primary,
          width: isNeo ? 3 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.dashboard_customize_rounded, color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  Text(
                    "KUSTOMISASI LAYOUT UI",
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => dashboardLayoutNotifier.resetLayout(),
                child: const Text("RESET", style: TextStyle(color: Colors.redAccent, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Tahan & geser ikon handler untuk memindahkan posisi kotak. Matikan switch jika tidak ingin menampilkan kotak.",
            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 11),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ValueListenableBuilder<List<LayoutItem>>(
              valueListenable: dashboardLayoutNotifier,
              builder: (context, layoutItems, _) {
                return ReorderableListView.builder(
                  itemCount: layoutItems.length,
                  onReorder: (oldIndex, newIndex) {
                    dashboardLayoutNotifier.reorder(oldIndex, newIndex);
                  },
                  itemBuilder: (context, index) {
                    final item = layoutItems[index];

                    return Container(
                      key: ValueKey(item.id),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(isNeo ? 4 : 12),
                        border: Border.all(
                          color: isNeo ? Colors.black : theme.colorScheme.primary.withOpacity(0.3),
                          width: isNeo ? 2 : 1,
                        ),
                      ),
                      child: ListTile(
                        leading: Icon(item.icon, color: theme.colorScheme.primary),
                        title: Text(
                          item.title,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: item.isVisible,
                              activeColor: theme.colorScheme.primary,
                              onChanged: (_) {
                                dashboardLayoutNotifier.toggleVisibility(item.id);
                              },
                            ),
                            ReorderableDragStartListener(
                              index: index,
                              child: const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Icon(Icons.drag_handle_rounded, color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
