import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'btrapps/.dart';

final baseUrl = Api.api;

class GroupPage extends StatefulWidget {
  final String username;
  final String password;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final String role;
  final String expiredDate;

  const GroupPage({
    super.key,
    required this.username,
    required this.password,
    required this.sessionKey,
    required this.listBug,
    required this.role,
    required this.expiredDate,
  });

  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> with TickerProviderStateMixin {
  final targetController = TextEditingController();
  late AnimationController _fadeController;
  late AnimationController _pulseController;

  Set<String> selectedBugIds = {};
  String _selectedSenderType = "private";

  bool _isSending = false;
  String? _responseMessage;

  final Color bgDark = const Color(0xFF0A0A0C);
  final Color cardGlass = const Color(0xFF16161A);
  final Color neonPink = const Color(0xFFFF007F);
  final Color neonCyan = const Color(0xFF00F5FF);
  final Color laserPurple = const Color(0xFF7B00FF);
  final Color primaryWhite = const Color(0xFFF5F5F7);
  final Color textGrey = Colors.white54;
  final Color borderGlass = Colors.white.withOpacity(0.08);

  final LinearGradient cyberpunkGradient = const LinearGradient(
    colors: [Color(0xFFFF007F), Color(0xFF7B00FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  late VideoPlayerController _videoController;
  late ChewieController _chewieController;
  bool _isVideoInitialized = false;

  bool get _isAllowedToUseGlobal {
    final cleanRole = widget.role.toLowerCase().trim();
    return cleanRole == "staff" ||
        cleanRole == "owner" ||
        cleanRole == "admin" ||
        cleanRole == "developer" ||
        cleanRole == "reseller" ||
        cleanRole == "vip";
  }

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _initializeVideoPlayer();
  }

  void _initializeVideoPlayer() {
    _videoController = VideoPlayerController.asset('assets/videos/banner.mp4');
    _videoController.initialize().then((_) {
      setState(() {
        _videoController.setVolume(0.0);
        _chewieController = ChewieController(
          videoPlayerController: _videoController,
          autoPlay: true,
          looping: true,
          showControls: false,
          autoInitialize: true,
        );
        _isVideoInitialized = true;
      });
    }).catchError((_) {
      setState(() => _isVideoInitialized = false);
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    targetController.dispose();
    if (_isVideoInitialized) {
      _videoController.dispose();
      _chewieController.dispose();
    }
    super.dispose();
  }

  bool isValidGroupLink(String input) {
    return input.contains('chat.whatsapp.com') && input.contains('https://');
  }

  void _showBugSelectionPopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: bgDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: neonPink.withOpacity(0.5), width: 1),
              ),
              title: Row(
                children: [
                  Icon(Icons.group_add, color: neonCyan, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    "PILIH BUG GROUP",
                    style: TextStyle(
                      color: primaryWhite,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Orbitron',
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              content: Container(
                width: double.maxFinite,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.listBug.length,
                  itemBuilder: (context, index) {
                    final bug = widget.listBug[index];
                    final bugId = bug['bug_id'];
                    final isSelected = selectedBugIds.contains(bugId);

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? neonCyan.withOpacity(0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? neonCyan : borderGlass,
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                        leading: Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: isSelected ? neonCyan : textGrey,
                        ),
                        title: Text(
                          bug['bug_name'],
                          style: TextStyle(
                            color: primaryWhite,
                            fontFamily: 'ShareTechMono',
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              selectedBugIds.remove(bugId);
                            } else {
                              selectedBugIds.add(bugId);
                            }
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => setState(() => selectedBugIds.clear()),
                  child: const Text(
                    "RESET",
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("CANCEL", style: TextStyle(color: textGrey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: neonCyan, foregroundColor: Colors.black),
                  onPressed: selectedBugIds.isEmpty
                      ? null
                      : () => Navigator.pop(context),
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _sendBug() async {
    final rawInput = targetController.text.trim();
    final key = widget.sessionKey;

    if (!isValidGroupLink(rawInput)) {
      _showAlert("❌ Invalid Link", "Masukkan link group WA yang valid.");
      return;
    }
    if (selectedBugIds.isEmpty) {
      _showAlert("❌ No Bug Selected", "Pilih minimal 1 bug.");
      return;
    }

    setState(() {
      _isSending = true;
      _responseMessage = null;
    });

    try {
      final bugsParam = selectedBugIds.join(',');
      final res = await http.get(
        Uri.parse(
          "$baseUrl/raidGrouP?key=$key&target=$rawInput&bug=$bugsParam&sender=$_selectedSenderType",
        ),
      );
      final data = jsonDecode(res.body);

      if (data["cooldown"] == true) {
        setState(() => _responseMessage = "⏳ Cooldown: Tunggu beberapa saat.");
      } else if (data["valid"] == false) {
        setState(() => _responseMessage = "❌ Key Invalid.");
      } else if (data["sender"] == false) {
        setState(() => _responseMessage = "❌ Sender Anda Kosong.");
      } else if (data["sended"] == false) {
        setState(() => _responseMessage = "⚠️ Gagal: Server maintenance.");
      } else {
        setState(() => _responseMessage = "✅ Berhasil mengirim serangan bug group!");
        targetController.clear();
        selectedBugIds.clear();
      }
    } catch (_) {
      setState(() => _responseMessage = "❌ Error: Terjadi kesalahan.");
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _showAlert(String title, String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: bgDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: neonPink.withOpacity(0.5)),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: neonPink,
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          msg,
          style: const TextStyle(
            color: Colors.white70,
            fontFamily: 'ShareTechMono',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "OK",
              style: TextStyle(color: neonCyan, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHeaderPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardGlass,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderGlass, width: 1),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: cyberpunkGradient,
            ),
            child: const CircleAvatar(
              radius: 32,
              backgroundColor: Colors.transparent,
              backgroundImage: AssetImage('assets/images/logo.png'),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.username,
                  style: TextStyle(
                    color: primaryWhite,
                    fontFamily: 'Orbitron',
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: neonPink.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: neonPink.withOpacity(0.3)),
                  ),
                  child: Text(
                    "Role: ${widget.role.toUpperCase()} • Exp: ${widget.expiredDate}",
                    style: TextStyle(
                      color: neonPink,
                      fontFamily: 'ShareTechMono',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
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

  Widget _buildVideoPlayer() {
    if (!_isVideoInitialized) {
      return Container(
        width: double.infinity,
        height: 200,
        margin: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: cardGlass,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: CircularProgressIndicator(color: neonCyan, strokeWidth: 3),
        ),
      );
    }
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: neonPink.withOpacity(0.3), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AspectRatio(
          aspectRatio: _videoController.value.aspectRatio,
          child: Chewie(controller: _chewieController),
        ),
      ),
    );
  }

  Widget _buildSenderTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "GUNAKAN SENDER",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
            fontFamily: 'Orbitron',
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedSenderType = "private"),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _selectedSenderType == "private"
                        ? neonCyan.withOpacity(0.1)
                        : cardGlass,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _selectedSenderType == "private"
                          ? neonCyan
                          : borderGlass,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person,
                        color: _selectedSenderType == "private"
                            ? neonCyan
                            : textGrey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "PRIVATE SENDER",
                        style: TextStyle(
                          color: _selectedSenderType == "private"
                              ? neonCyan
                              : textGrey,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          fontFamily: 'Orbitron',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (_isAllowedToUseGlobal) {
                    setState(() => _selectedSenderType = "global");
                  } else {
                    _showAlert(
                      "🔒 AKSES TERKUNCI",
                      "Global Sender khusus Admin/Reseller/Owner.",
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _selectedSenderType == "global"
                        ? laserPurple.withOpacity(0.15)
                        : cardGlass,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _selectedSenderType == "global"
                          ? laserPurple
                          : borderGlass,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isAllowedToUseGlobal ? Icons.public : Icons.lock,
                        color: _selectedSenderType == "global"
                            ? laserPurple
                            : textGrey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "GLOBAL SENDER",
                        style: TextStyle(
                          color: _isAllowedToUseGlobal
                              ? (_selectedSenderType == "global"
                                  ? laserPurple
                                  : primaryWhite)
                              : textGrey.withOpacity(0.4),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          fontFamily: 'Orbitron',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInputPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSenderTypeSelector(),
        const SizedBox(height: 24),
        const Text(
          "LINK GROUP WA",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
            fontFamily: 'Orbitron',
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: cardGlass,
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextField(
            controller: targetController,
            style: TextStyle(color: primaryWhite, fontSize: 16),
            cursorColor: neonCyan,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              hintText: "Contoh: https://chat.whatsapp.com/...",
              hintStyle: TextStyle(color: textGrey.withOpacity(0.3)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: borderGlass),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: neonCyan, width: 2),
              ),
              prefixIcon: Icon(Icons.link_rounded, color: neonCyan),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "PILIH BUG GROUP",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                fontFamily: 'Orbitron',
                letterSpacing: 1.5,
              ),
            ),
            if (selectedBugIds.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: neonCyan,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${selectedBugIds.length} dipilih",
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _showBugSelectionPopup,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: cardGlass,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderGlass, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: selectedBugIds.isEmpty
                      ? Text(
                          "Klik untuk memilih bug group",
                          style: TextStyle(color: textGrey, fontSize: 14),
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: selectedBugIds.map((bugId) {
                            final bug = widget.listBug.firstWhere(
                              (b) => b['bug_id'] == bugId,
                              orElse: () => {'bug_name': 'Unknown'},
                            );
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: neonCyan.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: neonCyan.withOpacity(0.4),
                                ),
                              ),
                              child: Text(
                                bug['bug_name'] ?? 'Unknown',
                                style: TextStyle(
                                  color: neonCyan,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                ),
                Icon(Icons.arrow_drop_down, color: neonCyan, size: 28),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSendButton() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          height: 65,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: cyberpunkGradient,
            boxShadow: [
              BoxShadow(
                color: neonPink.withOpacity(0.4),
                blurRadius: _pulseController.value * 25,
              )
            ],
          ),
          child: ElevatedButton(
            onPressed: _isSending ? null : _sendBug,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
            ),
            child: _isSending
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.group_work_rounded, color: Colors.white),
                      SizedBox(width: 12),
                      Text(
                        "SEND BUG GROUP",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          fontFamily: 'Orbitron',
                        ),
                      )
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildResponseMessage() {
    if (_responseMessage == null) return const SizedBox.shrink();
    final isSuccess = _responseMessage!.startsWith('✅');
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSuccess
              ? Colors.green.withOpacity(0.15)
              : Colors.red.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSuccess ? Colors.greenAccent : Colors.redAccent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: isSuccess ? Colors.greenAccent : Colors.redAccent,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _responseMessage!,
                style: TextStyle(
                  color: isSuccess ? Colors.greenAccent : Colors.redAccent,
                  fontFamily: 'ShareTechMono',
                  fontWeight: FontWeight.bold,
                ),
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildHeaderPanel(),
              _buildVideoPlayer(),
              _buildInputPanel(),
              const SizedBox(height: 30),
              _buildSendButton(),
              _buildResponseMessage(),
            ],
          ),
        ),
      ),
    );
  }
}
