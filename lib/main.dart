import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart'; 
import 'package:audio_service/audio_service.dart';
import 'audio_handler.dart';    

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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Api.loadGh();
  await AppTheme.init();
  
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
    return ValueListenableBuilder<int>(
      valueListenable: themeModeNotifier,
      builder: (context, modeIndex, child) {
        final currentTheme = AppTheme.currentTheme;

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'OXIDE APPS',
          theme: currentTheme,
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
                    username: args['username'] ?? "",
                    password: args['password'] ?? "",
                    role: args['role'] ?? "",
                    sessionKey: args['key'] ?? args['sessionKey'] ?? "",
                    expiredDate: args['expiredDate'] ?? "",
                    listBug: List<Map<String, dynamic>>.from(args['listBug'] ?? []),
                    listSpam: List<Map<String, dynamic>>.from(args['listSpam'] ?? []),
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
