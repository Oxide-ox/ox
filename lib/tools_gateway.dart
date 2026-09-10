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
import 'chtml.dart';
import 'am.dart';
import 'telegram.dart';
import 'spyware.dart';
import 'prikitiww_music_page.dart';
import 'anime_home.dart';
import 'instagram_login_page.dart';
import 'chatbot_page.dart';
import 'youtube_page.dart';
import 'music_player_page.dart';
import 'movie.dart';
import 'nftoken_page.dart';
import 'app_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNeo = themeModeNotifier.value != 0;
    final isLight = theme.brightness == Brightness.light;
    final textColor = isLight ? Colors.black87 : Colors.white;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 24),
                    _buildHeroCard(context),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Icon(Icons.widgets_outlined,
                            color: theme.colorScheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "SYSTEM MODULES",
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
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
                          context: context,
                          icon: Icons.flash_on,
                          title: "DDoS Tools",
                          subtitle: "Attack & Server",
                          onTap: () => _showDDoSTools(context),
                        ),
                        _buildGothicCard(
                          context: context,
                          icon: Icons.wifi_tethering,
                          title: "Network",
                          subtitle: "WiFi & Spam",
                          onTap: () => _showNetworkTools(context),
                        ),
                        _buildGothicCard(
                          context: context,
                          icon: Icons.radar,
                          title: "OSINT",
                          subtitle: "Investigation",
                          onTap: () => _showOSINTTools(context),
                        ),
                        _buildGothicCard(
                          context: context,
                          icon: Icons.cloud_download_outlined,
                          title: "Downloader",
                          subtitle: "Social Media",
                          onTap: () => _showDownloaderTools(context),
                        ),
                        _buildGothicCard(
                          context: context,
                          icon: Icons.precision_manufacturing_outlined,
                          title: "Utilities",
                          subtitle: "Extra Tools",
                          onTap: () => _showUtilityTools(context),
                        ),
                        _buildGothicCard(
                          context: context,
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
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final isNeo = themeModeNotifier.value != 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(isNeo ? 8 : 20),
        border: Border.all(
          color: isNeo ? Colors.black : theme.colorScheme.primary.withOpacity(0.5),
          width: isNeo ? 3 : 1,
        ),
        image: const DecorationImage(
          image: NetworkImage('https://smail.my.id/cloud/FHoXwjmX1'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Color(0xCC000000),
            BlendMode.darken,
          ),
        ),
        boxShadow: isNeo
            ? [const BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(4, 4))]
            : [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.2),
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
              color: theme.colorScheme.primary,
              border: isNeo ? Border.all(color: Colors.black, width: 2) : null,
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
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "ROLE: $userRole",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(isNeo ? 2 : 12),
              border: isNeo ? Border.all(color: Colors.black, width: 1.5) : null,
            ),
            child: Row(
              children: const [
                CircleAvatar(radius: 4, backgroundColor: Colors.white),
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
    final theme = Theme.of(context);
    final isNeo = themeModeNotifier.value != 0;

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
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(isNeo ? 8 : 24),
          border: Border.all(
            color: isNeo ? Colors.black : theme.colorScheme.primary,
            width: isNeo ? 3 : 1.5,
          ),
          boxShadow: isNeo
              ? [const BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(5, 5))]
              : [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
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
                children: [
                  Text(
                    "AI ASSISTANT",
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Tanya AI Pintar",
                    style: TextStyle(
                      color: theme.brightness == Brightness.light ? Colors.black87 : Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Sistem kecerdasan buatan siap membantu analisis & otomasi.",
                    style: TextStyle(
                      color: theme.brightness == Brightness.light ? Colors.black54 : Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary,
                border: isNeo ? Border.all(color: Colors.black, width: 2) : null,
              ),
              child: const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 30),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGothicCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isNeo = themeModeNotifier.value != 0;
    final isLight = theme.brightness == Brightness.light;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(isNeo ? 8 : 20),
          border: Border.all(
            color: isNeo ? Colors.black : theme.colorScheme.primary.withOpacity(0.4),
            width: isNeo ? 3 : 1,
          ),
          boxShadow: isNeo
              ? [const BoxShadow(color: Colors.black, blurRadius: 0, offset: Offset(4, 4))]
              : [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.15),
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
                color: theme.scaffoldBackgroundColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isNeo ? Colors.black : theme.colorScheme.primary.withOpacity(0.6),
                  width: isNeo ? 1.5 : 1,
                ),
              ),
              child: Icon(icon, color: theme.colorScheme.primary, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: isLight ? Colors.black87 : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: isLight ? Colors.black54 : Colors.white54,
                fontSize: 11,
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
          context: context,
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
          context: context,
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
          context: context,
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
          context: context,
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
          context: context,
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
          context: context,
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
          context: context,
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
          context: context,
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
          context: context,
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
          context: context,
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
          context: context,
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
          context: context,
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
          context: context,
          icon: Icons.music_note,
          label: "Music Player",
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MusicPlayerScreen()),
            );
          },
        ),
        _buildToolOption(
          context: context,
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
          context: context,
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
          context: context,
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
          context: context,
          icon: Icons.web,
          label: "Create Html Payment",
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreatePaymentHtmlPage()),
            );
          },
        ),
        _buildToolOption(
          context: context,
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
          context: context,
          icon: Icons.live_tv,
          label: "NF Token Generator",
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NfTokenPage()),
            );
          },
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
          context: context,
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
          context: context,
          icon: Icons.camera_alt,
          label: "Instagram Login",
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const InstagramLoginPage()),
            );
          },
        ),
        _buildToolOption(
          context: context,
          icon: Icons.theaters,
          label: "Drama China (Drachin)",
          onTap: () => _showComingSoon(context),
        ),
        _buildToolOption(
          context: context,
          icon: Icons.live_tv,
          label: "Movies & Series",
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NetflixMovieApp()),
            );
          },
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
    final theme = Theme.of(context);
    final isNeo = themeModeNotifier.value != 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isNeo ? 12 : 30),
            topRight: Radius.circular(isNeo ? 12 : 30),
          ),
          border: Border.all(
            color: isNeo ? Colors.black : theme.colorScheme.primary,
            width: isNeo ? 3 : 1.5,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isNeo ? 8 : 28),
                  topRight: Radius.circular(isNeo ? 8 : 28),
                ),
                border: isNeo
                    ? const Border(bottom: BorderSide(color: Colors.black, width: 2.5))
                    : null,
              ),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white, size: 26),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
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
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isNeo = themeModeNotifier.value != 0;
    final isLight = theme.brightness == Brightness.light;

    return Card(
      color: theme.scaffoldBackgroundColor,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isNeo ? 6 : 16),
        side: BorderSide(
          color: isNeo ? Colors.black : theme.colorScheme.primary.withOpacity(0.4),
          width: isNeo ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: isNeo ? Colors.black : theme.colorScheme.primary.withOpacity(0.5),
            ),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 20),
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isLight ? Colors.black87 : Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios,
            color: theme.colorScheme.primary, size: 14),
        onTap: onTap,
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.hourglass_top, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Feature Coming Soon!',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: theme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
