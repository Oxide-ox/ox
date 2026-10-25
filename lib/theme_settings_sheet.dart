import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'app_theme.dart';

class ThemeSettingsSheet extends StatefulWidget {
  const ThemeSettingsSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ThemeSettingsSheet(),
    );
  }

  @override
  State<ThemeSettingsSheet> createState() => _ThemeSettingsSheetState();
}

class _ThemeSettingsSheetState extends State<ThemeSettingsSheet> {
  final Color _bgOriginal = const Color(0xFF090212);
  final Color _cardOriginal = const Color(0xFF17092C);
  final Color _neonPink = const Color(0xFFE6007E);

  final ImagePicker _picker = ImagePicker();

  // Mapping Notifier Warna Berdasarkan Mode Tema Aktif (1 - 5)
  ValueNotifier<Color>? _getBgNotifier(int mode) {
    switch (mode) {
      case 1:
        return neoBgNotifier;
      case 2:
        return popBgNotifier;
      case 3:
        return holoBgNotifier;
      case 4:
        return retroBgNotifier;
      case 5:
        return comicBgNotifier;
      default:
        return null;
    }
  }

  ValueNotifier<Color>? _getPrimaryNotifier(int mode) {
    switch (mode) {
      case 1:
        return neoPrimaryNotifier;
      case 2:
        return popPrimaryNotifier;
      case 3:
        return holoPrimaryNotifier;
      case 4:
        return retroPrimaryNotifier;
      case 5:
        return comicPrimaryNotifier;
      default:
        return null;
    }
  }

  ValueNotifier<Color>? _getSecondaryNotifier(int mode) {
    switch (mode) {
      case 1:
        return neoSecondaryNotifier;
      case 2:
        return popSecondaryNotifier;
      case 3:
        return holoSecondaryNotifier;
      case 4:
        return retroSecondaryNotifier;
      case 5:
        return comicSecondaryNotifier;
      default:
        return null;
    }
  }

  ValueNotifier<Color>? _getBorderNotifier(int mode) {
    switch (mode) {
      case 1:
        return neoBorderNotifier;
      case 2:
        return popBorderNotifier;
      case 3:
        return holoBorderNotifier;
      case 4:
        return retroBorderNotifier;
      case 5:
        return comicBorderNotifier;
      default:
        return null;
    }
  }

  void _applyPreset(int mode, bool isDark) {
    switch (mode) {
      case 1:
        AppTheme.applyNeoPreset(isDark: isDark);
        break;
      case 2:
        AppTheme.applyPopArtPreset(isDark: isDark);
        break;
      case 3:
        AppTheme.applyHoloPreset(isDark: isDark);
        break;
      case 4:
        AppTheme.applyRetroPreset(isDark: isDark);
        break;
      case 5:
        AppTheme.applyComicPreset(isDark: isDark);
        break;
    }
  }

  String _getModeName(int mode) {
    switch (mode) {
      case 0:
        return "ORIGINAL CYBERPUNK";
      case 1:
        return "NEO BRUTALISM";
      case 2:
        return "POP ART";
      case 3:
        return "3D HOLOGRAPHIC";
      case 4:
        return "RETRO FUTURISM";
      case 5:
        return "STYLE KOMIK";
      default:
        return "CUSTOM";
    }
  }

  void _pickColor(String title, Color currentColor, Function(Color) onColorSelected) {
    showDialog(
      context: context,
      builder: (_) => CustomColorPickerDialog(
        initialColor: currentColor,
        onColorSelected: (col) {
          onColorSelected(col);
          setState(() {});
          themeModeNotifier.notifyListeners();
        },
      ),
    );
  }

  Future<void> _pickBgImage() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file != null) {
      await backgroundNotifier.setCustomImage(file.path);
      setState(() {});
    }
  }

  Future<void> _pickBgVideo() async {
    final XFile? file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file != null) {
      await backgroundNotifier.setCustomVideo(file.path);
      setState(() {});
    }
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    final currentMode = themeModeNotifier.value;
    final bgNotifierVal = _getBgNotifier(currentMode);
    final primaryNotifierVal = _getPrimaryNotifier(currentMode);
    final secondaryNotifierVal = _getSecondaryNotifier(currentMode);
    final borderNotifierVal = _getBorderNotifier(currentMode);

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: _bgOriginal,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: _neonPink.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Handle Bar Top
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.palette_rounded, color: _neonPink, size: 22),
              const SizedBox(width: 8),
              const Text(
                "PENGATURAN TEMA",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SECTION 1: MODE TAMPILAN (6 MODE)
                  _buildSectionHeader("MODE TAMPILAN (6 TEMA)", "Pilih tema aplikasi yang Anda sukai"),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 80,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildThemeCard(
                          title: "1. Original",
                          subtitle: "Cyberpunk Classic",
                          isSelected: currentMode == 0,
                          onTap: () {
                            setState(() => themeModeNotifier.value = 0);
                            themeModeNotifier.notifyListeners();
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildThemeCard(
                          title: "2. Neo Brutalism",
                          subtitle: "Tegeh & Kontras",
                          isSelected: currentMode == 1,
                          onTap: () {
                            setState(() => themeModeNotifier.value = 1);
                            themeModeNotifier.notifyListeners();
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildThemeCard(
                          title: "3. Pop Art",
                          subtitle: "Warna Cerah",
                          isSelected: currentMode == 2,
                          onTap: () {
                            setState(() => themeModeNotifier.value = 2);
                            themeModeNotifier.notifyListeners();
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildThemeCard(
                          title: "4. 3D Holo",
                          subtitle: "Cyan & Futuristic",
                          isSelected: currentMode == 3,
                          onTap: () {
                            setState(() => themeModeNotifier.value = 3);
                            themeModeNotifier.notifyListeners();
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildThemeCard(
                          title: "5. Retro Future",
                          subtitle: "80s Synthwave",
                          isSelected: currentMode == 4,
                          onTap: () {
                            setState(() => themeModeNotifier.value = 4);
                            themeModeNotifier.notifyListeners();
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildThemeCard(
                          title: "6. Style Komik",
                          subtitle: "Bold & Vibrant",
                          isSelected: currentMode == 5,
                          onTap: () {
                            setState(() => themeModeNotifier.value = 5);
                            themeModeNotifier.notifyListeners();
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // SECTION 2: KUSTOMISASI BACKGROUND (SOLID / GAMBAR / VIDEO)
                  _buildSectionHeader("LATAR BELAKANG KUSTOM (BACKGROUND)", "Pilih warna solid, gambar galeri, atau video"),
                  const SizedBox(height: 12),
                  ValueListenableBuilder<BgConfig>(
                    valueListenable: backgroundNotifier,
                    builder: (context, bgConfig, _) {
                      return Row(
                        children: [
                          Expanded(
                            child: _buildBgOptionBtn(
                              label: "Warna Solid",
                              icon: Icons.color_lens_outlined,
                              isSelected: bgConfig.type == BgType.color,
                              onTap: () async {
                                await backgroundNotifier.setSolidColor();
                                setState(() {});
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildBgOptionBtn(
                              label: "Gambar",
                              icon: Icons.image_outlined,
                              isSelected: bgConfig.type == BgType.image,
                              onTap: _pickBgImage,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildBgOptionBtn(
                              label: "Video",
                              icon: Icons.videocam_outlined,
                              isSelected: bgConfig.type == BgType.video,
                              onTap: _pickBgVideo,
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // SECTION 3: KUSTOMISASI WARNA (Khusus Mode 1 - 5)
                  if (currentMode != 0 &&
                      bgNotifierVal != null &&
                      primaryNotifierVal != null &&
                      secondaryNotifierVal != null &&
                      borderNotifierVal != null) ...[
                    _buildSectionHeader(
                      "KUSTOMISASI WARNA ${_getModeName(currentMode)}",
                      "Ubah 16 juta warna palet secara instan (Hex & Pickers)",
                    ),
                    const SizedBox(height: 12),

                    _buildColorRow(
                      label: "Warna Background",
                      subLabel: "Latar belakang layar & kartu",
                      color: bgNotifierVal.value,
                      currentMode: currentMode,
                      onTap: () {
                        _pickColor("Background", bgNotifierVal.value, (col) {
                          bgNotifierVal.value = col;
                        });
                      },
                    ),
                    _buildColorRow(
                      label: "Warna Aksen Utama",
                      subLabel: "Tombol utama, header, highlight penting",
                      color: primaryNotifierVal.value,
                      currentMode: currentMode,
                      onTap: () {
                        _pickColor("Aksen Utama", primaryNotifierVal.value, (col) {
                          primaryNotifierVal.value = col;
                        });
                      },
                    ),
                    _buildColorRow(
                      label: "Warna Aksen Kedua",
                      subLabel: "Badge, tag & highlight pendukung",
                      color: secondaryNotifierVal.value,
                      currentMode: currentMode,
                      onTap: () {
                        _pickColor("Aksen Kedua", secondaryNotifierVal.value, (col) {
                          secondaryNotifierVal.value = col;
                        });
                      },
                    ),
                    _buildColorRow(
                      label: "Warna Garis / Border",
                      subLabel: "Border & garis pembatas",
                      color: borderNotifierVal.value,
                      currentMode: currentMode,
                      onTap: () {
                        _pickColor("Garis / Border", borderNotifierVal.value, (col) {
                          borderNotifierVal.value = col;
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    // SECTION 4: REFERENSI PRESET (DARK & LIGHT)
                    _buildSectionHeader("PRESET CEPAT (INSPIRASI)", "Preset rekomendasi dark & light untuk ${_getModeName(currentMode)}."),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black45,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: currentMode == 1 ? BorderRadius.zero : BorderRadius.circular(10),
                                side: BorderSide(color: _neonPink.withOpacity(0.5)),
                              ),
                            ),
                            icon: const Icon(Icons.dark_mode, color: Colors.white, size: 18),
                            label: const Text("Preset Dark", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            onPressed: () {
                              _applyPreset(currentMode, true);
                              setState(() {});
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white10,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: currentMode == 1 ? BorderRadius.zero : BorderRadius.circular(10),
                                side: const BorderSide(color: Colors.white30),
                              ),
                            ),
                            icon: const Icon(Icons.light_mode, color: Colors.amber, size: 18),
                            label: const Text("Preset Light", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            onPressed: () {
                              _applyPreset(currentMode, false);
                              setState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _neonPink),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 11, color: Colors.white54),
        ),
      ],
    );
  }

  Widget _buildThemeCard({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? _neonPink.withOpacity(0.2) : _cardOriginal,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _neonPink : Colors.white12,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: _neonPink,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text("AKTIF", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
              ),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 9, color: Colors.white54),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBgOptionBtn({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? _neonPink.withOpacity(0.2) : _cardOriginal,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? _neonPink : Colors.white12,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? _neonPink : Colors.white70, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorRow({
    required String label,
    required String subLabel,
    required Color color,
    required int currentMode,
    required VoidCallback onTap,
  }) {
    final BorderRadius cardRadius = currentMode == 1 ? BorderRadius.zero : BorderRadius.circular(12);
    final BorderRadius previewRadius = currentMode == 1 ? BorderRadius.zero : BorderRadius.circular(8);
    final BorderRadius btnRadius = currentMode == 1 ? BorderRadius.zero : BorderRadius.circular(8);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _cardOriginal,
        borderRadius: cardRadius,
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius: previewRadius,
              border: Border.all(
                color: currentMode == 1 ? Colors.black : Colors.white38,
                width: currentMode == 1 ? 2.0 : 1.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                Text(subLabel, style: const TextStyle(fontSize: 10, color: Colors.white54)),
              ],
            ),
          ),
          InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: btnRadius,
                border: Border.all(color: Colors.white24, width: 1),
              ),
              child: Row(
                children: [
                  Text(_colorToHex(color), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: _neonPink)),
                  const SizedBox(width: 4),
                  Icon(Icons.colorize, size: 14, color: _neonPink),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// DIALOG CUSTOM COLOR PICKER (NEUBRUTALISM / RETRO PINK STYLE)
// ============================================================================
class CustomColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorSelected;

  const CustomColorPickerDialog({
    super.key,
    required this.initialColor,
    required this.onColorSelected,
  });

  @override
  State<CustomColorPickerDialog> createState() => _CustomColorPickerDialogState();
}

class _CustomColorPickerDialogState extends State<CustomColorPickerDialog> {
  late HSVColor _hsvColor;

  @override
  void initState() {
    super.initState();
    _hsvColor = HSVColor.fromColor(widget.initialColor);
  }

  Color get _currentColor => _hsvColor.toColor();

  void _updateSV(Offset localPosition, double width, double height) {
    final double sat = (localPosition.dx / width).clamp(0.0, 1.0);
    final double val = (1.0 - (localPosition.dy / height)).clamp(0.0, 1.0);
    setState(() {
      _hsvColor = _hsvColor.withSaturation(sat).withValue(val);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFFFB2D1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.black, width: 3),
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              blurRadius: 0,
              offset: Offset(4, 4),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. SATURATION & VALUE PALETTE
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final height = width * 0.72;
                return GestureDetector(
                  onPanUpdate: (details) => _updateSV(details.localPosition, width, height),
                  onPanDown: (details) => _updateSV(details.localPosition, width, height),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: width,
                      height: height,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black, width: 2.5),
                        color: HSVColor.fromAHSV(1.0, _hsvColor.hue, 1.0, 1.0).toColor(),
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.white, Colors.transparent],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.transparent, Colors.black],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: (_hsvColor.saturation * width).clamp(0.0, width) - 10,
                            top: ((1.0 - _hsvColor.value) * height).clamp(0.0, height) - 10,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.black, width: 2.5),
                                color: _currentColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 18),

            // 2. PREVIEW CIRCLE + HUE SLIDER
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _currentColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 2.5),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 24,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.black, width: 2.5),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFF0000),
                          Color(0xFFFFFF00),
                          Color(0xFF00FF00),
                          Color(0xFF00FFFF),
                          Color(0xFF0000FF),
                          Color(0xFFFF00FF),
                          Color(0xFFFF0000),
                        ],
                      ),
                    ),
                    child: SliderTheme(
                      data: SliderThemeData(
                        trackShape: const RectangularSliderTrackShape(),
                        trackHeight: 24,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
                        thumbColor: Colors.white,
                        overlayColor: Colors.transparent,
                        activeTrackColor: Colors.transparent,
                        inactiveTrackColor: Colors.transparent,
                      ),
                      child: Slider(
                        value: _hsvColor.hue,
                        min: 0.0,
                        max: 360.0,
                        onChanged: (val) {
                          setState(() {
                            _hsvColor = _hsvColor.withHue(val);
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 3. INDIKATOR RGB
            Row(
              children: [
                const SizedBox(width: 50),
                Row(
                  children: const [
                    Text(
                      "RGB",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.arrow_drop_down, color: Colors.black, size: 20),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    _buildRgbValue("R", _currentColor.red),
                    const SizedBox(width: 18),
                    _buildRgbValue("G", _currentColor.green),
                    const SizedBox(width: 18),
                    _buildRgbValue("B", _currentColor.blue),
                  ],
                ),
                const SizedBox(width: 20),
              ],
            ),
            const SizedBox(height: 22),

            // 4. ACTION BUTTONS
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "BATAL",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF2B7A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    side: const BorderSide(color: Colors.black, width: 2.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: () {
                    widget.onColorSelected(_currentColor);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "PILIH",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRgbValue(String label, int val) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "$val",
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
