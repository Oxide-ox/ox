import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'app_theme.dart';
import 'btrapps/.dart';

final baseUrl = Api.api;

class SpamOtpPage extends StatefulWidget {
  const SpamOtpPage({super.key});

  @override
  State<SpamOtpPage> createState() => _SpamOtpPageState();
}

class _SpamOtpPageState extends State<SpamOtpPage> {
  final List<TextEditingController> _controllers = List.generate(5, (_) => TextEditingController());
  
  // GANTI DENGAN URL BACKEND NODE.JS KAMU
  static const String API_URL = "$baseUrl/floxotp"; 

  bool _isLoading = false;
  String _statusMessage = "";
  
  // Variabel untuk statistik
  int _statSuccess = 0;
  int _statRate = 0;
  int _statBad = 0;
  int _statError = 0;
  bool _hasResult = false;

  bool get _isLight => Theme.of(context).brightness == Brightness.light;
  Color get _textColor => Theme.of(context).colorScheme.onSurface;
  Color get _subTextColor => Theme.of(context).colorScheme.onSurface.withOpacity(0.7);
  bool get _isNeo => themeModeNotifier.value == 1;

  @override
  void dispose() {
    for (var c in _controllers) { c.dispose(); }
    super.dispose();
  }

  Future<void> _requestOtp() async {
    List<String> numbers = _controllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
    
    if (numbers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Masukkan minimal 1 nomor HP!", style: TextStyle(color: Colors.white)), 
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = "Mengirim request...";
      _hasResult = false;
      _statSuccess = 0; _statRate = 0; _statBad = 0; _statError = 0;
    });

    try {
      final response = await http.post(
        Uri.parse(API_URL),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phones': numbers}),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['status'] == true) {
          final stats = data['total_stats'] ?? {};
          
          setState(() {
            _statSuccess = stats['success'] ?? 0;
            _statRate = stats['ratelimit'] ?? 0;
            _statBad = stats['bad'] ?? 0;
            _statError = stats['error'] ?? 0;
            _hasResult = true;
            _statusMessage = "Berhasil diproses (${data['time']})";
          });
          
          final results = data['results'] as List? ?? [];
          for (var r in results) {
            debugPrint("Nomor: ${r['phone']} | Status: ${r['status']} | Stats: ${r['stats']}");
          }

        } else {
          setState(() => _statusMessage = "Gagal: ${data['error']}");
        }
      } else {
        setState(() => _statusMessage = "Server Error: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => _statusMessage = "Error koneksi: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

              final primaryColor = theme.colorScheme.primary;
              final surfaceColor = theme.colorScheme.surface;
              final outlineColor = theme.colorScheme.outline;
              final bgScaffold = theme.scaffoldBackgroundColor;

              final cardRadius = BorderRadius.circular(isNeo ? 4 : 16);
              final btnRadius = BorderRadius.circular(isNeo ? 4 : 12);
              
              final cardBorder = Border.all(
                color: isNeo ? Colors.black : outlineColor.withOpacity(0.3),
                width: isNeo ? 2.5 : 1.0,
              );
              
              final cardShadow = isNeo
                  ? [const BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(4, 4))]
                  : [BoxShadow(color: primaryColor.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))];

              return Scaffold(
                backgroundColor: Colors.transparent,
                body: BackgroundWrapper(
                  child: SafeArea(
                    child: Column(
                      children: [
                        _buildHeader(surfaceColor, primaryColor, cardBorder, btnRadius, isNeo),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _buildInputCard(surfaceColor, primaryColor, bgScaffold, cardBorder, cardRadius, cardShadow, btnRadius, isNeo),
                                const SizedBox(height: 16),
                                _buildStartButton(primaryColor, outlineColor, btnRadius, isNeo, theme),
                                const SizedBox(height: 16),
                                if (_statusMessage.isNotEmpty) 
                                  _buildStatusCard(surfaceColor, primaryColor, cardBorder, cardRadius, isNeo),
                                const SizedBox(height: 16),
                                if (_hasResult) _buildStatsBox(surfaceColor, cardBorder, cardRadius, cardShadow),
                                const SizedBox(height: 40),
                              ],
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
        );
      },
    );
  }

  // ==================== UI COMPONENTS ====================
  
  Widget _buildHeader(Color surface, Color primary, BoxBorder border, BorderRadius radius, bool isNeo) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        border: Border(
          bottom: BorderSide(
            color: isNeo ? Colors.black : border.top.color, 
            width: isNeo ? 2.5 : border.top.width,
          ),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: surface, 
                borderRadius: radius, 
                border: border,
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded, color: primary, size: 18),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            "SPAM OTP",
            style: TextStyle(
              color: _textColor,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard(
    Color surface, 
    Color primary, 
    Color bg, 
    BoxBorder border, 
    BorderRadius radius, 
    List<BoxShadow> shadow, 
    BorderRadius btnRadius,
    bool isNeo,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: radius,
        border: border,
        boxShadow: shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.phone_android_rounded, color: primary, size: 18),
              const SizedBox(width: 8),
              Text(
                "NOMOR TARGET (MAKS 5)",
                style: TextStyle(
                  color: _textColor, 
                  fontSize: 11, 
                  fontWeight: FontWeight.w800, 
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(5, (index) {
              return SizedBox(
                width: (MediaQuery.of(context).size.width - 74) / 2,
                child: TextField(
                  controller: _controllers[index],
                  keyboardType: TextInputType.phone,
                  style: TextStyle(color: _textColor, fontSize: 14, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: "08xxxxxxxxxx",
                    hintStyle: TextStyle(color: _subTextColor, fontSize: 13),
                    prefixIcon: Icon(Icons.dialpad_rounded, color: primary, size: 18),
                    filled: true,
                    fillColor: bg,
                    border: OutlineInputBorder(borderRadius: btnRadius, borderSide: border.top),
                    enabledBorder: OutlineInputBorder(borderRadius: btnRadius, borderSide: border.top),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: btnRadius, 
                      borderSide: BorderSide(color: isNeo ? Colors.black : primary, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            "Format bebas (08xx / 62xx). Sistem otomatis normalisasi.",
            style: TextStyle(color: _subTextColor, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton(Color primary, Color outline, BorderRadius radius, bool isNeo, ThemeData theme) {
    final btnTextColor = isNeo && _isLight ? Colors.black : theme.colorScheme.onPrimary;

    return GestureDetector(
      onTap: _isLoading ? null : _requestOtp,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _isLoading ? theme.disabledColor : primary,
          borderRadius: radius,
          border: isNeo ? Border.all(color: Colors.black, width: 2.5) : null,
          boxShadow: isNeo && !_isLoading
              ? [const BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(4, 4))]
              : [BoxShadow(color: primary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 6))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading)
              SizedBox(
                width: 20, 
                height: 20, 
                child: CircularProgressIndicator(color: btnTextColor, strokeWidth: 2),
              )
            else
              Icon(Icons.send_rounded, color: btnTextColor, size: 22),
            const SizedBox(width: 10),
            Text(
              _isLoading ? "MEMPROSES..." : "REQUEST OTP",
              style: TextStyle(
                color: btnTextColor, 
                fontSize: 15, 
                fontWeight: FontWeight.w900, 
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(Color surface, Color primary, BoxBorder border, BorderRadius radius, bool isNeo) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: radius,
        border: border,
        boxShadow: isNeo ? [const BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(3, 3))] : null,
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _statusMessage, 
              style: TextStyle(color: _textColor, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBox(Color surface, BoxBorder border, BorderRadius radius, List<BoxShadow> shadow) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: radius,
        border: border,
        boxShadow: shadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem("Success", _statSuccess, Colors.greenAccent),
          _buildStatItem("Rate Limit", _statRate, Colors.orangeAccent),
          _buildStatItem("Bad Request", _statBad, Colors.redAccent),
          _buildStatItem("Error", _statError, Colors.red),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          "$value",
          style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: _subTextColor, fontSize: 10, letterSpacing: 1.0),
        ),
      ],
    );
  }
}
