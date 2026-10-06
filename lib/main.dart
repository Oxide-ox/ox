import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart'; 
import 'package:audio_service/audio_service.dart';
import 'audio_handler.dart';    

// IMPORT MUSIK & MINI PLAYER
import 'package:just_audio_background/just_audio_background.dart';
import 'providers/music_provider.dart'; 
import 'global_mini_player.dart'; 

import 'login_page.dart' hide AppTheme;
import 'dashboard_page.dart';
import 'home_page.dart';
import 'seller_page.dart';
import 'admin_page.dart';
import 'staff_page.dart';
import 'dev_page.dart';
import 'owner_page.dart';
import 'landing.dart' hide AppTheme;

import 'app_theme.dart';

import 'game/game_provider.dart';
import 'game/game_screen.dart';

import 'btrapps/.dart'; 

AudioHandler? globalAudioHandler;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 🔥 SOLUSI ANTI-STUCK (ANR): 
  // Langsung jalankan UI Bootloader agar Android tidak mengira aplikasi freeze.
  runApp(const AppBootloader());
}

// ============================================================================
// WIDGET BOOTLOADER (LAYAR LOADING AWAL)
// Menjalankan proses berat (API & Audio) di latar belakang sambil menampilkan UI
// ============================================================================
class AppBootloader extends StatefulWidget {
  const AppBootloader({super.key});

  @override
  State<AppBootloader> createState() => _AppBootloaderState();
}

class _AppBootloaderState extends State<AppBootloader> {
  bool _isReady = false;
  String _statusText = "Memulai Sistem Oxide...";

  @override
  void initState() {
    super.initState();
    _initializeHeavyTasks();
  }

  Future<void> _initializeHeavyTasks() async {
    try {
      if (mounted) setState(() => _statusText = "Menyiapkan Audio Engine...");
      
      // 1. Init Audio Background
      await JustAudioBackground.init(
        androidNotificationChannelId: 'com.oxide.music.channel.audio',
        androidNotificationChannelName: 'Audio playback',
        androidNotificationOngoing: true,
      );

      if (mounted) setState(() => _statusText = "Menghubungkan ke Server (API)...");
      
      // 2. Load API Backend (Proses yang sebelumnya bikin stuck)
      await Api.loadGh();
      
      if (mounted) setState(() => _statusText = "Memuat Tema & Konfigurasi...");
      
      // 3. Load Theme
      await AppTheme.init();

      // Jika semua sukses, ubah state menjadi ready
      if (mounted) {
        setState(() {
          _isReady = true;
        });
      }
    } catch (e) {
      debugPrint("Error Init: $e");
      if (mounted) setState(() => _statusText = "Terjadi masalah: $e");
      
      // Jika terjadi error (misal internet putus), tetap paksa masuk ke aplikasi
      // setelah menunggu 2 detik agar user tidak terjebak selamanya di layar loading.
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _isReady = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ⏳ Selama _isReady false, tampilkan layar loading sederhana
    if (!_isReady) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF0D0D0E), // Sesuaikan dengan AppTheme.bgDark
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Color(0xFFE6007E)), // Warna primary Magenta
                const SizedBox(height: 20),
                Text(
                  _statusText,
                  style: const TextStyle(
                    color: Colors.white70, 
                    fontFamily: 'monospace', 
                    fontSize: 12
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ✅ Jika _isReady true, load aplikasi utama beserta semua Provider-nya
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameProvider()),
        ChangeNotifierProvider(create: (_) => MusicProvider()),
      ],
      child: const MyApp(),
    );
  }
}

// ============================================================================
// APLIKASI UTAMA (GATEWAY & ROUTING)
// ============================================================================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: themeModeNotifier,
      builder: (context, modeIndex, child) {
        final currentTheme = AppTheme.currentTheme;

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'OXIDE APPS',
          theme: currentTheme,
          initialRoute: '/',
          
          // 🎵 GLOBAL MINI PLAYER (Menempel di semua rute)
          builder: (context, child) {
            return Stack(
              children: [
                if (child != null) child,
                const GlobalMiniPlayer(), 
              ],
            );
          },

          // 🚦 ROUTING / GATEWAY
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/':
                return MaterialPageRoute(builder: (_) => LandingPage());
              case '/login':
                return MaterialPageRoute(builder: (_) => const LoginPage());
              case '/dashboard':
                final args = settings.arguments as Map<String, dynamic>;
                return MaterialPageRoute(
                  builder: (_) => DashboardPage(
                    userId: args['userId'] ?? "000000",
                    level: args['level'] ?? "1",
                    username: args['username'] ?? "",
                    password: args['password'] ?? "",
                    role: args['role'] ?? "",
                    sessionKey: args['key'] ?? args['sessionKey'] ?? "",
                    expiredDate: args['expiredDate'] ?? "",
                    listBug: List<Map<String, dynamic>>.from(args['listBug'] ?? []),
                    listSpam: List<Map<String, dynamic>>.from(args['listSpam'] ?? []),
                    listGb: List<Map<String, dynamic>>.from(args['listGb'] ?? []),
                    listDoos: List<Map<String, dynamic>>.from(args['listDoos'] ?? []),
                    news: List<dynamic>.from(args['news'] ?? []),
                  ),
                );

              case '/home':
                final args = settings.arguments as Map<String, dynamic>;
                return MaterialPageRoute(
                  builder: (_) => BugModulePage(
                    username: args['username'] ?? "",
                    password: args['password'] ?? "",
                    sessionKey: args['sessionKey'] ?? "",
                    listBug: List<Map<String, dynamic>>.from(args['listBug'] ?? []),
                    listSpam: List<Map<String, dynamic>>.from(args['listSpam'] ?? []),
                    listGb: List<Map<String, dynamic>>.from(args['listGb'] ?? []),
                    role: args['role'] ?? "",
                    expiredDate: args['expiredDate'] ?? "",
                  ),
                );

              case '/seller':
                final args = settings.arguments as Map<String, dynamic>;
                return MaterialPageRoute(
                  builder: (_) => SellerPage(
                    keyToken: args['keyToken'] ?? "",
                  ),
                );

              case '/admin':
                final args = settings.arguments as Map<String, dynamic>;
                return MaterialPageRoute(
                  builder: (_) => AdminPage(
                    sessionKey: args['sessionKey'] ?? "",
                  ),
                );

              case '/owner':
                final args = settings.arguments as Map<String, dynamic>;
                return MaterialPageRoute(
                  builder: (_) => OwnerPage(
                    sessionKey: args['sessionKey'] ?? "",
                    username: args['username'] ?? "",
                  ),
                );

              default:
                return MaterialPageRoute(
                  builder: (_) => const Scaffold(
                    body: Center(
                      child: Text("404 - Not Found"),
                    ),
                  ),
                );
            }
          },
        );
      },
    );
  }
}
