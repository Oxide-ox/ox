import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'splash.dart';
import 'btrapps/.dart';
import 'login_page.dart';
import 'buy_access_page.dart';

final baseUrl = Api.api;

// =============================================================================
// KONSTANTA WARNA TEMA (Neon Magenta & Deep Gothic Purple)
// =============================================================================
class AppTheme {
  static const Color bgDark = Color(0xFF0D0D0E);
  static Color cardBg = const Color(0xFF160A22).withOpacity(0.85);
  static const Color primaryMagenta = Color(0xFFE6007E);
  static const Color secondaryPurple = Color(0xFF8E00C7);
  static const Color yellowBadge = Color(0xFFFFC107);
  static const Color whiteText = Colors.white;
  static const Color grayText = Color(0xFFA0A0AB);
}

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with SingleTickerProviderStateMixin {
  int _currentPage = 0;
  late AnimationController _indicatorAnimController;
  late Animation<double> _indicatorAnimation;

  final PageController _pageController = PageController();
  bool _isCheckingAuth = true;

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();

    _indicatorAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _indicatorAnimation = Tween<double>(begin: 6.0, end: 18.0).animate(
      CurvedAnimation(parent: _indicatorAnimController, curve: Curves.easeInOut),
    );
  }

  // ⚡ LOGIKA AUTO LOGIN RESMI MILIKMU
  Future<void> _checkAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUser = prefs.getString("username");
    final savedPass = prefs.getString("password");
    final savedKey = prefs.getString("key");

    if (savedUser == null || savedPass == null || savedKey == null) {
      if (mounted) setState(() => _isCheckingAuth = false);
      return;
    }

    try {
      final deviceInfo = DeviceInfoPlugin();
      final android = await deviceInfo.androidInfo;
      final androidId = android.id ?? "unknown_device";

      final uri = Uri.parse("$baseUrl/myInfo?username=$savedUser&password=$savedPass&androidId=$androidId&key=$savedKey");
      final res = await http.get(uri);
      final data = jsonDecode(res.body);

      if (data['valid'] == true && data['expired'] == false) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SplashScreen(
              userId: data['userId'] ?? "000000",
              level: data['level'] ?? "1",
              username: savedUser,
              password: savedPass,
              role: data['role'],
              sessionKey: data['key'],
              expiredDate: data['expiredDate'],
              listBug: (data['listBug'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
              listDoos: (data['listDDoS'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
              news: (data['news'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
            ),
          ),
        );
      } else {
        if (mounted) setState(() => _isCheckingAuth = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isCheckingAuth = false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _indicatorAnimController.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception("Could not launch $uri");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return Scaffold(
        backgroundColor: AppTheme.bgDark,
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryMagenta),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Stack(
        children: [
          // 1. BACKGROUND GLOW EFFECTS (NEON MAGENTA & PURPLE)
          _buildGlow(-60, -60, AppTheme.primaryMagenta.withOpacity(0.2)),
          _buildGlow(null, -60, AppTheme.secondaryPurple.withOpacity(0.25), bottom: -60),

          // 2. KONTEN VERTICAL PAGEVIEW (SWIPE UP)
          PageView(
            scrollDirection: Axis.vertical,
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() => _currentPage = page);
            },
            children: [
              // --- SLIDE 1: WELCOME ---
              _buildWelcomeSlide(),

              // --- SLIDE 2: DISCLAIMER ---
              _buildDisclaimerSlide(),

              // --- SLIDE 3: LANDING MENU UTAMA ---
              _buildMainLandingSlide(context),
            ],
          ),

          // 3. FIXED HEADER (ATAS)
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "OXIDE ",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.yellowBadge,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          "v",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "App: New Version",
                    style: TextStyle(
                      color: AppTheme.grayText,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. FIXED FOOTER (SWIPE ANIMATED INDICATOR)
          Positioned(
            bottom: 30, left: 0, right: 0,
            child: Center(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _currentPage == 2 ? 0.0 : 1.0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 22,
                      height: 42,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.grayText.withOpacity(0.6), width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.topCenter,
                      child: AnimatedBuilder(
                        animation: _indicatorAnimation,
                        builder: (context, child) => Padding(
                          padding: EdgeInsets.only(top: _indicatorAnimation.value),
                          child: Container(
                            width: 5,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryMagenta,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Swipe Up to continue",
                      style: TextStyle(
                        color: AppTheme.grayText,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- SLIDE BUILDERS ---
  Widget _buildWelcomeSlide() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Text(
            ".WELCOME.",
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimerSlide() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Disclaimer",
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          Text(
            "Oxide Apps adalah platform komunitas digital yang dibangun untuk memberikan kebebasan dalam berinovasi. Kami menyediakan berbagai tools canggih, mulai dari sistem manajemen server hingga asisten AI pintar.\n\nDengan bergabung bersama kami, Anda menjadi bagian dari ekosistem yang terus berkembang, mengedepankan keamanan dan kenyamanan pengguna.",
            style: TextStyle(
              color: AppTheme.grayText,
              fontSize: 14,
              height: 1.6,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainLandingSlide(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 60),

              // Logo Aplikasi Neon Glow
              _buildAppLogo(size: 130),
              const SizedBox(height: 25),

              // Title Header
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [AppTheme.primaryMagenta, Colors.white],
                ).createShader(bounds),
                child: const Text(
                  "OXIDE OX",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Please Log in or Buy Access to continue",
                style: TextStyle(
                  color: AppTheme.grayText,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 35),

              // 1. Tombol LOGIN FORM (Navigasi ke LoginPage)
              _buildGlowButton(
                text: "LOGIN FORM",
                icon: Icons.login_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                },
              ),
              const SizedBox(height: 16),

              // 2. Tombol BUY ACCESS AUTOMATIC (Navigasi ke BuyAccessPage)
              _buildGlowButton(
                text: "BUY ACCESS AUTOMATIC",
                icon: Icons.shopping_cart_checkout_rounded,
                isSecondary: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BuyAccessPage()),
                  );
                },
              ),
              const SizedBox(height: 20),

              // 3. Tombol Telegram Channel
              TextButton.icon(
                onPressed: () => _openUrl("https://t.me/AllinformationVirz"),
                icon: const Icon(Icons.telegram, color: AppTheme.primaryMagenta, size: 20),
                label: const Text(
                  "Telegram Channel",
                  style: TextStyle(color: AppTheme.grayText, fontSize: 13),
                ),
              ),

              const SizedBox(height: 25),
              const Text(
                "© 2026 Vanguard of Your Rising Empire",
                style: TextStyle(color: Colors.white38, fontSize: 11, fontFamily: 'monospace'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---
  Widget _buildAppLogo({double size = 90}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.primaryMagenta, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryMagenta.withOpacity(0.45),
            blurRadius: 30,
            spreadRadius: 3,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Image.asset(
          "assets/images/login.png",
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.security, size: 50, color: AppTheme.primaryMagenta),
        ),
      ),
    );
  }

  Widget _buildGlowButton({
    required String text,
    required VoidCallback onTap,
    IconData? icon,
    bool isSecondary = false,
  }) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isSecondary
              ? const [AppTheme.secondaryPurple, Color(0xFF4A0068)]
              : const [AppTheme.primaryMagenta, AppTheme.secondaryPurple],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: (isSecondary ? AppTheme.secondaryPurple : AppTheme.primaryMagenta).withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlow(double? top, double? left, Color color, {double? bottom, double? right}) {
    return Positioned(
      top: top,
      left: left,
      bottom: bottom,
      right: right,
      child: Container(
        width: 260,
        height: 260,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color,
              blurRadius: 100,
              spreadRadius: 30,
            ),
          ],
        ),
      ),
    );
  }
}
