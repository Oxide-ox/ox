import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'app_theme.dart';

class CreatePaymentHtmlPage extends StatefulWidget {
  const CreatePaymentHtmlPage({super.key});

  @override
  State<CreatePaymentHtmlPage> createState() => _CreatePaymentHtmlPageState();
}

class _CreatePaymentHtmlPageState extends State<CreatePaymentHtmlPage> {
  final _itemNameController = TextEditingController(text: "AKUN PREMIUM VIP");
  final _amountController = TextEditingController(text: "50000");
  final _qrisUrlController = TextEditingController(text: "https://smail.my.id/cloud/FHoXwjmX1");
  final _danaNumController = TextEditingController(text: "081234567890");
  final _danaNameController = TextEditingController(text: "RAMADHIAN WAFI");
  final _bcaNumController = TextEditingController(text: "1234567890");

  int _selectedTemplateIndex = 0;
  bool _isCreating = false;
  File? _generatedFile;

  bool get _isLight => Theme.of(context).brightness == Brightness.light;
  Color get _textColor => _isLight ? Colors.black87 : Colors.white;
  Color get _subTextColor => _isLight ? Colors.black54 : Colors.white70;
  bool get _isNeo => themeModeNotifier.value != 0;

  final List<Map<String, String>> _templates = [
    {
      "name": "Template 1: Modern Dark (QRIS + DANA)",
      "desc": "Tampilan cyberpunk dark mode dengan QRIS & DANA",
    },
    {
      "name": "Template 2: Complete Bank & E-Wallet",
      "desc": "Tampilan lengkap (QRIS + DANA + Bank BCA)",
    },
    {
      "name": "Template 3: Neo-Brutalist Style",
      "desc": "Tampilan khas dengan border tebal & warna tegas",
    },
  ];

  @override
  void dispose() {
    _itemNameController.dispose();
    _amountController.dispose();
    _qrisUrlController.dispose();
    _danaNumController.dispose();
    _danaNameController.dispose();
    _bcaNumController.dispose();
    super.dispose();
  }

  // FUNGSI UTAMA BIKIN FILE.HTML
  Future<void> _createHtmlFile() async {
    setState(() => _isCreating = true);

    final item = _itemNameController.text.trim();
    final amount = _amountController.text.trim();
    final qris = _qrisUrlController.text.trim();
    final danaNum = _danaNumController.text.trim();
    final danaName = _danaNameController.text.trim();
    final bcaNum = _bcaNumController.text.trim();

    String htmlContent = "";

    if (_selectedTemplateIndex == 0) {
      htmlContent = _buildTemplateDark(item, amount, qris, danaNum, danaName);
    } else if (_selectedTemplateIndex == 1) {
      htmlContent = _buildTemplateComplete(item, amount, qris, danaNum, danaName, bcaNum);
    } else {
      htmlContent = _buildTemplateNeo(item, amount, qris, danaNum, danaName);
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/file.html');
      await file.writeAsString(htmlContent);

      setState(() {
        _generatedFile = file;
        _isCreating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("file.html berhasil dibuat! Siap didownload."),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isCreating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal membuat file: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // FUNGSI DOWNLOAD LANGSUNG KE FOLDER DOWNLOAD HP
  Future<void> _downloadToDevice() async {
    if (_generatedFile == null) return;

    try {
      Directory? downloadDir;

      if (Platform.isAndroid) {
        downloadDir = Directory('/storage/emulated/0/Download');
        if (!await downloadDir.exists()) {
          downloadDir = await getExternalStorageDirectory();
        }
      } else {
        downloadDir = await getDownloadsDirectory();
      }

      final String targetPath = '${downloadDir?.path}/file.html';
      final File targetFile = File(targetPath);

      await targetFile.writeAsString(await _generatedFile!.readAsString());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("File berhasil didownload ke Folder Download!\n$targetPath"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal download file: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // TEMPLATE 1: MODERN DARK MODE
  String _buildTemplateDark(String item, String amount, String qris, String danaNum, String danaName) {
    return '''
<!DOCTYPE html>
<html lang="id">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Payment - $item</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; font-family: 'Segoe UI', Tahoma, sans-serif; }
    body { background: #0a0a0d; color: #fff; display: flex; justify-content: center; align-items: center; min-height: 100vh; padding: 16px; }
    .card { background: #141419; width: 100%; max-width: 380px; padding: 24px; border-radius: 16px; border: 1px solid #282832; text-align: center; box-shadow: 0 10px 25px rgba(0,0,0,0.5); }
    .title { color: #a855f7; font-size: 11px; font-weight: bold; letter-spacing: 1.5px; text-transform: uppercase; }
    .price { font-size: 30px; font-weight: 800; margin: 8px 0; color: #ffffff; }
    .box { background: #1d1d26; border: 1px solid #323242; padding: 14px; border-radius: 12px; margin-top: 14px; }
    .qris-img { width: 200px; height: 200px; border-radius: 8px; background: #fff; padding: 6px; object-fit: contain; }
    .btn { width: 100%; padding: 14px; background: #a855f7; color: #fff; border: none; border-radius: 10px; font-weight: bold; cursor: pointer; margin-top: 16px; font-size: 14px; }
    .btn:hover { background: #9333ea; }
  </style>
</head>
<body>
  <div class="card">
    <div class="title">OXIDE PAYMENT</div>
    <div class="price">Rp $amount</div>
    <div style="color:#aaa; font-size:13px;">Item: $item</div>
    
    <div class="box">
      <div style="color:#a855f7; font-weight:bold; font-size:13px; margin-bottom:8px;">SCAN QRIS PEMBAYARAN</div>
      <img src="$qris" class="qris-img" alt="QRIS">
    </div>

    <div class="box">
      <div style="font-size:12px; color:#aaa;">TRANSFER DANA</div>
      <div style="font-size:18px; font-weight:bold; color:#60a5fa; margin: 4px 0;">$danaNum</div>
      <div style="font-size:11px; color:#aaa;">a.n $danaName</div>
    </div>

    <button class="btn" onclick="alert('Terima kasih! Bukti pembayaran telah diproses.')">SAYA SUDAH BAYAR</button>
  </div>
</body>
</html>
''';
  }

  // TEMPLATE 2: COMPLETE BANK & E-WALLET
  String _buildTemplateComplete(String item, String amount, String qris, String danaNum, String danaName, String bcaNum) {
    return '''
<!DOCTYPE html>
<html lang="id">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Checkout - $item</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; font-family: sans-serif; }
    body { background: #0f172a; color: #f8fafc; display: flex; justify-content: center; padding: 20px; min-height: 100vh; align-items: center; }
    .card { background: #1e293b; width: 100%; max-width: 420px; padding: 24px; border-radius: 20px; border: 1px solid #334155; }
    .qris-box { background: #fff; padding: 12px; border-radius: 12px; text-align: center; margin: 16px 0; }
    .row { display: flex; justify-content: space-between; align-items: center; background: #0f172a; padding: 12px; border-radius: 8px; margin-top: 8px; font-size: 13px; }
    .btn { width: 100%; padding: 14px; background: #2563eb; color: #fff; border: none; border-radius: 10px; font-weight: bold; margin-top: 16px; cursor: pointer; }
    .btn:hover { background: #1d4ed8; }
  </style>
</head>
<body>
  <div class="card">
    <h3 style="text-align:center; color:#38bdf8;">TAGIHAN PEMBAYARAN</h3>
    <h2 style="text-align:center; margin:10px 0; font-size: 28px;">Rp $amount</h2>
    <p style="text-align:center; color:#94a3b8; font-size:13px;">Item: $item</p>

    <div class="qris-box">
      <img src="$qris" style="width:210px; height:210px; object-fit: contain;" alt="QRIS">
      <p style="color:#000; font-size:11px; margin-top:6px; font-weight: bold;">Scan QRIS Semua Pembayaran</p>
    </div>

    <div class="row">
      <span>DANA ($danaName)</span>
      <strong style="color:#38bdf8;">$danaNum</strong>
    </div>
    <div class="row">
      <span>BANK BCA</span>
      <strong style="color:#38bdf8;">$bcaNum</strong>
    </div>

    <button class="btn" onclick="alert('Konfirmasi berhasil dikirim!')">KONFIRMASI BAYAR</button>
  </div>
</body>
</html>
''';
  }

  // TEMPLATE 3: NEO-BRUTALIST STYLE
  String _buildTemplateNeo(String item, String amount, String qris, String danaNum, String danaName) {
    return '''
<!DOCTYPE html>
<html lang="id">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Payment Neo - $item</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; font-family: monospace; }
    body { background: #fefce8; color: #000; display: flex; justify-content: center; align-items: center; min-height: 100vh; padding: 16px; }
    .card { background: #fef08a; width: 100%; max-width: 380px; padding: 20px; border: 3px solid #000; box-shadow: 6px 6px 0px #000; text-align: center; }
    .box { background: #fff; border: 2px solid #000; padding: 12px; margin-top: 12px; box-shadow: 3px 3px 0px #000; }
    .btn { width: 100%; padding: 14px; background: #86efac; color: #000; border: 2px solid #000; font-weight: bold; box-shadow: 4px 4px 0px #000; margin-top: 16px; cursor: pointer; font-size: 14px; }
    .btn:active { transform: translate(2px, 2px); box-shadow: 2px 2px 0px #000; }
  </style>
</head>
<body>
  <div class="card">
    <h2 style="text-transform:uppercase;">OXIDE PAY</h2>
    <h1 style="font-size:32px; margin:8px 0;">Rp $amount</h1>
    <p><b>Item:</b> $item</p>

    <div class="box">
      <b>QRIS CODE</b><br><br>
      <img src="$qris" style="width:180px; height:180px; border:2px solid #000; object-fit: contain;" alt="QRIS">
    </div>

    <div class="box">
      <b>DANA:</b> $danaNum<br>
      <small>a.n $danaName</small>
    </div>

    <button class="btn" onclick="alert('Pembayaran Berhasil Dilakukan!')">SUDAH BAYAR</button>
  </div>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "CREATE FILE.HTML",
          style: TextStyle(color: _textColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: theme.colorScheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "PILIH TEMPLATE HTML",
              style: TextStyle(color: _textColor, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),

            // DOKUMEN SELEKSI TEMPLATE
            ...List.generate(_templates.length, (index) {
              final isSelected = _selectedTemplateIndex == index;
              return GestureDetector(
                onTap: () => setState(() => _selectedTemplateIndex = index),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary.withOpacity(0.15)
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(_isNeo ? 4 : 10),
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : (_isNeo ? Colors.black : Colors.white10),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: theme.colorScheme.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _templates[index]['name']!,
                              style: TextStyle(
                                color: _textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              _templates[index]['desc']!,
                              style: TextStyle(color: _subTextColor, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 16),
            _buildInputField("Nama Item", _itemNameController, Icons.shopping_bag),
            const SizedBox(height: 10),
            _buildInputField("Nominal (Rp)", _amountController, Icons.attach_money, isNumber: true),
            const SizedBox(height: 10),
            _buildInputField("URL Gambar QRIS", _qrisUrlController, Icons.qr_code),
            const SizedBox(height: 10),
            _buildInputField("Nomor DANA", _danaNumController, Icons.phone_android, isNumber: true),
            const SizedBox(height: 10),
            _buildInputField("Nama Pemilik DANA", _danaNameController, Icons.person),
            const SizedBox(height: 10),
            if (_selectedTemplateIndex == 1)
              _buildInputField("Nomor Rekening BCA", _bcaNumController, Icons.account_balance, isNumber: true),

            const SizedBox(height: 20),

            // TOMBOL BUAT FILE.HTML
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_isNeo ? 4 : 12),
                  ),
                  side: _isNeo ? const BorderSide(color: Colors.black, width: 2) : BorderSide.none,
                ),
                onPressed: _isCreating ? null : _createHtmlFile,
                icon: const Icon(Icons.code_rounded, color: Colors.white),
                label: _isCreating
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        "CREATE FILE.HTML",
                        style: TextStyle(
                          color: _isNeo && _isLight ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            // HASIL GENERATE & TOMBOL DOWNLOAD
            if (_generatedFile != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(_isNeo ? 6 : 12),
                  border: Border.all(
                    color: _isNeo ? Colors.black : theme.colorScheme.primary,
                    width: _isNeo ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "FILE BERHASIL GENERATE!",
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SelectableText(
                      _generatedFile!.path,
                      style: TextStyle(color: _textColor, fontSize: 11),
                    ),
                    const SizedBox(height: 14),

                    // TOMBOL DOWNLOAD LANGSUNG KE FOLDER DOWNLOAD HP
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(_isNeo ? 4 : 10),
                          ),
                          side: _isNeo
                              ? const BorderSide(color: Colors.black, width: 2)
                              : BorderSide.none,
                        ),
                        icon: const Icon(Icons.file_download_rounded, color: Colors.white),
                        label: const Text(
                          "DOWNLOAD FILE.HTML (KE HP)",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: _downloadToDevice,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, IconData icon, {bool isNumber = false}) {
    final theme = Theme.of(context);

    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: _textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: theme.colorScheme.primary, fontSize: 12),
        prefixIcon: Icon(icon, color: theme.colorScheme.primary, size: 20),
        filled: true,
        fillColor: theme.colorScheme.surface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_isNeo ? 4 : 10),
          borderSide: BorderSide(
            color: _isNeo ? Colors.black : theme.colorScheme.primary.withOpacity(0.3),
            width: _isNeo ? 2 : 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_isNeo ? 4 : 10),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
      ),
    );
  }
}
