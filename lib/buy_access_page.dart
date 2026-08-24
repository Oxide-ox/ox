import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:typed_data';
import 'btrapps/.dart'; // Sesuaikan lokasi file Api Anda

final baseUrl = Api.api;

// =============================================================================
// MODEL DATA PAKET
// =============================================================================
class PackageOption {
  final String role;
  final String duration;
  final String day; 
  final int price;

  PackageOption({
    required this.role,
    required this.duration,
    required this.day,
    required this.price,
  });

  String get label =>
      "$role - $duration (Rp ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')})";
}

// =============================================================================
// KONSTANTA WARNA TEMA & CONFIG NEVAPEDIA + TELEGRAM + VIP GROUP
// =============================================================================
class AppTheme {
  static const Color bgDark = Color(0xFF0D0D0E);
  static Color cardBg = const Color(0xFF160A22).withOpacity(0.85);
  static const Color primaryMagenta = Color(0xFFE6007E);
  static const Color secondaryPurple = Color(0xFF8E00C7);
  static const Color whiteText = Colors.white;
  static const Color grayText = Color(0xFFA0A0AB);

  static const String serverSecretKey = "PRIKITIWW_OXIDE";

  // 🟢 CONFIG NEVAPEDIA API
  static const String nevapediaApiKey = "SKY_efa101865cfa488b"; // Masukkan API Key Nevapedia Anda
  static const String nevapediaBaseUrl = "https://app.nevapedia.com";

  // 🤖 CONFIG BOT TELEGRAM CHANNEL & VIP GROUP
  static const String telegramBotToken = "8819084946:AAEKejK9JhiRUkgjph5HlNrXddQog3ggKwU"; 
  static const String telegramChannelId = "@AllinformationVirz"; 
  
  // 🔴 ID GRUP VIP TELEGRAM (Contoh: -1001234567890 atau @UsernameGrupVip)
  // Bot WAJIB jadi Admin di grup ini!
  static const String telegramVipGroupId = "-1003729220914"; 
}

class BuyAccessPage extends StatefulWidget {
  const BuyAccessPage({super.key});

  @override
  State<BuyAccessPage> createState() => _BuyAccessPageState();
}

class _BuyAccessPageState extends State<BuyAccessPage> {
  final customUserControl = TextEditingController();
  final customPassControl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final GlobalKey _receiptKey = GlobalKey(); 

  bool _obscurePassword = true;
  bool _isGeneratingQr = false;
  Timer? _pollingTimer;

  final List<PackageOption> _packageList = [
    PackageOption(role: "member", duration: "1d", day: "1", price: 2000),
    PackageOption(role: "member", duration: "7d", day: "7", price: 5000),
    PackageOption(role: "member", duration: "1bulan", day: "30", price: 10000),
    PackageOption(role: "member", duration: "permanen", day: "99999", price: 15000),
    PackageOption(role: "vip", duration: "perma", day: "3650", price: 20000),
    PackageOption(role: "reseller", duration: "perma", day: "99999", price: 25000),
    PackageOption(role: "admin", duration: "perma", day: "99999", price: 35000),
   PackageOption(role: "owner", duration: "perma", day: "99999", price: 50000),
   PackageOption(role: "staff", duration: "perma", day: "3650", price: 70000),
  ];

  late PackageOption _selectedPackage;

  @override
  void initState() {
    super.initState();
    _selectedPackage = _packageList[0];
  }

  // ⚡ 1. PROSES PEMBUATAN AKUN AUTOMATIS KE BACKEND (/userAdd)
  Future<bool> _createUserAccount({
    required String username,
    required String password,
    required String day,
    required String role,
  }) async {
    try {
      final url = Uri.parse(
        '$baseUrl/userAdd?key=${AppTheme.serverSecretKey}&username=$username&password=$password&day=$day&role=${role.toLowerCase()}',
      );
      final res = await http.get(url);
      final data = jsonDecode(res.body);

      return data['created'] == true;
    } catch (_) {
      return false;
    }
  }

  // 🔗 2. GENERATE LINK TELEGRAM VIP DYNAMIC (1X PAKAI / MEMBER_LIMIT = 1)
  Future<String?> _generateOneTimeTelegramVipLink() async {
    try {
      final url = Uri.parse("https://api.telegram.org/bot${AppTheme.telegramBotToken}/createChatInviteLink");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "chat_id": AppTheme.telegramVipGroupId,
          "member_limit": 1, // 🔴 KUNCI: HANYA UNTUK 1 USER, LALU OTOMATIS HANGUS
          "name": "VIP Single-Use: ${customUserControl.text.trim()}",
        }),
      );

      final data = jsonDecode(response.body);
      if (data['ok'] == true && data['result'] != null) {
        return data['result']['invite_link']; // Mengembalikan link unik (misal: https://t.me/+AbCdEf...)
      }
    } catch (e) {
      debugPrint("Error generate 1-time link: $e");
    }
    return null;
  }

  // ⚡ 3. GENERATE INVOICE QRIS VIA NEVAPEDIA API
  Future<void> _generateNevapediaQris() async {
    if (!_formKey.currentState!.validate()) return;

    final customUser = customUserControl.text.trim();
    final customPass = customPassControl.text.trim();

    setState(() => _isGeneratingQr = true);

    try {
      final url = Uri.parse(
        "${AppTheme.nevapediaBaseUrl}/api/invoice?apikey=${AppTheme.nevapediaApiKey}&amount=${_selectedPackage.price}",
      );

      final response = await http.get(url);
      final resData = jsonDecode(response.body);

      if (resData['invoice_id'] != null && resData['qris_image'] != null) {
        final qrImageUrl = resData['qris_image'];
        final invoiceId = resData['invoice_id'];

        if (mounted) {
          _showQRModal(
            context,
            qrImageUrl: qrImageUrl,
            invoiceId: invoiceId,
            customUser: customUser,
            customPass: customPass,
          );
        }
      } else {
        _showErrorSnackBar(resData['message'] ?? "Gagal membuat QRIS Invoice.");
      }
    } catch (e) {
      _showErrorSnackBar("Terjadi kesalahan koneksi ke Nevapedia.");
    } finally {
      if (mounted) setState(() => _isGeneratingQr = false);
    }
  }

  // 📸 4. CONVERT WIDGET STRUK MENJADI GAMBAR PNG
  Future<Uint8List?> _captureReceiptBytes() async {
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      RenderRepaintBoundary boundary =
          _receiptKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  // 📤 5. KIRIM STRUK GAMBAR & CAPTION KE BOT TELEGRAM
  Future<void> _sendReceiptToTelegramChannel(Uint8List imageBytes) async {
    if (AppTheme.telegramBotToken.contains("GANTI")) return;

    try {
      final String caption =
          "Role: ${_selectedPackage.role}\n"
          "Durasi: ${_selectedPackage.duration}\n"
          "Harga: Rp ${_selectedPackage.price}\n"
          "buy Oxide app & sc di @Virzofc";

      final uri = Uri.parse("https://api.telegram.org/bot${AppTheme.telegramBotToken}/sendPhoto");
      var request = http.MultipartRequest("POST", uri);

      request.fields['chat_id'] = AppTheme.telegramChannelId;
      request.fields['caption'] = caption;

      request.files.add(
        http.MultipartFile.fromBytes(
          'photo',
          imageBytes,
          filename: 'struk_${DateTime.now().millisecondsSinceEpoch}.png',
        ),
      );

      await request.send();
    } catch (_) {}
  }

  // 🔄 6. AUTO POLLING CEK STATUS INVOICE NEVAPEDIA
  void _startPollingStatus(String invoiceId, BuildContext modalContext) {
    _pollingTimer?.cancel();

    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        final url = Uri.parse(
          "${AppTheme.nevapediaBaseUrl}/api/invoice/status?apikey=${AppTheme.nevapediaApiKey}&invoice_id=$invoiceId",
        );

        final response = await http.get(url);
        final statusData = jsonDecode(response.body);

        if (statusData['invoice_id'] != null) {
          final String status = statusData['status'];

          if (status == 'paid' || status == 'success') {
            timer.cancel();

            final username = customUserControl.text.trim();
            final password = customPassControl.text.trim();

            // 1. Buat akun otomatis ke backend /userAdd
            await _createUserAccount(
              username: username,
              password: password,
              day: _selectedPackage.day,
              role: _selectedPackage.role,
            );

            // 2. Cek apakah berhak mendapatkan Link VIP 1x pakai (Member Perma ke atas)
            final bool isVipOrPermanent = _selectedPackage.duration.toLowerCase().contains('perma') || 
                                           _selectedPackage.role != 'member';
            
            String? oneTimeLink;
            if (isVipOrPermanent) {
              oneTimeLink = await _generateOneTimeTelegramVipLink();
            }

            // 3. Generate Struk Bukti & Kirim ke Telegram Channel
            final receiptBytes = await _captureReceiptBytes();
            if (receiptBytes != null) {
              await _sendReceiptToTelegramChannel(receiptBytes);
            }

            if (Navigator.canPop(modalContext)) {
              Navigator.pop(modalContext);
            }

            // 4. Tampilkan dialog sukses beserta link 1x pakai
            _showSuccessPaymentDialog(oneTimeLink);

          } else if (status == 'expired' || status == 'cancel' || status == 'failed') {
            timer.cancel();
            if (Navigator.canPop(modalContext)) {
              Navigator.pop(modalContext);
            }
            _showErrorSnackBar("Transaksi telah expired atau dibatalkan.");
          }
        }
      } catch (_) {}
    });
  }

  // 📥 BUKA LINK GRUP
  Future<void> _launchExternalUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showErrorSnackBar("Gagal membuka tautan.");
    }
  }

  // 🖼️ MODAL POPUP DISPLAY QR CODE
  void _showQRModal(
    BuildContext context, {
    required String qrImageUrl,
    required String invoiceId,
    required String customUser,
    required String customPass,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (modalContext) {
        _startPollingStatus(invoiceId, modalContext);

        return AlertDialog(
          backgroundColor: const Color(0xFF14081E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppTheme.primaryMagenta),
          ),
          title: const Text(
            "SCAN QRIS PAY",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.primaryMagenta, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E0616),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryMagenta.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Text("Account: $customUser", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text("Role: ${_selectedPackage.role.toUpperCase()} (${_selectedPackage.duration})", style: const TextStyle(color: AppTheme.grayText, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 15),

              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Image.network(
                  qrImageUrl,
                  width: 190,
                  height: 190,
                  loadingBuilder: (_, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const SizedBox(
                      width: 190,
                      height: 190,
                      child: Center(
                        child: CircularProgressIndicator(color: AppTheme.primaryMagenta),
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image_rounded,
                    size: 100,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryMagenta),
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Mengecek pembayaran otomatis...",
                    style: TextStyle(color: AppTheme.grayText, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryMagenta,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => _launchExternalUrl(qrImageUrl),
              icon: const Icon(Icons.download_rounded, color: Colors.white, size: 18),
              label: const Text("DOWNLOAD QR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            TextButton(
              onPressed: () {
                _pollingTimer?.cancel();
                Navigator.pop(modalContext);
              },
              child: const Text("Batal", style: TextStyle(color: Colors.white54)),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessPaymentDialog(String? oneTimeVipLink) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF14081E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.greenAccent),
        ),
        title: const Text(
          "🎉 PEMBAYARAN LUNAS!",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Pembayaran berhasil terverifikasi. Akun custom Anda otomatis dibuat dan bukti struk diposting ke Telegram!",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            if (oneTimeVipLink != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E0616),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryMagenta.withOpacity(0.5)),
                ),
                child: Column(
                  children: [
                    const Text(
                      "🎁 Link Grup VIP (Khusus 1x Pakai / Sekali Masuk Langsung Kadaluwarsa):",
                      style: TextStyle(color: AppTheme.primaryMagenta, fontWeight: FontWeight.bold, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryPurple,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _launchExternalUrl(oneTimeVipLink),
                      icon: const Icon(Icons.group_rounded, color: Colors.white, size: 16),
                      label: const Text("JOIN GRUP EKSKLUSIF", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("OK, Mantap!", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    customUserControl.dispose();
    customPassControl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Stack(
        children: [
          // 🖼️ WIDGET STRUK AUTOGENERATE
          Positioned(
            left: -9999,
            child: RepaintBoundary(
              key: _receiptKey,
              child: Container(
                width: 350,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(color: Color(0xFF0F0818)),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.12,
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(Icons.security, size: 150, color: Colors.white),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "OXIDE APPS",
                          style: TextStyle(
                            color: AppTheme.primaryMagenta,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        const Text(
                          "TRANSACTION RECEIPT",
                          style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 1),
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: AppTheme.primaryMagenta, thickness: 1),
                        const SizedBox(height: 12),
                        _buildReceiptRow("USERNAME", customUserControl.text.isEmpty ? "User" : customUserControl.text),
                        _buildReceiptRow("ROLE", _selectedPackage.role.toUpperCase()),
                        _buildReceiptRow("DURASI", _selectedPackage.duration),
                        _buildReceiptRow("TOTAL HARGA", "Rp ${_selectedPackage.price}"),
                        _buildReceiptRow("STATUS", "SUCCESS / LUNAS", isStatus: true),
                        const SizedBox(height: 12),
                        const Divider(color: Colors.white24),
                        const SizedBox(height: 8),
                        const Text(
                          "buy Oxide app & sc di @Virzofc",
                          style: TextStyle(color: AppTheme.grayText, fontSize: 11, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          _buildGlow(null, -60, AppTheme.secondaryPurple.withOpacity(0.25), bottom: -60),

          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    padding: const EdgeInsets.all(16),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.primaryMagenta),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "ORDER ACCESS",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.whiteText,
                            ),
                          ),
                          const Text("Set Custom Credentials", style: TextStyle(color: AppTheme.grayText)),
                          const SizedBox(height: 20),

                          _buildAppLogo(size: 75),
                          const SizedBox(height: 25),

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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Custom Account Info", style: TextStyle(color: AppTheme.primaryMagenta, fontWeight: FontWeight.bold, fontSize: 14)),
                                  const SizedBox(height: 14),

                                  TextFormField(
                                    controller: customUserControl,
                                    validator: (v) => (v == null || v.isEmpty) ? "Username custom wajib diisi" : null,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      labelText: "Custom Username",
                                      labelStyle: const TextStyle(color: AppTheme.grayText),
                                      prefixIcon: const Icon(Icons.person_add_alt_1_rounded, color: AppTheme.primaryMagenta),
                                      filled: true,
                                      fillColor: const Color(0xFF0E0616),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                    ),
                                  ),
                                  const SizedBox(height: 14),

                                  TextFormField(
                                    controller: customPassControl,
                                    obscureText: _obscurePassword,
                                    validator: (v) => (v == null || v.isEmpty) ? "Password custom wajib diisi" : null,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      labelText: "Custom Password",
                                      labelStyle: const TextStyle(color: AppTheme.grayText),
                                      prefixIcon: const Icon(Icons.key_rounded, color: AppTheme.primaryMagenta),
                                      suffixIcon: IconButton(
                                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: AppTheme.grayText),
                                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                      ),
                                      filled: true,
                                      fillColor: const Color(0xFF0E0616),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Divider(color: Colors.white10),
                                  const SizedBox(height: 12),

                                  const Text("Pilih Paket Access", style: TextStyle(color: AppTheme.grayText, fontSize: 13)),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0E0616),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppTheme.primaryMagenta.withOpacity(0.3)),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<PackageOption>(
                                        value: _selectedPackage,
                                        dropdownColor: const Color(0xFF14081E),
                                        isExpanded: true,
                                        icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primaryMagenta),
                                        items: _packageList.map((pkg) {
                                          return DropdownMenuItem<PackageOption>(
                                            value: pkg,
                                            child: Text(
                                              pkg.label,
                                              style: const TextStyle(color: Colors.white, fontSize: 13),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(() => _selectedPackage = val);
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  _buildInfoRow("Role", _selectedPackage.role.toUpperCase()),
                                  _buildInfoRow("Durasi", _selectedPackage.duration),
                                  _buildInfoRow("Harga", "Rp ${_selectedPackage.price}", isPrice: true),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 25),

                          _buildGlowButton(
                            text: _isGeneratingQr ? "GENERATING QR..." : "PAY NOW (QRIS)",
                            icon: Icons.qr_code_scanner_rounded,
                            isLoading: _isGeneratingQr,
                            onTap: _isGeneratingQr ? () {} : _generateNevapediaQris,
                          ),
                          const SizedBox(height: 20),
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

  Widget _buildReceiptRow(String label, String value, {bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
          Text(
            value,
            style: TextStyle(
              color: isStatus ? Colors.greenAccent : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isPrice = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.grayText, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              color: isPrice ? AppTheme.primaryMagenta : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: isPrice ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppLogo({double size = 90}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.primaryMagenta, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryMagenta.withOpacity(0.4),
            blurRadius: 25,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset(
          'assets/images/logo.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.security, size: 40, color: AppTheme.primaryMagenta),
        ),
      ),
    );
  }

  Widget _buildGlowButton({
    required String text,
    required VoidCallback onTap,
    IconData? icon,
    bool isLoading = false,
  }) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryMagenta, AppTheme.secondaryPurple],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryMagenta.withOpacity(0.4),
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
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[Icon(icon, color: Colors.white, size: 20), const SizedBox(width: 8)],
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
