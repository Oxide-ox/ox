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

  // Opsi Pilihan Warna Cepat untuk Color Picker
  final List<Color> _paletteOptions = [
    const Color(0xFF0F0A1C),
    const Color(0xFFFEFCE8),
    const Color(0xFFFFE600),
    const Color(0xFFA855F7),
    const Color(0xFFEC4899),
    const Color(0xFFFF0055),
    const Color(0xFF00E5FF),
    const Color(0xFF86EFAC),
    const Color(0xFF000000),
    const Color(0xFFFFFFFF),
  ];

  void _pickColor(String title, Color currentColor, Function(Color) onColorSelected) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _cardOriginal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _neonPink.withOpacity(0.5), width: 1.5),
        ),
        title: Text(
          "Pilih $title",
          style: TextStyle(color: _neonPink, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _paletteOptions.map((col) {
            return GestureDetector(
              onTap: () {
                onColorSelected(col);
                Navigator.pop(context);
                setState(() {});
                themeModeNotifier.notifyListeners();
              },
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: col,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white38, width: 2),
                ),
              ),
            );
          }).toList(),
        ),
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
        color: _bgOriginal, // MENGGUNAKAN BG TEMA 1 ORIGINAL
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
                      onTap: () {
                        _pickColor("Background", currentMode == 1 ? neoBgNotifier.value : popBgNotifier.value, (col) {
                          if (currentMode == 1) neoBgNotifier.value = col;
                          else popBgNotifier.value = col;
                        });
                      },
                    ),
                    _buildColorRow(
                      label: "Warna Aksen Utama",
                      subLabel: "Tombol utama, header, highlight penting",
                      color: currentMode == 1 ? neoPrimaryNotifier.value : popPrimaryNotifier.value,
                      onTap: () {
                        _pickColor("Aksen Utama", currentMode == 1 ? neoPrimaryNotifier.value : popPrimaryNotifier.value, (col) {
                          if (currentMode == 1) neoPrimaryNotifier.value = col;
                          else popPrimaryNotifier.value = col;
                        });
                      },
                    ),
                    _buildColorRow(
                      label: "Warna Aksen Kedua",
                      subLabel: "Badge, tag & highlight pendukung",
                      color: currentMode == 1 ? neoSecondaryNotifier.value : popSecondaryNotifier.value,
                      onTap: () {
                        _pickColor("Aksen Kedua", currentMode == 1 ? neoSecondaryNotifier.value : popSecondaryNotifier.value, (col) {
                          if (currentMode == 1) neoSecondaryNotifier.value = col;
                          else popSecondaryNotifier.value = col;
                        });
                      },
                    ),
                    _buildColorRow(
                      label: "Warna Garis / Border",
                      subLabel: "Border tebal & garis pembatas",
                      color: currentMode == 1 ? neoBorderNotifier.value : popBorderNotifier.value,
                      onTap: () {
                        _pickColor("Garis / Border", currentMode == 1 ? neoBorderNotifier.value : popBorderNotifier.value, (col) {
                          if (currentMode == 1) neoBorderNotifier.value = col;
                          else popBorderNotifier.value = col;
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    // SECTION 3: REFERENSI PRESET (DARK & LIGHT) DI BAGIAN PALING BAWAH
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
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(color: _neonPink.withOpacity(0.5)),
                              ),
                            ),
                            icon: const Icon(Icons.dark_mode, color: Colors.white, size: 18),
                            label: const Text("Preset Dark", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            onPressed: () {
                              if (currentMode == 1) AppTheme.applyNeoPreset(isDark: true);
                              else AppTheme.applyPopArtPreset(isDark: true);
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
                                borderRadius: BorderRadius.circular(10),
                                side: const BorderSide(color: Colors.white30),
                              ),
                            ),
                            icon: const Icon(Icons.light_mode, color: Colors.amber, size: 18),
                            label: const Text("Preset Light", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            onPressed: () {
                              if (currentMode == 1) AppTheme.applyNeoPreset(isDark: false);
                              else AppTheme.applyPopArtPreset(isDark: false);
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
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _cardOriginal,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white38, width: 1.5),
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
                borderRadius: BorderRadius.circular(8),
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
