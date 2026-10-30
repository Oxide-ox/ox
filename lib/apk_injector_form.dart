import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'app_theme.dart';
import 'btrapps/.dart'; // Uncomment jika menggunakan base URL dari file ini
final baseUrl = Api.api;
class ApkModderPage extends StatefulWidget {
  final String username;

  const ApkModderPage({
    super.key,
    required this.username,
  });

  @override
  State<ApkModderPage> createState() => _ApkModderPageState();
}

class _ApkModderPageState extends State<ApkModderPage> with SingleTickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  
  bool _isProcessing = false;
  String _processStatus = "";
  double _progressValue = 0.0;
  
  bool _isFinished = false;
  String? _downloadUrl;

  late AnimationController _pulseController;

  // Ganti dengan domain/IP VPS kamu
 // final String _apiUrl = "http://IP_VPS_KAMU:3000/api/inject-apk";

  @override
  void initState() {
    super.initState();
    _usernameController.text = widget.username;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _processApk() async {
    final newUsername = _usernameController.text.trim();
    if (newUsername.isEmpty) {
      _showToast("Username tidak boleh kosong!", isError: true);
      return;
    }

    setState(() {
      _isProcessing = true;
      _isFinished = false;
      _progressValue = 0.5;
      _processStatus = "Memproses injeksi di VPS...";
    });

    try {
      final response = await http.post(
        Uri.parse("${baseUrl}/api/inject-apk"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'newUsername': newUsername}),
      ).timeout(const Duration(seconds: 30)); // Timeout 30 detik untuk proses zip/signing

      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        setState(() {
          _progressValue = 1.0;
          _processStatus = "Selesai!";
          _downloadUrl = data['downloadUrl'];
          _isFinished = true;
        });
        _showToast("APK Berhasil Dimodifikasi!");
      } else {
        setState(() => _processStatus = "Gagal memproses APK");
        _showToast(data['message'] ?? "Terjadi kesalahan di server", isError: true);
      }
    } catch (e) {
      setState(() => _processStatus = "Koneksi gagal");
      _showToast("Gagal terhubung ke VPS: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _downloadApk() async {
    if (_downloadUrl != null) {
      final uri = Uri.parse(_downloadUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showToast("Gagal membuka link download", isError: true);
      }
    }
  }

  Future<void> _shareApk() async {
    if (_downloadUrl != null) {
      await Share.share(
        "Nih bro APK modded spesial buat kamu!\nUsername: ${_usernameController.text}\nDownload: $_downloadUrl",
        subject: "Modded APK",
      );
    }
  }

  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showTutorial(ThemeData theme, bool isNeo) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isNeo ? 8 : 20),
            side: BorderSide(
              color: isNeo ? Colors.black : theme.colorScheme.primary,
              width: isNeo ? 3 : 1.5,
            ),
          ),
          title: Row(
            children: [
              Icon(Icons.menu_book_rounded, color: theme.colorScheme.primary, size: 24),
              const SizedBox(width: 10),
              Text(
                "TUTORIAL INJECT APK",
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
              _buildStep(theme, "1", "Masukkan username baru kamu di kolom yang disediakan."),
              _buildStep(theme, "2", "Sistem akan mengirimkan request ke VPS untuk membongkar name.zip."),
              _buildStep(theme, "3", "Sistem akan mencari file konfigurasi di path: assets/@kaell_Xz"),
              _buildStep(theme, "4", "Username bawaan 'virz' akan direplace otomatis dengan username kamu lalu di-sign menjadi .apk."),
              _buildStep(theme, "5", "Setelah selesai, kamu bisa langsung Download atau Share APK tersebut."),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                side: isNeo ? const BorderSide(color: Colors.black, width: 2) : BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isNeo ? 4 : 8),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(
                "MENGERTI",
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

  Widget _buildStep(ThemeData theme, String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
              num,
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
              style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.8), fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: themeModeNotifier,
      builder: (context, modeIndex, child) {
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
                    "APK INJECTOR",
                    style: TextStyle(color: textColor, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                  ),
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded, color: primary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(Icons.help_rounded, color: primary),
                      tooltip: 'Tutorial',
                      onPressed: () => _showTutorial(theme, isNeo),
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
                          
                          // INFO CARD
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: primary.withOpacity(0.15),
                              borderRadius: cardRadius,
                              border: Border.all(
                                color: isNeo ? Colors.black : primary.withOpacity(0.5),
                                width: isNeo ? 2.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.build_rounded, color: primary, size: 28),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "TARGET: assets/@kaell_Xz",
                                        style: TextStyle(
                                          color: primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Sistem VPS akan membongkar ZIP, mengganti string 'virz' jadi username kamu, lalu merepack menjadi APK.",
                                        style: TextStyle(color: textColor, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // INPUT USERNAME CARD
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
                                Text(
                                  "USERNAME BARU",
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _usernameController,
                                  style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold),
                                  decoration: InputDecoration(
                                    hintText: "Masukkan username...",
                                    hintStyle: TextStyle(color: subTextColor, fontSize: 13, fontWeight: FontWeight.normal),
                                    filled: true,
                                    fillColor: theme.scaffoldBackgroundColor,
                                    prefixIcon: Icon(Icons.person_pin_rounded, color: primary),
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
                                  ),
                                ),
                                const SizedBox(height: 20),
                                
                                // TOMBOL PROSES
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
                                    onPressed: _isProcessing ? null : _processApk,
                                    child: _isProcessing
                                        ? Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                height: 20, width: 20,
                                                child: CircularProgressIndicator(
                                                  color: (isNeo && isLight) ? Colors.black : Colors.white, 
                                                  strokeWidth: 2,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                "MEMPROSES DI VPS...",
                                                style: TextStyle(
                                                  color: (isNeo && isLight) ? Colors.black : Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              )
                                            ],
                                          )
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.build_circle_rounded, color: (isNeo && isLight) ? Colors.black : Colors.white),
                                              const SizedBox(width: 8),
                                              Text(
                                                "PROSES APK",
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

                          // STATUS PROGRESS
                          if (_isProcessing || _isFinished) ...[
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.scaffoldBackgroundColor,
                                borderRadius: btnRadius,
                                border: borderStyle,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _processStatus,
                                        style: TextStyle(
                                          color: _isFinished ? Colors.greenAccent : primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        "${(_progressValue * 100).toInt()}%",
                                        style: TextStyle(
                                          color: textColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  LinearProgressIndicator(
                                    value: _progressValue,
                                    backgroundColor: theme.colorScheme.surface,
                                    color: _isFinished ? Colors.greenAccent : primary,
                                    minHeight: 8,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // HASIL SELESAI (DOWNLOAD & SHARE)
                          if (_isFinished && _downloadUrl != null) ...[
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      side: BorderSide(
                                        color: isNeo ? Colors.black : primary, 
                                        width: isNeo ? 2 : 1
                                      ),
                                      shape: RoundedRectangleBorder(borderRadius: btnRadius),
                                    ),
                                    icon: Icon(Icons.share_rounded, size: 20, color: textColor),
                                    label: Text("SHARE APK", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                                    onPressed: _shareApk,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: AnimatedBuilder(
                                    animation: _pulseController,
                                    builder: (context, child) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          borderRadius: btnRadius,
                                          boxShadow: isNeo ? null : [
                                            BoxShadow(
                                              color: Colors.greenAccent.withOpacity(0.4),
                                              blurRadius: _pulseController.value * 15,
                                            )
                                          ],
                                        ),
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                            side: isNeo ? const BorderSide(color: Colors.black, width: 2) : BorderSide.none,
                                            shape: RoundedRectangleBorder(borderRadius: btnRadius),
                                            elevation: 0,
                                          ),
                                          icon: Icon(Icons.download_rounded, size: 20, color: (isNeo && isLight) ? Colors.black : Colors.white),
                                          label: Text(
                                            "DOWNLOAD", 
                                            style: TextStyle(
                                              color: (isNeo && isLight) ? Colors.black : Colors.white, 
                                              fontWeight: FontWeight.bold
                                            )
                                          ),
                                          onPressed: _downloadApk,
                                        ),
                                      );
                                    }
                                  ),
                                ),
                              ],
                            ),
                          ]

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
