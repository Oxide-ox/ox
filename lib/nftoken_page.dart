import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'nftoken_service.dart'; // import file service yang kamu buat
import 'app_theme.dart';

class NfTokenPage extends StatefulWidget {
  const NfTokenPage({super.key});

  @override
  State<NfTokenPage> createState() => _NfTokenPageState();
}

class _NfTokenPageState extends State<NfTokenPage> {
  final NfTokenService _tokenService = NfTokenService();
  NfTokenResult? _result;
  bool _isLoading = false;
  String? _errorMessage;

  bool get _isLight => Theme.of(context).brightness == Brightness.light;
  Color get _textColor => _isLight ? Colors.black87 : Colors.white;
  Color get _subTextColor => _isLight ? Colors.black54 : Colors.white70;
  bool get _isNeo => themeModeNotifier.value != 0;

  Future<void> _generateToken() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _tokenService.generate();
      setState(() {
        _result = res;
      });
    } on RateLimitException catch (e) {
      setState(() {
        _errorMessage = "${e.message}\nReset dalam: ${e.formattedTimeLeft}";
      });
    } on NfTokenException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Terjadi kesalahan: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Teks berhasil disalin!"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "NF TOKEN GENERATOR",
          style: TextStyle(
            color: _textColor,
            fontWeight: FontWeight.bold,
          ),
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
            // Status Card Kuota
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(_isNeo ? 8 : 16),
                border: Border.all(
                  color: _isNeo ? Colors.black : theme.colorScheme.primary.withOpacity(0.3),
                  width: _isNeo ? 3 : 1,
                ),
                boxShadow: _isNeo
                    ? [const BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(4, 4))]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Sisa Kuota Harian",
                        style: TextStyle(color: _subTextColor, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${_tokenService.remainingQuota} / ${_tokenService.maxDailyLimit}",
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.auto_awesome_rounded,
                    color: theme.colorScheme.primary,
                    size: 32,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tombol Generate
            SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  side: _isNeo ? const BorderSide(color: Colors.black, width: 2) : BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_isNeo ? 6 : 12),
                  ),
                ),
                onPressed: _isLoading ? null : _generateToken,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        "GENERATE TOKEN",
                        style: TextStyle(
                          color: _isNeo && _isLight ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 20),

            // Error Message
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(_isNeo ? 6 : 12),
                  border: Border.all(color: Colors.redAccent, width: _isNeo ? 2 : 1),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),

            // Hasil Generate
            if (_result != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(_isNeo ? 8 : 16),
                  border: Border.all(
                    color: _isNeo ? Colors.black : theme.colorScheme.primary.withOpacity(0.4),
                    width: _isNeo ? 3 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "RESULT",
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.copy_rounded, color: theme.colorScheme.primary, size: 20),
                          onPressed: () => _copyToClipboard(_result!.formatForCopy()),
                        ),
                      ],
                    ),
                    const Divider(),
                    Text("Country: ${_result!.profile.country}", style: TextStyle(color: _textColor)),
                    Text("Plan: ${_result!.profile.plan}", style: TextStyle(color: _textColor)),
                    Text("Expired: ${_result!.expiry}", style: TextStyle(color: _textColor)),
                    const SizedBox(height: 10),
                    Text("PC Link:", style: TextStyle(color: _subTextColor, fontSize: 11)),
                    SelectableText(_result!.links.pc, style: TextStyle(color: theme.colorScheme.primary, fontSize: 12)),
                    const SizedBox(height: 8),
                    Text("TV Link:", style: TextStyle(color: _subTextColor, fontSize: 11)),
                    SelectableText(_result!.links.tv, style: TextStyle(color: theme.colorScheme.primary, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
