import 'dart:ui';
import 'package:flutter/material.dart';
import 'manage_server.dart';
import 'wifi_internal.dart';
import 'wifi_external.dart';
import 'ddos_panel.dart';
import 'nik_check.dart';
import 'tiktok_page.dart';
import 'instagram_page.dart';
import 'phone_lookup.dart';
import 'qr_gen.dart';
import 'domain_page.dart';
import 'spam_ngl.dart';
import 'am.dart';
import 'telegram.dart';
import 'spyware.dart';
import 'prikitiww_music_page.dart';
import 'anime_home.dart';
import 'chatbot_page.dart';
import 'youtube_page.dart';

class ToolsPage extends StatelessWidget {
  final String username;
  final String sessionKey;
  final String userRole;
  final List<Map<String, dynamic>> listDoos;

  const ToolsPage({
    super.key,
    required this.username,
    required this.sessionKey,
    required this.userRole,
    required this.listDoos,
  });

  static const Color bgDark = Color(0xFF090212);
  static const Color bgDeepPurple = Color(0xFF140526);
  static const Color neonMagenta = Color(0xFFE6007E);
  static const Color neonPurple = Color(0xFF8E00C7);
  static const Color cardDark = Color(0xFF120722);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgDark, bgDeepPurple, bgDark],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildHeroCard(context),
                      const SizedBox(height: 24),
                      Row(
                        children: const [
                          Icon(Icons.widgets_outlined, color: neonMagenta, size: 20),
                          SizedBox(width: 8),
                          Text(
                            "SYSTEM MODULES",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontFamily: 'Orbitron',
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              shadows: [
                                Shadow(color: neonMagenta, blurRadius: 10),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.1,
                        children: [
                          _buildGothicCard(
                            icon: Icons.flash_on,
                            title: "DDoS Tools",
                            subtitle: "Attack & Server",
                            onTap: () => _showDDoSTools(context),
                          ),
                          _buildGothicCard(
                            icon: Icons.wifi_tethering,
                            title: "Network",
                            subtitle: "WiFi & Spam",
                            onTap: () => _showNetworkTools(context),
                          ),
                          _buildGothicCard(
                            icon: Icons.radar,
                            title: "OSINT",
                            subtitle: "Investigation",
                            onTap: () => _showOSINTTools(context),
                          ),
                          _buildGothicCard(
                            icon: Icons.cloud_download_outlined,
                            title: "Downloader",
                            subtitle: "Social Media",
                            onTap: () => _showDownloaderTools(context),
                          ),
                          _buildGothicCard(
                            icon: Icons.precision_manufacturing_outlined,
                            title: "Utilities",
                            subtitle: "Extra Tools",
                            onTap: () => _showUtilityTools(context),
                          ),
                          _buildGothicCard(
                            icon: Icons.movie_creation_outlined,
                            title: "Streaming",
                            subtitle: "Nonton & Hiburan",
                            onTap: () => _showStreamingTools(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardDark.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: neonPurple.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: neonMagenta.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [neonMagenta, neonPurple]),
              boxShadow: [
                BoxShadow(
                  color: neonMagenta.withOpacity(0.6),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Icon(Icons.security, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Orbitron',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "ROLE: $userRole",
                  style: TextStyle(
                    color: neonMagenta.withOpacity(0.9),
                    fontSize: 12,
                    fontFamily: 'ShareTechMono',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: neonMagenta.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: neonMagenta),
            ),
            child: Row(
              children: const [
                CircleAvatar(radius: 4, backgroundColor: neonMagenta),
                SizedBox(width: 6),
                Text(
                  "ONLINE",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AiChatPage(),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [neonPurple, cardDark],
          ),
          border: Border.all(color: neonMagenta, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: neonMagenta.withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "AI ASSISTANT",
                    style: TextStyle(
                      color: neonMagenta,
                      fontSize: 12,
                      fontFamily: 'ShareTechMono',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Tanya AI Pintar",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontFamily: 'Orbitron',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Sistem kecerdasan buatan siap membantu analisis & otomasi.",
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [neonMagenta, neonPurple]),
                boxShadow: [
                  BoxShadow(
                    color: neonMagenta.withOpacity(0.8),
                    blurRadius: 15,
                  ),
                ],
              ),
              child: const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 30),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGothicCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardDark.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: neonPurple.withOpacity(0.4), width: 1),
          boxShadow: [
            BoxShadow(
              color: neonPurple.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgDark,
                shape: BoxShape.circle,
                border: Border.all(color: neonMagenta.withOpacity(0.6)),
                boxShadow: [
                  BoxShadow(
                    color: neonMagenta.withOpacity(0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Icon(icon, color: neonMagenta, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'Orbitron',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontFamily: 'ShareTechMono',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDDoSTools(BuildContext context) {
    _showGothicBottomSheet(
      context: context,
      title: "DDoS Tools",
      icon: Icons.flash_on,
      children: [
        _buildToolOption(
          icon: Icons.flash_on,
          label: "Attack Panel",
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AttackPanel(
                  sessionKey: sessionKey,
                  listDoos: listDoos,
                ),
              ),
            );
          },
        ),
        _buildToolOption(
          icon: Icons.dns,
          label: "Manage Server",
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ManageServerPage(keyToken: sessionKey),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showNetworkTools(BuildContext context) {
    _showGothicBottomSheet(
      context: context,
      title: "Network Tools",
      icon: Icons.wifi_tethering,
      children: [
        _buildToolOption(
          icon: Icons.security,
          label: "Spyware",
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SpywarePage(
                  sessionKey: sessionKey,
                  userRole: userRole,
                  username: username,
                ),
              ),
            );
          },
        ),
        _buildToolOption(
          icon: Icons.telegram,
          label: "TG Spam",
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TelegramSpamPage(sessionKey: sessionKey),
              ),
            );
          },
        ),
        _buildToolOption(
          icon: Icons.newspaper_outlined,
          label: "Spam NGL",
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => NglPage()),
            );
          },
        ),
        _buildToolOption(
          icon: Icons.wifi_off,
          label: "WiFi Killer (Internal)",
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => WifiKillerPage()),
            );
          },
        ),
        _buildToolOption(
          icon: Icons.router,
          label: "WiFi Killer (External)",
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WifiInternalPage(sessionKey: sessionKey),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showOSINTTools(BuildContext context) {
    _showGothicBottomSheet(
      context: context,
      title: "OSINT Tools",
      icon: Icons.radar,
      children: [
        _buildToolOption(
          icon: Icons.badge,
          label: "NIK Detail",
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NikCheckerPage()),
            );
          },
        ),
        _buildToolOption(
          icon: Icons.domain,
          label: "Domain OSINT",
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DomainOsintPage()),
            );
          },
        ),
        _buildToolOption(
          icon: Icons.person_search,
          label: "Phone Lookup",
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PhoneLookupPage()),
            );
          },
        ),
        _buildToolOption(
          icon: Icons.email,
          label: "Email OSINT",
          onTap: () => _showComingSoon(context),
        ),
      ],
    );
  }

  void _showDownloaderTools(BuildContext context) {
    _showGothicBottomSheet(
      context: context,
      title: "Media Downloader",
      icon: Icons.cloud_download_outlined,
      children: [
        _buildToolOption(
          icon: Icons.video_library,
          label: "TikTok Downloader",
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TiktokDownloaderPage()),
            );
          },
        ),
        _buildToolOption(
          icon: Icons.music_note,
          label: "Music Player",
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrikitiwwMusicPage()),
            );
          },
        ),
        _buildToolOption(
          icon: Icons.ondemand_video,
          label: "YouTube Player",
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          },
        ),
        _buildToolOption(
          icon: Icons.camera_alt,
          label: "Instagram Downloader",
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const InstagramDownloaderPage()),
            );
          },
        ),
      ],
    );
  }

  void _showUtilityTools(BuildContext context) {
    _showGothicBottomSheet(
      context: context,
      title: "Utility Tools",
      icon: Icons.precision_manufacturing_outlined,
      children: [
        _buildToolOption(
          icon: Icons.qr_code,
          label: "QR Generator",
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const QrGeneratorPage()),
            );
          },
        ),
        _buildToolOption(
          icon: Icons.security,
          label: "IP Scanner",
          onTap: () => _showComingSoon(context),
        ),
        _buildToolOption(
          icon: Icons.auto_awesome_motion,
          label: "Alight Motion Prem",
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AlightMotionPremScreen()),
            );
          },
        ),
        _buildToolOption(
          icon: Icons.network_check,
          label: "Port Scanner",
          onTap: () => _showComingSoon(context),
        ),
      ],
    );
  }

  void _showStreamingTools(BuildContext context) {
    _showGothicBottomSheet(
      context: context,
      title: "Streaming & Hiburan",
      icon: Icons.movie_creation_outlined,
      children: [
        _buildToolOption(
          icon: Icons.movie_filter,
          label: "Anime Stream",
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HomeAnimePage()),
            );
          },
        ),
        _buildToolOption(
          icon: Icons.video_library,
          label: "Donghua Stream",
          onTap: () => _showComingSoon(context),
        ),
        _buildToolOption(
          icon: Icons.theaters,
          label: "Drama China (Drachin)",
          onTap: () => _showComingSoon(context),
        ),
        _buildToolOption(
          icon: Icons.live_tv,
          label: "Movies & Series",
          onTap: () => _showComingSoon(context),
        ),
      ],
    );
  }

  void _showGothicBottomSheet({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: BoxDecoration(
          color: cardDark,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          border: Border.all(color: neonMagenta, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: neonMagenta.withOpacity(0.3),
              blurRadius: 25,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [neonPurple, cardDark],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Row(
                children: [
                  Icon(icon, color: neonMagenta, size: 26),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontFamily: 'Orbitron',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(children: children),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Card(
      color: bgDark,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: neonPurple.withOpacity(0.4)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: neonMagenta.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: neonMagenta.withOpacity(0.5)),
          ),
          child: Icon(icon, color: neonMagenta, size: 20),
        ),
        title: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Orbitron',
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: neonMagenta, size: 14),
        onTap: onTap,
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.hourglass_top, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Feature Coming Soon!',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: neonPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
} 