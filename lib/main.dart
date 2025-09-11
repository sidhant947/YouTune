// lib/main.dart
import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart'; // Remove if not used elsewhere now
import 'package:get/get.dart';
import 'screens/home_screen.dart'; // Import HomeScreen directly
// import 'screens/search_screen.dart'; // Not needed directly here anymore
import 'services/database_service.dart';
import 'controllers/audio_player_controller.dart';
import 'controllers/download_controller.dart';
// Remove import for navigation_controller.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.init();
  Get.put(DatabaseService());
  Get.put(DownloadController());
  Get.put(AudioPlayerController());
  // Remove Get.put for NavigationController
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Youtune',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.white,
        fontFamily: 'Inter',
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          secondary: Colors.white,
          surface: Colors.black,
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(), // Set HomeScreen directly as home
    );
  }
}
