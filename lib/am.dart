import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

class AlightMotionPremScreen extends StatefulWidget {
  const AlightMotionPremScreen({Key? key}) : super(key: key);

  @override
  State<AlightMotionPremScreen> createState() => _AlightMotionPremScreenState();
}

class _AlightMotionPremScreenState extends State<AlightMotionPremScreen> {
  static const String baseSatriam = 'https://satriam.satriadeveloperz.workers.dev';
  static const String baseGenEmail = 'https://generator.email';
  static const String userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36';

  final TextEditingController _manualEmailController = TextEditingController();
  final TextEditingController _manualLinkController = TextEditingController();

  int _usageCount = 0;
  final int _maxLimit = 15;
  bool _isLoading = false;
  String _loadingStatus = '';
  int _activeTab = 0; // 0 = Auto Generate, 1 = Manual Input
  int _manualStep = 1; // Untuk mode manual

  Map<String, dynamic>? _generatedResult;

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
    final lastCycleMillis = prefs.getInt('am_last_cycle_timestamp') ?? 0;
    final currentCycleMillis = _getCurrentCycleStart().millisecondsSinceEpoch;

    if (lastCycleMillis < currentCycleMillis) {
      await prefs.setInt('am_last_cycle_timestamp', currentCycleMillis);
      await prefs.setInt('am_daily_usage_count', 0);
      setState(() => _usageCount = 0);
    } else {
      setState(() => _usageCount = prefs.getInt('am_daily_usage_count') ?? 0);
    }
  }

  Future<void> _incrementUsage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _usageCount++);
    await prefs.setInt('am_daily_usage_count', _usageCount);
  }

  // === SATRIAM & GENERATOR.EMAIL API LOGIC ===

  Future<Map<String, String>> _getGeneratorEmailSession() async {
    final res = await http.get(
      Uri.parse('$baseGenEmail/'),
      headers: {'User-Agent': userAgent},
    ).timeout(const Duration(seconds: 10));

    final rawCookies = res.headers['set-cookie'] ?? '';
    String hpCookieHeader = '';
    String domain = 'heyzalo.vn';

    if (rawCookies.contains('__Host-ab_hp=')) {
      final parts = rawCookies.split(';');
      for (var part in parts) {
        if (part.trim().startsWith('__Host-ab_hp=')) {
          hpCookieHeader = part.trim();
          break;
        }
      }
    }

    if (rawCookies.contains('inbox_ctx=')) {
      try {
        final ctxPart = rawCookies
            .split(';')
            .firstWhere((element) => element.contains('inbox_ctx='));
        final val = ctxPart.split('=')[1];
        final decoded = Uri.decodeComponent(val);
        final extracted = decoded.split('/')[0];
        if (extracted.isNotEmpty) domain = extracted;
      } catch (_) {}
    }

    return {'domain': domain, 'hpCookieHeader': hpCookieHeader};
  }

  String _generateRandomUser() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    String user = 'am';
    for (int i = 0; i < 6; i++) {
      user += chars[(chars.length * (DateTime.now().microsecondsSinceEpoch % 100) ~/ 100) % chars.length];
    }
    user += (10 + (DateTime.now().millisecondsSinceEpoch % 89)).toString();
    return user;
  }

  Future<Map<String, dynamic>> _sendSatriamLink(String email) async {
    final res = await http
        .post(
          Uri.parse('$baseSatriam/api/satriam/send-link'),
          headers: {
            'Content-Type': 'application/json',
            'User-Agent': userAgent,
          },
          body: jsonEncode({'email': email}),
        )
        .timeout(const Duration(seconds: 15));

    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> _verifySatriamLink(String email, String magicLink) async {
    final res = await http
        .post(
          Uri.parse('$baseSatriam/api/satriam/verify-link'),
          headers: {
            'Content-Type': 'application/json',
            'User-Agent': userAgent,
          },
          body: jsonEncode({'email': email, 'magicLink': magicLink}),
        )
        .timeout(const Duration(seconds: 15));

    return jsonDecode(res.body);
  }

  Future<String> _fetchMagicLink(String domain, String user, String hpCookieHeader) async {
    final ctx = Uri.encodeComponent('$domain/$user/');
    final cookies = 'inbox_ctx=$ctx; $hpCookieHeader';

    for (int attempt = 1; attempt <= 10; attempt++) {
      await Future.delayed(Duration(seconds: attempt == 1 ? 5 : 3));
      if (!mounted) break;

      setState(() => _loadingStatus = 'Mengecek Inbox email (Percobaan $attempt/10)...');

      try {
        final res = await http.get(
          Uri.parse('$baseGenEmail/inbox1/'),
          headers: {
            'User-Agent': userAgent,
            'Cookie': cookies,
          },
        ).timeout(const Duration(seconds: 10));

        final html = res.body;
        final regExp = RegExp(r'''https?://[^\s"'<>]+''', caseSensitive: false);


        final matches = regExp.allMatches(html);

        for (final match in matches) {
          final link = match.group(0) ?? '';
          if ((link.contains('alight-creative.firebaseapp.com') ||
                  link.contains('alightcreative.com')) &&
              (link.contains('signInWithEmailLink') ||
                  link.contains('auth_action') ||
                  link.contains('links?link='))) {
            return link.replaceAll('&amp;', '&');
          }
        }
      } catch (_) {}
    }

    throw Exception('Waktu tunggu email Magic Link habis.');
  }

  // === PROCESS ACTIONS ===

  Future<void> _handleAutoGenerate() async {
    if (_usageCount >= _maxLimit) {
      _showSnackBar('Limit harian ($_maxLimit/$_maxLimit) tercapai! Reset pada jam 12:00 WIB.');
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingStatus = 'Memulai pembuatan akun Temp Mail...';
      _generatedResult = null;
    });

    try {
      final session = await _getGeneratorEmailSession();
      final domain = session['domain']!;
      final hpCookieHeader = session['hpCookieHeader']!;
      final user = _generateRandomUser();
      final email = '$user@$domain';

      setState(() => _loadingStatus = 'Mengirim Magic Link ke $email...');
      final sendRes = await _sendSatriamLink(email);

      if (sendRes['success'] != true) {
        throw Exception(sendRes['message'] ?? sendRes['error'] ?? 'Gagal mengirim magic link.');
      }

      setState(() => _loadingStatus = 'Menunggu email masuk dari Alight Motion...');
      final magicLink = await _fetchMagicLink(domain, user, hpCookieHeader);

      setState(() => _loadingStatus = 'Memverifikasi akun Alight Motion Pro...');
      final verifyRes = await _verifySatriamLink(email, magicLink);

      if (verifyRes['success'] != true) {
        throw Exception(verifyRes['message'] ?? verifyRes['error'] ?? 'Gagal memverifikasi magic link.');
      }

      await _incrementUsage();

      setState(() {
        _isLoading = false;
        _generatedResult = {
          'email': email,
          'inbox': '$baseGenEmail/$email',
          'plan': verifyRes['planName'] ?? 'Alight Motion Pro / Premium',
          'status': verifyRes['membershipStatus'] ?? 'PREMIUM_ACTIVE',
          'orderId': verifyRes['orderId'] ?? '-',
        };
      });

      _showSnackBar('Berhasil membuat akun Alight Motion Premium!');
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  Future<void> _handleManualSendLink() async {
    final email = _manualEmailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showSnackBar('Masukkan email yang valid!');
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingStatus = 'Mengirim Magic Link ke $email...';
    });

    try {
      final sendRes = await _sendSatriamLink(email);
      setState(() => _isLoading = false);

      if (sendRes['success'] == true) {
        setState(() => _manualStep = 2);
        _showSnackBar('Magic Link telah dikirim ke $email. Silakan cek Inbox/Spam.');
      } else {
        _showSnackBar(sendRes['message'] ?? sendRes['error'] ?? 'Gagal mengirim link.');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Kesalahan koneksi: $e');
    }
  }

  Future<void> _handleManualVerifyLink() async {
    final email = _manualEmailController.text.trim();
    final link = _manualLinkController.text.trim();

    if (link.isEmpty || !link.startsWith('http')) {
      _showSnackBar('Masukkan Magic Link URL yang valid!');
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingStatus = 'Memverifikasi Magic Link...';
    });

    try {
      final verifyRes = await _verifySatriamLink(email, link);
      setState(() => _isLoading = false);

      if (verifyRes['success'] == true) {
        await _incrementUsage();
        setState(() {
          _manualStep = 3;
          _generatedResult = {
            'email': email,
            'plan': verifyRes['planName'] ?? 'Alight Motion Pro / Premium',
            'status': verifyRes['membershipStatus'] ?? 'PREMIUM_ACTIVE',
            'orderId': verifyRes['orderId'] ?? '-',
          };
        });
        _showSnackBar('Aktivasi Alight Motion Premium Berhasil!');
      } else {
        _showSnackBar(verifyRes['message'] ?? verifyRes['error'] ?? 'Verifikasi gagal.');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Kesalahan koneksi: $e');
    }
  }

  void _showSnackBar(String msg) {
    if (!mounted) return;
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: theme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNeo = themeModeNotifier.value != 0;
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isLight ? Colors.black87 : Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'ALIGHT',
                style: TextStyle(
                  color: isLight ? Colors.black87 : Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              TextSpan(
                text: ' MOTION PRO',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14, top: 12, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(isNeo ? 4 : 12),
              border: Border.all(
                color: isNeo ? Colors.black : theme.colorScheme.primary.withOpacity(0.5),
                width: isNeo ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(
                'Limit: ${_maxLimit - _usageCount}/$_maxLimit',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TAB SELECTOR (AUTO VS MANUAL)
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(isNeo ? 8 : 16),
                  border: Border.all(
                    color: isNeo ? Colors.black : theme.colorScheme.primary.withOpacity(0.3),
                    width: isNeo ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _isLoading ? null : () => setState(() => _activeTab = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _activeTab == 0
                                ? theme.colorScheme.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(isNeo ? 6 : 14),
                          ),
                          child: Center(
                            child: Text(
                              'Otomatis (1-Click)',
                              style: TextStyle(
                                color: _activeTab == 0
                                    ? Colors.white
                                    : (isLight ? Colors.black87 : Colors.white70),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: _isLoading ? null : () => setState(() => _activeTab = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _activeTab == 1
                                ? theme.colorScheme.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(isNeo ? 6 : 14),
                          ),
                          child: Center(
                            child: Text(
                              'Manual Email',
                              style: TextStyle(
                                color: _activeTab == 1
                                    ? Colors.white
                                    : (isLight ? Colors.black87 : Colors.white70),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // TAB 0: AUTO GENERATE
              if (_activeTab == 0) ...[
                _buildCardContainer(
                  context: context,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.bolt_rounded, color: theme.colorScheme.primary, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            'Auto Generator Pro',
                            style: TextStyle(
                              color: isLight ? Colors.black87 : Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sistem akan otomatis membuat email sementara, mengirim magic link, dan mengaktifkan akun Alight Motion Premium tanpa ribet.',
                        style: TextStyle(
                          color: isLight ? Colors.black54 : Colors.white60,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(isNeo ? 6 : 12),
                            ),
                            elevation: isNeo ? 0 : 4,
                          ),
                          onPressed: _isLoading ? null : _handleAutoGenerate,
                          child: const Text(
                            'Buat Akun Pro Sekarang',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ]

              // TAB 1: MANUAL EMAIL & VERIFY LINK
              else ...[
                _buildCardContainer(
                  context: context,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _manualStep == 1
                            ? 'Langkah 1: Masukkan Email Anda'
                            : _manualStep == 2
                                ? 'Langkah 2: Tempelkan Magic Link'
                                : 'Aktivasi Berhasil!',
                        style: TextStyle(
                          color: isLight ? Colors.black87 : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (_manualStep == 1) ...[
                        _buildTextField(
                          context: context,
                          controller: _manualEmailController,
                          hint: 'user@gmail.com',
                          label: 'Alamat Email Gmail',
                          icon: Icons.email_rounded,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(isNeo ? 6 : 12),
                              ),
                            ),
                            onPressed: _isLoading ? null : _handleManualSendLink,
                            child: const Text(
                              'Kirim Magic Link',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ] else if (_manualStep == 2) ...[
                        _buildTextField(
                          context: context,
                          controller: _manualLinkController,
                          hint: 'https://alightcreative.com/...',
                          label: 'Magic Link URL dari Email',
                          icon: Icons.link_rounded,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(isNeo ? 6 : 12),
                              ),
                            ),
                            onPressed: _isLoading ? null : _handleManualVerifyLink,
                            child: const Text(
                              'Verifikasi & Aktifkan',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        Center(
                          child: TextButton(
                            onPressed: () => setState(() => _manualStep = 1),
                            child: Text(
                              'Ganti Email',
                              style: TextStyle(color: theme.colorScheme.primary),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              // LOADING INDICATOR STATUS
              if (_isLoading) ...[
                const SizedBox(height: 20),
                _buildCardContainer(
                  context: context,
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: theme.colorScheme.primary),
                      const SizedBox(height: 14),
                      Text(
                        _loadingStatus,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isLight ? Colors.black87 : Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // RESULT CARD DISPLAY
              if (_generatedResult != null && !_isLoading) ...[
                const SizedBox(height: 20),
                _buildCardContainer(
                  context: context,
                  borderColor: Colors.greenAccent,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 26),
                          SizedBox(width: 8),
                          Text(
                            'Akun Pro Berhasil Dibuat!',
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24, color: Colors.white24),
                      _buildResultItem('Email', _generatedResult!['email'] ?? '-'),
                      _buildResultItem('Plan Status', _generatedResult!['plan'] ?? 'Pro'),
                      _buildResultItem('Membership', _generatedResult!['status'] ?? 'ACTIVE'),
                      if (_generatedResult!['inbox'] != null)
                        _buildResultItem('Inbox Mail', _generatedResult!['inbox']!),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: theme.colorScheme.primary),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(isNeo ? 6 : 10),
                                ),
                              ),
                              icon: Icon(Icons.copy_rounded, color: theme.colorScheme.primary, size: 16),
                              label: Text(
                                'Salin Email',
                                style: TextStyle(color: theme.colorScheme.primary, fontSize: 12),
                              ),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: _generatedResult!['email'] ?? ''));
                                _showSnackBar('Email disalin ke clipboard!');
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardContainer({
    required BuildContext context,
    required Widget child,
    Color? borderColor,
  }) {
    final theme = Theme.of(context);
    final isNeo = themeModeNotifier.value != 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(isNeo ? 8 : 20),
        border: Border.all(
          color: borderColor ??
              (isNeo ? Colors.black : theme.colorScheme.primary.withOpacity(0.4)),
          width: isNeo ? 2.5 : 1.5,
        ),
        boxShadow: isNeo
            ? [
                const BoxShadow(
                  color: Colors.black,
                  blurRadius: 0,
                  offset: Offset(3, 3),
                )
              ]
            : [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: child,
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String hint,
    required String label,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final isNeo = themeModeNotifier.value != 0;
    final isLight = theme.brightness == Brightness.light;

    return TextField(
      controller: controller,
      style: TextStyle(color: isLight ? Colors.black87 : Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isLight ? Colors.black54 : Colors.white70),
        hintText: hint,
        hintStyle: TextStyle(color: isLight ? Colors.black38 : Colors.white30),
        prefixIcon: Icon(icon, color: theme.colorScheme.primary),
        filled: true,
        fillColor: theme.scaffoldBackgroundColor,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isNeo ? 6 : 12),
          borderSide: BorderSide(
            color: isNeo ? Colors.black : theme.colorScheme.primary.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isNeo ? 6 : 12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildResultItem(String label, String value) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isLight ? Colors.black54 : Colors.white54,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          SelectableText(
            value,
            style: TextStyle(
              color: isLight ? Colors.black87 : Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
