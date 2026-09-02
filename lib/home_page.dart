import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

import 'nomor_page.dart';
import 'group_page.dart';

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
  // Warna Tema Hitam - Ungu Neon
  final Color bgDark = const Color(0xFF07020E);
  final Color cardGlass = const Color(0xFF160A2C).withOpacity(0.9);
  final Color primaryPurple = const Color(0xFF9D00FF);
  final Color neonMagenta = const Color(0xFFE6007E);
  final Color accentViolet = const Color(0xFFC040FF);
  final Color primaryWhite = const Color(0xFFF5F5F7);
  final Color textGrey = const Color(0xFFA098B5);
  final Color borderGlass = const Color(0xFF9D00FF).withOpacity(0.35);

  final LinearGradient purpleGradient = const LinearGradient(
    colors: [Color(0xFF9D00FF), Color(0xFFE6007E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  late VideoPlayerController _videoController;
  late ChewieController _chewieController;
  bool _isVideoInitialized = false;

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
    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeaderPanel(),
              _buildVideoPlayer(),
              const SizedBox(height: 10),

              // CARD MODULE 1: BUG NOMOR
              _buildModuleCard(
                title: "BUG NOMOR",
                subtitle: "TARGET NOMOR",
                badgeText: "NUMBER ONLY",
                badgeColor: primaryPurple,
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

              const SizedBox(height: 18),

              // CARD MODULE 2: BUG GROUP
              _buildModuleCard(
                title: "BUG GROUP",
                subtitle: "TARGET KOMUNITAS / GRUP",
                badgeText: "GROUP ONLY",
                badgeColor: neonMagenta,
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
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardGlass,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderGlass, width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: purpleGradient,
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
                    color: primaryWhite,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: primaryPurple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: primaryPurple.withOpacity(0.5)),
                  ),
                  child: Text(
                    "ROLE: ${widget.role.toUpperCase()} | EXP: ${widget.expiredDate}",
                    style: TextStyle(
                      color: accentViolet,
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
    if (!_isVideoInitialized) {
      return Container(
        width: double.infinity,
        height: 160,
        margin: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: cardGlass,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderGlass),
        ),
        child: Center(
          child: CircularProgressIndicator(color: primaryPurple, strokeWidth: 2.5),
        ),
      );
    }
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryPurple.withOpacity(0.4), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardGlass,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: badgeColor.withOpacity(0.45), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
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
                    style: TextStyle(
                      color: primaryWhite,
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
                  color: badgeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: badgeColor),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: badgeColor,
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
                padding: const EdgeInsets.symmetric(vertical: 2.5),
                child: Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: badgeColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        f,
                        style: TextStyle(
                          color: textGrey,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: purpleGradient,
              ),
              child: ElevatedButton(
                onPressed: onStart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      buttonText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
