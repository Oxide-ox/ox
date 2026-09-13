import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'nftoken_service.dart';
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

  void _copyToClipboard(String text, {String label = "Teks"}) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$label berhasil disalin!"),
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
                    : [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
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

            // Tombol Generate dibungkus Container untuk mendukung boxShadow di Neo theme
            Container(
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_isNeo ? 6 : 12),
                boxShadow: _isNeo
                    ? [const BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(3, 3))]
                    : null,
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  elevation: _isNeo ? 0 : 2,
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
            if (_result != null && _result!.isSuccess) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(_isNeo ? 8 : 16),
                  border: Border.all(
                    color: _isNeo ? Colors.black : theme.colorScheme.primary.withOpacity(0.4),
                    width: _isNeo ? 3 : 1,
                  ),
                  boxShadow: _isNeo
                      ? [const BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(4, 4))]
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "RESULT DETAILS",
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.copy_all_rounded, color: theme.colorScheme.primary, size: 22),
                          tooltip: "Salin Semua",
                          onPressed: () => _copyToClipboard(_result!.formatForCopy(), label: "Semua Detail Token"),
                        ),
                      ],
                    ),
                    Divider(color: _isNeo ? Colors.black : Colors.white10, thickness: _isNeo ? 2 : 1),
                    const SizedBox(height: 6),

                    _buildInfoRow("Country", _result!.profile.country),
                    _buildInfoRow("Plan", _result!.profile.plan),
                    _buildInfoRow("Expired", _result!.expiry),
                    
                    if (_result!.token != null && _result!.token!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text("Token String:", style: TextStyle(color: _subTextColor, fontSize: 11)),
                      const SizedBox(height: 2),
                      SelectableText(
                        _result!.token!,
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),
                    Text(
                      "PLATFORM ACCESS LINKS",
                      style: TextStyle(
                        color: _textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // PC Link
                    _buildLinkItem(
                      label: "PC Link",
                      icon: Icons.computer_rounded,
                      url: _result!.links.pc,
                    ),
                    const SizedBox(height: 8),

                    // TV Link
                    _buildLinkItem(
                      label: "TV Link",
                      icon: Icons.tv_rounded,
                      url: _result!.links.tv,
                    ),
                    const SizedBox(height: 8),

                    // Android Link
                    _buildLinkItem(
                      label: "Android Link",
                      icon: Icons.phone_android_rounded,
                      url: _result!.links.android,
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

  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: _subTextColor, fontSize: 12)),
          Text(value, style: TextStyle(color: _textColor, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildLinkItem({
    required String label,
    required IconData icon,
    required String url,
  }) {
    final theme = Theme.of(context);
    final isHasUrl = url.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(_isNeo ? 4 : 8),
        border: Border.all(
          color: _isNeo ? Colors.black : Colors.white12,
          width: _isNeo ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: _subTextColor, fontSize: 10)),
                SelectableText(
                  isHasUrl ? url : "-",
                  style: TextStyle(
                    color: isHasUrl ? theme.colorScheme.primary : _subTextColor,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                ),
              ],
            ),
          ),
          if (isHasUrl)
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 16),
              color: theme.colorScheme.primary,
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
              onPressed: () => _copyToClipboard(url, label: label),
            ),
        ],
      ),
    );
  }
}
