import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'app_theme.dart';

class AmFinderPage extends StatefulWidget {
  const AmFinderPage({super.key});

  @override
  State<AmFinderPage> createState() => _AmFinderPageState();
}

class _AmFinderPageState extends State<AmFinderPage> {
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;
  
  String? _resultLink;
  String? _errorMessage;

  // Endpoint API AM Finder
  static const String apiUrl = "https://api.ikyyxd.my.id/tools/amfinder?url=";

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  // --- LOGIKA FETCH API ---
  Future<void> _findPreset() async {
    final targetUrl = _urlController.text.trim();
    
    if (targetUrl.isEmpty) {
      _showToast("Masukkan link TikTok terlebih dahulu!", isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _resultLink = null;
      _errorMessage = null;
    });

    try {
      final response = await http.get(Uri.parse('$apiUrl$targetUrl'));
      
      if (response.statusCode == 200) {
        // Parsing respons JSON secara fleksibel
        final data = jsonDecode(response.body);
        
        String foundLink = '';
        if (data['result'] != null) {
          if (data['result'] is String) {
            foundLink = data['result'];
          } else if (data['result'] is Map) {
            foundLink = data['result']['url'] ?? data['result']['link'] ?? data['result']['xml'] ?? '';
          }
        } else if (data['url'] != null) {
          foundLink = data['url'];
        }

        if (foundLink.isNotEmpty) {
          setState(() => _resultLink = foundLink);
          _showToast("Preset berhasil ditemukan!");
        } else {
          setState(() => _errorMessage = "Preset tidak ditemukan pada video tersebut.");
        }
      } else {
        setState(() => _errorMessage = "Gagal memuat API (Status: ${response.statusCode})");
      }
    } catch (e) {
      setState(() => _errorMessage = "Terjadi kesalahan jaringan atau server mati.\n$e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- LOGIKA UTILITIES ---
  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data != null && data.text != null) {
      setState(() {
        _urlController.text = data.text!;
      });
      _showToast("Link disalin dari clipboard");
    }
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    _showToast("Link preset berhasil disalin!");
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showToast("Gagal membuka link ke aplikasi", isError: true);
    }
  }

  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // --- POPUP TUTORIAL ---
  void _showTutorialPopup(bool isNeo, ThemeData theme) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isNeo ? 8 : 20),
            side: BorderSide(
              color: isNeo ? Colors.black : theme.colorScheme.primary.withOpacity(0.5),
              width: isNeo ? 3 : 1.5,
            ),
          ),
          title: Row(
            children: [
              Icon(Icons.help_outline_rounded, color: theme.colorScheme.primary, size: 26),
              const SizedBox(width: 10),
              Text(
                "CARA PENGGUNAAN",
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStep(theme, "1", "Buka TikTok, cari video jedag-jedug (AM Preset)."),
              _buildStep(theme, "2", "Klik ikon 'Bagikan' (Share) ➡️ pilih 'Salin Tautan' (Copy Link)."),
              _buildStep(theme, "3", "Kembali ke aplikasi ini, lalu Paste (Tempel) link TikTok tadi."),
              _buildStep(theme, "4", "Klik tombol CARI PRESET dan tunggu sebentar."),
              _buildStep(theme, "5", "Setelah link XML/AM muncul, kamu bisa langsung Salin atau Buka di Alight Motion."),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                side: isNeo ? const BorderSide(color: Colors.black, width: 2) : BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isNeo ? 4 : 10)),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(
                "SAYA MENGERTI",
                style: TextStyle(
                  color: (isNeo && theme.brightness == Brightness.light) ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStep(ThemeData theme, String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI RENDERER ---
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: themeModeNotifier,
      builder: (context, modeIndex, _) {
        final currentTheme = AppTheme.currentTheme;
        
        return Theme(
          data: currentTheme,
          child: Builder(
            builder: (context) {
              final theme = Theme.of(context);
              final isNeo = modeIndex == 1;
              final isLight = theme.brightness == Brightness.light;
              
              final textColor = theme.colorScheme.onSurface;
              final subTextColor = textColor.withOpacity(0.7);
              final primary = theme.colorScheme.primary;

              final cardRadius = BorderRadius.circular(isNeo ? 6 : 20);
              final btnRadius = BorderRadius.circular(isNeo ? 4 : 12);
              final borderStyle = Border.all(
                color: isNeo ? Colors.black : theme.colorScheme.outline.withOpacity(0.3),
                width: isNeo ? 2.5 : 1.0,
              );
              final shadowStyle = isNeo
                  ? [const BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(4, 4))]
                  : [BoxShadow(color: primary.withOpacity(0.12), blurRadius: 15, offset: const Offset(0, 5))];

              return Scaffold(
                backgroundColor: Colors.transparent,
                appBar: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  centerTitle: true,
                  title: Text(
                    "AM PRESET FINDER",
                    style: TextStyle(color: textColor, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                  ),
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded, color: primary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(Icons.help_rounded, color: primary),
                      tooltip: 'Tutorial Cara Pakai',
                      onPressed: () => _showTutorialPopup(isNeo, theme),
                    ),
                  ],
                ),
                body: BackgroundWrapper(
                  child: SafeArea(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // KARTU INPUT URL
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: cardRadius,
                              border: borderStyle,
                              boxShadow: shadowStyle,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.tiktok_rounded, color: primary, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      "LINK TIKTOK VIDEO",
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                TextField(
                                  controller: _urlController,
                                  style: TextStyle(color: textColor, fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: "https://vt.tiktok.com/ZS...",
                                    hintStyle: TextStyle(color: subTextColor, fontSize: 13),
                                    filled: true,
                                    fillColor: theme.scaffoldBackgroundColor,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: btnRadius,
                                      borderSide: BorderSide(
                                        color: isNeo ? Colors.black : theme.colorScheme.outline.withOpacity(0.3),
                                        width: isNeo ? 2 : 1,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: btnRadius,
                                      borderSide: BorderSide(
                                        color: isNeo ? Colors.black : primary,
                                        width: 2,
                                      ),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(Icons.content_paste_rounded, color: primary, size: 20),
                                      onPressed: _pasteFromClipboard,
                                      tooltip: "Paste dari Clipboard",
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primary,
                                      side: isNeo ? const BorderSide(color: Colors.black, width: 2.5) : BorderSide.none,
                                      shape: RoundedRectangleBorder(borderRadius: btnRadius),
                                      elevation: 0,
                                    ),
                                    onPressed: _isLoading ? null : _findPreset,
                                    child: _isLoading
                                        ? SizedBox(
                                            height: 20, width: 20,
                                            child: CircularProgressIndicator(
                                              color: (isNeo && isLight) ? Colors.black : Colors.white, 
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.search_rounded, color: (isNeo && isLight) ? Colors.black : Colors.white, size: 20),
                                              const SizedBox(width: 8),
                                              Text(
                                                "CARI PRESET",
                                                style: TextStyle(
                                                  color: (isNeo && isLight) ? Colors.black : Colors.white,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: 1.0,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // KARTU HASIL / ERROR
                          if (_errorMessage != null)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.15),
                                borderRadius: cardRadius,
                                border: Border.all(
                                  color: isNeo ? Colors.black : Colors.redAccent,
                                  width: isNeo ? 2.5 : 1.0,
                                ),
                                boxShadow: isNeo ? [const BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(4, 4))] : null,
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded, color: Colors.redAccent),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          if (_resultLink != null)
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: cardRadius,
                                border: borderStyle,
                                boxShadow: shadowStyle,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.check_circle_outline_rounded, color: Colors.greenAccent.shade400),
                                      const SizedBox(width: 8),
                                      Text(
                                        "PRESET DITEMUKAN",
                                        style: TextStyle(color: Colors.greenAccent.shade400, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.0),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: theme.scaffoldBackgroundColor,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
                                    ),
                                    child: SelectableText(
                                      _resultLink!,
                                      style: TextStyle(color: primary, fontSize: 13, decoration: TextDecoration.underline),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            side: BorderSide(color: isNeo ? Colors.black : primary, width: isNeo ? 2 : 1),
                                            shape: RoundedRectangleBorder(borderRadius: btnRadius),
                                          ),
                                          icon: Icon(Icons.copy_rounded, size: 18, color: textColor),
                                          label: Text("SALIN", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                                          onPressed: () => _copyToClipboard(_resultLink!),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: primary,
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            side: isNeo ? const BorderSide(color: Colors.black, width: 2) : BorderSide.none,
                                            shape: RoundedRectangleBorder(borderRadius: btnRadius),
                                            elevation: 0,
                                          ),
                                          icon: Icon(Icons.open_in_new_rounded, size: 18, color: (isNeo && isLight) ? Colors.black : Colors.white),
                                          label: Text(
                                            "BUKA DI AM", 
                                            style: TextStyle(
                                              color: (isNeo && isLight) ? Colors.black : Colors.white, 
                                              fontWeight: FontWeight.bold
                                            )
                                          ),
                                          onPressed: () => _openLink(_resultLink!),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }
          ),
        );
      }
    );
  }
}
