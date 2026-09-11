import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';

import 'nik_check.dart';
import 'staff_page.dart';
import 'admin_page.dart';
import 'owner_page.dart';
import 'home_page.dart';
import 'dev_page.dart';
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
import 'tq_to.dart';
import 'anime_home.dart';
import 'btrapps/.dart';
import 'app_theme.dart';

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

  final PageController _newsPageController = PageController();
  int _currentNewsIndex = 0;
  final ImagePicker _picker = ImagePicker();

  List<dynamic> _backendStories = [];
  bool _isUploadingStory = false;

  List<dynamic> _cnnNewsList = [];
  bool _isLoadingCnnNews = true;

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
    _fetchCnnNews();
  }

  Future<void> _fetchCnnNews() async {
    try {
      final res = await http.get(
        Uri.parse('https://api-berita-indonesia.vercel.app/cnn/terbaru/'),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['data'] != null) {
          if (mounted) {
            setState(() {
              _cnnNewsList = data['data']['posts'] ?? [];
              _isLoadingCnnNews = false;
              _selectedPage = _buildMainDashboardContent();
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetch CNN News: $e");
      if (mounted) {
        setState(() => _isLoadingCnnNews = false);
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

  Future<void> _uploadStoryToBackend() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultipleMedia();
      if (pickedFiles.isEmpty) return;

      setState(() => _isUploadingStory = true);

      int successCount = 0;

      for (var file in pickedFiles) {
        List<int> bytes = await file.readAsBytes();
        String base64Data = base64Encode(bytes);

        String mimeType = "image/png";
        String pathLower = file.path.toLowerCase();
        if (pathLower.endsWith('.mp4') ||
            pathLower.endsWith('.mov') ||
            pathLower.endsWith('.mkv') ||
            pathLower.endsWith('.webm') ||
            pathLower.endsWith('.avi')) {
          mimeType = "video/mp4";
        }

        final res = await http.post(
          Uri.parse('$baseUrl/api/story/add'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': username,
            'image': 'data:$mimeType;base64,$base64Data',
          }),
        );

        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          successCount++;
        }
      }

      if (mounted && successCount > 0) {
        final theme = Theme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$successCount Story berhasil dipublikasikan!"),
            backgroundColor: theme.colorScheme.primary,
          ),
        );
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

  void _viewUserStories(String user, List<dynamic> userStories) {
    int currentIndex = 0;
    PageController pageController = PageController();
    final theme = Theme.of(context);
    final isNeo = themeModeNotifier.value != 0;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(isNeo ? 8 : 20),
                border: Border.all(
                  color: isNeo ? Colors.black : theme.colorScheme.primary,
                  width: isNeo ? 3 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isNeo ? Colors.black : theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: isNeo ? 0 : 15,
                    offset: isNeo ? const Offset(5, 5) : const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: List.generate(userStories.length, (idx) {
                      return Expanded(
                        child: Container(
                          height: isNeo ? 4 : 3,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: idx == currentIndex
                                ? theme.colorScheme.primary
                                : (_isLight ? Colors.black12 : Colors.white24),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Icon(Icons.history_toggle_off_rounded,
                          color: theme.colorScheme.primary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        user,
                        style: TextStyle(
                          color: _textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.close, color: _subTextColor),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),

                  SizedBox(
                    height: 380,
                    child: PageView.builder(
                      controller: pageController,
                      itemCount: userStories.length,
                      onPageChanged: (idx) {
                        setModalState(() => currentIndex = idx);
                      },
                      itemBuilder: (context, idx) {
                        final story = userStories[idx];
                        String imgUrl = story['imageUrl'] ?? '';
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(isNeo ? 6 : 14),
                          child: SingleStoryMedia(url: imgUrl),
                        );
                      },
                    ),
                  ),

                  if (userStories.length > 1) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back_ios,
                              color: theme.colorScheme.primary, size: 18),
                          onPressed: currentIndex > 0
                              ? () => pageController.previousPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  )
                              : null,
                        ),
                        Text(
                          "${currentIndex + 1} / ${userStories.length}",
                          style: TextStyle(color: _subTextColor, fontSize: 12),
                        ),
                        IconButton(
                          icon: Icon(Icons.arrow_forward_ios,
                              color: theme.colorScheme.primary, size: 18),
                          onPressed: currentIndex < userStories.length - 1
                              ? () => pageController.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  )
                              : null,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickProfileImage() async {
    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
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
      final response =
          await http.get(Uri.parse('${Api.api}/api/dashboard-stats?username=$username'));
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
        _selectedPage = _buildMainDashboardContent();
      } else if (index == 1) {
        _selectedPage = BugModulePage(
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
          _buildCnnIndonesiaNewsCard(),
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
            onTap: _isUploadingStory ? null : _uploadStoryToBackend,
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
                            color: isNeo ? Colors.black : theme.colorScheme.primary,
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
                                      child: Icon(Icons.person, color: _subTextColor),
                                    ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isNeo ? theme.colorScheme.secondary : theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          border: isNeo ? Border.all(color: Colors.black, width: 1.5) : null,
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 16),
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
              final latestStory = userStories.first;
              final String img = latestStory['imageUrl'] ?? '';

              return GestureDetector(
                onTap: () => _viewUserStories(userKey, userStories),
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
                          border: isNeo ? Border.all(color: Colors.black, width: 2) : null,
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
                            child: SingleStoryMedia(url: img),
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
            color: isNeo ? Colors.black : theme.colorScheme.primary.withOpacity(0.3),
            width: isNeo ? 3.0 : 1.0,
          ),
          boxShadow: isNeo
              ? [const BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(5, 5))]
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
            onPageChanged: (index) => setState(() => _currentNewsIndex = index),
            itemBuilder: (context, index) {
              final item = newsList[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(isNeo ? 8 : 20),
                  color: theme.colorScheme.surface,
                  border: Border.all(
                    color: isNeo ? Colors.black : theme.colorScheme.primary.withOpacity(0.3),
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
                      if (item['image'] != null && item['image'].toString().isNotEmpty)
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
            color: isNeo ? Colors.black : theme.colorScheme.primary.withOpacity(0.3),
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
                        color: isNeo ? Colors.black : theme.colorScheme.primary,
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
                      const Text(
                        username,
                        style: TextStyle(
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
                          color: isNeo ? theme.colorScheme.primary : theme.colorScheme.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(isNeo ? 2 : 6),
                          border: Border.all(
                            color: isNeo ? Colors.black : theme.colorScheme.primary.withOpacity(0.4),
                            width: isNeo ? 1.5 : 1.0,
                          ),
                        ),
                        child: Text(
                          role.toUpperCase(),
                          style: TextStyle(
                            color: isNeo ? Colors.black : theme.colorScheme.primary,
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
        const Text(
          label,
          style: TextStyle(color: Colors.white70, fontSize: 11),
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
        "sub": "WA Sender Tools",
        "icon": FontAwesomeIcons.whatsapp,
        "color": isNeo ? theme.colorScheme.secondary : theme.colorScheme.primary,
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
        "icon": FontAwesomeIcons.telegram,
        "color": isNeo ? theme.colorScheme.primary : const Color(0xFF0088CC),
        "onTap": () => _openUrl("https://t.me/AllinformationVirz"),
      },
      {
        "title": "Tq To Team",
        "sub": "Credits & Credits",
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            "QUICK ACTIONS",
            style: TextStyle(
              color: _textColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: actions.length,
            itemBuilder: (context, index) {
              final item = actions[index];
              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(isNeo ? 8 : 18),
                  border: Border.all(
                    color: isNeo ? Colors.black : theme.colorScheme.primary.withOpacity(0.4),
                    width: isNeo ? 3.0 : 1.5,
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
                            color: theme.colorScheme.primary.withOpacity(0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: item['onTap'] as VoidCallback,
                    borderRadius: BorderRadius.circular(isNeo ? 8 : 18),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: isNeo ? (item['color'] as Color) : (item['color'] as Color).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(isNeo ? 4 : 12),
                              border: isNeo ? Border.all(color: Colors.black, width: 1.5) : null,
                            ),
                            child: Icon(
                              item['icon'] as IconData,
                              color: isNeo ? Colors.black : item['color'] as Color,
                              size: 22,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            item['title'] as String,
                            style: TextStyle(
                              color: _textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item['sub'] as String,
                            style: TextStyle(
                              color: _subTextColor,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCnnIndonesiaNewsCard() {
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
            color: isNeo ? Colors.black : theme.colorScheme.primary.withOpacity(0.35),
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
                    color: isNeo ? theme.colorScheme.primary : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(isNeo ? 4 : 8),
                    border: isNeo ? Border.all(color: Colors.black, width: 1.5) : null,
                  ),
                  child: Icon(
                    Icons.newspaper_rounded,
                    color: isNeo ? Colors.black : Colors.redAccent,
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
                        "CNN Indonesia • Auto Update",
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
                    setState(() => _isLoadingCnnNews = true);
                    _fetchCnnNews();
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

            if (_isLoadingCnnNews)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                    strokeWidth: 2,
                  ),
                ),
              )
            else if (_cnnNewsList.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  "Gagal memuat berita CNN Indonesia.",
                  style: TextStyle(color: _subTextColor, fontSize: 12),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _cnnNewsList.length > 4 ? 4 : _cnnNewsList.length,
                separatorBuilder: (_, __) => Divider(
                  color: isNeo ? Colors.black54 : Colors.white10,
                  height: 16,
                  thickness: isNeo ? 1.5 : 1.0,
                ),
                itemBuilder: (context, idx) {
                  final newsItem = _cnnNewsList[idx];
                  final String title = newsItem['title'] ?? 'Tanpa Judul';
                  final String image = newsItem['image']['small'] ??
                      newsItem['image']['large'] ??
                      '';
                  final String link = newsItem['link'] ?? '';
                  final String pubDate = newsItem['pubDate'] ?? '';

                  return InkWell(
                    onTap: () {
                      if (link.isNotEmpty) _openUrl(link);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(isNeo ? 4 : 8),
                          child: image.isNotEmpty
                              ? Image.network(
                                  image,
                                  width: 65,
                                  height: 65,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 65,
                                    height: 65,
                                    color: theme.colorScheme.surface,
                                    child: const Icon(Icons.image_not_supported,
                                        color: Colors.white38, size: 24),
                                  ),
                                )
                              : Container(
                                  width: 65,
                                  height: 65,
                                  color: theme.colorScheme.surface,
                                  child: const Icon(Icons.article,
                                      color: Colors.white38, size: 24),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  color: _textColor,
                                  fontSize: 12,
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
                                      color: isNeo ? theme.colorScheme.primary : Colors.red.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(isNeo ? 2 : 4),
                                      border: isNeo ? Border.all(color: Colors.black, width: 1) : null,
                                    ),
                                    child: Text(
                                      "CNN Indonesia",
                                      style: TextStyle(
                                        color: isNeo ? Colors.black : Colors.redAccent,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (pubDate.isNotEmpty)
                                    Expanded(
                                      child: Text(
                                        pubDate.split("T").first,
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
                      ],
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
                                  color: isNeo ? Colors.black : theme.colorScheme.primary,
                                  width: isNeo ? 3.0 : 2.5),
                              boxShadow: isNeo
                                  ? [const BoxShadow(color: Colors.black, blurRadius: 0)]
                                  : [
                                      BoxShadow(
                                        color: theme.colorScheme.primary.withOpacity(0.4),
                                        blurRadius: 15,
                                      )
                                    ],
                            ),
                            child: ClipOval(
                              child: _profileImage != null
                                  ? Image.file(_profileImage!, fit: BoxFit.cover)
                                  : const Icon(FontAwesomeIcons.userAstronaut,
                                      size: 40, color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          username,
                          style: TextStyle(
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
                if (role == "developer")
                  _buildDrawerMenuItem(
                    icon: Icons.workspace_premium_rounded,
                    label: "developer Page",
                    onTap: () => _onSidebarTabSelected(5),
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
        color: isLogout ? Colors.red.withOpacity(0.12) : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(isNeo ? 6 : 12),
        border: Border.all(
          color: isLogout
              ? Colors.red
              : (isNeo ? Colors.black : theme.colorScheme.primary.withOpacity(0.2)),
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
        ThemeData currentTheme;
        if (modeIndex == 1) {
          currentTheme = AppTheme.neoDarkNeon;
        } else if (modeIndex == 2) {
          currentTheme = AppTheme.neoCreamPastel;
        } else {
          currentTheme = AppTheme.classic;
        }

        final isNeo = modeIndex != 0;

        return Theme(
          data: currentTheme,
          child: Builder(
            builder: (context) {
              final theme = Theme.of(context);

              IconData themeIcon;
              if (modeIndex == 0) {
                themeIcon = Icons.palette_outlined;
              } else if (modeIndex == 1) {
                themeIcon = Icons.bolt_rounded;
              } else {
                themeIcon = Icons.wb_sunny_rounded;
              }

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
                        themeIcon,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                      tooltip: "Ganti Tema",
                      onPressed: () {
                        themeModeNotifier.value = (themeModeNotifier.value + 1) % 3;
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
                            color: isNeo ? Colors.black : theme.colorScheme.primary,
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
                    Positioned(
                      top: -60,
                      right: -60,
                      child: Container(
                        width: 240,
                        height: 240,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withOpacity(0.15),
                              blurRadius: isNeo ? 0 : 100,
                              spreadRadius: isNeo ? 0 : 30,
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
                  ],
                ),
                bottomNavigationBar: Container(
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    border: Border(
                      top: BorderSide(
                        color: isNeo ? Colors.black : theme.colorScheme.primary.withOpacity(0.2),
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
                    selectedLabelStyle:
                        const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
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
    super.dispose();
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
