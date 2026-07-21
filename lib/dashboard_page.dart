import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';

// Imports internal aplikasi Anda
import 'nik_check.dart';
import 'admin_page.dart';
import 'owner_page.dart';
import 'home_page.dart';
import 'seller_page.dart';
import 'change_password_page.dart';
import 'tools_gateway.dart';
import 'login_page.dart';
import 'bug_sender.dart';
import 'contact_page.dart';
import 'profile_page.dart';
import 'riwayat_page.dart';
import 'info_page.dart';
import 'publik_chat.dart';
import 'global_mini_player.dart';
import 'tq_to.dart';
import 'anime_home.dart';

class DashboardPage extends StatefulWidget {
  final String userId;
  final String level;
  final String username;
  final String password;
  final String role;
  final String expiredDate;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final List<Map<String, dynamic>> listDoos;
  final List<dynamic> news;

  const DashboardPage({
    super.key,
    required this.userId,
    required this.level,
    required this.username,
    required this.password,
    required this.role,
    required this.expiredDate,
    required this.listBug,
    required this.listDoos,
    required this.sessionKey,
    required this.news,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  late String sessionKey;
  late String username;
  late String password;
  late String role;
  late String expiredDate;
  late List<Map<String, dynamic>> listBug;
  late List<Map<String, dynamic>> listDoos;
  late List<dynamic> newsList;

  File? _profileImage;
  VideoPlayerController? _menuVideoController;
  int _bottomNavIndex = 0;
  late Widget _selectedPage;

  int onlineUsers = 0;
  int activeConnections = 0;

  // Realtime Clock & Prayer Times via IP
  Timer? _timer;
  DateTime _now = DateTime.now();
  Map<String, String> _prayerTimes = {};
  String _nextPrayerName = "-";
  String _timeUntilNextPrayer = "--:--:--";
  bool _isLoadingPrayer = true;
  String _locationName = "Mendeteksi lokasi...";

  // PALET WARNA TEMA OXIDE (Deep Cosmic Violet & Metallic Silver)
  final Color bgDark = const Color(0xFF080613);
  final Color neonViolet = const Color(0xFF9D00FF);
  final Color glowPurple = const Color(0xFF7A02C7);
  final Color silverWhite = const Color(0xFFE2E8F0);
  final Color silverAccent = const Color(0xFF94A3B8);
  final Color cardGlass = const Color(0xFF130D2B).withOpacity(0.65);
  final Color borderGlass = const Color(0xFF9D00FF).withOpacity(0.35);

  final Color primaryPink = const Color(0xFF1C0B36);
  final Color cardDark = const Color(0xFF140C2E);
  final Color cardDarker = const Color(0xFF090418);
  final Color primaryDark = const Color(0xFF040209);

  late PageController _pageController;
  int _currentNewsIndex = 0;

  @override
  void initState() {
    super.initState();
    sessionKey = widget.sessionKey;
    username = widget.username;
    password = widget.password;
    role = widget.role;
    expiredDate = widget.expiredDate;
    listBug = widget.listBug;
    listDoos = widget.listDoos;
    newsList = widget.news;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();

    _pageController = PageController();
    _selectedPage = _buildNewsPage();
    _loadProfileImage();
    _initMenuVideo();
    _fetchDashboardStats();

    // Start Clock Timer & Fetch Waktu Sholat via IP
    _startClockTimer();
    _fetchPrayerTimesViaIP();
  }

  void _startClockTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
          _calculateNextPrayer();
        });
      }
    });
  }

  // --- DETEKSI LOKASI & SHOLAT OTOMATIS VIA IP INTERNET ---
  Future<void> _fetchPrayerTimesViaIP() async {
    try {
      final ipResponse = await http
          .get(Uri.parse('https://ipapi.co/json/'))
          .timeout(const Duration(seconds: 10));

      if (ipResponse.statusCode == 200) {
        final ipData = jsonDecode(ipResponse.body);
        final double lat = (ipData['latitude'] as num).toDouble();
        final double lon = (ipData['longitude'] as num).toDouble();
        final String city = ipData['city'] ?? "Unknown City";
        final String country = ipData['country_code'] ?? "ID";

        if (mounted) {
          setState(() {
            _locationName = "$city, $country";
          });
        }

        final prayerResponse = await http.get(
          Uri.parse(
            'https://api.aladhan.com/v1/timings?latitude=$lat&longitude=$lon&method=2',
          ),
        );

        if (prayerResponse.statusCode == 200) {
          final prayerData = jsonDecode(prayerResponse.body);
          final timings = prayerData['data']['timings'];

          if (mounted) {
            setState(() {
              _prayerTimes = {
                'Subuh': timings['Fajr'],
                'Dzuhur': timings['Dhuhr'],
                'Ashar': timings['Asr'],
                'Maghrib': timings['Maghrib'],
                'Isya': timings['Isha'],
              };
              _isLoadingPrayer = false;
              _calculateNextPrayer();
            });
          }
        }
      } else {
        _handleFallbackPrayer();
      }
    } catch (e) {
      debugPrint("Error fetching location/prayer via IP: $e");
      _handleFallbackPrayer();
    }
  }

  void _handleFallbackPrayer() {
    if (mounted) {
      setState(() {
        _locationName = "Indonesia";
        _isLoadingPrayer = false;
      });
    }
  }

  void _calculateNextPrayer() {
    if (_prayerTimes.isEmpty) return;

    DateTime today = DateTime.now();
    DateTime? nextPrayerTime;
    String nextName = "";

    _prayerTimes.forEach((name, timeStr) {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final prayerDateTime =
          DateTime(today.year, today.month, today.day, hour, minute);

      if (prayerDateTime.isAfter(today)) {
        if (nextPrayerTime == null || prayerDateTime.isBefore(nextPrayerTime!)) {
          nextPrayerTime = prayerDateTime;
          nextName = name;
        }
      }
    });

    if (nextPrayerTime == null) {
      final parts = _prayerTimes['Subuh']!.split(':');
      nextPrayerTime = DateTime(today.year, today.month, today.day + 1,
          int.parse(parts[0]), int.parse(parts[1]));
      nextName = 'Subuh';
    }

    final diff = nextPrayerTime!.difference(today);
    final hours = diff.inHours.toString().padLeft(2, '0');
    final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');

    _nextPrayerName = nextName;
    _timeUntilNextPrayer = "$hours:$minutes:$seconds";
  }

  Future<void> _fetchDashboardStats() async {
    try {
      final response = await http.get(Uri.parse('${Api.api}/api/dashboard-stats'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            onlineUsers = data['onlineUsers'] ?? 0;
            activeConnections = data['activeConnections'] ?? 0;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetch stats: $e");
    }
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('profile_image_$username');
    if (imagePath != null && imagePath.isNotEmpty) {
      setState(() {
        _profileImage = File(imagePath);
      });
    }
  }

  void _initMenuVideo() {
    _menuVideoController = VideoPlayerController.asset('assets/videos/banner.mp4')
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
          _menuVideoController?.setLooping(true);
          _menuVideoController?.setVolume(0.0);
          _menuVideoController?.play();
        }
      });
  }

  Future<void> _openUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception("Could not launch $uri");
    }
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _bottomNavIndex = index;
      if (index == 0) {
        _selectedPage = _buildNewsPage();
      } else if (index == 1) {
        _selectedPage = HomePage(
          username: username,
          password: password,
          listBug: listBug,
          role: role,
          expiredDate: expiredDate,
          sessionKey: sessionKey,
        );
      } else if (index == 2) {
        _selectedPage = InfoPage(sessionKey: sessionKey);
      } else if (index == 3) {
        _selectedPage = ToolsPage(
            username: username,
            sessionKey: sessionKey,
            userRole: role,
            listDoos: listDoos);
      }
    });
  }

  void _onSidebarTabSelected(int index) {
    setState(() {
      if (index == 1) {
        _selectedPage = SellerPage(keyToken: sessionKey);
      } else if (index == 2) {
        _selectedPage = AdminPage(sessionKey: sessionKey);
      } else if (index == 3) {
        _selectedPage = OwnerPage(sessionKey: sessionKey, username: username);
      }
    });
    Navigator.pop(context);
  }

  Widget _buildNewsPage() {
    final timeFormatted =
        "${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}:${_now.second.toString().padLeft(2, '0')}";
    final dateFormatted =
        "${_now.day.toString().padLeft(2, '0')}/${_now.month.toString().padLeft(2, '0')}/${_now.year}";

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 12),

          // CARD 1: JAM REAL-TIME & WAKTU SHOLAT VIA IP
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardGlass,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderGlass, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: neonViolet.withOpacity(0.15),
                    blurRadius: 20,
                    spreadRadius: -2,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.location_on_rounded,
                                  color: neonViolet, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                _locationName,
                                style: TextStyle(
                                  color: silverAccent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dateFormatted,
                            style: TextStyle(
                              color: silverAccent.withOpacity(0.8),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: cardDarker.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderGlass),
                        ),
                        child: Text(
                          timeFormatted,
                          style: TextStyle(
                            color: silverWhite,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'ShareTechMono',
                            letterSpacing: 1.5,
                            shadows: [
                              Shadow(color: neonViolet, blurRadius: 10),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Divider(color: borderGlass.withOpacity(0.3), height: 1),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.access_time_filled_rounded,
                              color: neonViolet, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            "Menuju $_nextPrayerName :",
                            style: TextStyle(
                                color: silverWhite,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      Text(
                        _timeUntilNextPrayer,
                        style: TextStyle(
                          color: neonViolet,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'ShareTechMono',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _isLoadingPrayer
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF9D00FF), strokeWidth: 2),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: _prayerTimes.entries.map((entry) {
                            final isNext = entry.key == _nextPrayerName;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                              decoration: BoxDecoration(
                                color: isNext
                                    ? neonViolet.withOpacity(0.25)
                                    : cardDarker.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isNext ? neonViolet : borderGlass,
                                  width: isNext ? 1.5 : 0.8,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    entry.key,
                                    style: TextStyle(
                                      color: isNext ? silverWhite : silverAccent,
                                      fontSize: 10,
                                      fontWeight: isNext
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    entry.value,
                                    style: TextStyle(
                                      color: silverWhite,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'ShareTechMono',
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // CARD 2: DASHBOARD STATS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardGlass,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderGlass, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: neonViolet.withOpacity(0.12),
                    blurRadius: 25,
                    spreadRadius: -2,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildCompactInfoItem(
                      icon: Icons.people_alt_rounded,
                      label: "Online Users",
                      value: "$onlineUsers",
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCompactInfoItem(
                      icon: Icons.hub_rounded,
                      label: "Connections",
                      value: "$activeConnections",
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          _buildNewsList(),
          const SizedBox(height: 16),
          _buildNewsCarousel(),
          const SizedBox(height: 20),

          // QUICK ACTION BUTTONS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: FontAwesomeIcons.telegram,
                    label: "Channel Info",
                    onPressed: () => _openUrl("https://t.me/AllinformationVirz"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.favorite_rounded,
                    label: "Tq To Team",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const TqPage()),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: FontAwesomeIcons.whatsapp,
                    label: "Manage Sender",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BugSenderPage(
                            sessionKey: sessionKey,
                            username: username,
                            role: role,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.forum_rounded,
                    label: "Publik Chat",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CommunityPage(
                            username: username,
                            role: role,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            glowPurple.withOpacity(0.8),
            primaryPink,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: neonViolet.withOpacity(0.6), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: neonViolet.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        icon: Icon(icon, color: silverWhite, size: 18),
        label: Text(
          label,
          style: TextStyle(
            color: silverWhite,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            fontFamily: 'Orbitron',
            letterSpacing: 0.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildNewsList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        height: 240,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderGlass, width: 1.2),
          gradient: LinearGradient(
            colors: [cardDark, cardDarker],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: neonViolet.withOpacity(0.15),
              blurRadius: 20,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const _VideoPlayerAsset(),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryDark.withOpacity(0.85),
                      Colors.transparent,
                      neonViolet.withOpacity(0.1),
                    ],
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                  ),
                ),
              ),
              Positioned(
                left: 20,
                bottom: 20,
                child: Row(
                  children: [
                    Text(
                      "OXIDE",
                      style: TextStyle(
                        color: silverWhite,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                        fontFamily: 'Orbitron',
                        shadows: [
                          Shadow(
                            color: neonViolet,
                            blurRadius: 18,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "APPS",
                      style: TextStyle(
                        color: silverAccent,
                        fontSize: 15,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 2,
                        fontFamily: 'Orbitron',
                      ),
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

  Widget _buildNewsCarousel() {
    if (newsList.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: cardDarker.withOpacity(0.5),
          border: Border.all(color: borderGlass),
        ),
        child: const Center(
          child: Text(
            "No news available",
            style: TextStyle(
              color: Colors.white54,
              fontFamily: "ShareTechMono",
            ),
          ),
        ),
      );
    }
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 220,
          child: PageView.builder(
            controller: _pageController,
            itemCount: newsList.length,
            onPageChanged: (index) {
              setState(() {
                _currentNewsIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final item = newsList[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: cardGlass,
                  border: Border.all(color: borderGlass),
                  boxShadow: [
                    BoxShadow(
                      color: neonViolet.withOpacity(0.12),
                      blurRadius: 15,
                      spreadRadius: 1,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (item['image'] != null &&
                          item['image'].toString().isNotEmpty)
                        NewsMedia(url: item['image']),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.85),
                              Colors.transparent
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'] ?? 'No Title',
                              style: TextStyle(
                                color: silverWhite,
                                fontSize: 16,
                                fontFamily: "Orbitron",
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['desc'] ?? '',
                              style: TextStyle(
                                  color: silverAccent,
                                  fontSize: 12,
                                  fontFamily: "ShareTechMono"),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (newsList.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              newsList.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                height: 6,
                width: _currentNewsIndex == index ? 20 : 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: _currentNewsIndex == index
                      ? neonViolet
                      : Colors.white.withOpacity(0.2),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCompactInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: cardDarker.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderGlass),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: neonViolet.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: neonViolet, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: silverAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: silverWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'ShareTechMono',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomDrawer() {
    return Drawer(
      backgroundColor: bgDark,
      width: MediaQuery.of(context).size.width * 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 240,
            color: Colors.black,
            child: Stack(
              children: [
                if (_menuVideoController != null &&
                    _menuVideoController!.value.isInitialized)
                  SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _menuVideoController!.value.size.width,
                        height: _menuVideoController!.value.size.height,
                        child: VideoPlayer(_menuVideoController!),
                      ),
                    ),
                  ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.3),
                        bgDark.withOpacity(0.95),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 85,
                          height: 85,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: neonViolet, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: neonViolet.withOpacity(0.5),
                                blurRadius: 20,
                                spreadRadius: 2,
                              )
                            ],
                          ),
                          child: ClipOval(
                            child: _profileImage != null
                                ? Image.file(_profileImage!, fit: BoxFit.cover)
                                : Icon(
                                    FontAwesomeIcons.userAstronaut,
                                    size: 40,
                                    color: silverWhite,
                                  ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          username,
                          style: TextStyle(
                            color: silverWhite,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Orbitron',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          role.toUpperCase(),
                          style: TextStyle(
                            color: neonViolet,
                            fontSize: 11,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: bgDark,
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  if (role == "reseller")
                    _buildDrawerMenuItem(
                      icon: Icons.storefront_rounded,
                      label: "Seller Page",
                      onTap: () => _onSidebarTabSelected(1),
                    ),
                  if (role == "admin")
                    _buildDrawerMenuItem(
                      icon: Icons.admin_panel_settings_rounded,
                      label: "Admin Page",
                      onTap: () => _onSidebarTabSelected(2),
                    ),
                  if (role == "owner")
                    _buildDrawerMenuItem(
                      icon: Icons.workspace_premium_rounded,
                      label: "Owner Page",
                      onTap: () => _onSidebarTabSelected(3),
                    ),
                  _buildDrawerMenuItem(
                    icon: Icons.history_rounded,
                    label: "Riwayat Aktivitas",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RiwayatPage(
                            sessionKey: sessionKey,
                            role: role,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildDrawerMenuItem(
                    icon: Icons.movie_filter_rounded,
                    label: "Nonton Anime",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HomeAnimePage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildDrawerMenuItem(
                    icon: Icons.logout_rounded,
                    label: "Log Out",
                    isLogout: true,
                    onTap: () async {
                      Navigator.pop(context);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.clear();
                      if (!mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isLogout ? Colors.red.withOpacity(0.12) : cardGlass,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLogout ? Colors.red.withOpacity(0.4) : borderGlass,
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isLogout ? Colors.redAccent : neonViolet,
          size: 20,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isLogout ? Colors.redAccent : silverWhite,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          color: silverAccent.withOpacity(0.5),
          size: 12,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildCustomDrawer(),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: silverWhite),
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 8),
            Icon(FontAwesomeIcons.key, color: neonViolet, size: 14),
            const SizedBox(width: 6),
            Text("0",
                style: TextStyle(
                    color: silverWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'ShareTechMono')),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: () => ProfilePage(
                    username: username,
                    password: password,
                    role: role,
                    expiredDate: expiredDate,
                    sessionKey: sessionKey,
                  ),
                ),
              );
            },
            child: Row(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(username,
                        style: TextStyle(
                            color: silverWhite,
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text("#${widget.userId}",
                            style: TextStyle(
                                color: silverAccent,
                                fontSize: 9,
                                fontFamily: 'ShareTechMono')),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                              color: neonViolet.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4)),
                          child: Row(
                            children: [
                              Icon(Icons.military_tech_rounded,
                                  color: neonViolet, size: 10),
                              const SizedBox(width: 2),
                              Text("Lvl. ${widget.level}",
                                  style: TextStyle(
                                      color: silverWhite,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: neonViolet, width: 1.5)),
                  child: ClipOval(
                    child: _profileImage != null
                        ? Image.file(_profileImage!, fit: BoxFit.cover)
                        : Icon(FontAwesomeIcons.userAstronaut,
                            color: silverWhite, size: 18),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.notifications_none_rounded,
                    color: silverWhite, size: 24),
                onPressed: () {},
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration:
                      BoxDecoration(color: neonViolet, shape: BoxShape.circle),
                  child: const Text("8",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        color: bgDark,
        child: Stack(
          children: [
            Positioned(
              top: -80,
              right: -60,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: neonViolet.withOpacity(0.22),
                  boxShadow: [
                    BoxShadow(
                      color: neonViolet.withOpacity(0.22),
                      blurRadius: 140,
                      spreadRadius: 60,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              left: -80,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: glowPurple.withOpacity(0.18),
                  boxShadow: [
                    BoxShadow(
                      color: glowPurple.withOpacity(0.18),
                      blurRadius: 120,
                      spreadRadius: 50,
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: FadeTransition(
                opacity: _animation,
                child: _selectedPage,
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: GlobalMiniPlayer(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: cardDarker.withOpacity(0.92),
          border: Border(top: BorderSide(color: borderGlass, width: 1)),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: silverWhite,
          unselectedItemColor: silverAccent.withOpacity(0.5),
          currentIndex: _bottomNavIndex,
          onTap: _onBottomNavTapped,
          selectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_rounded),
              activeIcon: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: neonViolet,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: neonViolet.withOpacity(0.5), blurRadius: 10),
                  ],
                ),
                child: const Icon(Icons.home_rounded, color: Colors.white),
              ),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: const Icon(FontAwesomeIcons.whatsapp),
              activeIcon: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: neonViolet,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: neonViolet.withOpacity(0.5), blurRadius: 10),
                  ],
                ),
                child: const Icon(FontAwesomeIcons.whatsapp, color: Colors.white),
              ),
              label: "WhatsApp",
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.notifications_rounded),
              activeIcon: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: neonViolet,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: neonViolet.withOpacity(0.5), blurRadius: 10),
                  ],
                ),
                child: const Icon(Icons.notifications_rounded, color: Colors.white),
              ),
              label: "Info",
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.build_circle_rounded),
              activeIcon: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: neonViolet,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: neonViolet.withOpacity(0.5), blurRadius: 10),
                  ],
                ),
                child: const Icon(Icons.build_circle_rounded, color: Colors.white),
              ),
              label: "Tools",
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _menuVideoController?.dispose();
    _pageController.dispose();
    super.dispose();
  }
}

class _VideoPlayerAsset extends StatefulWidget {
  const _VideoPlayerAsset();

  @override
  __VideoPlayerAssetState createState() => __VideoPlayerAssetState();
}

class __VideoPlayerAssetState extends State<_VideoPlayerAsset> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/videos/banner.mp4')
      ..initialize().then((_) {
        _controller.setLooping(true);
        _controller.setVolume(0.0);
        _controller.play();
        if (mounted) setState(() {});
      });
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.value.isInitialized) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller.value.size.width,
          height: _controller.value.size.height,
          child: VideoPlayer(_controller),
        ),
      );
    } else {
      return Container(
        color: const Color(0xFF080613),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF9D00FF)),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class NewsMedia extends StatefulWidget {
  final String url;
  const NewsMedia({super.key, required this.url});

  @override
  State<NewsMedia> createState() => _NewsMediaState();
}

class _NewsMediaState extends State<NewsMedia> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    if (_isVideo(widget.url)) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {});
            _controller?.setLooping(true);
            _controller?.setVolume(0.0);
            _controller?.play();
          }
        });
    }
  }

  bool _isVideo(String url) {
    return url.endsWith(".mp4") ||
        url.endsWith(".webm") ||
        url.endsWith(".mov") ||
        url.endsWith(".mkv");
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isVideo(widget.url)) {
      if (_controller != null && _controller!.value.isInitialized) {
        return AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: VideoPlayer(_controller!),
        );
      } else {
        return const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF9D00FF),
          ),
        );
      }
    } else {
      return Image.network(
        widget.url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey.shade900,
          child: const Icon(Icons.error, color: Color(0xFF9D00FF)),
        ),
      );
    }
  }
}