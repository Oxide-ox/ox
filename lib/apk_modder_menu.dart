import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'apk_injector_form.dart'; 
import 'spyware.dart';
class ApkModderMenu extends StatefulWidget {
  final String sessionKey;
  final String userRole;
  final String username;

  const ApkModderMenu({
    super.key,
    required this.sessionKey,
    required this.userRole,
    required this.username,
  });

  @override
  State<ApkModderMenu> createState() => _ApkModderMenuState();
}

class _ApkModderMenuState extends State<ApkModderMenu> {
  final PageController _pageController = PageController(viewportFraction: 1.0);
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: themeModeNotifier,
      builder: (context, modeIndex, _) {
        final currentTheme = AppTheme.currentTheme;

        return Theme(
          data: currentTheme,
          child: Builder(
            builder: (context) {
              final theme = Theme.of(context);
              final isNeo = modeIndex == 1;
              final primary = theme.colorScheme.primary;
              final textColor = theme.colorScheme.onSurface;

              final boxDecoration = BoxDecoration(
                color: isNeo ? theme.colorScheme.surface : theme.colorScheme.surface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(isNeo ? 8 : 24),
                border: Border.all(
                  color: isNeo ? Colors.black : primary.withOpacity(0.3),
                  width: isNeo ? 2.5 : 1.0,
                ),
                boxShadow: isNeo ? [const BoxShadow(color: Colors.black, offset: Offset(4, 4))] : [],
              );

              return Scaffold(
                backgroundColor: Colors.transparent,
                extendBodyBehindAppBar: true,
                appBar: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded, color: primary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                body: BackgroundWrapper(
                  child: SafeArea(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            
                            // 1. LOGO ATAS (Dinamis: APK atau Laptop)
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: primary.withOpacity(0.2),
                                shape: BoxShape.circle,
                                border: Border.all(color: primary.withOpacity(0.5), width: 2),
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 400),
                                transitionBuilder: (Widget child, Animation<double> animation) {
                                  return ScaleTransition(scale: animation, child: child);
                                },
                                child: Icon(
                                  _currentPage == 0 ? Icons.android_rounded : Icons.laptop_mac_rounded,
                                  key: ValueKey<int>(_currentPage), // Kunci penting agar animasi jalan
                                  size: 40,
                                  color: primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Icon(Icons.cloud_rounded, size: 60, color: Colors.white.withOpacity(0.8)),
                            const SizedBox(height: 30),

                            // 2. KARTU MENU TENGAH (PAGEVIEW)
                            SizedBox(
                              height: 150, 
                              child: PageView(
                                controller: _pageController,
                                onPageChanged: (index) {
                                  setState(() {
                                    _currentPage = index; // Trigger perubahan state
                                  });
                                },
                                children: [
                                  // MENU 1: Inject Username
                                  _buildMenuCard(
                                    title: "Inject Username",
                                    subtitle: "Ubah Nama • form rebrand",
                                    badgeText: "APK TOOL",
                                    textColor: textColor,
                                    primaryColor: primary,
                                    decoration: boxDecoration,
                                  ),
                                  // MENU 2: VPS Monitor (Contoh Menu Laptop)
                                  _buildMenuCard(
                                    title: "Panel Controler",
                                    subtitle: "Control Device Target",
                                    badgeText: "SERVER TOOL",
                                    textColor: textColor,
                                    primaryColor: primary,
                                    decoration: boxDecoration,
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 30),
                            
                            // 3. INDIKATOR TITIK
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(2, (index) {
                                return _buildDot(primary, _currentPage == index);
                              }),
                            ),

                            const SizedBox(height: 30),

                            // 4. TOMBOL BUKA HALAMAN
                            GestureDetector(
                              onTap: () {
                                if (_currentPage == 0) {
                                  // Navigasi ke form APK Injector
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ApkModderPage(username: widget.username),
                                    ),
                                  );
                                } else if (_currentPage == 1) {
                                  // Navigasi ke menu laptop/server (Bisa diganti nanti)
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SpywarePage(
                                      sessionKey: widget.sessionKey,
                                      userRole: widget.userRole,
                                      username: widget.username,
                                    ),
                                  ),
                                 );
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: boxDecoration.copyWith(
                                  color: primary.withOpacity(0.2),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _currentPage == 0 ? Icons.electric_bolt_rounded : Icons.dns_rounded, 
                                      color: primary, 
                                      size: 18
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _currentPage == 0 ? "Buka Inject Username" : "Buka Controler Panel",
                                      style: TextStyle(
                                        color: primary,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }
          ),
        );
      }
    );
  }

  // WIDGET KARTU MENU
  Widget _buildMenuCard({
    required String title,
    required String subtitle,
    required String badgeText,
    required Color textColor,
    required Color primaryColor,
    required BoxDecoration decoration,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: decoration,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 12),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryColor.withOpacity(0.5), width: 1),
            ),
            child: Text(
              badgeText,
              style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET TITIK INDIKATOR
  Widget _buildDot(Color color, bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 20 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? color : color.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
