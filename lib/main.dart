// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Import BLoC
import 'screens/home_screen.dart';
import 'services/database_service.dart';
import 'blocs/audio_player/audio_player_bloc.dart'; // Import BLoC
import 'blocs/download/download_bloc.dart'; // Import BLoC
import 'blocs/navigation/navigation_bloc.dart'; // Import BLoC

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.init();

  runApp(
    MultiBlocProvider(
      // Use MultiBlocProvider to provide multiple BLoCs
      providers: [
        BlocProvider(create: (context) => NavigationBloc()),
        BlocProvider(
          create: (context) => DownloadBloc(databaseService: DatabaseService()),
        ),
        BlocProvider(
          create: (context) => AudioPlayerBloc(
            databaseService: DatabaseService(),
            downloadBloc: context.read<DownloadBloc>(), // Access DownloadBloc
          ),
        ),
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
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}
