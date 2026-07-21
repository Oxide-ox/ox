import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'btrapps/.dart';
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

  // State manajemen: "private" atau "global"
  String _selectedManageType = "private";

  // --- TEMA WARNA CYBERPUNK PINK & NEON CYAN ---
  final Color bgDark = const Color(0xFF0A0A0C);       // Hitam Obsidian
  final Color cardGlass = const Color(0xFF16161A);    // Abu Gelap Card
  final Color neonPink = const Color(0xFFFF007F);     // Pink Cyberpunk
  final Color neonCyan = const Color(0xFF00F5FF);     // Cyan Cyberpunk
  final Color laserPurple = const Color(0xFF7B00FF);   // Ungu Laser
  final Color primaryWhite = const Color(0xFFF5F5F7);  // Putih Terang
  final Color borderGlass = Colors.white.withOpacity(0.08);

  // --- VALIDASI ROLE (Ditambahkan Admin) ---
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
      final currentKey = _selectedManageType == "private" ? widget.sessionKey : "global";

      final response = await http.get(
        Uri.parse("${baseUrl}/mySender?key=${widget.sessionKey}"),
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

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: bgDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: neonPink.withOpacity(0.5)),
        ),
        title: Row(
          children: [
            Icon(Icons.add_circle, color: neonCyan),
            const SizedBox(width: 12),
            Text(
              "ADD ${_selectedManageType.toUpperCase()} SENDER",
              style: TextStyle(color: primaryWhite, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Orbitron'),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              style: TextStyle(color: primaryWhite),
              decoration: InputDecoration(
                labelText: "Phone Number",
                labelStyle: TextStyle(color: neonCyan),
                hintText: "62xxx",
                hintStyle: const TextStyle(color: Colors.white24),
                prefixIcon: Icon(Icons.phone, color: neonCyan),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: neonPink.withOpacity(0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: neonCyan, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL", style: TextStyle(color: Colors.white54, fontFamily: 'Orbitron')),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [neonPink, laserPurple]),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: neonPink.withOpacity(0.3), blurRadius: 10)],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              child: Text("ADD SENDER", style: TextStyle(color: primaryWhite, fontFamily: 'Orbitron', fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addSender(String number) async {
    setState(() => isLoading = true);

    try {
      final currentKey = _selectedManageType == "private" ? widget.sessionKey : "global";

      final response = await http.get(
        Uri.parse("${baseUrl}/getPairing?key=${widget.sessionKey}&number=$number"),
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: bgDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: neonCyan.withOpacity(0.5)),
        ),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: neonCyan.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.qr_code_2, color: neonCyan, size: 40),
            ),
            const SizedBox(height: 15),
            Text("PAIRING REQUIRED",
                style: TextStyle(color: primaryWhite, fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Orbitron')),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardGlass,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: neonPink.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Number: $number", style: TextStyle(color: primaryWhite, fontFamily: 'ShareTechMono')),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: neonCyan, width: 2),
                  boxShadow: [
                    BoxShadow(color: neonCyan.withOpacity(0.4), blurRadius: 15, spreadRadius: 1)
                  ],
                ),
                child: Text(
                  code,
                  style: TextStyle(
                    color: neonCyan,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    fontFamily: 'Courier',
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: neonPink.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: neonPink),
                ),
                child: OutlinedButton.icon(
                  icon: Icon(Icons.copy, color: neonPink),
                  label: Text(
                      "COPY CODE",
                      style: TextStyle(color: neonPink, fontWeight: FontWeight.bold, fontFamily: 'Orbitron')
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text("Code copied to clipboard!", style: TextStyle(color: Colors.white)),
                        backgroundColor: neonPink,
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
            child: Text("CLOSE", style: TextStyle(color: primaryWhite, fontFamily: 'Orbitron')),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [neonPink, neonCyan]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(context);
                _fetchSenders();
              },
              child: Text("REFRESH LIST", style: TextStyle(color: primaryWhite, fontFamily: 'Orbitron', fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSender(String senderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: bgDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            const SizedBox(width: 12),
            Text("CONFIRM DELETE", style: TextStyle(color: primaryWhite, fontFamily: 'Orbitron')),
          ],
        ),
        content: const Text(
          "Are you sure you want to delete this sender? This action cannot be undone.",
          style: TextStyle(color: Colors.white70, fontFamily: 'ShareTechMono'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("CANCEL", style: TextStyle(color: primaryWhite, fontFamily: 'Orbitron')),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.redAccent),
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("DELETE", style: TextStyle(color: Colors.redAccent, fontFamily: 'Orbitron', fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => isLoading = true);

      try {
        final currentKey = _selectedManageType == "private" ? widget.sessionKey : "global";

        final response = await http.delete(
          Uri.parse("${baseUrl}/deleteSender?key=${widget.sessionKey}&id=$senderId"),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontFamily: 'ShareTechMono')),
        backgroundColor: isError ? Colors.redAccent : neonPink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildRoleTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: cardGlass,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderGlass),
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
                  gradient: _selectedManageType == "private" 
                      ? LinearGradient(colors: [neonPink, laserPurple]) 
                      : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    "PRIVATE SENDER",
                    style: TextStyle(
                      color: primaryWhite,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      fontFamily: 'Orbitron',
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
                      backgroundColor: bgDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: neonPink.withOpacity(0.5)),
                      ),
                      title: Row(
                        children: [
                          Icon(Icons.lock, color: neonPink),
                          const SizedBox(width: 10),
                          Text("AKSES TERKUNCI", style: TextStyle(color: primaryWhite, fontFamily: 'Orbitron')),
                        ],
                      ),
                      content: const Text(
                        "Manajemen Sender Global khusus bagi member ber-role ADMIN, RESELLER, atau OWNER.",
                        style: TextStyle(color: Colors.white70, fontFamily: 'ShareTechMono'),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text("OK", style: TextStyle(color: neonCyan, fontFamily: 'Orbitron')),
                        )
                      ],
                    ),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: _selectedManageType == "global" 
                      ? LinearGradient(colors: [neonPink, laserPurple]) 
                      : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "GLOBAL SENDER",
                      style: TextStyle(
                        color: _isAllowedToUseGlobal ? primaryWhite : Colors.white24,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                    if (!_isAllowedToUseGlobal) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.lock, size: 14, color: Colors.white24),
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
    final name = sender['sessionName'] ?? 'WhatsApp Sender';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cardGlass,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderGlass),
        boxShadow: [
          BoxShadow(
            color: neonPink.withOpacity(0.05),
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
                    color: neonCyan.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.phone_android, color: neonCyan),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: primaryWhite,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'ShareTechMono',
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: neonCyan.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: neonCyan.withOpacity(0.3)),
                  ),
                  child: Text(
                    "ONLINE",
                    style: TextStyle(
                      color: neonCyan,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      fontFamily: 'Orbitron',
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
                    icon: Icon(Icons.refresh, size: 16, color: primaryWhite),
                    label: const Text("REFRESH"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryWhite,
                      backgroundColor: Colors.white.withOpacity(0.02),
                      side: BorderSide(color: borderGlass),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(fontFamily: 'Orbitron', fontSize: 12),
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
                      backgroundColor: Colors.redAccent.withOpacity(0.1),
                      foregroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(fontFamily: 'Orbitron', fontSize: 12),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: neonPink.withOpacity(0.05),
                shape: BoxShape.circle,
                border: Border.all(color: neonPink.withOpacity(0.2)),
              ),
              child: Icon(Icons.phone_iphone, color: neonPink, size: 80),
            ),
            const SizedBox(height: 24),
            Text(
              "NO SENDERS FOUND",
              style: TextStyle(color: primaryWhite, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Orbitron'),
            ),
            const SizedBox(height: 12),
            Text(
              "Add your first WhatsApp $_selectedManageType sender to get started",
              style: const TextStyle(color: Colors.white38, fontSize: 14, fontFamily: 'ShareTechMono'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [neonPink, laserPurple]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: neonPink.withOpacity(0.4), blurRadius: 15)
                ],
              ),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("ADD FIRST SENDER"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  textStyle: const TextStyle(fontFamily: 'Orbitron', fontWeight: FontWeight.bold),
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
              style: TextStyle(color: primaryWhite, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Orbitron'),
            ),
            const SizedBox(height: 12),
            Text(
              errorMessage ?? "Unknown error occurred",
              style: const TextStyle(color: Colors.white38, fontSize: 14, fontFamily: 'ShareTechMono'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [neonPink, laserPurple]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text("TRY AGAIN"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  textStyle: const TextStyle(fontFamily: 'Orbitron', fontWeight: FontWeight.bold),
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
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        title: Text(
          "MANAGE BUG SENDER",
          style: TextStyle(
            color: primaryWhite,
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.bold,
            shadows: [
              BoxShadow(color: neonPink.withOpacity(0.8), blurRadius: 10)
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: neonCyan),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: neonCyan),
            onPressed: isLoading ? null : _refreshSenders,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgDark, neonPink.withOpacity(0.03), bgDark],
          ),
        ),
        child: Column(
          children: [
            _buildRoleTabs(),
            Expanded(
              child: isLoading && senderList.isEmpty
                  ? Center(child: CircularProgressIndicator(color: neonCyan))
                  : errorMessage != null && senderList.isEmpty
                  ? _buildErrorState()
                  : senderList.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                color: neonCyan,
                backgroundColor: cardGlass,
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
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [neonPink, neonCyan]),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: neonPink.withOpacity(0.4), blurRadius: 20, spreadRadius: 2)
          ],
        ),
        child: FloatingActionButton(
          onPressed: _showAddSenderDialog,
          backgroundColor: Colors.transparent,
          child: Icon(Icons.add, color: primaryWhite),
        ),
      ),
    );
  }
}
