import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'vps_service.dart';
import 'vps_manage_page.dart';
import 'btrapps/.dart';

final baseUrl = Api.api;

class VpsPanelPage extends StatefulWidget {
  final String username;
  final String sessionKey;
  final String role;

  const VpsPanelPage({
    super.key,
    required this.username,
    required this.sessionKey,
    required this.role,
  });

  @override
  State<VpsPanelPage> createState() => _VpsPanelPageState();
}

class _VpsPanelPageState extends State<VpsPanelPage> {
  late VpsService _vpsService;
  late VideoPlayerController _videoController;
  
  List<VpsNode> _vpsServers = [];
  VpsNode? _selectedServer;

  bool _isLoading = false;
  bool _isVideoInitialized = false;
  String _status = "Checking...";
  String _cpu = "0";
  String _ram = "0";
  List<String> _logs = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _vpsService = VpsService();
    
    // SETUP VIDEO BACKGROUND
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse('https://smail.my.id/cloud/x2eYygfb1'),
    )..initialize().then((_) {
        _videoController.setLooping(true);
        _videoController.setVolume(0.0); // Mute audio
        _videoController.play();
        if (mounted) {
          setState(() => _isVideoInitialized = true);
        }
      });

    _loadVpsServers();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _fetchStatus());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _videoController.dispose();
    super.dispose();
  }

  Future<void> _loadVpsServers() async {
    final list = await _vpsService.fetchVpsList();
    if (list.isNotEmpty && mounted) {
      setState(() {
        _vpsServers = list;
        _selectedServer = list.first;
      });
      _fetchStatus();
    }
  }

  Future<void> _fetchStatus() async {
    if (_selectedServer == null) return;
    try {
      final res = await http.get(
        Uri.parse('${_selectedServer!.fullUrl}/air/status/${widget.username}'),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _status = data['status'] ?? 'Stopped';
            _cpu = data['cpu'].toString();
            _ram = data['ram'].toString();
            _logs = List<String>.from(data['logs'] ?? []);
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _actionStart() async {
    if (_selectedServer == null) return;
    setState(() => _isLoading = true);
    try {
      final res = await http.post(
        Uri.parse('${_selectedServer!.fullUrl}/air/start'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': widget.username}),
      );
      final data = jsonDecode(res.body);
      _showToast(data['message'] ?? 'Start diproses');
    } catch (e) {
      _showToast('Gagal terhubung ke VPS server');
    }
    setState(() => _isLoading = false);
    _fetchStatus();
  }

  Future<void> _actionStop() async {
    if (_selectedServer == null) return;
    setState(() => _isLoading = true);
    try {
      final res = await http.post(
        Uri.parse('${_selectedServer!.fullUrl}/air/stop'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': widget.username}),
      );
      final data = jsonDecode(res.body);
      _showToast(data['message'] ?? 'Stop diproses');
    } catch (e) {
      _showToast('Gagal terhubung ke VPS server');
    }
    setState(() => _isLoading = false);
    _fetchStatus();
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    bool isRunning = _status == "Running";

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. BACKGROUND VIDEO (FULLSCREEN COVER)
          if (_isVideoInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController.value.size.width,
                  height: _videoController.value.size.height,
                  child: VideoPlayer(_videoController),
                ),
              ),
            )
          else
            const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),

          // 2. OVERLAY DARK GLASS EFFECT
          Container(color: Colors.black.withOpacity(0.7)),

          // 3. UI KONTEN PANEL
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER PANEL & BUTTON MANAGE VPS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'VPS NAT PANEL',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          Text(
                            'User: ${widget.username}',
                            style: const TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          if (widget.role == 'developer')
                            IconButton(
                              icon: const Icon(Icons.settings, color: Colors.cyanAccent),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => VpsManagePage(
                                      username: widget.username,
                                      role: widget.role,
                                      sessionKey: widget.sessionKey,
                                    ),
                                  ),
                                ).then((_) => _loadVpsServers());
                              },
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isRunning
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isRunning ? Colors.greenAccent : Colors.redAccent,
                              ),
                            ),
                            child: Text(
                              _status.toUpperCase(),
                              style: TextStyle(
                                color: isRunning ? Colors.greenAccent : Colors.redAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // DROPDOWN SERVER SWITCHER
                  if (_vpsServers.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: DropdownButton<VpsNode>(
                        value: _selectedServer,
                        dropdownColor: const Color(0xFF1A1A24),
                        isExpanded: true,
                        underline: const SizedBox(),
                        hint: const Text("Pilih Server VPS", style: TextStyle(color: Colors.white)),
                        items: _vpsServers.map((server) {
                          return DropdownMenuItem<VpsNode>(
                            value: server,
                            child: Text(server.name, style: const TextStyle(color: Colors.white)),
                          );
                        }).toList(),
                        onChanged: (newServer) {
                          setState(() => _selectedServer = newServer);
                          _fetchStatus();
                        },
                      ),
                    ),
                  const SizedBox(height: 16),

                  // RESOURCE METRICS (CPU & RAM)
                  Row(
                    children: [
                      _buildMetricCard(
                        'CPU USAGE',
                        '$_cpu %',
                        (double.tryParse(_cpu) ?? 0) / 100,
                        Colors.cyanAccent,
                      ),
                      const SizedBox(width: 12),
                      _buildMetricCard(
                        'RAM USAGE',
                        '$_ram MB',
                        ((double.tryParse(_ram) ?? 0) / 250).clamp(0.0, 1.0),
                        Colors.purpleAccent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ACTION BUTTONS (START / STOP)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.greenAccent,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : const Icon(Icons.play_arrow),
                          label: const Text('START', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: _isLoading ? null : _actionStart,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.stop),
                          label: const Text('STOP', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: _isLoading ? null : _actionStop,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // LIVE CONSOLE LOGS
                  const Text(
                    'Console Log Console',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: _logs.isEmpty
                          ? const Center(
                              child: Text(
                                'Belum ada log aktif.',
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            )
                          : ListView.builder(
                              reverse: true,
                              itemCount: _logs.length,
                              itemBuilder: (context, i) {
                                String log = _logs[_logs.length - 1 - i];
                                Color color = log.startsWith('[ERR]')
                                    ? Colors.redAccent
                                    : Colors.greenAccent;
                                return Text(
                                  log,
                                  style: TextStyle(
                                    color: color,
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, double progress, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              color: color,
              backgroundColor: Colors.white12,
            ),
          ],
        ),
      ),
    );
  }
}
