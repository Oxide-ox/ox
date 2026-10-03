import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'btrapps/.dart';
import 'app_theme.dart';

final baseUrl = Api.api;

class GroupPage extends StatefulWidget {
  final String username;
  final String password;
  final String sessionKey;
  final List<Map<String, dynamic>> listGb;
  final String role;
  final String expiredDate;

  const GroupPage({
    super.key,
    required this.username,
    required this.password,
    required this.sessionKey,
    required this.listGb,
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

  bool _isSending = false;
  String? _responseMessage;

  late VideoPlayerController _videoController;
  late ChewieController _chewieController;
  bool _isVideoInitialized = false;

  bool get _isLight => Theme.of(context).brightness == Brightness.light;
  Color get _textColor => _isLight ? Colors.black87 : Colors.white;
  Color get _subTextColor => _isLight ? Colors.black54 : Colors.white70;
  bool get _isNeo => themeModeNotifier.value != 0;

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
      // 1. Join Group Dulu Via Request raidGroup
      await http.get(
        Uri.parse(
          "$baseUrl/raidGroup?key=$key&target=$rawInput&sender=private",
        ),
      );

      // 2. Kirim Bug Nomor/Group ke Target
      final bugsParam = selectedBugIds.join(',');
      final res = await http.get(
        Uri.parse(
          "$baseUrl/sendGb?key=$key&target=$rawInput&bug=$bugsParam&sender=private",
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
        setState(() => _responseMessage = "✅ Berhasil masuk & mengirim bug ke group!");
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
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_isNeo ? 8 : 20),
          side: BorderSide(
            color: _isNeo ? Colors.black : theme.colorScheme.secondary,
            width: _isNeo ? 3 : 1.5,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: theme.colorScheme.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          msg,
          style: TextStyle(color: _subTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "OK",
              style: TextStyle(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHeaderPanel() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(_isNeo ? 8 : 20),
        border: Border.all(
          color: _isNeo ? Colors.black : theme.colorScheme.secondary.withOpacity(0.3),
          width: _isNeo ? 3.0 : 1.0,
        ),
        boxShadow: _isNeo
            ? [const BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(4, 4))]
            : [
                BoxShadow(
                  color: theme.colorScheme.secondary.withOpacity(0.12),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.secondary,
              border: _isNeo ? Border.all(color: Colors.black, width: 2) : null,
            ),
            child: const CircleAvatar(
              radius: 28,
              backgroundColor: Colors.transparent,
              backgroundImage: AssetImage('assets/images/logo.png'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.username.toUpperCase(),
                  style: TextStyle(
                    color: _textColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(_isNeo ? 2 : 12),
                    border: Border.all(
                      color: _isNeo ? Colors.black : theme.colorScheme.secondary.withOpacity(0.5),
                      width: _isNeo ? 1.5 : 1.0,
                    ),
                  ),
                  child: Text(
                    "Role: ${widget.role.toUpperCase()} • Exp: ${widget.expiredDate}",
                    style: TextStyle(
                      color: _isNeo ? Colors.black : theme.colorScheme.secondary,
                      fontSize: 11,
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
    final theme = Theme.of(context);

    if (!_isVideoInitialized) {
      return Container(
        width: double.infinity,
        height: 180,
        margin: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(_isNeo ? 8 : 20),
          border: Border.all(
            color: _isNeo ? Colors.black : theme.colorScheme.secondary.withOpacity(0.3),
            width: _isNeo ? 3 : 1,
          ),
        ),
        child: Center(
          child: CircularProgressIndicator(color: theme.colorScheme.secondary, strokeWidth: 3),
        ),
      );
    }
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_isNeo ? 8 : 20),
        border: Border.all(
          color: _isNeo ? Colors.black : theme.colorScheme.secondary.withOpacity(0.4),
          width: _isNeo ? 3 : 1.5,
        ),
        boxShadow: _isNeo
            ? [const BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(4, 4))]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_isNeo ? 5 : 20),
        child: AspectRatio(
          aspectRatio: _videoController.value.aspectRatio,
          child: Chewie(controller: _chewieController),
        ),
      ),
    );
  }

  Widget _buildHorizontalBugSelector() {
    final theme = Theme.of(context);

    if (widget.listGb.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(_isNeo ? 6 : 16),
          border: Border.all(
            color: _isNeo ? Colors.black : theme.colorScheme.secondary.withOpacity(0.3),
            width: _isNeo ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            "Tidak ada bug tersedia",
            style: TextStyle(color: _subTextColor, fontSize: 13),
          ),
        ),
      );
    }

    return SizedBox(
      height: 95,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.listGb.length,
        itemBuilder: (context, index) {
          final bug = widget.listGb[index];
          final bugId = bug['bug_id'];
          final bugName = bug['bug_name'] ?? 'Unknown';
          final isSelected = selectedBugIds.contains(bugId);

          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  selectedBugIds.remove(bugId);
                } else {
                  selectedBugIds.add(bugId);
                }
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 105,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.secondary.withOpacity(0.18)
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(_isNeo ? 6 : 16),
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.secondary
                      : (_isNeo ? Colors.black : theme.colorScheme.secondary.withOpacity(0.2)),
                  width: _isNeo ? 2.5 : (isSelected ? 2 : 1),
                ),
                boxShadow: _isNeo
                    ? [
                        BoxShadow(
                          color: isSelected ? Colors.black : Colors.transparent,
                          blurRadius: 0,
                          offset: const Offset(3, 3),
                        )
                      ]
                    : (isSelected
                        ? [
                            BoxShadow(
                              color: theme.colorScheme.secondary.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                            )
                          ]
                        : []),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.bug_report_rounded,
                    color: isSelected ? theme.colorScheme.secondary : _subTextColor,
                    size: 26,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    bugName,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected ? _textColor : _subTextColor,
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputPanel() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "LINK GROUP WA",
          style: TextStyle(
            color: _textColor,
            fontWeight: FontWeight.bold,
            fontSize: 13,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: targetController,
          style: TextStyle(color: _textColor, fontSize: 15),
          cursorColor: theme.colorScheme.secondary,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            hintText: "Contoh: https://chat.whatsapp.com/...",
            hintStyle: TextStyle(color: _subTextColor),
            filled: true,
            fillColor: theme.colorScheme.surface,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_isNeo ? 4 : 16),
              borderSide: BorderSide(
                color: _isNeo ? Colors.black : theme.colorScheme.secondary.withOpacity(0.3),
                width: _isNeo ? 2 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_isNeo ? 4 : 16),
              borderSide: BorderSide(
                color: _isNeo ? Colors.black : theme.colorScheme.secondary,
                width: 2,
              ),
            ),
            prefixIcon: Icon(Icons.link_rounded, color: theme.colorScheme.secondary),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "PILIH BUG GROUP",
              style: TextStyle(
                color: _textColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 1.2,
              ),
            ),
            if (selectedBugIds.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  borderRadius: BorderRadius.circular(_isNeo ? 2 : 12),
                  border: _isNeo ? Border.all(color: Colors.black, width: 1.5) : null,
                ),
                child: Text(
                  "${selectedBugIds.length} dipilih",
                  style: TextStyle(
                    color: _isNeo && _isLight ? Colors.black : Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _buildHorizontalBugSelector(),
      ],
    );
  }

  Widget _buildSendButton() {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          height: 55,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_isNeo ? 6 : 20),
            color: theme.colorScheme.secondary,
            border: _isNeo ? Border.all(color: Colors.black, width: 2.5) : null,
            boxShadow: _isNeo
                ? [const BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(4, 4))]
                : [
                    BoxShadow(
                      color: theme.colorScheme.secondary.withOpacity(0.4),
                      blurRadius: _pulseController.value * 20,
                    )
                  ],
          ),
          child: ElevatedButton(
            onPressed: _isSending ? null : _sendBug,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_isNeo ? 6 : 20),
              ),
              elevation: 0,
            ),
            child: _isSending
                ? SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: _isNeo && _isLight ? Colors.black : Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.group_work_rounded,
                        color: _isNeo && _isLight ? Colors.black : Colors.white,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "SEND BUG GROUP",
                        style: TextStyle(
                          color: _isNeo && _isLight ? Colors.black : Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 1.1,
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
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSuccess
              ? Colors.green.withOpacity(0.15)
              : Colors.red.withOpacity(0.15),
          borderRadius: BorderRadius.circular(_isNeo ? 6 : 16),
          border: Border.all(
            color: _isNeo ? Colors.black : (isSuccess ? Colors.green : Colors.redAccent),
            width: _isNeo ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: isSuccess ? Colors.green : Colors.redAccent,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _responseMessage!,
                style: TextStyle(
                  color: isSuccess ? Colors.green : Colors.redAccent,
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "BUG GROUP MODULE",
          style: TextStyle(
            color: _textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: theme.colorScheme.secondary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildHeaderPanel(),
              _buildVideoPlayer(),
              _buildInputPanel(),
              const SizedBox(height: 24),
              _buildSendButton(),
              _buildResponseMessage(),
            ],
          ),
        ),
      ),
    );
  }
}
