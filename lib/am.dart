import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AlightMotionPremScreen extends StatefulWidget {
  const AlightMotionPremScreen({Key? key}) : super(key: key);

  @override
  State<AlightMotionPremScreen> createState() => _AlightMotionPremScreenState();
}

class _AlightMotionPremScreenState extends State<AlightMotionPremScreen> {
  static const Color bgDark = Color(0xFF090212);
  static const Color bgDeepPurple = Color(0xFF140526);
  static const Color neonMagenta = Color(0xFFE6007E);
  static const Color neonPurple = Color(0xFF8E00C7);

  final String baseUrl = "https://restapidhan.vercel.app";
  final String apiKey = "freeapikeydhan26";

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();

  int _usageCount = 0;
  final int _maxLimit = 15;
  bool _isLoading = false;
  int _currentStep = 1;
  String _orderCode = "-";

  @override
  void initState() {
    super.initState();
    _checkAndResetLimit();
  }

  DateTime _getWibNow() {
    return DateTime.now().toUtc().add(const Duration(hours: 7));
  }

  DateTime _getCurrentCycleStart() {
    final nowWib = _getWibNow();
    final today12pm = DateTime.utc(nowWib.year, nowWib.month, nowWib.day, 12, 0, 0);

    if (nowWib.isBefore(today12pm)) {
      return today12pm.subtract(const Duration(days: 1));
    } else {
      return today12pm;
    }
  }

  Future<void> _checkAndResetLimit() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCycleMillis = prefs.getInt('last_cycle_timestamp') ?? 0;
    final currentCycleMillis = _getCurrentCycleStart().millisecondsSinceEpoch;

    if (lastCycleMillis < currentCycleMillis) {
      await prefs.setInt('last_cycle_timestamp', currentCycleMillis);
      await prefs.setInt('daily_usage_count', 0);
      setState(() {
        _usageCount = 0;
      });
    } else {
      setState(() {
        _usageCount = prefs.getInt('daily_usage_count') ?? 0;
      });
    }
  }

  Future<void> _incrementUsage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _usageCount++;
    });
    await prefs.setInt('daily_usage_count', _usageCount);
  }

  Future<void> _sendEmail() async {
    if (_usageCount >= _maxLimit) {
      _showSnackBar("Limit harian (15/15) tercapai! Reset pada jam 12:00 WIB.");
      return;
    }

    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      _showSnackBar("Masukkan alamat email Gmail yang valid!");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uri = Uri.parse(
        "$baseUrl/api/am?action=send&apikey=$apiKey&email=${Uri.encodeComponent(email)}",
      );
      final response = await http.get(uri);
      final data = jsonDecode(response.body);

      setState(() => _isLoading = false);

      if (response.statusCode == 200 && data['status'] == true) {
        await _incrementUsage();
        _showMagicLinkPopup();
      } else {
        _showSnackBar(data['error'] ?? data['message'] ?? "Gagal mengirim magic link.");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar("Terjadi kesalahan koneksi: $e");
    }
  }

  Future<void> _verifyLink() async {
    final email = _emailController.text.trim();
    final link = _linkController.text.trim();

    if (link.isEmpty || !link.startsWith('http')) {
      _showSnackBar("Masukkan link magic URL yang valid!");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uri = Uri.parse(
        "$baseUrl/api/am?action=verif&apikey=$apiKey&email=${Uri.encodeComponent(email)}&url=${Uri.encodeComponent(link)}",
      );
      final response = await http.get(uri);
      final data = jsonDecode(response.body);

      setState(() => _isLoading = false);

      if (response.statusCode == 200 && data['status'] == true) {
        final code = data['codeorder'] ?? data['code'] ?? "-";
        setState(() {
          _orderCode = code.toString();
          _currentStep = 3;
        });
        _showSnackBar("Aktivasi Alight Motion Premium Berhasil!");
      } else {
        _showSnackBar(data['error'] ?? data['message'] ?? "Verifikasi gagal atau link kedaluwarsa.");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar("Terjadi kesalahan koneksi: $e");
    }
  }

  void _showMagicLinkPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: bgDeepPurple,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: neonMagenta, width: 1.5),
          ),
          title: const Row(
            children: [
              Icon(Icons.mark_email_unread_rounded, color: neonMagenta, size: 28),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Link Magic Terkirim!",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Link magic verifikasi telah berhasil dikirim ke email Anda.",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              SizedBox(height: 14),
              Text(
                "Petunjuk:",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              SizedBox(height: 6),
              Text("1. Silakan cek inbox email Anda.", style: TextStyle(color: Colors.white60, fontSize: 13)),
              Text("2. Cek juga folder SPAM / Promotions jika tidak ada.", style: TextStyle(color: Colors.white60, fontSize: 13)),
              Text("3. Salin link magic tersebut untuk ditempelkan.", style: TextStyle(color: Colors.white60, fontSize: 13)),
            ],
          ),
          actions: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [neonMagenta, neonPurple]),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: neonMagenta.withOpacity(0.5),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _currentStep = 2;
                  });
                },
                child: const Text(
                  "Selanjutnya",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: neonPurple,
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _currentStep = 1;
      _emailController.clear();
      _linkController.clear();
      _orderCode = "-";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgDark, bgDeepPurple],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [neonMagenta, neonPurple],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: neonMagenta.withOpacity(0.6),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.maybePop(context),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: neonMagenta.withOpacity(0.5)),
                        ),
                        child: Text(
                          "Limit: ${_maxLimit - _usageCount}/$_maxLimit (Reset 12:00 WIB)",
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    "Alight Motion Prem",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(color: neonMagenta, blurRadius: 15),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentStep == 1
                        ? "Langkah 1: Masukkan email untuk menerima link magic."
                        : _currentStep == 2
                            ? "Langkah 2: Tempelkan link magic yang disalin dari Email."
                            : "Aktivasi Sukses! Akun Pro Anda sudah aktif.",
                    style: const TextStyle(color: Colors.white60, fontSize: 14),
                  ),
                  const SizedBox(height: 30),
                  if (_currentStep == 1) ...[
                    _buildGothicTextField(
                      controller: _emailController,
                      hint: "user@example.com",
                      label: "Email Gmail",
                      icon: Icons.email_outlined,
                    ),
                    const SizedBox(height: 20),
                    _buildNeonButton(
                      text: "Kirim Magic Link",
                      onPressed: _isLoading ? null : _sendEmail,
                    ),
                  ] else if (_currentStep == 2) ...[
                    _buildGothicTextField(
                      controller: _linkController,
                      hint: "https://...",
                      label: "Magic Link URL",
                      icon: Icons.link_rounded,
                    ),
                    const SizedBox(height: 20),
                    _buildNeonButton(
                      text: "Verifikasi & Aktifkan",
                      onPressed: _isLoading ? null : _verifyLink,
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton(
                        onPressed: () => setState(() => _currentStep = 1),
                        child: const Text(
                          "Ganti Email",
                          style: TextStyle(color: neonMagenta),
                        ),
                      ),
                    )
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.greenAccent.withOpacity(0.5)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 50),
                          const SizedBox(height: 10),
                          const Text(
                            "Akun Berhasil Ditingkatkan!",
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          const Text("Order Code:", style: TextStyle(color: Colors.white60, fontSize: 12)),
                          SelectableText(
                            _orderCode,
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildNeonButton(
                      text: "Buat Akun Lagi",
                      onPressed: _resetForm,
                    ),
                  ],
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 20.0),
                      child: Center(
                        child: CircularProgressIndicator(color: neonMagenta),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGothicTextField({
    required TextEditingController controller,
    required String hint,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white30),
        prefixIcon: Icon(icon, color: neonMagenta),
        filled: true,
        fillColor: Colors.black26,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: neonPurple.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: neonMagenta, width: 2),
        ),
      ),
    );
  }

  Widget _buildNeonButton({required String text, required VoidCallback? onPressed}) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [neonMagenta, neonPurple]),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: neonMagenta.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
