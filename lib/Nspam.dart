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

  // Real-time Sender Count State
  int _privateSenderCount = 0;
  int _globalSenderCount = 0;
  bool _isFetchingSenders = false;

  // State Limit Khusus Global Sender dari Backend
  int _globalUsageCount = 0;
  int _maxGlobalLimit = 0;
  Map<String, int> _currentRoleLimits = {};
  bool _isLoadingLimits = false;

  // Key SharedPreferences khusus pemakaian harian lokal user
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

  // HANYA ROLE DEVELOPER YANG BISA UBAH LIMIT
  bool get _isOnlyDeveloper {
    final cleanRole = widget.role.toLowerCase().trim();
    return cleanRole == "dev" || cleanRole == "developer";
  }

  // HAK AKSES GLOBAL SENDER (MEMBER TIDAK DAPAT, MINIMAL VIP)
  bool get _isAllowedToUseGlobal {
    final cleanRole = widget.role.toLowerCase().trim();
    if (cleanRole == "member") return false;
    return _maxGlobalLimit > 0;
  }

  @override
  void initState() {
    super.initState();
    _fetchRoleLimitsFromBackend();
    _loadUserUsageCount();
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

  // AMBIL LIMIT ROLE TERBARU DARI BACKEND
  Future<void> _fetchRoleLimitsFromBackend() async {
    setState(() => _isLoadingLimits = true);
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/limits'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['limits'] != null) {
          final Map<String, dynamic> rawLimits = data['limits'];
          final Map<String, int> parsedLimits = rawLimits.map(
            (key, value) => MapEntry(key.toLowerCase(), (value as num).toInt()),
          );

          final cleanRole = widget.role.toLowerCase().trim();
          if (mounted) {
            setState(() {
              _currentRoleLimits = parsedLimits;
              _maxGlobalLimit = cleanRole == "member" ? 0 : (parsedLimits[cleanRole] ?? 0);
            });
          }
        }
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _isLoadingLimits = false);
    }
  }

  // AMBIL PEMAKAIAN HARIAN USER LOKAL
  Future<void> _loadUserUsageCount() async {
    final prefs = await SharedPreferences.getInstance();
    final String? firstUseStr = prefs.getString(_keyGlobalFirstUseTime);
    int count = prefs.getInt(_keyGlobalUsageCount) ?? 0;

    if (firstUseStr != null) {
      final firstUseTime = DateTime.parse(firstUseStr);
      final now = DateTime.now();

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

  // KIRIM UPDATE LIMIT ROLE KE BACKEND (KHUSUS DEV)
  Future<void> _saveLimitsToBackend(Map<String, int> newLimits) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/limits/update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'senderRole': widget.role,
          'limits': newLimits,
        }),
      );

      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        await _fetchRoleLimitsFromBackend();
        if (mounted) {
          _showAlert("✅ BERHASIL", "Limit Global Sender telah disimpan di server untuk semua user!");
        }
      } else {
        if (mounted) {
          _showAlert("❌ GAGAL", data['message'] ?? "Gagal menyimpan perubahan ke server.");
        }
      }
    } catch (_) {
      if (mounted) {
        _showAlert("❌ ERROR", "Gagal terhubung ke server backend.");
      }
    }
  }

  // DIALOG EDIT LIMIT (KHUSUS DEVELOPER)
  Future<void> _showManageRoleLimitsDialog() async {
    if (!_isOnlyDeveloper) return;

    final theme = Theme.of(context);
    final Map<String, TextEditingController> controllers = {};
    _currentRoleLimits.forEach((role, limit) {
      controllers[role] = TextEditingController(text: limit.toString());
    });

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
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
              Icon(Icons.developer_mode, color: theme.colorScheme.primary, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "SETTING LIMIT (BACKEND)",
                  style: TextStyle(
                    color: _textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Ubah limit harian Global Sender per role. Perubahan ini tersimpan di server dan otomatis memengaruhi semua user.",
                    style: TextStyle(color: _subTextColor, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  ..._currentRoleLimits.keys.map((roleKey) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              roleKey.toUpperCase(),
                              style: TextStyle(
                                color: roleKey == "member" ? Colors.redAccent : _textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: controllers[roleKey],
                              keyboardType: TextInputType.number,
                              style: TextStyle(color: _textColor, fontSize: 13),
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                filled: true,
                                fillColor: theme.scaffoldBackgroundColor,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(_isNeo ? 4 : 8),
                                  borderSide: BorderSide(
                                    color: _isNeo ? Colors.black : theme.colorScheme.primary.withOpacity(0.3),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(_isNeo ? 4 : 8),
                                  borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("BATAL", style: TextStyle(color: _subTextColor)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                side: _isNeo ? const BorderSide(color: Colors.black, width: 2) : BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_isNeo ? 4 : 8),
                ),
              ),
              onPressed: () async {
                final Map<String, int> updatedLimits = {};
                for (String roleKey in controllers.keys) {
                  final newVal = int.tryParse(controllers[roleKey]!.text.trim());
                  if (newVal != null) {
                    updatedLimits[roleKey] = newVal;
                  }
                }
                Navigator.pop(context);
                await _saveLimitsToBackend(updatedLimits);
              },
              child: Text(
                "SIMPAN KE SERVER",
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
      if (!_isAllowedToUseGlobal) {
        _showAlert(
          "🔒 TERKUNCI",
          "Role MEMBER tidak mendapat akses Global Sender. Minimal role VIP.",
        );
        return;
      }

      final allowed = await _checkAndIncrementGlobalUsage();
      if (!allowed) {
        _showAlert(
          "⏳ Limit Global Sender Tercapai",
          "Batas pemakaian Global Sender ($_maxGlobalLimit x / 24 jam) untuk role ${widget.role.toUpperCase()} telah habis.",
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
          if (_isOnlyDeveloper)
            IconButton(
              icon: Icon(Icons.settings, color: theme.colorScheme.primary),
              tooltip: 'Set Limit Backend (Dev Only)',
              onPressed: _showManageRoleLimitsDialog,
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
              onPressed: _isFetchingSenders ? null : () {
                _fetchSenderCounts();
                _fetchRoleLimitsFromBackend();
              },
              icon: _isFetchingSenders || _isLoadingLimits
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
                      "Role MEMBER tidak mendapat akses Global Sender. Minimal role VIP.",
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
                      const SizedBox(height: 4),
                      Text(
                        _isAllowedToUseGlobal
                            ? "Kuota: $_globalUsageCount/$_maxGlobalLimit"
                            : "No Access",
                        style: TextStyle(
                          color: !_isAllowedToUseGlobal || _globalUsageCount >= _maxGlobalLimit
                              ? Colors.redAccent
                              : theme.colorScheme.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
