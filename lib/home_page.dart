import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

import 'nomer_page.dart';
import 'group_page.dart';
import 'app_theme.dart';

class BugModulePage extends StatefulWidget {
  final String username;
  final String password;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final String role;
  final String expiredDate;

  const BugModulePage({
    super.key,
    required this.username,
    required this.password,
    required this.sessionKey,
    required this.listBug,
    required this.role,
    required this.expiredDate,
  });

  @override
  State<BugModulePage> createState() => _BugModulePageState();
}

class _BugModulePageState extends State<BugModulePage> {
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
    if (_isVideoInitialized) {
      _videoController.dispose();
      _chewieController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderPanel(),
              _buildVideoPlayer(),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  "SELECT MODULE",
                  style: TextStyle(
                    color: _textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              SizedBox(
                height: 380,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildModuleCard(
                      title: "BUG NOMOR",
                      subtitle: "TARGET NOMOR",
                      badgeText: "NUMBER ONLY",
                      badgeColor: theme.colorScheme.primary,
                      iconData: Icons.phone_android_rounded,
                      features: [
                        "ATTACK NUMBER",
                        "CRASH SYSTEM",
                        "SPAM BUG",
                      ],
                      buttonText: "START MODULE",
                      onStart: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NHomePage(
                              username: widget.username,
                              password: widget.password,
                              sessionKey: widget.sessionKey,
                              listBug: widget.listBug,
                              role: widget.role,
                              expiredDate: widget.expiredDate,
                            ),
                          ),
                        );
                      },
                    ),
                    _buildModuleCard(
                      title: "BUG GROUP",
                      subtitle: "TARGET KOMUNITAS / GRUP",
                      badgeText: "GROUP ONLY",
                      badgeColor: theme.colorScheme.secondary,
                      iconData: Icons.groups_rounded,
                      features: [
                        "ATTACK VIA LINK WA GROUP TARGET",
                        "SPAM RAID MULTI ANGGOTA GRUP WA",
                        "MENDUKUNG SENDER PRIVATE & GLOBAL",
                      ],
                      buttonText: "START MODULE",
                      onStart: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GroupPage(
                              username: widget.username,
                              password: widget.password,
                              sessionKey: widget.sessionKey,
                              listBug: widget.listBug,
                              role: widget.role,
                              expiredDate: widget.expiredDate,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderPanel() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(_isNeo ? 8 : 22),
        border: Border.all(
          color: _isNeo ? Colors.black : theme.colorScheme.primary.withOpacity(0.3),
          width: _isNeo ? 3.0 : 1.2,
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
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary,
              border: _isNeo ? Border.all(color: Colors.black, width: 2) : null,
            ),
            child: const CircleAvatar(
              radius: 26,
              backgroundColor: Colors.black,
              backgroundImage: AssetImage('assets/images/logo.png'),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.username.toUpperCase(),
                  style: TextStyle(
                    color: _textColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(_isNeo ? 2 : 8),
                    border: Border.all(
                      color: _isNeo ? Colors.black : theme.colorScheme.primary.withOpacity(0.5),
                      width: _isNeo ? 1.5 : 1.0,
                    ),
                  ),
                  child: Text(
                    "ROLE: ${widget.role.toUpperCase()} | EXP: ${widget.expiredDate}",
                    style: TextStyle(
                      color: _isNeo ? Colors.black : theme.colorScheme.primary,
                      fontSize: 10,
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
        height: 160,
        margin: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(_isNeo ? 8 : 20),
          border: Border.all(
            color: _isNeo ? Colors.black : theme.colorScheme.primary.withOpacity(0.3),
            width: _isNeo ? 3 : 1,
          ),
        ),
        child: Center(
          child: CircularProgressIndicator(color: theme.colorScheme.primary, strokeWidth: 2.5),
        ),
      );
    }
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 14),
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

  Widget _buildModuleCard({
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required IconData iconData,
    required List<String> features,
    required String buttonText,
    required VoidCallback onStart,
  }) {
    final theme = Theme.of(context);
    final cardWidth = MediaQuery.of(context).size.width * 0.82;

    return Container(
      width: cardWidth,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(_isNeo ? 8 : 24),
        border: Border.all(
          color: _isNeo ? Colors.black : badgeColor,
          width: _isNeo ? 3.0 : 1.5,
        ),
        boxShadow: _isNeo
            ? [const BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(5, 5))]
            : [
                BoxShadow(
                  color: badgeColor.withOpacity(0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_isNeo ? 5 : 22),
        child: Stack(
          children: [
            const Positioned.fill(
              child: CardVideoBackground(
                url: 'https://smail.my.id/cloud/ZmVtsZ3V1',
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.88),
                      Colors.black.withOpacity(0.72),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(iconData, color: badgeColor, size: 22),
                              const SizedBox(width: 8),
                              Text(
                                title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: badgeColor.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(_isNeo ? 2 : 10),
                              border: Border.all(
                                color: _isNeo ? Colors.black : badgeColor,
                                width: _isNeo ? 1.5 : 1.0,
                              ),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                color: _isNeo ? Colors.white : badgeColor,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        "FITUR:",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...features.map((f) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: badgeColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    f,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(_isNeo ? 4 : 14),
                        color: badgeColor,
                        border: _isNeo ? Border.all(color: Colors.black, width: 2) : null,
                      ),
                      child: ElevatedButton(
                        onPressed: onStart,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(_isNeo ? 4 : 14),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              buttonText,
                              style: TextStyle(
                                color: _isNeo && _isLight ? Colors.black : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: _isNeo && _isLight ? Colors.black : Colors.white,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
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

class CardVideoBackground extends StatefulWidget {
  final String url;
  const CardVideoBackground({super.key, required this.url});

  @override
  State<CardVideoBackground> createState() => _CardVideoBackgroundState();
}

class _CardVideoBackgroundState extends State<CardVideoBackground> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
          _controller.setLooping(true);
          _controller.setVolume(0.0);
          _controller.play();
        }
      }).catchError((e) {
        debugPrint("Error loading card video: $e");
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialized && _controller.value.isInitialized) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _controller.value.size.width,
            height: _controller.value.size.height,
            child: VideoPlayer(_controller),
          ),
        ),
      );
    }
    return Container(color: Colors.black);
  }
}
