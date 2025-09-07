import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'services/database_service.dart';
import 'controllers/audio_player_controller.dart';
import 'controllers/download_controller.dart';
import 'controllers/navigation_controller.dart';
import 'widgets/mini_player.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.init();

  Get.put(DatabaseService());
  Get.put(DownloadController());
  Get.put(AudioPlayerController());
  Get.put(NavigationController());

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
        fontFamily:
            'Inter', // Consider adding a font like Inter for a clean look
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          secondary: Colors.white,
          surface: Colors.black,
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final navController = Get.find<NavigationController>();
    const double miniPlayerHeight = 70.0;

    return Obx(
      () => Scaffold(
        extendBodyBehindAppBar:
            true, // Allows content to go behind the glass app bar
        appBar: AppBar(
          backgroundColor: Colors.black.withOpacity(0.3),
          elevation: 0,
          title: Text(
            navController.isSearchVisible.value ? 'Search' : 'Library',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ).animate().fade(duration: 300.ms),
          leading: navController.isSearchVisible.value
              ? IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                  ),
                  onPressed: () => navController.showHome(),
                )
              : null,
        ),
        body: Stack(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: navController.isSearchVisible.value
                  ? const SearchScreen()
                  : const HomeScreen(),
            ),
            const Positioned(bottom: 0, left: 0, right: 0, child: MiniPlayer()),
          ],
        ),
        floatingActionButton: navController.isSearchVisible.value
            ? null
            : Padding(
                padding: const EdgeInsets.only(bottom: miniPlayerHeight),
                child: FloatingActionButton(
                  backgroundColor: Colors.white.withOpacity(0.9),
                  foregroundColor: Colors.black,
                  elevation: 10,
                  child: const Icon(Icons.search),
                  onPressed: () {
                    navController.showSearch();
                  },
                ).animate().scale(delay: 300.ms),
              ),
      ),
    );
  }
}
