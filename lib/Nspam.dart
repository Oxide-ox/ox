import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'btrapps/.dart';
import 'app_theme.dart';

final baseUrl = Api.api;

class SpamNHomePage extends StatefulWidget {
  final String username;
  final String password;
  final String sessionKey;
  final List<Map<String, dynamic>> listSpam;
  final String role;
  final String expiredDate;

  const SpamNHomePage({
    super.key,
    required this.username,
    required this.password,
    required this.sessionKey,
    required this.listSpam,
    required this.role,
    required this.expiredDate,
  });

  @override
  State<SpamNHomePage> createState() => _SpamNHomePageState();
}

class _SpamNHomePageState extends State<SpamNHomePage> with TickerProviderStateMixin {
  final targetController = TextEditingController();
  late AnimationController _fadeController;
  late AnimationController _pulseController;

  Set<String> selectedBugIds = {};
  String _selectedSenderType = "private";

  bool _isSending = false;
  String? _responseMessage;

  // Real-time Sender Count State (Murni Mengikuti API)
  int _privateSenderCount = 0;
  int _globalSenderCount = 0;
  bool _isFetchingSenders = false;

  // State Limit Khusus Global Sender
  int _globalUsageCount = 0;
  final int _maxGlobalLimit = 5;

  // KEY USER-SPECIFIC (Tersimpan Berdasarkan Username)
  String get _keyGlobalUsageCount => 'global_usage_count_${widget.username.toLowerCase()}';
  String get _keyGlobalFirstUseTime => 'global_first_use_${widget.username.toLowerCase()}';

  late VideoPlayerController _videoController;
  late ChewieController _chewieController;
  bool _isVideoInitialized = false;

  // GETTER KONTROL TEMA DINAMIS
  bool get _isLight => Theme.of(context).brightness == Brightness.light;
  Color get _textColor => _isLight ? Colors.black87 : Colors.white;
  Color get _subTextColor => _isLight ? Colors.black54 : Colors.white70;
  bool get _isNeo => themeModeNotifier.value != 0;

  bool get _isAllowedToUseGlobal {
    final cleanRole = widget.role.toLowerCase().trim();
    return cleanRole == "staff" ||
        cleanRole == "team" ||
        cleanRole == "owner" ||
        cleanRole == "admin" ||
        cleanRole == "developer" ||
        cleanRole == "reseller" ||
        cleanRole == "vip";
  }

  @override
  void initState() {
    super.initState();
    _loadGlobalUsageData();
    _fetchSenderCounts();

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

  Future<void> _fetchSenderCounts() async {
    setState(() => _isFetchingSenders = true);
    try {
      final res = await http.get(
        Uri.parse(
          '$baseUrl/getSenderCount?key=${widget.sessionKey}&username=${widget.username}',
        ),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _privateSenderCount = data['privateSenders'] ?? 0;
            _globalSenderCount = data['globalSenders'] ?? 0;
          });
        }
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _isFetchingSenders = false);
    }
  }

  // FUNGSI LOAD DATA LIMIT
  Future<void> _loadGlobalUsageData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? firstUseStr = prefs.getString(_keyGlobalFirstUseTime);
    int count = prefs.getInt(_keyGlobalUsageCount) ?? 0;

    if (firstUseStr != null) {
      final firstUseTime = DateTime.parse(firstUseStr);
      final now = DateTime.now();

      // Reset kuota jika sudah melewati 24 jam dari pemakaian pertama
      if (now.difference(firstUseTime).inHours >= 24) {
        count = 0;
        await prefs.setInt(_keyGlobalUsageCount, 0);
        await prefs.remove(_keyGlobalFirstUseTime);
      }
    }

    if (mounted) {
      setState(() {
        _globalUsageCount = count;
      });
    }
  }

  // FUNGSI CEK & TAMBAH LIMIT
  Future<bool> _checkAndIncrementGlobalUsage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? firstUseStr = prefs.getString(_keyGlobalFirstUseTime);
    final now = DateTime.now();

    if (firstUseStr == null) {
      await prefs.setString(_keyGlobalFirstUseTime, now.toIso8601String());
      await prefs.setInt(_keyGlobalUsageCount, 1);
      setState(() => _globalUsageCount = 1);
      return true;
    }

    final firstUseTime = DateTime.parse(firstUseStr);
    if (now.difference(firstUseTime).inHours >= 24) {
      await prefs.setString(_keyGlobalFirstUseTime, now.toIso8601String());
      await prefs.setInt(_keyGlobalUsageCount, 1);
      setState(() => _globalUsageCount = 1);
      return true;
    }

    int count = prefs.getInt(_keyGlobalUsageCount) ?? 0;
    if (count >= _maxGlobalLimit) {
      return false;
    }

    count++;
    await prefs.setInt(_keyGlobalUsageCount, count);
    setState(() => _globalUsageCount = count);
    return true;
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

  String? formatPhoneNumber(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.length < 8) return null;
    return cleaned;
  }

  void _showBugSelectionPopup() {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
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
                  Icon(Icons.bug_report, color: theme.colorScheme.primary, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    "PILIH BUG NOMOR",
                    style: TextStyle(
                      color: _textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              content: Container(
                width: double.maxFinite,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: widget.listSpam.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text(
                            "Belum ada data bug spam dari server.",
                            style: TextStyle(color: Colors.white54, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: widget.listSpam.length,
                        itemBuilder: (context, index) {
                          final bug = widget.listSpam[index];
                          final bugId = bug['bug_id'];
                          final isSelected = selectedBugIds.contains(bugId);

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primary.withOpacity(0.15)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(_isNeo ? 4 : 12),
                              border: Border.all(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : (_isNeo ? Colors.black26 : theme.colorScheme.primary.withOpacity(0.2)),
                                width: _isNeo ? 2 : 1,
                              ),
                            ),
                            child: ListTile(
                              leading: Icon(
                                isSelected
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: isSelected ? theme.colorScheme.primary : _subTextColor,
                              ),
                              title: Text(
                                bug['bug_name'] ?? 'Unknown',
                                style: TextStyle(color: _textColor, fontWeight: FontWeight.bold),
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
                    style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("CANCEL", style: TextStyle(color: _subTextColor)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    side: _isNeo ? const BorderSide(color: Colors.black, width: 2) : BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_isNeo ? 4 : 8),
                    ),
                  ),
                  onPressed: selectedBugIds.isEmpty
                      ? null
                      : () => Navigator.pop(context),
                  child: Text(
                    "OK",
                    style: TextStyle(
                      color: _isNeo && _isLight ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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

    if (formatPhoneNumber(rawInput) == null || key.isEmpty) {
      _showAlert("❌ Invalid Number", "Gunakan nomor internasional (+62, 1, dll).");
      return;
    }
    if (selectedBugIds.isEmpty) {
      _showAlert("❌ No Bug Selected", "Pilih minimal 1 bug.");
      return;
    }

    if (_selectedSenderType == "global") {
      final allowed = await _checkAndIncrementGlobalUsage();
      if (!allowed) {
        _showAlert(
          "⏳ Limit Global Sender Tercapai",
          "Batas pemakaian Global Sender (5x / 24 jam) telah habis.",
        );
        return;
      }
    }

    setState(() {
      _isSending = true;
      _responseMessage = null;
    });

    try {
      final bugsParam = selectedBugIds.join(',');
      final res = await http.get(
        Uri.parse(
          "$baseUrl/sendBBug?key=$key&target=$rawInput&bug=$bugsParam&sender=$_selectedSenderType",
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
        setState(() => _responseMessage = "✅ Berhasil mengirim serangan bug nomor!");
        targetController.clear();
        selectedBugIds.clear();
        _fetchSenderCounts();
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
            color: _isNeo ? Colors.black : theme.colorScheme.primary,
            width: _isNeo ? 3 : 1.5,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: theme.colorScheme.primary,
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
              style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
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
          color: _isNeo ? Colors.black : theme.colorScheme.primary.withOpacity(0.3),
          width: _isNeo ? 3.0 : 1.0,
        ),
        boxShadow: _isNeo
            ? [const BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(4, 4))]
            : [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.12),
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
              color: theme.colorScheme.primary,
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
                    color: theme.colorScheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(_isNeo ? 2 : 12),
                    border: Border.all(
                      color: _isNeo ? Colors.black : theme.colorScheme.primary.withOpacity(0.5),
                      width: _isNeo ? 1.5 : 1.0,
                    ),
                  ),
                  child: Text(
                    "Role: ${widget.role.toUpperCase()} • Exp: ${widget.expiredDate}",
                    style: TextStyle(
                      color: _isNeo ? Colors.black : theme.colorScheme.primary,
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
            color: _isNeo ? Colors.black : theme.colorScheme.primary.withOpacity(0.3),
            width: _isNeo ? 3 : 1,
          ),
        ),
        child: Center(
          child: CircularProgressIndicator(color: theme.colorScheme.primary, strokeWidth: 3),
        ),
      );
    }
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_isNeo ? 8 : 20),
        border: Border.all(
          color: _isNeo ? Colors.black : theme.colorScheme.primary.withOpacity(0.4),
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

  Widget _buildSenderTypeSelector() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Sender Type",
                  style: TextStyle(
                    color: _textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Pilih sumber nomor pengirim",
                  style: TextStyle(
                    color: _subTextColor,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            IconButton(
              onPressed: _isFetchingSenders ? null : _fetchSenderCounts,
              icon: _isFetchingSenders
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : Icon(
                      Icons.refresh_rounded,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            // KARTU GLOBAL SENDER
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
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                  decoration: BoxDecoration(
                    color: _selectedSenderType == "global"
                        ? theme.colorScheme.primary.withOpacity(0.18)
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(_isNeo ? 6 : 16),
                    border: Border.all(
                      color: _selectedSenderType == "global"
                          ? theme.colorScheme.primary
                          : (_isNeo ? Colors.black : theme.colorScheme.primary.withOpacity(0.2)),
                      width: _isNeo ? 2.5 : (_selectedSenderType == "global" ? 2 : 1),
                    ),
                    boxShadow: _isNeo
                        ? [
                            BoxShadow(
                              color: _selectedSenderType == "global" ? Colors.black : Colors.transparent,
                              blurRadius: 0,
                              offset: const Offset(3, 3),
                            )
                          ]
                        : [],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.language_rounded,
                        color: _selectedSenderType == "global"
                            ? theme.colorScheme.primary
                            : _subTextColor,
                        size: 24,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Global",
                        style: TextStyle(
                          color: _selectedSenderType == "global"
                              ? theme.colorScheme.primary
                              : _textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "$_globalSenderCount sender",
                        style: TextStyle(
                          color: _subTextColor,
                          fontSize: 11,
                        ),
                      ),
                      if (_isAllowedToUseGlobal) ...[
                        const SizedBox(height: 4),
                        Text(
                          "Kuota: $_globalUsageCount/$_maxGlobalLimit",
                          style: TextStyle(
                            color: _globalUsageCount >= _maxGlobalLimit
                                ? Colors.redAccent
                                : theme.colorScheme.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // KARTU PRIVATE SENDER
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedSenderType = "private"),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                  decoration: BoxDecoration(
                    color: _selectedSenderType == "private"
                        ? theme.colorScheme.primary.withOpacity(0.18)
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(_isNeo ? 6 : 16),
                    border: Border.all(
                      color: _selectedSenderType == "private"
                          ? theme.colorScheme.primary
                          : (_isNeo ? Colors.black : theme.colorScheme.primary.withOpacity(0.2)),
                      width: _isNeo ? 2.5 : (_selectedSenderType == "private" ? 2 : 1),
                    ),
                    boxShadow: _isNeo
                        ? [
                            BoxShadow(
                              color: _selectedSenderType == "private" ? Colors.black : Colors.transparent,
                              blurRadius: 0,
                              offset: const Offset(3, 3),
                            )
                          ]
                        : [],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        color: _selectedSenderType == "private"
                            ? theme.colorScheme.primary
                            : _subTextColor,
                        size: 24,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Private",
                        style: TextStyle(
                          color: _selectedSenderType == "private"
                              ? theme.colorScheme.primary
                              : _textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _privateSenderCount > 0
                            ? "$_privateSenderCount sender aktif"
                            : "Session sendiri",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _subTextColor,
                          fontSize: 11,
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
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSenderTypeSelector(),
        const SizedBox(height: 20),
        Text(
          "NOMOR TARGET",
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
          cursorColor: theme.colorScheme.primary,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: "Contoh: +62xxxxxxxxxx",
            hintStyle: TextStyle(color: _subTextColor),
            filled: true,
            fillColor: theme.colorScheme.surface,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_isNeo ? 4 : 16),
              borderSide: BorderSide(
                color: _isNeo ? Colors.black : theme.colorScheme.primary.withOpacity(0.3),
                width: _isNeo ? 2 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_isNeo ? 4 : 16),
              borderSide: BorderSide(
                color: _isNeo ? Colors.black : theme.colorScheme.primary,
                width: 2,
              ),
            ),
            prefixIcon: Icon(Icons.phone_android_rounded, color: theme.colorScheme.primary),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "PILIH BUG NOMOR",
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
                  color: theme.colorScheme.primary,
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
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _showBugSelectionPopup,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(_isNeo ? 4 : 16),
              border: Border.all(
                color: _isNeo ? Colors.black : theme.colorScheme.primary.withOpacity(0.3),
                width: _isNeo ? 2 : 1.5,
              ),
              boxShadow: _isNeo
                  ? [const BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(3, 3))]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: selectedBugIds.isEmpty
                      ? Text(
                          "Klik untuk memilih bug",
                          style: TextStyle(color: _subTextColor, fontSize: 14),
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: selectedBugIds.map((bugId) {
                            final bug = widget.listSpam.firstWhere(
                              (b) => b['bug_id'] == bugId,
                              orElse: () => {'bug_name': 'Unknown'},
                            );
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(_isNeo ? 2 : 12),
                                border: Border.all(
                                  color: _isNeo ? Colors.black : theme.colorScheme.primary.withOpacity(0.5),
                                  width: _isNeo ? 1.5 : 1,
                                ),
                              ),
                              child: Text(
                                bug['bug_name'] ?? 'Unknown',
                                style: TextStyle(
                                  color: _isNeo ? Colors.black : theme.colorScheme.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                ),
                Icon(Icons.arrow_drop_down, color: theme.colorScheme.primary, size: 28),
              ],
            ),
          ),
        ),
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
            color: theme.colorScheme.primary,
            border: _isNeo ? Border.all(color: Colors.black, width: 2.5) : null,
            boxShadow: _isNeo
                ? [const BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(4, 4))]
                : [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.4),
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
                        Icons.rocket_launch_rounded,
                        color: _isNeo && _isLight ? Colors.black : Colors.white,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "SEND BUG NUMBER",
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
          "BUG NOMOR MODULE",
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
