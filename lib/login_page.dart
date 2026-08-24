import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'splash.dart';
import 'btrapps/.dart';
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

// =============================================================================
// 1. MAIN LANDING PAGE (SWIPE UP: WELCOME -> DISCLAIMER -> MAIN MENU)
// =============================================================================
class MainLandingPage extends StatefulWidget {
  const MainLandingPage({super.key});

  @override
  State<MainLandingPage> createState() => _MainLandingPageState();
}

class _MainLandingPageState extends State<MainLandingPage> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Stack(
        children: [
          _buildGlow(-60, -60, AppTheme.primaryMagenta.withOpacity(0.18)),
          _buildGlow(null, -60, AppTheme.secondaryPurple.withOpacity(0.2), bottom: -60),

          SafeArea(
            child: PageView(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              children: [
                _buildWelcomeSlide(),
                _buildDisclaimerSlide(),
                _buildMainMenuSlide(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader() {
    return Column(
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
          "App: 4.0.0 (56)",
          style: TextStyle(
            color: AppTheme.grayText,
            fontSize: 12,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildSwipeUpIndicator() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.grayText.withOpacity(0.6), width: 2),
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: const EdgeInsets.only(top: 6),
              width: 4,
              height: 8,
              decoration: BoxDecoration(
                color: AppTheme.grayText,
                borderRadius: BorderRadius.circular(2),
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
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildWelcomeSlide() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          _buildTopHeader(),
          const Spacer(),
          const Text(
            ".WELCOME.",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 4,
              fontFamily: 'monospace',
            ),
          ),
          const Spacer(),
          _buildSwipeUpIndicator(),
        ],
      ),
    );
  }

  Widget _buildDisclaimerSlide() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          _buildTopHeader(),
          const Spacer(),
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Disclaimer",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  "Oxide Apps adalah platform komunitas digital yang dibangun untuk memberikan kebebasan dalam berinovasi. Kami menyediakan berbagai tools canggih, mulai dari sistem manajemen server hingga asisten AI pintar.",
                  style: TextStyle(
                    color: AppTheme.grayText,
                    fontSize: 14,
                    height: 1.6,
                    fontFamily: 'monospace',
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  "Dengan bergabung bersama kami, Anda menjadi bagian dari ekosistem yang terus berkembang, mengedepankan keamanan dan kenyamanan pengguna.",
                  style: TextStyle(
                    color: AppTheme.grayText,
                    fontSize: 14,
                    height: 1.6,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          _buildSwipeUpIndicator(),
        ],
      ),
    );
  }

  Widget _buildMainMenuSlide(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          _buildTopHeader(),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildAppLogo(size: 130),
                    const SizedBox(height: 35),

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

                    TextButton.icon(
                      onPressed: () async {
                        await launchUrl(
                          Uri.parse("https://t.me/Virzofc"),
                          mode: LaunchMode.externalApplication,
                        );
                      },
                      icon: const Icon(Icons.telegram, color: AppTheme.primaryMagenta, size: 20),
                      label: const Text(
                        "Telegram Channel",
                        style: TextStyle(color: AppTheme.grayText, fontSize: 13),
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
}

// =============================================================================
// 2. LOGIN PAGE (FORM UTAMA LOGIN)
// =============================================================================
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final userController = TextEditingController();
  final passController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool isLoading = false;
  bool _obscurePassword = true;
  String? androidId;

  @override
  void initState() {
    super.initState();
    initLogin();
  }

  Future<void> initLogin() async {
    androidId = await getAndroidId();
  }

  Future<String> getAndroidId() async {
    final deviceInfo = DeviceInfoPlugin();
    final android = await deviceInfo.androidInfo;
    return android.id ?? "unknown_device";
  }

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    final username = userController.text.trim();
    final password = passController.text.trim();

    setState(() => isLoading = true);

    try {
      final validate = await http.post(
        Uri.parse("$baseUrl/validate"),
        body: {
          "username": username,
          "password": password,
          "androidId": androidId ?? "unknown_device",
        },
      );

      final validData = jsonDecode(validate.body);
      if (validData['expired'] == true) {
        _showPopup(
          title: "⏳ Access Expired",
          message: "Masa akses Anda telah habis.\nSilakan perpanjang akses.",
          color: Colors.orangeAccent,
          showContact: true,
        );
      } else if (validData['valid'] != true) {
        final String errorMsg = (validData['message'] ?? "").toLowerCase();
        if (errorMsg.contains("perangkat") ||
            errorMsg.contains("device") ||
            errorMsg.contains("another")) {
          _showPopup(
            title: "⚠️ Sesi Aktif",
            message: "Akun ini sedang login di perangkat lain.\nSilakan logout terlebih dahulu di perangkat lama.",
            color: Colors.amberAccent,
          );
        } else {
          _showPopup(
            title: "❌ Login Gagal",
            message: "Username atau password salah.",
            color: AppTheme.primaryMagenta,
          );
        }
      } else {
        final prefs = await SharedPreferences.getInstance();
        prefs.setString("username", username);
        prefs.setString("password", password);
        prefs.setString("key", validData['key']);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => SplashScreen(
                username: username,
                password: password,
                role: validData['role'],
                userId: validData['userId'] ?? "000000",
                level: validData['level'] ?? "1",
                sessionKey: validData['key'],
                expiredDate: validData['expiredDate'],
                listBug: (validData['listBug'] as List? ?? [])
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .toList(),
                listDoos: (validData['listDDoS'] as List? ?? [])
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .toList(),
                news: (validData['news'] as List? ?? [])
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .toList(),
              ),
            ),
          );
        }
      }
    } catch (e) {
      _showPopup(
        title: "⚠️ Connection Error",
        message: "Gagal terhubung ke server.\nPeriksa koneksi internet Anda.",
        color: AppTheme.primaryMagenta,
      );
    }

    if (mounted) setState(() => isLoading = false);
  }

  void _showPopup({
    required String title,
    required String message,
    Color color = AppTheme.primaryMagenta,
    bool showContact = false,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF14081E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: color.withOpacity(0.5), width: 1),
        ),
        title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
        content: Text(message, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        actions: [
          if (showContact)
            TextButton(
              onPressed: () async {
                await launchUrl(Uri.parse("https://t.me/Virzofc"), mode: LaunchMode.externalApplication);
              },
              child: const Text("Contact Admin", style: TextStyle(color: AppTheme.primaryMagenta, fontWeight: FontWeight.bold)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    userController.dispose();
    passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Stack(
        children: [
          _buildGlow(-60, -60, AppTheme.primaryMagenta.withOpacity(0.2)),
          _buildGlow(null, -60, AppTheme.secondaryPurple.withOpacity(0.25), bottom: -60),

          SafeArea(
            child: Column(
              children: [
                Stack(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        padding: const EdgeInsets.all(16),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.primaryMagenta),
                        onPressed: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          } else {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const MainLandingPage()),
                            );
                          }
                        },
                      ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Column(
                          children: const [
                            Text(
                              "LOGIN PORTAL",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.whiteText,
                                letterSpacing: 1.5,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              "v4.0.0",
                              style: TextStyle(color: AppTheme.grayText, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildAppLogo(size: 120),
                          const SizedBox(height: 30),

                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppTheme.cardBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.primaryMagenta.withOpacity(0.3)),
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  _buildTextField(
                                    controller: userController,
                                    label: "Username",
                                    icon: Icons.person_outline_rounded,
                                    validator: (v) => (v == null || v.trim().isEmpty) ? "Username wajib diisi" : null,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    controller: passController,
                                    label: "Password",
                                    icon: Icons.lock_outline_rounded,
                                    isPass: true,
                                    validator: (v) => (v == null || v.trim().isEmpty) ? "Password wajib diisi" : null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 25),

                          _buildGlowButton(
                            text: isLoading ? "LOADING..." : "SUBMIT LOGIN",
                            isLoading: isLoading,
                            onTap: isLoading ? () {} : login,
                          ),
                          const SizedBox(height: 25),

                          GestureDetector(
                            onTap: () async {
                              await launchUrl(
                                Uri.parse("https://t.me/Virzofc"),
                                mode: LaunchMode.externalApplication,
                              );
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.help_outline_rounded, size: 16, color: AppTheme.grayText),
                                SizedBox(width: 6),
                                Text("Butuh bantuan? ", style: TextStyle(color: AppTheme.grayText, fontSize: 13)),
                                Text(
                                  "Hubungi Admin",
                                  style: TextStyle(
                                    color: AppTheme.primaryMagenta,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 15),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPass = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPass ? _obscurePassword : false,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.grayText, fontSize: 14),
        prefixIcon: Icon(icon, color: AppTheme.primaryMagenta, size: 22),
        suffixIcon: isPass
            ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: AppTheme.grayText,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              )
            : null,
        filled: true,
        fillColor: const Color(0xFF0E0616),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryMagenta.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryMagenta, width: 1.5),
        ),
      ),
    );
  }
}

// =============================================================================
// REUSABLE HELPER WIDGETS
// =============================================================================
Widget _buildAppLogo({double size = 90}) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: AppTheme.primaryMagenta, width: 1.8),
      boxShadow: [
        BoxShadow(
          color: AppTheme.primaryMagenta.withOpacity(0.45),
          blurRadius: 30,
          spreadRadius: 3,
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Image.asset(
        'assets/images/logo.png',
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
  bool isLoading = false,
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
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) Icon(icon, color: Colors.white, size: 20),
                    if (icon != null) const SizedBox(width: 8),
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
