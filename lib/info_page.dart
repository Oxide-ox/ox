import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'btrapps/.dart';
import 'app_theme.dart';

final baseUrl = Api.api;
final AudioPlayer _audioPlayer = AudioPlayer();

class InfoPage extends StatefulWidget {
  final String sessionKey;

  const InfoPage({super.key, required this.sessionKey});

  @override
  State<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  Map<String, dynamic>? serverInfo;
  bool isLoading = true;

  bool isApiOnline = false;
  int apiPingMs = 0;
  Color apiStatusColor = Colors.grey;
  String apiStatusText = "Checking...";
  Timer? _pingTimer;

  final Set<int> _expandedIndices = {};

  bool get _isLight => Theme.of(context).brightness == Brightness.light;
  Color get _textColor => _isLight ? Colors.black87 : Colors.white;
  Color get _subTextColor => _isLight ? Colors.black54 : Colors.white70;
  bool get _isNeo => themeModeNotifier.value != 0;

  @override
  void initState() {
    super.initState();
    _initAsyncData();
  }

  void _initAsyncData() async {
    _fetchServerInfo();
    _startApiPingLoop();
    await _audioPlayer.resume();
  }

  @override
  void dispose() {
    _pingTimer?.cancel();
    _audioPlayer.pause();
    super.dispose();
  }

  Future<void> _fetchServerInfo() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/getServerInfo?key=${widget.sessionKey}'),
      );
      if (res.statusCode == 200) {
        setState(() {
          serverInfo = jsonDecode(res.body);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _startApiPingLoop() {
    _checkApiPing();
    _pingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkApiPing();
    });
  }

  Future<void> _checkApiPing() async {
    final start = DateTime.now();
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/ping?key=${widget.sessionKey}'),
      ).timeout(const Duration(seconds: 3));

      final end = DateTime.now();
      final duration = end.difference(start).inMilliseconds;

      if (res.statusCode == 200) {
        setState(() {
          isApiOnline = true;
          apiPingMs = duration;
          if (duration < 200) {
            apiStatusColor = const Color(0xFF00FF87);
          } else if (duration < 500) {
            apiStatusColor = Colors.amber;
          } else {
            apiStatusColor = Colors.orangeAccent;
          }
          apiStatusText = "Online (${duration}ms)";
        });
      } else {
        throw Exception("Failed");
      }
    } catch (e) {
      setState(() {
        isApiOnline = false;
        apiPingMs = 0;
        apiStatusColor = Colors.redAccent;
        apiStatusText = "Offline";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text("Info", style: TextStyle(color: _textColor)),
        ),
        body: Center(
          child: CircularProgressIndicator(color: theme.colorScheme.primary),
        ),
      );
    }

    final List<Map<String, String>> rulesList = [
      {
        "title": "Larangan Barter Akun",
        "desc": "Akun tidak boleh ditukar dengan barang, jasa, atau akun lain dalam bentuk apa pun."
      },
      {
        "title": "Larangan Membagikan Akun",
        "desc": "Setiap akun bersifat pribadi dan hanya boleh digunakan oleh pemilik akun yang terdaftar."
      },
      {
        "title": "Larangan Menjual Akun",
        "desc": "Member TIDAK diperbolehkan menjual akun. Penjualan akun hanya boleh dilakukan oleh role yang diizinkan secara resmi."
      },
      {
        "title": "Larangan Jual Durasi Ilegal",
        "desc": "Dilarang menjual akses harian, mingguan, trial, atau sejenisnya di luar ketentuan yang telah ditetapkan."
      },
      {
        "title": "Larangan Banting Harga",
        "desc": "Dilarang merusak atau menurunkan harga yang telah ditentukan (banting harga) di bawah ketentuan owner app."
      },
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          "PERATURAN & INFO",
          style: TextStyle(
            color: _textColor,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCompactApiStatus(),
            const SizedBox(height: 20),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isNeo ? theme.colorScheme.primary : theme.colorScheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(_isNeo ? 4 : 8),
                    border: Border.all(
                      color: _isNeo ? Colors.black : theme.colorScheme.primary.withOpacity(0.5),
                      width: _isNeo ? 1.5 : 1.0,
                    ),
                  ),
                  child: Icon(
                    Icons.gavel,
                    color: _isNeo ? Colors.black : theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "PERATURAN PENGGUNA",
                  style: TextStyle(
                    color: _textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            ...rulesList.asMap().entries.map((entry) {
              int index = entry.key + 1;
              Map<String, String> rule = entry.value;
              return _buildCollapsibleRule(index, rule);
            }).toList(),

            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(_isNeo ? 8 : 20),
                border: Border.all(
                  color: _isNeo ? Colors.black : theme.colorScheme.primary,
                  width: _isNeo ? 3 : 1.5,
                ),
                boxShadow: _isNeo
                    ? [const BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(5, 5))]
                    : [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.2),
                          blurRadius: 15,
                          spreadRadius: 1,
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: _isNeo ? Colors.redAccent : theme.colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "SANKSI",
                        style: TextStyle(
                          color: _isNeo ? Colors.redAccent : theme.colorScheme.primary,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Jika pengguna terbukti melanggar salah satu peraturan di atas:",
                    style: TextStyle(color: _subTextColor, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Akun akan DIHAPUS secara permanen 🚫",
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Tanpa pengembalian akun, saldo, atau kompensasi apa pun ‼️",
                    style: TextStyle(
                      color: _isNeo ? Colors.redAccent : theme.colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Center(
              child: Column(
                children: [
                  Icon(Icons.shield_moon_rounded, color: theme.colorScheme.primary, size: 30),
                  const SizedBox(height: 12),
                  Text(
                    "Peraturan ini dibuat untuk menjaga keamanan, kenyamanan, dan kestabilan ekosistem Prikitiww App. Dengan menggunakan aplikasi ini, pengguna dianggap telah menyetujui seluruh peraturan di atas.",
                    style: TextStyle(
                      color: _subTextColor,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 3,
                    width: 80,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsibleRule(int index, Map<String, String> rule) {
    final theme = Theme.of(context);
    final bool isExpanded = _expandedIndices.contains(index);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(_isNeo ? 8 : 16),
          border: Border.all(
            color: _isNeo
                ? Colors.black
                : (isExpanded ? theme.colorScheme.primary : theme.colorScheme.primary.withOpacity(0.3)),
            width: _isNeo ? 2.5 : (isExpanded ? 1.5 : 1.0),
          ),
          boxShadow: _isNeo
              ? [const BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(4, 4))]
              : [
                  BoxShadow(
                    color: isExpanded
                        ? theme.colorScheme.primary.withOpacity(0.2)
                        : Colors.transparent,
                    blurRadius: isExpanded ? 10 : 4,
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(_isNeo ? 8 : 16),
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedIndices.remove(index);
                } else {
                  _expandedIndices.add(index);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _isNeo ? theme.colorScheme.primary : theme.colorScheme.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(_isNeo ? 3 : 8),
                          border: Border.all(
                            color: _isNeo ? Colors.black : theme.colorScheme.primary.withOpacity(0.5),
                            width: _isNeo ? 1.5 : 1.0,
                          ),
                        ),
                        child: Text(
                          "Rule $index",
                          style: TextStyle(
                            color: _isNeo ? Colors.black : theme.colorScheme.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          rule['title']!,
                          style: TextStyle(
                            color: _textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                    ],
                  ),
                  if (isExpanded) ...[
                    const SizedBox(height: 10),
                    Divider(
                      color: _isNeo ? Colors.black : Colors.white10,
                      thickness: _isNeo ? 1.5 : 1,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      rule['desc']!,
                      style: TextStyle(
                        color: _subTextColor,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactApiStatus() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(_isNeo ? 6 : 12),
        border: Border.all(
          color: _isNeo ? Colors.black : theme.colorScheme.primary.withOpacity(0.3),
          width: _isNeo ? 2 : 1,
        ),
        boxShadow: _isNeo
            ? [const BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(3, 3))]
            : [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  blurRadius: 8,
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: apiStatusColor,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: apiStatusColor.withOpacity(0.6), blurRadius: 6)],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            "System Status: ${apiStatusText.toUpperCase()}",
            style: TextStyle(
              color: _subTextColor,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
