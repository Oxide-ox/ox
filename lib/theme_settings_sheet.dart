import 'package:flutter/material.dart';
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
  // Warna Utama Tema 1 (Original Dark)
  final Color _bgOriginal = const Color(0xFF090212);
  final Color _cardOriginal = const Color(0xFF17092C);
  final Color _neonPink = const Color(0xFFE6007E);

  // FUNGSI MEMBUKA DIALOG CUSTOM COLOR PICKER RETRO
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

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    final currentMode = themeModeNotifier.value;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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
                  // SECTION 1: MODE TAMPILAN
                  _buildSectionHeader("MODE TAMPILAN", "Pilih tampilan apk"),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildThemeCard(
                          title: "1. Original",
                          subtitle: "Cyberpunk Classic",
                          isSelected: currentMode == 0,
                          onTap: () {
                            setState(() => themeModeNotifier.value = 0);
                            themeModeNotifier.notifyListeners();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildThemeCard(
                          title: "2. Neo Brutalism",
                          subtitle: "Custom Colors",
                          isSelected: currentMode == 1,
                          onTap: () {
                            setState(() => themeModeNotifier.value = 1);
                            themeModeNotifier.notifyListeners();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildThemeCard(
                          title: "3. Pop Art",
                          subtitle: "Custom Colors",
                          isSelected: currentMode == 2,
                          onTap: () {
                            setState(() => themeModeNotifier.value = 2);
                            themeModeNotifier.notifyListeners();
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // SECTION 2: KUSTOMISASI WARNA (Khusus Tema 2 & Tema 3)
                  if (currentMode != 0) ...[
                    _buildSectionHeader(
                      currentMode == 1 ? "KUSTOMISASI WARNA NEO BRUTALISM" : "KUSTOMISASI WARNA POP ART",
                      "Pilih warna apa saja dari palet warna (16 juta warna / HEX)",
                    ),
                    const SizedBox(height: 12),

                    // Color Pickers
                    _buildColorRow(
                      label: "Warna Background",
                      subLabel: "Latar belakang layar & kartu",
                      color: currentMode == 1 ? neoBgNotifier.value : popBgNotifier.value,
                      currentMode: currentMode,
                      onTap: () {
                        _pickColor("Background", currentMode == 1 ? neoBgNotifier.value : popBgNotifier.value, (col) {
                          if (currentMode == 1) {
                            neoBgNotifier.value = col;
                          } else {
                            popBgNotifier.value = col;
                          }
                        });
                      },
                    ),
                    _buildColorRow(
                      label: "Warna Aksen Utama",
                      subLabel: "Tombol utama, header, highlight penting",
                      color: currentMode == 1 ? neoPrimaryNotifier.value : popPrimaryNotifier.value,
                      currentMode: currentMode,
                      onTap: () {
                        _pickColor("Aksen Utama", currentMode == 1 ? neoPrimaryNotifier.value : popPrimaryNotifier.value, (col) {
                          if (currentMode == 1) {
                            neoPrimaryNotifier.value = col;
                          } else {
                            popPrimaryNotifier.value = col;
                          }
                        });
                      },
                    ),
                    _buildColorRow(
                      label: "Warna Aksen Kedua",
                      subLabel: "Badge, tag & highlight pendukung",
                      color: currentMode == 1 ? neoSecondaryNotifier.value : popSecondaryNotifier.value,
                      currentMode: currentMode,
                      onTap: () {
                        _pickColor("Aksen Kedua", currentMode == 1 ? neoSecondaryNotifier.value : popSecondaryNotifier.value, (col) {
                          if (currentMode == 1) {
                            neoSecondaryNotifier.value = col;
                          } else {
                            popSecondaryNotifier.value = col;
                          }
                        });
                      },
                    ),
                    _buildColorRow(
                      label: "Warna Garis / Border",
                      subLabel: "Border tebal & garis pembatas",
                      color: currentMode == 1 ? neoBorderNotifier.value : popBorderNotifier.value,
                      currentMode: currentMode,
                      onTap: () {
                        _pickColor("Garis / Border", currentMode == 1 ? neoBorderNotifier.value : popBorderNotifier.value, (col) {
                          if (currentMode == 1) {
                            neoBorderNotifier.value = col;
                          } else {
                            popBorderNotifier.value = col;
                          }
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    // SECTION 3: REFERENSI PRESET (DARK & LIGHT)
                    _buildSectionHeader("PRESET CEPAT (INSPIRASI)", "Pilih preset rekomendasi dark & light."),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black45,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                // KOTAK LANCIP DI NEO BRUTALISM, MELENGKUNG DI POP ART
                                borderRadius: currentMode == 1 ? BorderRadius.zero : BorderRadius.circular(10),
                                side: BorderSide(color: _neonPink.withOpacity(0.5)),
                              ),
                            ),
                            icon: const Icon(Icons.dark_mode, color: Colors.white, size: 18),
                            label: const Text("Preset Dark", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            onPressed: () {
                              if (currentMode == 1) {
                                AppTheme.applyNeoPreset(isDark: true);
                              } else {
                                AppTheme.applyPopArtPreset(isDark: true);
                              }
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
                                // KOTAK LANCIP DI NEO BRUTALISM, MELENGKUNG DI POP ART
                                borderRadius: currentMode == 1 ? BorderRadius.zero : BorderRadius.circular(10),
                                side: const BorderSide(color: Colors.white30),
                              ),
                            ),
                            icon: const Icon(Icons.light_mode, color: Colors.amber, size: 18),
                            label: const Text("Preset Light", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            onPressed: () {
                              if (currentMode == 1) {
                                AppTheme.applyNeoPreset(isDark: false);
                              } else {
                                AppTheme.applyPopArtPreset(isDark: false);
                              }
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
          children: [
            if (isSelected)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: _neonPink,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text("AKTIF", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
              ),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 9, color: Colors.white54)),
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
    // KOTAK PERSEGcontrast DAN BORDER PENUH PADA NEO BRUTALISM (LANCIP), MELENGKUNG PADA POP ART
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
          color: const Color(0xFFFFB2D1), // Warna Modal Pink Retro
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
            // 1. KANVAS PEMILIH WARNA (SATURATION & VALUE PALETTE)
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
                          // Gradient Saturation (Putih ke Transparan)
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
                          // Gradient Value (Transparan ke Hitam)
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
                          // Kursor Pemilih Warna
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

            // 2. PREVIEW CIRCLE + SLIDER PELANGI (HUE SLIDER)
            Row(
              children: [
                // Circle Pratinjau Warna di Kiri Slider
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
                // Slider Spektrum Warna Lengkap (Pelangi)
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

            // 3. INDIKATOR RGB (DESAIN TEKS DAN ANGKA RGB)
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

            // 4. TOMBOL BATAL DAN PILIH WARNA DENGAN BORDER TEGAS
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
                    backgroundColor: const Color(0xFFFF2B7A), // Hot Pink
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
