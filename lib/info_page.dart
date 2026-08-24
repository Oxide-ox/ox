import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'btrapps/.dart';

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

  static const Color bgDark = Color(0xFF090212);
  static const Color bgDeepPurple = Color(0xFF140526);
  static const Color neonMagenta = Color(0xFFE6007E);
  static const Color neonPurple = Color(0xFF8E00C7);
  static const Color cardDark = Color(0xFF120722);

  final Set<int> _expandedIndices = {};

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
        apiStatusColor = neonMagenta;
        apiStatusText = "Offline";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: bgDark,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: const Text("Info", style: TextStyle(color: Colors.white)),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: neonMagenta),
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
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          "PERATURAN & INFO",
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            shadows: [
              Shadow(color: neonMagenta, blurRadius: 10),
            ],
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgDark, bgDeepPurple, bgDark],
          ),
        ),
        child: SingleChildScrollView(
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
                      color: neonMagenta.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: neonMagenta.withOpacity(0.5)),
                    ),
                    child: const Icon(Icons.gavel, color: neonMagenta, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "PERATURAN PENGGUNA",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Orbitron',
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
                  gradient: const LinearGradient(
                    colors: [bgDeepPurple, cardDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: neonMagenta, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: neonMagenta.withOpacity(0.3),
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
                      children: const [
                        Icon(Icons.warning_amber_rounded, color: neonMagenta, size: 28),
                        SizedBox(width: 10),
                        Text(
                          "SANKSI",
                          style: TextStyle(
                            color: neonMagenta,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Orbitron',
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Jika pengguna terbukti melanggar salah satu peraturan di atas:",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Akun akan DIHAPUS secara permanen 🚫",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Tanpa pengembalian akun, saldo, atau kompensasi apa pun ‼️",
                      style: TextStyle(
                        color: neonMagenta,
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
                    const Icon(Icons.shield_moon_rounded, color: neonMagenta, size: 30),
                    const SizedBox(height: 12),
                    const Text(
                      "Peraturan ini dibuat untuk menjaga keamanan, kenyamanan, dan kestabilan ekosistem Prikitiww App. Dengan menggunakan aplikasi ini, pengguna dianggap telah menyetujui seluruh peraturan di atas.",
                      style: TextStyle(
                        color: Colors.white54,
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
                        color: neonMagenta,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: neonMagenta.withOpacity(0.8),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsibleRule(int index, Map<String, String> rule) {
    final bool isExpanded = _expandedIndices.contains(index);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: cardDark.withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isExpanded ? neonMagenta : neonPurple.withOpacity(0.4),
            width: isExpanded ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isExpanded ? neonMagenta.withOpacity(0.25) : neonPurple.withOpacity(0.1),
              blurRadius: isExpanded ? 10 : 4,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
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
                          color: neonMagenta.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: neonMagenta.withOpacity(0.5)),
                        ),
                        child: Text(
                          "Rule $index",
                          style: const TextStyle(
                            color: neonMagenta,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Orbitron',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          rule['title']!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: neonMagenta,
                        size: 24,
                      ),
                    ],
                  ),
                  if (isExpanded) ...[
                    const SizedBox(height: 10),
                    Divider(color: neonPurple.withOpacity(0.4), height: 1),
                    const SizedBox(height: 10),
                    Text(
                      rule['desc']!,
                      style: const TextStyle(
                        color: Colors.white70,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardDark.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: neonPurple.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: neonMagenta.withOpacity(0.15),
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
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontFamily: 'ShareTechMono',
            ),
          ),
        ],
      ),
    );
  }
}