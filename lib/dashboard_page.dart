import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';

import 'nik_check.dart';
import 'staff_page.dart';
import 'admin_page.dart';
import 'vps_panel_page.dart';
import 'owner_page.dart';
import 'home_page.dart';
import 'dev_page.dart';
import 'seller_page.dart';
import 'team_page.dart';
import 'change_password_page.dart';
import 'tools_gateway.dart';
import 'login_page.dart' hide AppTheme;
import 'bug_sender.dart';
import 'contact_page.dart';
import 'profile_page.dart';
import 'riwayat_page.dart';
import 'info_page.dart';
import 'publik_chat.dart';
import 'tq_to.dart';
import 'anime_home.dart';
import 'btrapps/.dart';
import 'app_theme.dart';
import 'theme_settings_sheet.dart';

final baseUrl = Api.api;

class DashboardPage extends StatefulWidget {
  final String userId;
  final String level;
  final String username;
  final String password;
  final String role;
  final String expiredDate;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final List<Map<String, dynamic>> listSpam;
  final List<Map<String, dynamic>> listGb;
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
    required this.listSpam,
    required this.listGb,
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
  late List<Map<String, dynamic>> listSpam;
  late List<Map<String, dynamic>> listGb;
  late List<Map<String, dynamic>> listDoos;
  late List<dynamic> newsList;

  File? _profileImage;
  VideoPlayerController? _menuVideoController;
  int _bottomNavIndex = 0;
  late Widget _selectedPage;

  int onlineUsers = 0;
  int activeConnections = 0;

  final PageController _newsPageController = PageController();
  int _currentNewsIndex = 0;

  final PageController _quickActionPageController =
      PageController(viewportFraction: 0.92);
  int _currentQuickActionIndex = 0;

  final ImagePicker _picker = ImagePicker();

  List<dynamic> _backendStories = [];
  bool _isUploadingStory = false;

  List<dynamic> _newsListFromApi = [];
  bool _isLoadingNews = true;

  bool get _isLight => Theme.of(context).brightness == Brightness.light;
  Color get _textColor => _isLight ? Colors.black87 : Colors.white;
  Color get _subTextColor => _isLight ? Colors.black54 : Colors.white70;

  @override
  void initState() {
    super.initState();
    sessionKey = widget.sessionKey;
    username = widget.username;
    password = widget.password;
    role = widget.role;
    expiredDate = widget.expiredDate;
    listBug = widget.listBug;
    listSpam = widget.listSpam;
    listGb = widget.listGb;
    listDoos = widget.listDoos;
    newsList = widget.news;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();

    _selectedPage = _buildMainDashboardContent();
    _loadProfileImage();
    _initMenuVideo();
    _fetchDashboardStats();
    _fetchStoriesFromBackend();
    _fetchNews();
  }

  Future<void> _fetchNews() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/news'),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        List<dynamic> parsedList = [];
        if (data is List) {
          parsedList = data;
        } else if (data is Map && data['data'] != null) {
          parsedList = data['data'];
        }

        if (mounted) {
          setState(() {
            _newsListFromApi = parsedList.where((item) {
              final src = (item['source'] ?? '').toString().toLowerCase();
              return !src.contains('cnn') && !src.contains('jtv');
            }).toList();
            _isLoadingNews = false;
            _selectedPage = _buildMainDashboardContent();
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingNews = false);
      }
    } catch (e) {
      debugPrint("Error fetch news: $e");
      if (mounted) {
        setState(() => _isLoadingNews = false);
      }
    }
  }

  Future<void> _fetchStoriesFromBackend() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/stories'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          if (mounted) {
            setState(() {
              _backendStories = data['stories'] ?? [];
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetch stories: $e");
    }
  }

  Future<void> _uploadStoryWithMusicToBackend(
      Map<String, dynamic> storyData) async {
    try {
      setState(() => _isUploadingStory = true);

      final res = await http.post(
        Uri.parse('$baseUrl/api/story/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'type': storyData['type'],
          'text': storyData['text'],
          'bgColor': storyData['bgColor'],
          'audioUrl': storyData['audioUrl'],
          'audioTitle': storyData['audioTitle'],
          'audioStartSec': storyData['audioStartSec'],
          'imagePath': storyData['imagePath'],
        }),
      );

      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        if (mounted) {
          final theme = Theme.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Story berhasil dipublikasikan!"),
              backgroundColor: theme.colorScheme.primary,
            ),
          );
        }
        _fetchStoriesFromBackend();
      }
    } catch (e) {
      debugPrint("Error upload story: $e");
    } finally {
      if (mounted) setState(() => _isUploadingStory = false);
    }
  }

  Map<String, List<dynamic>> _getGroupedStories() {
    Map<String, List<dynamic>> grouped = {};
    for (var story in _backendStories) {
      String user = story['username'] ?? 'User';
      grouped.putIfAbsent(user, () => []).add(story);
    }
    return grouped;
  }

  Future<void> _pickProfileImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
          source: ImageSource.gallery, imageQuality: 80);
      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_image_$username', pickedFile.path);
      }
    } catch (e) {
      debugPrint("Gagal memilih gambar profil: $e");
    }
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('profile_image_$username');
    if (imagePath != null && imagePath.isNotEmpty) {
      if (File(imagePath).existsSync()) {
        setState(() {
          _profileImage = File(imagePath);
        });
      }
    }
  }

  Future<void> _fetchDashboardStats() async {
    try {
      final response = await http
          .get(Uri.parse('${Api.api}/api/dashboard-stats?username=$username'));
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

  void _initMenuVideo() {
    _menuVideoController =
        VideoPlayerController.asset('assets/videos/banner.mp4')
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
        _selectedPage = _buildMainDashboardContent();
      } else if (index == 1) {
        _selectedPage = BugModulePage(
          username: username,
          password: password,
          listBug: listBug,
          listSpam: listSpam,
          listGb: listGb,
          role: role,
          expiredDate: expiredDate,
          sessionKey: sessionKey,
        );
      } else if (index == 2) {
        _selectedPage = InfoPage(sessionKey: sessionKey);
      } else if (index == 3) {
        _selectedPage = VpsPanelPage(
          username: username,
          sessionKey: sessionKey,
          role: role,
        );
      } else if (index == 4) {
        _selectedPage = ToolsPage(
          username: username,
          sessionKey: sessionKey,
          userRole: role,
          listDoos: listDoos,
        );
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
      } else if (index == 4) {
        _selectedPage = StaffPage(sessionKey: sessionKey, username: username);
      } else if (index == 5) {
        _selectedPage = TeamPage(sessionKey: sessionKey, username: username);
      } else if (index == 6) {
        _selectedPage = DevPage(sessionKey: sessionKey, username: username);
      }
    });
    Navigator.pop(context);
  }

  Widget _buildMainDashboardContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStorySection(),
          const SizedBox(height: 18),
          _buildNewsCarouselSection(),
          const SizedBox(height: 20),
          _buildDashboardUserCard(),
          const SizedBox(height: 20),
          _buildHorizontalQuickActions(),
          const SizedBox(height: 20),
          _buildKompasNewsCard(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStorySection() {
    final groupedStories = _getGroupedStories();
    final theme = Theme.of(context);
    final isNeo = themeModeNotifier.value != 0;

    return SizedBox(
      height: 95,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          GestureDetector(
            onTap: _isUploadingStory
                ? null
                : () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => CreateStorySheet(
                        onSubmit: (storyData) {
                          _uploadStoryWithMusicToBackend(storyData);
                        },
                      ),
                    );
                  },
            child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isNeo
                                ? Colors.black
                                : theme.colorScheme.primary,
                            width: isNeo ? 3 : 2,
                          ),
                        ),
                        child: ClipOval(
                          child: _isUploadingStory
                              ? CircularProgressIndicator(
                                  color: theme.colorScheme.primary,
                                  strokeWidth: 2,
                                )
                              : _profileImage != null
                                  ? Image.file(_profileImage!, fit: BoxFit.cover)
                                  : Container(
                                      color: theme.colorScheme.surface,
                                      child: Icon(Icons.person,
                                          color: _subTextColor),
                                    ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isNeo
                              ? theme.colorScheme.secondary
                              : theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          border: isNeo
                              ? Border.all(color: Colors.black, width: 1.5)
                              : null,
                        ),
                        child:
                            const Icon(Icons.add, color: Colors.white, size: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Buat Story",
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (groupedStories.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 15),
                child: Text(
                  "Belum ada story",
                  style: TextStyle(
                    color: _subTextColor,
                    fontSize: 11,
                  ),
                ),
              ),
            )
          else
            ...groupedStories.keys.map((userKey) {
              final userStories = groupedStories[userKey]!;

              return GestureDetector(
                onTap: () {
                  openFullStoryViewer(context, userKey, userStories);
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Column(
                    children: [
                      Container(
                        width: 62,
                        height: 62,
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: isNeo
                              ? Border.all(color: Colors.black, width: 2)
                              : null,
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.secondary,
                            ],
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.scaffoldBackgroundColor,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(2),
                          child: ClipOval(
                            child: CircleAvatar(
                              backgroundColor:
                                  theme.colorScheme.primary.withOpacity(0.3),
                              child: Text(
                                userKey[0].toUpperCase(),
                                style: TextStyle(
                                  color: _textColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 62,
                        child: Text(
                          userKey,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _subTextColor,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildNewsCarouselSection() {
    final theme = Theme.of(context);
    final isNeo = themeModeNotifier.value != 0;

    if (newsList.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        height: 210,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isNeo ? 8 : 20),
          color: theme.colorScheme.surface,
          border: Border.all(
            color: isNeo
                ? Colors.black
                : theme.colorScheme.primary.withOpacity(0.3),
            width: isNeo ? 3.0 : 1.0,
          ),
          boxShadow: isNeo
              ? [
                  const BoxShadow(
                      color: Colors.black, blurRadius: 0, offset: Offset(5, 5))
                ]
              : null,
        ),
        child: Center(
          child: Text(
            "Tidak ada berita terbaru",
            style: TextStyle(color: _subTextColor),
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 210,
          child: PageView.builder(
            controller: _newsPageController,
            itemCount: newsList.length,
            onPageChanged: (index) =>
                setState(() => _currentNewsIndex = index),
            itemBuilder: (context, index) {
              final item = newsList[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(isNeo ? 8 : 20),
                  color: theme.colorScheme.surface,
                  border: Border.all(
                    color: isNeo
                        ? Colors.black
                        : theme.colorScheme.primary.withOpacity(0.3),
                    width: isNeo ? 3.0 : 1.0,
                  ),
                  boxShadow: isNeo
                      ? [
                          const BoxShadow(
                            color: Colors.black,
                            blurRadius: 0,
                            offset: Offset(5, 5),
                          )
                        ]
                      : [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.15),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(isNeo ? 5 : 20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (item['image'] != null &&
                          item['image'].toString().isNotEmpty)
                        NewsMedia(url: item['image'])
                      else
                        Container(color: theme.colorScheme.surface),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.85),
                              Colors.transparent,
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 14,
                        left: 14,
                        right: 14,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'] ?? 'OXIDE NEWS',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item['desc'] ?? '',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
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
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            newsList.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 6,
              width: _currentNewsIndex == index ? 18 : 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: _currentNewsIndex == index
                    ? theme.colorScheme.primary
                    : (_isLight ? Colors.black26 : Colors.white24),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardUserCard() {
    final theme = Theme.of(context);
    final isNeo = themeModeNotifier.value != 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(isNeo ? 8 : 22),
          border: Border.all(
            color: isNeo
                ? Colors.black
                : theme.colorScheme.primary.withOpacity(0.3),
            width: isNeo ? 3.0 : 1.0,
          ),
          image: const DecorationImage(
            image: AssetImage('assets/images/logo.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Color(0xEE0B0314), BlendMode.darken),
          ),
          boxShadow: isNeo
              ? [
                  const BoxShadow(
                    color: Colors.black,
                    blurRadius: 0,
                    offset: Offset(5, 5),
                  )
                ]
              : [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: _pickProfileImage,
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            isNeo ? Colors.black : theme.colorScheme.primary,
                        width: isNeo ? 2.5 : 2.0,
                      ),
                    ),
                    child: ClipOval(
                      child: _profileImage != null
                          ? Image.file(_profileImage!, fit: BoxFit.cover)
                          : const Icon(FontAwesomeIcons.userAstronaut,
                              color: Colors.white, size: 26),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: isNeo
                              ? theme.colorScheme.primary
                              : theme.colorScheme.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(isNeo ? 2 : 6),
                          border: Border.all(
                            color: isNeo
                                ? Colors.black
                                : theme.colorScheme.primary.withOpacity(0.4),
                            width: isNeo ? 1.5 : 1.0,
                          ),
                        ),
                        child: Text(
                          role.toUpperCase(),
                          style: TextStyle(
                            color: isNeo
                                ? Colors.black
                                : theme.colorScheme.primary,
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
            const SizedBox(height: 16),
            Divider(
              color: isNeo ? Colors.black : Colors.white10,
              thickness: isNeo ? 2 : 1,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem("Online User", "$onlineUsers User",
                    Icons.people_outline_rounded),
                _buildStatItem("Active Sender", "$activeConnections Active",
                    Icons.cell_tower_rounded),
                _buildStatItem("Expired", expiredDate, Icons.timer_outlined),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 20),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalQuickActions() {
    final theme = Theme.of(context);
    final isNeo = themeModeNotifier.value != 0;

    final actions = [
      {
        "title": "Manage Sender",
        "sub": "Pairing & Configuration",
        "badge": "SENDER WA",
        "icon": FontAwesomeIcons.whatsapp,
        "color": isNeo ? theme.colorScheme.secondary : const Color(0xFFE6007E),
        "onTap": () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BugSenderPage(
                sessionKey: sessionKey,
                username: username,
                role: role,
              ),
            ),
          );
        },
      },
      {
        "title": "Publik Chat",
        "sub": "Komunitas Global",
        "badge": "GLOBAL CHAT",
        "icon": Icons.chat_bubble_outline_rounded,
        "color": theme.colorScheme.primary,
        "onTap": () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CommunityPage(
                username: username,
                role: role,
              ),
            ),
          );
        },
      },
      {
        "title": "Channel Info",
        "sub": "Telegram Updates",
        "badge": "TELEGRAM",
        "icon": FontAwesomeIcons.telegram,
        "color": isNeo ? theme.colorScheme.primary : const Color(0xFF0088CC),
        "onTap": () => _openUrl("https://t.me/AllinformationVirz"),
      },
      {
        "title": "Tq To Team",
        "sub": "Credits & Respects",
        "badge": "CREDITS",
        "icon": Icons.favorite_border_rounded,
        "color": Colors.pinkAccent,
        "onTap": () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TqPage()),
          );
        },
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(isNeo ? 8 : 16),
              border: Border.all(
                color: isNeo
                    ? Colors.black
                    : theme.colorScheme.primary.withOpacity(0.35),
                width: isNeo ? 3.0 : 1.2,
              ),
              boxShadow: isNeo
                  ? [
                      const BoxShadow(
                        color: Colors.black,
                        blurRadius: 0,
                        offset: Offset(4, 4),
                      )
                    ]
                  : [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    border:
                        isNeo ? Border.all(color: Colors.black, width: 2) : null,
                  ),
                  child: Icon(
                    Icons.bolt_rounded,
                    color: _isLight ? Colors.black : Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "QUICK ACTIONS",
                        style: TextStyle(
                          color: _textColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 1.1,
                        ),
                      ),
                      Text(
                        "Beberapa Menu Tambahan",
                        style: TextStyle(
                          color: _subTextColor,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isNeo ? Colors.black : theme.colorScheme.primary,
                      width: isNeo ? 1.5 : 1.0,
                    ),
                  ),
                  child: Text(
                    "OXIDE",
                    style: TextStyle(
                      color: isNeo ? Colors.black : theme.colorScheme.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 155,
          child: PageView.builder(
            controller: _quickActionPageController,
            itemCount: actions.length,
            onPageChanged: (index) {
              setState(() => _currentQuickActionIndex = index);
            },
            itemBuilder: (context, index) {
              final item = actions[index];
              final Color actionColor = item['color'] as Color;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: isNeo ? actionColor : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(isNeo ? 10 : 20),
                  border: Border.all(
                    color: isNeo ? Colors.black : actionColor.withOpacity(0.5),
                    width: isNeo ? 3.5 : 1.5,
                  ),
                  boxShadow: isNeo
                      ? [
                          const BoxShadow(
                            color: Colors.black,
                            blurRadius: 0,
                            offset: Offset(5, 5),
                          )
                        ]
                      : [
                          BoxShadow(
                            color: actionColor.withOpacity(0.25),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(isNeo ? 7 : 18),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -15,
                        bottom: -15,
                        child: Icon(
                          item['icon'] as IconData,
                          size: 130,
                          color: (isNeo ? Colors.black : actionColor)
                              .withOpacity(0.15),
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: item['onTap'] as VoidCallback,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isNeo
                                            ? Colors.white
                                            : actionColor.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isNeo
                                              ? Colors.black
                                              : actionColor,
                                          width: isNeo ? 2 : 1,
                                        ),
                                      ),
                                      child: Icon(
                                        item['icon'] as IconData,
                                        color:
                                            isNeo ? Colors.black : actionColor,
                                        size: 20,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: Colors.white24, width: 1),
                                      ),
                                      child: Text(
                                        item['badge'] as String,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Text(
                                  item['title'] as String,
                                  style: TextStyle(
                                    color: isNeo ? Colors.black : Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item['sub'] as String,
                                  style: TextStyle(
                                    color: isNeo
                                        ? Colors.black87
                                        : Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            actions.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 6,
              width: _currentQuickActionIndex == index ? 22 : 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: _currentQuickActionIndex == index
                    ? theme.colorScheme.primary
                    : (_isLight ? Colors.black26 : Colors.white24),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKompasNewsCard() {
    final theme = Theme.of(context);
    final isNeo = themeModeNotifier.value != 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(isNeo ? 8 : 20),
          border: Border.all(
            color: isNeo
                ? Colors.black
                : theme.colorScheme.primary.withOpacity(0.35),
            width: isNeo ? 3.0 : 1.2,
          ),
          boxShadow: isNeo
              ? [
                  const BoxShadow(
                    color: Colors.black,
                    blurRadius: 0,
                    offset: Offset(5, 5),
                  )
                ]
              : [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isNeo
                        ? theme.colorScheme.primary
                        : Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(isNeo ? 4 : 8),
                    border: isNeo
                        ? Border.all(color: Colors.black, width: 1.5)
                        : null,
                  ),
                  child: Icon(
                    Icons.newspaper_rounded,
                    color: isNeo ? Colors.black : Colors.blueAccent,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Berita Indonesia Terkini",
                        style: TextStyle(
                          color: _textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Kompas.com • Auto Update",
                        style: TextStyle(
                          color: _subTextColor,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.refresh_rounded,
                    color: theme.colorScheme.primary,
                    size: 18,
                  ),
                  onPressed: () {
                    setState(() => _isLoadingNews = true);
                    _fetchNews();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(
              color: isNeo ? Colors.black : Colors.white10,
              thickness: isNeo ? 2 : 1,
            ),
            const SizedBox(height: 12),
            if (_isLoadingNews)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                    strokeWidth: 2,
                  ),
                ),
              )
            else if (_newsListFromApi.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  "Gagal memuat berita.",
                  style: TextStyle(color: _subTextColor, fontSize: 12),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount:
                    _newsListFromApi.length > 5 ? 5 : _newsListFromApi.length,
                separatorBuilder: (_, __) => Divider(
                  color: isNeo ? Colors.black54 : Colors.white10,
                  height: 16,
                  thickness: isNeo ? 1.5 : 1.0,
                ),
                itemBuilder: (context, idx) {
                  final newsItem = _newsListFromApi[idx];
                  final String title = newsItem['headline'] ??
                      newsItem['title'] ??
                      'Tanpa Judul';
                  final String sourceName = newsItem['source'] ?? 'Kompas.com';
                  final String link =
                      newsItem['url'] ?? newsItem['link'] ?? '';
                  final String pubDate =
                      newsItem['timestamp'] ?? newsItem['pubDate'] ?? '';

                  return InkWell(
                    onTap: () {
                      if (link.isNotEmpty) _openUrl(link);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: _textColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isNeo
                                      ? theme.colorScheme.primary
                                      : Colors.blue.withOpacity(0.2),
                                  borderRadius:
                                      BorderRadius.circular(isNeo ? 2 : 4),
                                  border: isNeo
                                      ? Border.all(
                                          color: Colors.black, width: 1)
                                      : null,
                                ),
                                child: Text(
                                  sourceName,
                                  style: TextStyle(
                                    color: isNeo
                                        ? Colors.black
                                        : Colors.blueAccent,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (pubDate.isNotEmpty)
                                Expanded(
                                  child: Text(
                                    pubDate.contains("T")
                                        ? pubDate.split("T").first
                                        : pubDate,
                                    style: TextStyle(
                                      color: _subTextColor,
                                      fontSize: 10,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomDrawer() {
    final theme = Theme.of(context);
    final isNeo = themeModeNotifier.value != 0;

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      width: MediaQuery.of(context).size.width * 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 230,
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
                        Colors.black.withOpacity(0.2),
                        theme.scaffoldBackgroundColor.withOpacity(0.95),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: _pickProfileImage,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: isNeo
                                      ? Colors.black
                                      : theme.colorScheme.primary,
                                  width: isNeo ? 3.0 : 2.5),
                              boxShadow: isNeo
                                  ? [
                                      const BoxShadow(
                                          color: Colors.black, blurRadius: 0)
                                    ]
                                  : [
                                      BoxShadow(
                                        color: theme.colorScheme.primary
                                            .withOpacity(0.4),
                                        blurRadius: 15,
                                      )
                                    ],
                            ),
                            child: ClipOval(
                              child: _profileImage != null
                                  ? Image.file(_profileImage!,
                                      fit: BoxFit.cover)
                                  : const Icon(FontAwesomeIcons.userAstronaut,
                                      size: 40, color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          role.toUpperCase(),
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
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
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                _buildDrawerMenuItem(
                  icon: Icons.person_rounded,
                  label: "My Profile",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfilePage(
                          username: username,
                          password: password,
                          role: role,
                          expiredDate: expiredDate,
                          sessionKey: sessionKey,
                        ),
                      ),
                    ).then((_) => _loadProfileImage());
                  },
                ),
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
                if (role == "staff")
                  _buildDrawerMenuItem(
                    icon: Icons.workspace_premium_rounded,
                    label: "staff Page",
                    onTap: () => _onSidebarTabSelected(4),
                  ),
                if (role == "team")
                  _buildDrawerMenuItem(
                    icon: Icons.workspace_premium_rounded,
                    label: "team project Page",
                    onTap: () => _onSidebarTabSelected(5),
                  ),
                if (role == "developer")
                  _buildDrawerMenuItem(
                    icon: Icons.workspace_premium_rounded,
                    label: "developer Page",
                    onTap: () => _onSidebarTabSelected(6),
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
                const SizedBox(height: 15),
                _buildDrawerMenuItem(
                  icon: Icons.logout_rounded,
                  label: "Log Out",
                  isLogout: true,
                  onTap: () async {
                    Navigator.pop(context);
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove('username');
                    await prefs.remove('password');
                    await prefs.remove('sessionKey');
                    await prefs.remove('isLoggedIn');
                    await prefs.remove('token');
                    
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
    final theme = Theme.of(context);
    final isNeo = themeModeNotifier.value != 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color:
            isLogout ? Colors.red.withOpacity(0.12) : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(isNeo ? 6 : 12),
        border: Border.all(
          color: isLogout
              ? Colors.red
              : (isNeo
                  ? Colors.black
                  : theme.colorScheme.primary.withOpacity(0.2)),
          width: isNeo ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Icon(icon,
            color: isLogout ? Colors.redAccent : theme.colorScheme.primary,
            size: 20),
        title: Text(
          label,
          style: TextStyle(
            color: isLogout ? Colors.redAccent : _textColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: themeModeNotifier,
      builder: (context, modeIndex, child) {
        final currentTheme = AppTheme.currentTheme;
        final isNeo = modeIndex != 0;

        return Theme(
          data: currentTheme,
          child: Builder(
            builder: (context) {
              final theme = Theme.of(context);

              return Scaffold(
                backgroundColor: theme.scaffoldBackgroundColor,
                drawer: _buildCustomDrawer(),
                appBar: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: Builder(
                    builder: (context) => IconButton(
                      icon: Icon(Icons.menu_rounded,
                          color: theme.colorScheme.primary, size: 26),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: TextStyle(
                          color: _textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${role.toUpperCase()} [$expiredDate]",
                        style: TextStyle(
                          color: _subTextColor,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(
                        Icons.palette_outlined,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                      tooltip: "Pengaturan Tema",
                      onPressed: () {
                        ThemeSettingsSheet.show(context);
                      },
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfilePage(
                              username: username,
                              password: password,
                              role: role,
                              expiredDate: expiredDate,
                              sessionKey: sessionKey,
                            ),
                          ),
                        ).then((_) => _loadProfileImage());
                      },
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isNeo
                                ? Colors.black
                                : theme.colorScheme.primary,
                            width: isNeo ? 2.0 : 1.5,
                          ),
                        ),
                        child: ClipOval(
                          child: _profileImage != null
                              ? Image.file(_profileImage!, fit: BoxFit.cover)
                              : const Icon(FontAwesomeIcons.userAstronaut,
                                  color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.headset_mic_rounded,
                          color: theme.colorScheme.primary, size: 22),
                      onPressed: () => _openUrl("https://t.me/Virzofc"),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                body: Stack(
                  children: [
                    SafeArea(
                      child: FadeTransition(
                        opacity: _animation,
                        child: _selectedPage,
                      ),
                    ),
                  ],
                ),
                bottomNavigationBar: Container(
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    border: Border(
                      top: BorderSide(
                        color: isNeo
                            ? Colors.black
                            : theme.colorScheme.primary.withOpacity(0.2),
                        width: isNeo ? 3 : 1,
                      ),
                    ),
                  ),
                  child: BottomNavigationBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    type: BottomNavigationBarType.fixed,
                    selectedItemColor: theme.colorScheme.primary,
                    unselectedItemColor: _subTextColor,
                    currentIndex: _bottomNavIndex,
                    onTap: _onBottomNavTapped,
                    selectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12),
                    unselectedLabelStyle: const TextStyle(fontSize: 12),
                    items: const [
                      BottomNavigationBarItem(
                        icon: Icon(Icons.home_rounded),
                        label: "Dashboard",
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(FontAwesomeIcons.whatsapp),
                        label: "WhatsApp",
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.notifications_none_rounded),
                        label: "Info",
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.dns_rounded),
                        label: "VPS Panel",
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.build_circle_outlined),
                        label: "Tools",
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _menuVideoController?.dispose();
    _newsPageController.dispose();
    _quickActionPageController.dispose();
    super.dispose();
  }
}

void openFullStoryViewer(
    BuildContext context, String username, List<dynamic> stories) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.black,
    useSafeArea: true,
    builder: (context) =>
        StoryViewerWidget(username: username, stories: stories),
  );
}

class StoryViewerWidget extends StatefulWidget {
  final String username;
  final List<dynamic> stories;

  const StoryViewerWidget({
    super.key,
    required this.username,
    required this.stories,
  });

  @override
  State<StoryViewerWidget> createState() => _StoryViewerWidgetState();
}

class _StoryViewerWidgetState extends State<StoryViewerWidget> {
  int _currentIndex = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _playCurrentStoryAudio();
  }

  void _playCurrentStoryAudio() async {
    await _audioPlayer.stop();
    if (_currentIndex < 0 || _currentIndex >= widget.stories.length) return;

    final story = widget.stories[_currentIndex];
    final String? audioUrl = story['audioUrl'];
    final int startSec = (story['audioStartSec'] as num?)?.toInt() ?? 0;

    if (audioUrl != null && audioUrl.isNotEmpty) {
      try {
        await _audioPlayer.play(UrlSource(audioUrl));
        await _audioPlayer.seek(Duration(seconds: startSec));
      } catch (e) {
        debugPrint("Error play story audio: $e");
      }
    }
  }

  void _nextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _playCurrentStoryAudio();
    } else {
      Navigator.pop(context);
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _playCurrentStoryAudio();
    }
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[_currentIndex];
    final String? type = story['type'];
    final String? textContent = story['text'];
    final String? imageUrl = story['imageUrl'] ?? story['image'];
    final String? audioTitle = story['audioTitle'];

    Color bgColor = Colors.deepPurple;
    if (story['bgColor'] != null) {
      try {
        bgColor = Color(int.parse(story['bgColor'].toString()));
      } catch (_) {}
    }

    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity! > 300) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(
              child: type == 'text' || (imageUrl == null || imageUrl.isEmpty)
                  ? Container(
                      color: bgColor,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Center(
                        child: Text(
                          textContent ?? '',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(blurRadius: 10, color: Colors.black45)
                            ],
                          ),
                        ),
                      ),
                    )
                  : SingleStoryMedia(url: imageUrl),
            ),
            Positioned.fill(
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _previousStory,
                      child: const SizedBox.expand(),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _nextStory,
                      child: const SizedBox.expand(),
                    ),
                  ),
                ],
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Row(
                      children: List.generate(widget.stories.length, (index) {
                        return Expanded(
                          child: Container(
                            height: 3,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: index <= _currentIndex
                                  ? Colors.white
                                  : Colors.white38,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.purple,
                          child: Text(
                            widget.username[0].toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.username,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            if (audioTitle != null && audioTitle.isNotEmpty)
                              Row(
                                children: [
                                  const Icon(Icons.music_note,
                                      color: Colors.white70, size: 12),
                                  const SizedBox(width: 4),
                                  SizedBox(
                                    width: 160,
                                    child: Text(
                                      audioTitle,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CreateStorySheet extends StatefulWidget {
  final Function(Map<String, dynamic> storyData) onSubmit;

  const CreateStorySheet({super.key, required this.onSubmit});

  @override
  State<CreateStorySheet> createState() => _CreateStorySheetState();
}

class _CreateStorySheetState extends State<CreateStorySheet> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _searchMusicController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String _activeMode = 'text';

  File? _selectedImageFile;
  Color _selectedBgColor = const Color(0xFF1E1E2C);
  final List<Color> _bgColors = [
    const Color(0xFF1E1E2C),
    Colors.deepPurple,
    Colors.indigo,
    Colors.teal,
    Colors.pink,
    Colors.orange,
    Colors.black,
  ];

  bool _isSearchingMusic = false;
  String? _selectedAudioUrl;
  String? _selectedAudioTitle;
  double _audioStartSec = 0.0;
  double _maxAudioDurationSec = 180.0;

  final AudioPlayer _previewPlayer = AudioPlayer();
  bool _isPlayingPreview = false;

  Future<void> _pickMedia(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(source: source, imageQuality: 80);
      if (file != null) {
        setState(() {
          _selectedImageFile = File(file.path);
          _activeMode = 'image';
        });
      }
    } catch (e) {
      _showSnackBar("Gagal mengambil gambar");
    }
  }

  Future<void> _fetchMusicFromApi(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _isSearchingMusic = true);

    try {
      final res = await http.get(
        Uri.parse('http://api.ikyyxd.my.id/search/ytplayv3?q=${Uri.encodeComponent(query)}'),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == true && data['result'] != null) {
          final result = data['result'];
          setState(() {
            _selectedAudioUrl = result['download'];
            _selectedAudioTitle = result['title'];
            _maxAudioDurationSec = (result['duration'] as num?)?.toDouble() ?? 180.0;
            _audioStartSec = 0.0;
          });

          if (_isPlayingPreview) {
            await _previewPlayer.stop();
            _isPlayingPreview = false;
          }
        } else {
          _showSnackBar("Lagu tidak ditemukan!");
        }
      } else {
        _showSnackBar("Gagal menghubungi server musik.");
      }
    } catch (e) {
      _showSnackBar("Terjadi kesalahan koneksi.");
    } finally {
      if (mounted) setState(() => _isSearchingMusic = false);
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  @override
  void dispose() {
    _previewPlayer.stop();
    _previewPlayer.dispose();
    _textController.dispose();
    _searchMusicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Color(0xFF121216),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Text(
                    "Tambah status",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActionButton(
                  icon: Icons.edit_rounded,
                  label: "Teks",
                  isActive: _activeMode == 'text' && _selectedImageFile == null,
                  onTap: () {
                    setState(() {
                      _activeMode = 'text';
                      _selectedImageFile = null;
                    });
                  },
                ),
                const SizedBox(width: 16),
                _buildActionButton(
                  icon: Icons.music_note_rounded,
                  label: "Musik",
                  isActive: _selectedAudioUrl != null,
                  onTap: _showMusicSearchDialog,
                ),
                const SizedBox(width: 16),
                _buildActionButton(
                  icon: Icons.photo_library_rounded,
                  label: "Galeri",
                  isActive: _selectedImageFile != null,
                  onTap: () => _pickMedia(ImageSource.gallery),
                ),
                const SizedBox(width: 16),
                _buildActionButton(
                  icon: Icons.camera_alt_rounded,
                  label: "Kamera",
                  isActive: false,
                  onTap: () => _pickMedia(ImageSource.camera),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: _selectedImageFile != null ? Colors.black : _selectedBgColor,
                borderRadius: BorderRadius.circular(20),
                image: _selectedImageFile != null
                    ? DecorationImage(
                        image: FileImage(_selectedImageFile!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: Stack(
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: TextField(
                        controller: _textController,
                        maxLines: 5,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: _selectedImageFile != null ? 18 : 22,
                          fontWeight: FontWeight.bold,
                          shadows: const [
                            Shadow(blurRadius: 8, color: Colors.black87)
                          ],
                        ),
                        decoration: const InputDecoration(
                          hintText: "Ketik status...",
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  if (_selectedImageFile == null)
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: SizedBox(
                        height: 36,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: _bgColors.map((color) {
                            return GestureDetector(
                              onTap: () => setState(() => _selectedBgColor = color),
                              child: Container(
                                margin: const EdgeInsets.only(right: 10),
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: _selectedBgColor == color
                                      ? Border.all(color: Colors.white, width: 2.5)
                                      : null,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  if (_selectedAudioTitle != null)
                    Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.music_note, color: Colors.pinkAccent, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedAudioTitle!,
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                _previewPlayer.stop();
                                setState(() {
                                  _selectedAudioUrl = null;
                                  _selectedAudioTitle = null;
                                  _isPlayingPreview = false;
                                });
                              },
                              child: const Icon(Icons.close, color: Colors.white70, size: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 14,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                label: const Text(
                  "BAGIKAN KE STORY",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                onPressed: () {
                  if (_textController.text.trim().isEmpty &&
                      _selectedImageFile == null &&
                      _selectedAudioUrl == null) {
                    _showSnackBar("Isi teks, gambar, atau musik!");
                    return;
                  }

                  widget.onSubmit({
                    'type': _selectedImageFile != null ? 'image' : 'text',
                    'text': _textController.text.trim(),
                    'bgColor': '0x${_selectedBgColor.value.toRadixString(16)}',
                    'audioUrl': _selectedAudioUrl,
                    'audioTitle': _selectedAudioTitle,
                    'audioStartSec': _audioStartSec.toInt(),
                    'imagePath': _selectedImageFile?.path,
                  });

                  Navigator.pop(context);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isActive ? Theme.of(context).colorScheme.primary : const Color(0xFF2A2B36),
              shape: BoxShape.circle,
              border: isActive ? Border.all(color: Colors.white, width: 2) : null,
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white60,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showMusicSearchDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E2C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Cari & Pasang Musik",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchMusicController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: "Judul lagu (ex: Duka)",
                            hintStyle: const TextStyle(color: Colors.white38),
                            filled: true,
                            fillColor: Colors.black26,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onSubmitted: (val) async {
                            await _fetchMusicFromApi(val);
                            setModalState(() {});
                            setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          await _fetchMusicFromApi(_searchMusicController.text);
                          setModalState(() {});
                          setState(() {});
                        },
                        child: _isSearchingMusic
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.search, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                  if (_selectedAudioUrl != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      "Pilih Reff: ${_audioStartSec.toInt()}s",
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Slider(
                      value: _audioStartSec.clamp(0.0, _maxAudioDurationSec),
                      min: 0.0,
                      max: _maxAudioDurationSec,
                      activeColor: Theme.of(context).colorScheme.primary,
                      onChanged: (val) {
                        setModalState(() => _audioStartSec = val);
                        setState(() => _audioStartSec = val);
                      },
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: const Size(double.infinity, 44),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("Gunakan Lagu Ini", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class SingleStoryMedia extends StatefulWidget {
  final String url;
  const SingleStoryMedia({super.key, required this.url});

  @override
  State<SingleStoryMedia> createState() => _SingleStoryMediaState();
}

class _SingleStoryMediaState extends State<SingleStoryMedia> {
  VideoPlayerController? _vController;
  File? _tempVideoFile;
  bool _isInitializing = false;

  bool get isVideo {
    final lower = widget.url.toLowerCase();
    return lower.startsWith('data:video') ||
        lower.contains('.mp4') ||
        lower.contains('.mov') ||
        lower.contains('.mkv') ||
        lower.contains('.webm') ||
        lower.contains('.avi');
  }

  @override
  void initState() {
    super.initState();
    if (isVideo) {
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    setState(() => _isInitializing = true);
    try {
      if (widget.url.startsWith('data:video')) {
        final base64Str = widget.url.split(',').last;
        final bytes = base64Decode(base64Str);
        final tempDir = Directory.systemTemp;
        final file = File(
            '${tempDir.path}/story_vid_${DateTime.now().microsecondsSinceEpoch}.mp4');
        await file.writeAsBytes(bytes);
        _tempVideoFile = file;
        _vController = VideoPlayerController.file(file);
      } else if (widget.url.startsWith('http')) {
        _vController = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      }

      if (_vController != null) {
        await _vController!.initialize();
        _vController!.setLooping(true);
        _vController!.play();
      }
    } catch (e) {
      debugPrint("Error init video story: $e");
    } finally {
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  @override
  void dispose() {
    _vController?.dispose();
    if (_tempVideoFile != null && _tempVideoFile!.existsSync()) {
      _tempVideoFile!.delete();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isVideo) {
      if (_isInitializing) {
        return Center(
          child: CircularProgressIndicator(
            color: theme.colorScheme.primary,
          ),
        );
      }
      if (_vController != null && _vController!.value.isInitialized) {
        return FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _vController!.value.size.width,
            height: _vController!.value.size.height,
            child: VideoPlayer(_vController!),
          ),
        );
      }
      return const Center(
        child: Icon(Icons.broken_image, color: Colors.white),
      );
    }

    if (widget.url.startsWith('data:image')) {
      return Image.memory(
        base64Decode(widget.url.split(',').last),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.broken_image, color: Colors.white),
      );
    }

    return Image.network(
      widget.url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          const Icon(Icons.broken_image, color: Colors.white),
    );
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
    final theme = Theme.of(context);

    if (_isVideo(widget.url)) {
      if (_controller != null && _controller!.value.isInitialized) {
        return AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: VideoPlayer(_controller!),
        );
      } else {
        return Center(
          child: CircularProgressIndicator(
            color: theme.colorScheme.primary,
          ),
        );
      }
    } else {
      return Image.network(
        widget.url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: theme.colorScheme.surface,
          child: Icon(
            Icons.error_outline_rounded,
            color: theme.colorScheme.primary,
          ),
        ),
      );
    }
  }
}
