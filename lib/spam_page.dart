import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'app_theme.dart';

class SpamOtpPage extends StatefulWidget {
  const SpamOtpPage({super.key});

  @override
  State<SpamOtpPage> createState() => _SpamOtpPageState();
}

class _SpamOtpPageState extends State<SpamOtpPage> {
  final TextEditingController _numberController = TextEditingController();

  // ===== CONFIG =====
  static const String BASE_URL = "https://spamotp-api-eef5f0834c07.herokuapp.com";
  static const int TOTAL_ENDPOINT = 64;
  static const int INTERVAL_MS = 800;

  int _roundCount = 3;
  final int _threads = 43;
  bool _isLoading = false;
  String _statusMessage = "";
  final List<Map<String, dynamic>> _liveResults = [];

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  // ==================== NORMALIZE NUMBER ====================
  String _normalizeNumber(String input) {
    String cleaned = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.startsWith('0')) {
      cleaned = '62${cleaned.substring(1)}';
    } else if (cleaned.startsWith('8')) {
      cleaned = '62$cleaned';
    }
    return cleaned;
  }

  // ==================== START SPAM ====================
  Future<void> _startSpam() async {
    final input = _numberController.text.trim();
    if (input.isEmpty) {
      _showError("Masukkan nomor target!");
      return;
    }

    final number = _normalizeNumber(input);
    if (number.length < 10) {
      _showError("Nomor tidak valid!");
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = "Memulai spam...";
      _liveResults.clear();
    });

    try {
      for (int round = 1; round <= _roundCount; round++) {
        setState(() {
          _statusMessage = "Round $round/$_roundCount...";
        });

        final futures = <Future>[];
        for (int i = 0; i < TOTAL_ENDPOINT; i++) {
          futures.add(_sendBurst(number, i));
        }

        await Future.wait(futures);

        if (round < _roundCount) {
          await Future.delayed(const Duration(milliseconds: 1600));
        }
      }

      setState(() {
        _isLoading = false;
        _statusMessage = "✅ Selesai! $_roundCount round × $TOTAL_ENDPOINT endpoint";
      });
      _showSuccess("Spam selesai!");
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = "❌ Error: $e";
      });
      _showError("Gagal: $e");
    }
  }

  Future<void> _sendBurst(String number, int index) async {
    try {
      final url = Uri.parse('$BASE_URL/api/$number?mode=single&threads=$_threads');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (mounted) {
        setState(() {
          _liveResults.add({
            'api': 'API-${index + 1}',
            'status': (response.statusCode == 200 || response.statusCode == 202) ? 'SUCCESS' : 'FAILED',
            'success': (response.statusCode == 200 || response.statusCode == 202),
          });
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _liveResults.add({
            'api': 'API-${index + 1}',
            'status': 'ERROR',
            'success': false,
          });
        });
      }
    }
  }

  // ==================== STOP SPAM ====================
  Future<void> _stopSpam() async {
    if (_numberController.text.isEmpty) return;
    final number = _normalizeNumber(_numberController.text);
    try {
      final url = Uri.parse('$BASE_URL/api/$number/stop');
      await http.post(url).timeout(const Duration(seconds: 10));
      setState(() {
        _isLoading = false;
        _statusMessage = "⏹️ Stopped";
      });
      _showSuccess("Spam dihentikan!");
    } catch (e) {
      _showError("Gagal stop: $e");
    }
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.greenAccent.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: themeModeNotifier,
      builder: (context, modeIndex, child) {
        final theme = Theme.of(context);
        final isNeo = modeIndex == 1; // Mode 1 = Neo Brutalism

        final primaryColor = theme.colorScheme.primary;
        final secondaryColor = theme.colorScheme.secondary;
        final surfaceColor = theme.colorScheme.surface;
        final outlineColor = theme.colorScheme.outline;
        final bgScaffold = theme.scaffoldBackgroundColor;

        // Radius & Shadow Sesuai Mode Tema
        final cardRadius = isNeo ? BorderRadius.zero : BorderRadius.circular(16);
        final btnRadius = isNeo ? BorderRadius.zero : BorderRadius.circular(12);
        final cardBorder = Border.all(
          color: isNeo ? outlineColor : primaryColor.withOpacity(0.3),
          width: isNeo ? 2.5 : 1.0,
        );
        final cardShadow = isNeo
            ? [BoxShadow(color: outlineColor, blurRadius: 0, offset: const Offset(4, 4))]
            : [BoxShadow(color: primaryColor.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))];

        return Scaffold(
          backgroundColor: bgScaffold,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(surfaceColor, primaryColor, cardBorder, btnRadius),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildStatsRow(surfaceColor, primaryColor, secondaryColor, cardBorder, cardRadius, cardShadow),
                        const SizedBox(height: 16),
                        _buildInputCard(surfaceColor, primaryColor, bgScaffold, cardBorder, cardRadius, cardShadow, btnRadius),
                        const SizedBox(height: 16),
                        _buildRoundCard(surfaceColor, primaryColor, bgScaffold, cardBorder, cardRadius, cardShadow, btnRadius, isNeo),
                        const SizedBox(height: 16),
                        _buildStartButton(primaryColor, secondaryColor, outlineColor, btnRadius, isNeo),
                        const SizedBox(height: 16),
                        if (_statusMessage.isNotEmpty) _buildStatusCard(surfaceColor, primaryColor, cardBorder, cardRadius),
                        const SizedBox(height: 16),
                        if (_liveResults.isNotEmpty) _buildLiveResults(surfaceColor, primaryColor, cardBorder, cardRadius, cardShadow),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==================== HEADER ====================
  Widget _buildHeader(Color surface, Color primary, BoxBorder border, BorderRadius radius) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        border: Border(bottom: BorderSide(color: border.top.color, width: border.top.width)),
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
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            "SPAM OTP",
            style: TextStyle(
              color: primary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== STATS ROW ====================
  Widget _buildStatsRow(Color surface, Color primary, Color secondary, BoxBorder border, BorderRadius radius, List<BoxShadow> shadow) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: radius,
        border: border,
        boxShadow: shadow,
      ),
      child: Row(
        children: [
          _buildStatItem(icon: Icons.hub_rounded, value: "$TOTAL_ENDPOINT", label: "Endpoint", color: primary),
          _buildDivider(border.top.color),
          _buildStatItem(icon: Icons.speed_rounded, value: "${INTERVAL_MS}ms", label: "Interval", color: secondary),
          _buildDivider(border.top.color),
          _buildStatItem(icon: Icons.flash_on_rounded, value: "1x", label: "Burst", color: primary),
        ],
      ),
    );
  }

  Widget _buildStatItem({required IconData icon, required String value, required String label, required Color color}) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildDivider(Color color) {
    return Container(width: 1, height: 40, color: color.withOpacity(0.3));
  }

  // ==================== INPUT CARD ====================
  Widget _buildInputCard(Color surface, Color primary, Color bg, BoxBorder border, BorderRadius radius, List<BoxShadow> shadow, BorderRadius btnRadius) {
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
              const Text(
                "NOMOR TARGET WHATSAPP / SMS",
                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _numberController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: "08xxxxxxxxxx / 62...",
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                    prefixIcon: Icon(Icons.dialpad_rounded, color: primary, size: 20),
                    filled: true,
                    fillColor: bg,
                    border: OutlineInputBorder(borderRadius: btnRadius, borderSide: border.top),
                    enabledBorder: OutlineInputBorder(borderRadius: btnRadius, borderSide: border.top),
                    focusedBorder: OutlineInputBorder(borderRadius: btnRadius, borderSide: BorderSide(color: primary, width: 2)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Format bebas (08xx, 628xx, +62). Sistem otomatis normalisasi nomor untuk setiap provider.",
            style: TextStyle(color: Colors.white54, fontSize: 10),
          ),
        ],
      ),
    );
  }

  // ==================== ROUND CARD ====================
  Widget _buildRoundCard(Color surface, Color primary, Color bg, BoxBorder border, BorderRadius radius, List<BoxShadow> shadow, BorderRadius btnRadius, bool isNeo) {
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
              Icon(Icons.refresh_rounded, color: primary, size: 18),
              const SizedBox(width: 8),
              const Text("PENGULANGAN (RONDE)", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.2),
                  borderRadius: isNeo ? BorderRadius.zero : BorderRadius.circular(20),
                  border: isNeo ? Border.all(color: Colors.white, width: 1) : null,
                ),
                child: Text("= ${_roundCount * TOTAL_ENDPOINT} KIRIMAN", style: TextStyle(color: primary, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildCounterBtn(icon: Icons.remove, bg: bg, border: border.top, radius: btnRadius, onTap: () { if (_roundCount > 1) setState(() => _roundCount--); }),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(color: bg, borderRadius: btnRadius, border: border),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("$_roundCount", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                      const SizedBox(width: 4),
                      const Text("x", style: TextStyle(color: Colors.white54, fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildCounterBtn(icon: Icons.add, bg: bg, border: border.top, radius: btnRadius, onTap: () => setState(() => _roundCount++)),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [1, 2, 3, 5, 10, 25].map((n) {
              final isSelected = _roundCount == n;
              return GestureDetector(
                onTap: () => setState(() => _roundCount = n),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? primary : surface,
                    borderRadius: btnRadius,
                    border: isSelected ? Border.all(color: Colors.white, width: isNeo ? 2 : 1) : border,
                  ),
                  child: Text("${n}x", style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Text(
            "Tiap ronde mengirim ulang ke semua $TOTAL_ENDPOINT provider, jeda antar ronde ±1,6 detik.",
            style: const TextStyle(color: Colors.white54, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterBtn({required IconData icon, required Color bg, required BorderSide border, required BorderRadius radius, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: radius,
          border: Border.all(color: border.color, width: border.width),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  // ==================== START BUTTON ====================
  Widget _buildStartButton(Color primary, Color secondary, Color outline, BorderRadius radius, bool isNeo) {
    return Column(
      children: [
        GestureDetector(
          onTap: _isLoading ? null : _startSpam,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: _isLoading ? Colors.grey.shade800 : primary,
              borderRadius: radius,
              border: isNeo ? Border.all(color: outline, width: 2.5) : null,
              boxShadow: isNeo && !_isLoading
                  ? [BoxShadow(color: outline, blurRadius: 0, offset: const Offset(4, 4))]
                  : [BoxShadow(color: primary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 6))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isLoading)
                  const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                else
                  const Icon(Icons.flash_on_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Text(
                  _isLoading ? "SEDANG SPAM..." : "MULAI SPAM OTP ×$_roundCount",
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
        ),
        if (_isLoading) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _stopSpam,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.15),
                borderRadius: radius,
                border: Border.all(color: Colors.redAccent, width: isNeo ? 2.5 : 1.5),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.stop_rounded, color: Colors.redAccent, size: 20),
                  SizedBox(width: 8),
                  Text("STOP SPAM", style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ==================== STATUS CARD ====================
  Widget _buildStatusCard(Color surface, Color primary, BoxBorder border, BorderRadius radius) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: radius,
        border: border,
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(_statusMessage, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ==================== LIVE RESULTS ====================
  Widget _buildLiveResults(Color surface, Color primary, BoxBorder border, BorderRadius radius, List<BoxShadow> shadow) {
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
              Icon(Icons.list_alt_rounded, color: primary, size: 18),
              const SizedBox(width: 8),
              const Text("LIVE RESULTS", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              const Spacer(),
              Text(
                "${_liveResults.where((r) => r['success'] == true).length}/${_liveResults.length}",
                style: TextStyle(color: Colors.greenAccent.shade400, fontSize: 11, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._liveResults.reversed.take(20).map((result) {
            final isSuccess = result['success'] == true;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isSuccess ? Colors.greenAccent.shade400 : Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(result['api'], style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text(
                    result['status'],
                    style: TextStyle(
                      color: isSuccess ? Colors.greenAccent.shade400 : Colors.redAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
