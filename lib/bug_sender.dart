import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'btrapps/.dart';
import 'app_theme.dart';

final baseUrl = Api.api;

class BugSenderPage extends StatefulWidget {
  final String sessionKey;
  final String username;
  final String role;

  const BugSenderPage({
    super.key,
    required this.sessionKey,
    required this.username,
    required this.role,
  });

  @override
  State<BugSenderPage> createState() => _BugSenderPageState();
}

class _BugSenderPageState extends State<BugSenderPage> {
  List<dynamic> senderList = [];
  bool isLoading = false;
  bool isRefreshing = false;
  String? errorMessage;

  String _selectedManageType = "private";

  bool get _isLight => Theme.of(context).brightness == Brightness.light;
  Color get _textColor => _isLight ? Colors.black87 : Colors.white;
  Color get _subTextColor => _isLight ? Colors.black54 : Colors.white70;
  bool get _isNeo => themeModeNotifier.value != 0;

  bool get _isAllowedToUseGlobal {
    final cleanRole = widget.role.toLowerCase().trim();
    return cleanRole == "owner" || cleanRole == "admin" || cleanRole == "reseller";
  }

  @override
  void initState() {
    super.initState();
    _fetchSenders();
  }

  Future<void> _fetchSenders() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/mySender?key=${widget.sessionKey}"),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["valid"] == true) {
          setState(() {
            senderList = data["connections"] ?? [];
          });
        } else {
          setState(() {
            errorMessage = data["message"] ?? "Failed to fetch senders";
          });
        }
      } else {
        setState(() {
          errorMessage = "Server error: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Connection failed: $e";
      });
    } finally {
      setState(() {
        isLoading = false;
        isRefreshing = false;
      });
    }
  }

  Future<void> _refreshSenders() async {
    setState(() => isRefreshing = true);
    await _fetchSenders();
    _showSnackBar("List refreshed!", isError: false);
  }

  void _showAddSenderDialog() {
    final phoneController = TextEditingController();
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_isNeo ? 8 : 20),
          side: BorderSide(
            color: _isNeo ? Colors.black : theme.colorScheme.primary,
            width: _isNeo ? 3 : 1.5,
          ),
        ),
        title: Row(
          children: [
            Icon(Icons.add_circle, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Text(
              "ADD ${_selectedManageType.toUpperCase()} SENDER",
              style: TextStyle(
                color: _textColor,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              style: TextStyle(color: _textColor),
              decoration: InputDecoration(
                labelText: "Phone Number",
                labelStyle: TextStyle(color: theme.colorScheme.primary),
                hintText: "62xxx",
                hintStyle: TextStyle(color: _subTextColor),
                prefixIcon: Icon(Icons.phone, color: theme.colorScheme.primary),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(_isNeo ? 4 : 12),
                  borderSide: BorderSide(
                    color: _isNeo ? Colors.black : theme.colorScheme.primary.withOpacity(0.5),
                    width: _isNeo ? 2 : 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(_isNeo ? 4 : 12),
                  borderSide: BorderSide(
                    color: _isNeo ? Colors.black : theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("CANCEL", style: TextStyle(color: _subTextColor)),
          ),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(_isNeo ? 4 : 12),
              border: _isNeo ? Border.all(color: Colors.black, width: 2) : null,
              boxShadow: _isNeo
                  ? [const BoxShadow(color: Colors.black, offset: Offset(2, 2))]
                  : null,
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_isNeo ? 4 : 12),
                ),
              ),
              onPressed: () async {
                final number = phoneController.text.trim();

                if (number.isEmpty) {
                  _showSnackBar("Please enter phone number", isError: true);
                  return;
                }

                Navigator.pop(context);
                await _addSender(number);
              },
              child: Text(
                "ADD SENDER",
                style: TextStyle(
                  color: _isNeo && _isLight ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addSender(String number) async {
    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/getPairing?key=${widget.sessionKey}&number=$number"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["valid"] == true) {
          _showPairingCodeDialog(number, data['pairingCode']);
          _showSnackBar("Pairing code generated successfully!", isError: false);
        } else {
          _showSnackBar(data['message'] ?? "Failed to generate pairing code", isError: true);
        }
      } else {
        _showSnackBar("Server error: ${response.statusCode}", isError: true);
      }
    } catch (e) {
      _showSnackBar("Connection failed: $e", isError: true);
    } finally {
      setState(() => isLoading = false);
      _fetchSenders();
    }
  }

  void _showPairingCodeDialog(String number, String code) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_isNeo ? 8 : 20),
          side: BorderSide(
            color: _isNeo ? Colors.black : theme.colorScheme.primary,
            width: _isNeo ? 3 : 1.5,
          ),
        ),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.15),
                shape: BoxShape.circle,
                border: _isNeo ? Border.all(color: Colors.black, width: 2) : null,
              ),
              child: Icon(Icons.qr_code_2, color: theme.colorScheme.primary, size: 40),
            ),
            const SizedBox(height: 15),
            Text(
              "PAIRING REQUIRED",
              style: TextStyle(
                color: _textColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(_isNeo ? 6 : 16),
            border: Border.all(
              color: _isNeo ? Colors.black : theme.colorScheme.primary.withOpacity(0.3),
              width: _isNeo ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Number: $number", style: TextStyle(color: _textColor)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(_isNeo ? 4 : 12),
                  border: Border.all(
                    color: _isNeo ? Colors.black : theme.colorScheme.primary,
                    width: 2,
                  ),
                  boxShadow: _isNeo
                      ? [const BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(3, 3))]
                      : [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                            blurRadius: 15,
                          )
                        ],
                ),
                child: Text(
                  code,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(_isNeo ? 4 : 12),
                  border: Border.all(
                    color: _isNeo ? Colors.black : theme.colorScheme.primary,
                    width: _isNeo ? 2 : 1,
                  ),
                ),
                child: OutlinedButton.icon(
                  icon: Icon(Icons.copy, color: theme.colorScheme.primary),
                  label: Text(
                    "COPY CODE",
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_isNeo ? 4 : 12),
                    ),
                  ),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text("Code copied to clipboard!"),
                        backgroundColor: theme.colorScheme.primary,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("CLOSE", style: TextStyle(color: _textColor)),
          ),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(_isNeo ? 4 : 12),
              border: _isNeo ? Border.all(color: Colors.black, width: 2) : null,
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_isNeo ? 4 : 12),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                _fetchSenders();
              },
              child: Text(
                "REFRESH LIST",
                style: TextStyle(
                  color: _isNeo && _isLight ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSender(String senderId) async {
    final theme = Theme.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_isNeo ? 8 : 20),
          side: BorderSide(
            color: _isNeo ? Colors.black : Colors.redAccent,
            width: _isNeo ? 3 : 1.5,
          ),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            const SizedBox(width: 12),
            Text("CONFIRM DELETE", style: TextStyle(color: _textColor)),
          ],
        ),
        content: Text(
          "Are you sure you want to delete this sender? This action cannot be undone.",
          style: TextStyle(color: _subTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("CANCEL", style: TextStyle(color: _textColor)),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(_isNeo ? 4 : 12),
              border: Border.all(color: Colors.redAccent, width: _isNeo ? 2 : 1),
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_isNeo ? 4 : 12),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                "DELETE",
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => isLoading = true);

      try {
        final response = await http.delete(
          Uri.parse("$baseUrl/deleteSender?key=${widget.sessionKey}&id=$senderId"),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data["valid"] == true) {
            _showSnackBar("Sender deleted successfully!", isError: false);
            _fetchSenders();
          } else {
            _showSnackBar(data["message"] ?? "Failed to delete sender", isError: true);
          }
        } else {
          _showSnackBar("Server error: ${response.statusCode}", isError: true);
        }
      } catch (e) {
        _showSnackBar("Connection failed: $e", isError: true);
      } finally {
        setState(() => isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: isError ? Colors.redAccent : theme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_isNeo ? 4 : 12),
          side: _isNeo ? const BorderSide(color: Colors.black, width: 2) : BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildRoleTabs() {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(_isNeo ? 8 : 16),
        border: Border.all(
          color: _isNeo ? Colors.black : theme.colorScheme.primary.withOpacity(0.2),
          width: _isNeo ? 3 : 1,
        ),
        boxShadow: _isNeo
            ? [const BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(4, 4))]
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedManageType = "private";
                  senderList.clear();
                });
                _fetchSenders();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedManageType == "private"
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(_isNeo ? 4 : 12),
                  border: _selectedManageType == "private" && _isNeo
                      ? Border.all(color: Colors.black, width: 1.5)
                      : null,
                ),
                child: Center(
                  child: Text(
                    "PRIVATE SENDER",
                    style: TextStyle(
                      color: _selectedManageType == "private"
                          ? (_isNeo && _isLight ? Colors.black : Colors.white)
                          : _textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_isAllowedToUseGlobal) {
                  setState(() {
                    _selectedManageType = "global";
                    senderList.clear();
                  });
                  _fetchSenders();
                } else {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: theme.colorScheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_isNeo ? 8 : 20),
                        side: BorderSide(
                          color: _isNeo ? Colors.black : theme.colorScheme.primary,
                          width: _isNeo ? 3 : 1.5,
                        ),
                      ),
                      title: Row(
                        children: [
                          Icon(Icons.lock, color: theme.colorScheme.primary),
                          const SizedBox(width: 10),
                          Text("AKSES TERKUNCI", style: TextStyle(color: _textColor)),
                        ],
                      ),
                      content: Text(
                        "Manajemen Sender Global khusus bagi member ber-role ADMIN, RESELLER, atau OWNER.",
                        style: TextStyle(color: _subTextColor),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text("OK", style: TextStyle(color: theme.colorScheme.primary)),
                        )
                      ],
                    ),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedManageType == "global"
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(_isNeo ? 4 : 12),
                  border: _selectedManageType == "global" && _isNeo
                      ? Border.all(color: Colors.black, width: 1.5)
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "GLOBAL SENDER",
                      style: TextStyle(
                        color: _selectedManageType == "global"
                            ? (_isNeo && _isLight ? Colors.black : Colors.white)
                            : (_isAllowedToUseGlobal ? _textColor : _subTextColor),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    if (!_isAllowedToUseGlobal) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.lock, size: 14, color: _subTextColor),
                    ]
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSenderCard(Map<String, dynamic> sender, int index) {
    final theme = Theme.of(context);
    final name = sender['sessionName'] ?? 'WhatsApp Sender';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(_isNeo ? 8 : 20),
        border: Border.all(
          color: _isNeo ? Colors.black : theme.colorScheme.primary.withOpacity(0.3),
          width: _isNeo ? 3.0 : 1.0,
        ),
        boxShadow: _isNeo
            ? [const BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(5, 5))]
            : [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: _isNeo ? Border.all(color: Colors.black, width: 2) : null,
                  ),
                  child: Icon(Icons.phone_android, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: _textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(_isNeo ? 2 : 8),
                    border: Border.all(
                      color: _isNeo ? Colors.black : theme.colorScheme.secondary,
                      width: _isNeo ? 1.5 : 1.0,
                    ),
                  ),
                  child: Text(
                    "ONLINE",
                    style: TextStyle(
                      color: _isNeo ? Colors.black : theme.colorScheme.secondary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.refresh, size: 16, color: _textColor),
                    label: const Text("REFRESH"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _textColor,
                      backgroundColor: theme.scaffoldBackgroundColor,
                      side: BorderSide(
                        color: _isNeo ? Colors.black : theme.colorScheme.primary.withOpacity(0.3),
                        width: _isNeo ? 2 : 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_isNeo ? 4 : 12),
                      ),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => _refreshSenders(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                    label: const Text("DELETE"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.withOpacity(0.12),
                      foregroundColor: Colors.redAccent,
                      side: _isNeo ? const BorderSide(color: Colors.black, width: 2) : BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_isNeo ? 4 : 12),
                      ),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => _deleteSender(sender['sessionName']),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _isNeo ? Colors.black : theme.colorScheme.primary.withOpacity(0.3),
                  width: _isNeo ? 3 : 1.5,
                ),
              ),
              child: Icon(Icons.phone_iphone, color: theme.colorScheme.primary, size: 80),
            ),
            const SizedBox(height: 24),
            Text(
              "NO SENDERS FOUND",
              style: TextStyle(
                color: _textColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Add your first WhatsApp $_selectedManageType sender to get started",
              style: TextStyle(color: _subTextColor, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(_isNeo ? 6 : 16),
                border: _isNeo ? Border.all(color: Colors.black, width: 2.5) : null,
                boxShadow: _isNeo
                    ? [const BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(4, 4))]
                    : [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.4),
                          blurRadius: 15,
                        ),
                      ],
              ),
              child: ElevatedButton.icon(
                icon: Icon(
                  Icons.add,
                  color: _isNeo && _isLight ? Colors.black : Colors.white,
                ),
                label: Text(
                  "ADD FIRST SENDER",
                  style: TextStyle(
                    color: _isNeo && _isLight ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_isNeo ? 6 : 16),
                  ),
                ),
                onPressed: _showAddSenderDialog,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 80),
            const SizedBox(height: 24),
            Text(
              "FAILED TO LOAD",
              style: TextStyle(
                color: _textColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              errorMessage ?? "Unknown error occurred",
              style: TextStyle(color: _subTextColor, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(_isNeo ? 6 : 16),
                border: _isNeo ? Border.all(color: Colors.black, width: 2) : null,
              ),
              child: ElevatedButton.icon(
                icon: Icon(
                  Icons.refresh,
                  color: _isNeo && _isLight ? Colors.black : Colors.white,
                ),
                label: Text(
                  "TRY AGAIN",
                  style: TextStyle(
                    color: _isNeo && _isLight ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_isNeo ? 6 : 16),
                  ),
                ),
                onPressed: _fetchSenders,
              ),
            ),
          ],
        ),
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
          "MANAGE BUG SENDER",
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
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: theme.colorScheme.primary),
            onPressed: isLoading ? null : _refreshSenders,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildRoleTabs(),
          Expanded(
            child: isLoading && senderList.isEmpty
                ? Center(
                    child: CircularProgressIndicator(color: theme.colorScheme.primary),
                  )
                : errorMessage != null && senderList.isEmpty
                    ? _buildErrorState()
                    : senderList.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            color: theme.colorScheme.primary,
                            backgroundColor: theme.colorScheme.surface,
                            onRefresh: _refreshSenders,
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: senderList.length,
                              itemBuilder: (context, index) => _buildSenderCard(
                                Map<String, dynamic>.from(senderList[index]),
                                index,
                              ),
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          shape: BoxShape.circle,
          border: _isNeo ? Border.all(color: Colors.black, width: 2.5) : null,
          boxShadow: _isNeo
              ? [const BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(3, 3))]
              : [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.4),
                    blurRadius: 15,
                  ),
                ],
        ),
        child: FloatingActionButton(
          onPressed: _showAddSenderDialog,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Icon(
            Icons.add,
            color: _isNeo && _isLight ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }
}
