import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io';
// Tambahkan library provider di paling atas
import 'package:provider/provider.dart'; 
import 'package:audio_service/audio_service.dart';
import 'audio_handler.dart';    

import 'login_page.dart';
import 'dashboard_page.dart';
import 'home_page.dart';
import 'seller_page.dart';
import 'admin_page.dart';
import 'staff_page.dart';
import 'dev_page.dart';
import 'owner_page.dart';
import 'landing.dart';
import 'btrapps/.dart';

// IMPORT FILE GAME BARU KAMU DI SINI
import 'game/game_provider.dart';
import 'game/game_screen.dart';

// Variable Global agar Handler bisa diakses dari mana saja
AudioHandler? globalAudioHandler;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Api.loadGh();
  try {
    globalAudioHandler = await initAudioService().timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        debugPrint("⚠️ AudioService init timeout, melanjutkan buka aplikasi...");
        return null as AudioHandler;
      },
    );
  } catch (e) {
    debugPrint("⚠️ Gagal inisialisasi AudioService: $e");
  }
  
  // BUNGKUS MyApp DENGAN MULTIPROVIDER AGAR STATE GAME JALAN
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PRIKITIWW APPS',
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'ShareTechMono',
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark().copyWith(
          secondary: const Color(0xFF2196F3),
        ),
      ),
      initialRoute: '/',
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
                username: args['username'],
                password: args['password'],
                role: args['role'],
                sessionKey: args['key'],
                expiredDate: args['expiredDate'],
                listBug: List<Map<String, dynamic>>.from(args['listBug'] ?? []),
                listDoos: List<Map<String, dynamic>>.from(args['listDoos'] ?? []),
                news: List<Map<String, dynamic>>.from(args['news'] ?? []),
              ),
            );

          case '/home':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => HomePage(
                username: args['username'],
                password: args['password'],
                listBug: List<Map<String, dynamic>>.from(args['listBug'] ?? []),
                role: args['role'],
                expiredDate: args['expiredDate'],
                sessionKey: args['sessionKey'],
              ),
            );

          case '/seller':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => SellerPage(
                keyToken: args['keyToken'],
              ),
            );

          case '/admin':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => AdminPage(
                sessionKey: args['sessionKey'],
              ),
            );

          case '/owner':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => OwnerPage(
                sessionKey: args['sessionKey'],
                username: args['username'],
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
  }
}
