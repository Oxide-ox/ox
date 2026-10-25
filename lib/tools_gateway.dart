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
import 'providers/music_provider.dart';
import 'screens/main_screen.dart';

import 'webv/youtube_view.dart';
import 'webv/tiktok_view.dart';
import 'webv/instagram_view.dart';
import 'webv/facebook_view.dart';
import 'webv/netflix_view.dart';
import 'webv/chrome_view.dart';
import 'webv/crazygames_view.dart';
import 'webv/anime_view.dart';

class ToolItem {
  final String title;
  final String subtitle;
  final String category;
  final IconData icon;
  final Color iconColor;
  final String? statusBadge;
  final Widget Function(BuildContext) builder;

  ToolItem({
    required this.title,
    required this.subtitle,
    required this.category,
    required this.icon,
    required this.iconColor,
    this.statusBadge,
    required this.builder,
  });
}

class ToolsPage extends StatefulWidget {
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
  State<ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends State<ToolsPage> {
  String _selectedCategory = 'ALL';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'ALL',
    'SOCIAL MEDIA',
    'STREAMING',
    'NETWORK',
    'UTILITIES',
    'OSINT',
    'ENTERTAINMENT',
    'ALL IN ONE',
  ];

  late final List<ToolItem> _tools = [
    // --- SOCIAL MEDIA MODULES ---
    ToolItem(
      title: 'TikTok',
      subtitle: 'Platform TikTok',
      category: 'SOCIAL MEDIA',
      icon: Icons.music_note_rounded,
      iconColor: Colors.cyanAccent,
      statusBadge: 'LIVE',
      builder: (_) => const TiktokView(),
    ),
    ToolItem(
      title: 'OXGram',
      subtitle: 'Feed & Direct Message Instagram',
      category: 'SOCIAL MEDIA',
      icon: Icons.camera_alt_rounded,
      iconColor: Colors.pinkAccent,
      statusBadge: 'LIVE',
      builder: (_) => const InstagramView(),
    ),
    ToolItem(
      title: 'OXBook',
      subtitle: 'Komunitas Facebook',
      category: 'SOCIAL MEDIA',
      icon: Icons.facebook_rounded,
      iconColor: Colors.blueAccent,
      statusBadge: 'LIVE',
      builder: (_) => const FacebookView(),
    ),

    // --- STREAMING MODULES ---
    ToolItem(
      title: 'OXTube',
      subtitle: 'Nonton & Cari Video YouTube',
      category: 'STREAMING',
      icon: Icons.ondemand_video_rounded,
      iconColor: Colors.redAccent,
      statusBadge: 'ONLINE',
      builder: (_) => const YoutubeView(),
    ),
    ToolItem(
      title: 'OXMovies',
      subtitle: 'Streaming Film & Series Netflix',
      category: 'STREAMING',
      icon: Icons.movie_rounded,
      iconColor: Colors.red,
      statusBadge: 'LIVE',
      builder: (_) => const NetflixView(),
    ),
    ToolItem(
      title: 'OXAnime',
      subtitle: 'Anime Center Stream',
      category: 'STREAMING',
      icon: Icons.tv_rounded,
      iconColor: Colors.lightBlueAccent,
      statusBadge: 'ONLINE',
      builder: (_) => const AnimeView(),
    ),

    // --- NETWORK & DDOS MODULES ---
    ToolItem(
      title: 'Attack Panel',
      subtitle: 'DDoS Attack Panel & Server Control',
      category: 'NETWORK',
      icon: Icons.flash_on_rounded,
      iconColor: Colors.amber,
      statusBadge: 'ONLINE',
      builder: (_) => AttackPanel(
        sessionKey: widget.sessionKey,
        listDoos: widget.listDoos,
      ),
    ),
    ToolItem(
      title: 'Manage Server',
      subtitle: 'DNS & Kelola Server Tunnel',
      category: 'NETWORK',
      icon: Icons.dns_rounded,
      iconColor: Colors.blueAccent,
      builder: (_) => ManageServerPage(keyToken: widget.sessionKey),
    ),
    ToolItem(
      title: 'Spyware',
      subtitle: 'Monitoring & Pelacakan Sistem',
      category: 'NETWORK',
      icon: Icons.security_rounded,
      iconColor: Colors.redAccent,
      builder: (_) => SpywarePage(
        sessionKey: widget.sessionKey,
        userRole: widget.userRole,
        username: widget.username,
      ),
    ),
    ToolItem(
      title: 'TG Spam',
      subtitle: 'Otomasi Telegram Bot Spam',
      category: 'NETWORK',
      icon: Icons.telegram_rounded,
      iconColor: Colors.lightBlue,
      builder: (_) => TelegramSpamPage(sessionKey: widget.sessionKey),
    ),
    ToolItem(
      title: 'Spam NGL',
      subtitle: 'Otomasi Pesan NGL Link',
      category: 'NETWORK',
      icon: Icons.newspaper_outlined,
      iconColor: Colors.orangeAccent,
      builder: (_) => NglPage(),
    ),
    ToolItem(
      title: 'WiFi Killer (Internal)',
      subtitle: 'Internal Network Tool',
      category: 'NETWORK',
      icon: Icons.wifi_off_rounded,
      iconColor: Colors.deepOrange,
      builder: (_) => WifiKillerPage(),
    ),
    ToolItem(
      title: 'WiFi Killer (External)',
      subtitle: 'External Network Manager',
      category: 'NETWORK',
      icon: Icons.router_rounded,
      iconColor: Colors.indigoAccent,
      builder: (_) => WifiInternalPage(sessionKey: widget.sessionKey),
    ),

    // --- OSINT MODULES ---
    ToolItem(
      title: 'NIK Detail',
      subtitle: 'Pengecekan data NIK kependudukan',
      category: 'OSINT',
      icon: Icons.badge_rounded,
      iconColor: Colors.amberAccent,
      builder: (_) => const NikCheckerPage(),
    ),
    ToolItem(
      title: 'Domain OSINT',
      subtitle: 'Analisis Whois & DNS Domain',
      category: 'OSINT',
      icon: Icons.domain_rounded,
      iconColor: Colors.tealAccent,
      builder: (_) => const DomainOsintPage(),
    ),
    ToolItem(
      title: 'Phone Lookup',
      subtitle: 'Pencarian detail nomor telepon',
      category: 'OSINT',
      icon: Icons.person_search_rounded,
      iconColor: Colors.lightGreenAccent,
      builder: (_) => const PhoneLookupPage(),
    ),

    // --- UTILITIES MODULES ---
    ToolItem(
      title: 'Chroom',
      subtitle: 'Browser Penjelajah Web Cepat',
      category: 'UTILITIES',
      icon: Icons.language_rounded,
      iconColor: Colors.greenAccent,
      statusBadge: 'LIVE',
      builder: (_) => const ChromeView(),
    ),
    ToolItem(
      title: 'Mini Game',
      subtitle: 'Arena Hiburan',
      category: 'UTILITIES',
      icon: Icons.sports_esports_rounded,
      iconColor: Colors.purpleAccent,
      statusBadge: 'LIVE',
      builder: (_) => const CrazygamesView(),
    ),
    ToolItem(
      title: 'TikTok Downloader',
      subtitle: 'Download video TikTok tanpa WM',
      category: 'UTILITIES',
      icon: Icons.video_library_rounded,
      iconColor: Colors.pinkAccent,
      builder: (_) => const TiktokDownloaderPage(),
    ),
    ToolItem(
      title: 'Instagram Downloader',
      subtitle: 'Download Reels & Media IG',
      category: 'UTILITIES',
      icon: Icons.camera_alt_outlined,
      iconColor: Colors.purpleAccent,
      builder: (_) => const InstagramDownloaderPage(),
    ),
    ToolItem(
      title: 'QR Generator',
      subtitle: 'Pembuat kode QR kustom cepat',
      category: 'UTILITIES',
      icon: Icons.qr_code_2_rounded,
      iconColor: Colors.cyan,
      builder: (_) => const QrGeneratorPage(),
    ),
    ToolItem(
      title: 'Create Html Payment',
      subtitle: 'Buat Halaman Invoice HTML',
      category: 'UTILITIES',
      icon: Icons.web_rounded,
      iconColor: Colors.greenAccent,
      builder: (_) => const CreatePaymentHtmlPage(),
    ),
    ToolItem(
      title: 'Alight Motion Prem',
      subtitle: 'Akses Fitur Alight Motion Pro',
      category: 'UTILITIES',
      icon: Icons.auto_awesome_motion_rounded,
      iconColor: Colors.lightBlue,
      builder: (_) => const AlightMotionPremScreen(),
    ),

    // --- ENTERTAINMENT & MUSIC ---
    ToolItem(
      title: 'Oxfy',
      subtitle: 'Oxide music',
      category: 'ENTERTAINMENT',
      icon: Icons.music_note_rounded,
      iconColor: Colors.cyanAccent,
      builder: (_) => const MainScreen(),
    ),

    // --- ALL IN ONE MODULES ---
    ToolItem(
      title: 'NF Token Generator',
      subtitle: 'Generator Token Netflix Premium',
      category: 'ALL IN ONE',
      icon: Icons.live_tv_rounded,
      iconColor: Colors.red,
      builder: (_) => const NfTokenPage(),
    ),
  ];

  List<ToolItem> get _filteredTools {
    return _tools.where((tool) {
      final matchesCategory =
          _selectedCategory == 'ALL' || tool.category == _selectedCategory;
      final matchesQuery = tool.title
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          tool.subtitle.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: themeModeNotifier,
      builder: (context, modeIndex, child) {
        final currentTheme = AppTheme.currentTheme;

        return Theme(
          data: currentTheme,
          child: Builder(
            builder: (context) {
              final theme = Theme.of(context);
              final isNeo = modeIndex == 1;
              final textColor = theme.colorScheme.onSurface;
              final subTextColor = textColor.withOpacity(0.7);

              return Scaffold(
                backgroundColor: Colors.transparent,
                body: BackgroundWrapper(
                  child: SafeArea(
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        // SEARCH BAR + STAR ICON
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface,
                                    borderRadius:
                                        BorderRadius.circular(isNeo ? 8 : 16),
                                    border: Border.all(
                                      color: isNeo
                                          ? Colors.black
                                          : theme.colorScheme.outline
                                              .withOpacity(0.3),
                                      width: isNeo ? 2.5 : 1.5,
                                    ),
                                    boxShadow: isNeo
                                        ? [
                                            const BoxShadow(
                                              color: Colors.black,
                                              blurRadius: 0,
                                              offset: Offset(3, 3),
                                            )
                                          ]
                                        : null,
                                  ),
                                  child: TextField(
                                    controller: _searchController,
                                    onChanged: (val) =>
                                        setState(() => _searchQuery = val),
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 14,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Cari tools...',
                                      hintStyle: TextStyle(
                                        color: subTextColor,
                                        fontSize: 14,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.search_rounded,
                                        color: theme.colorScheme.primary,
                                        size: 20,
                                      ),
                                      suffixIcon: _searchQuery.isNotEmpty
                                          ? IconButton(
                                              icon: Icon(
                                                Icons.clear,
                                                color: subTextColor,
                                                size: 18,
                                              ),
                                              onPressed: () {
                                                _searchController.clear();
                                                setState(
                                                    () => _searchQuery = '');
                                              },
                                            )
                                          : null,
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                height: 48,
                                width: 48,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius:
                                      BorderRadius.circular(isNeo ? 8 : 16),
                                  border: Border.all(
                                    color: isNeo
                                        ? Colors.black
                                        : theme.colorScheme.outline
                                            .withOpacity(0.3),
                                    width: isNeo ? 2.5 : 1.5,
                                  ),
                                  boxShadow: isNeo
                                      ? [
                                          const BoxShadow(
                                            color: Colors.black,
                                            blurRadius: 0,
                                            offset: Offset(3, 3),
                                          )
                                        ]
                                      : null,
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.star_outline_rounded,
                                    color: theme.colorScheme.primary,
                                  ),
                                  onPressed: () {},
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // HORIZONTAL CATEGORY CHIPS
                        SizedBox(
                          height: 38,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _categories.length,
                            itemBuilder: (context, index) {
                              final category = _categories[index];
                              final isSelected = _selectedCategory == category;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: GestureDetector(
                                  onTap: () => setState(
                                      () => _selectedCategory = category),
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.surface,
                                      borderRadius: BorderRadius.circular(
                                          isNeo ? 6 : 20),
                                      border: Border.all(
                                        color: isNeo
                                            ? Colors.black
                                            : (isSelected
                                                ? theme.colorScheme.primary
                                                : theme.colorScheme.outline
                                                    .withOpacity(0.3)),
                                        width: isNeo ? 2 : 1.5,
                                      ),
                                      boxShadow: isNeo
                                          ? (isSelected
                                              ? [
                                                  const BoxShadow(
                                                    color: Colors.black,
                                                    blurRadius: 0,
                                                    offset: Offset(2, 2),
                                                  )
                                                ]
                                              : [])
                                          : (isSelected
                                              ? [
                                                  BoxShadow(
                                                    color: theme
                                                        .colorScheme.primary
                                                        .withOpacity(0.4),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  )
                                                ]
                                              : []),
                                    ),
                                    child: Row(
                                      children: [
                                        if (category == 'ALL') ...[
                                          Icon(
                                            Icons.grid_view_rounded,
                                            size: 14,
                                            color: isSelected
                                                ? theme.colorScheme.onPrimary
                                                : theme.colorScheme.primary,
                                          ),
                                          const SizedBox(width: 6),
                                        ],
                                        Text(
                                          category,
                                          style: TextStyle(
                                            color: isSelected
                                                ? (isNeo &&
                                                        theme.brightness ==
                                                            Brightness.light
                                                    ? Colors.black
                                                    : theme.colorScheme
                                                        .onPrimary)
                                                : textColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        // GRID VIEW TOOLS
                        Expanded(
                          child: _filteredTools.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.search_off_rounded,
                                        size: 48,
                                        color: theme.colorScheme.primary
                                            .withOpacity(0.4),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Tools tidak ditemukan',
                                        style: TextStyle(
                                          color: subTextColor,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : GridView.builder(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  physics: const BouncingScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 14,
                                    mainAxisSpacing: 14,
                                    childAspectRatio: 0.95,
                                  ),
                                  itemCount: _filteredTools.length,
                                  itemBuilder: (context, index) {
                                    final tool = _filteredTools[index];
                                    return _buildToolCard(
                                        context, tool, isNeo, textColor, subTextColor);
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildToolCard(
    BuildContext context,
    ToolItem tool,
    bool isNeo,
    Color textColor,
    Color subTextColor,
  ) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (ctx) => tool.builder(ctx)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(isNeo ? 8 : 20),
          border: Border.all(
            color: isNeo
                ? Colors.black
                : theme.colorScheme.outline.withOpacity(0.3),
            width: isNeo ? 2.5 : 1.5,
          ),
          boxShadow: isNeo
              ? [
                  const BoxShadow(
                    color: Colors.black,
                    blurRadius: 0,
                    offset: Offset(3, 3),
                  )
                ]
              : [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: tool.iconColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isNeo ? Colors.black : tool.iconColor.withOpacity(0.4),
                      width: isNeo ? 1.5 : 1.0,
                    ),
                  ),
                  child: Icon(tool.icon, color: tool.iconColor, size: 22),
                ),
                if (tool.statusBadge != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.greenAccent.withOpacity(0.8),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.greenAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          tool.statusBadge!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              tool.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              tool.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: subTextColor,
                fontSize: 10,
                height: 1.2,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(isNeo ? 4 : 8),
                border: Border.all(
                  color: isNeo
                      ? Colors.black
                      : theme.colorScheme.outline.withOpacity(0.3),
                  width: isNeo ? 1.5 : 1.0,
                ),
              ),
              child: Text(
                tool.category,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
