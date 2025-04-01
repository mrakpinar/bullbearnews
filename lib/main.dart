import 'package:bullbearnews/models/news_model.dart';
import 'package:bullbearnews/services/local_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/auth/auth_wrapper.dart';
import 'providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive ve Firebase başlatma
  await _initializeApp();

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

Future<void> _initializeApp() async {
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    await Hive.initFlutter();
    Hive.registerAdapter(NewsModelAdapter());
    await LocalStorageService.init();
  } catch (e) {
    print('Initialization error: $e');
    // Hata durumunda box'ı temizle ve yeniden dene
    try {
      await Hive.deleteBoxFromDisk('savedNews');
      await LocalStorageService.init();
    } catch (e) {
      print('Recovery failed: $e');
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'BullBearNews',
      debugShowCheckedModeBanner: false,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: themeProvider.themeMode,
      home: AuthWrapper(),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      // Light tema ayarları
      colorScheme: ColorScheme.light(
        primary: Colors.purple,
        secondary: Colors.purpleAccent,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData.dark().copyWith(
      // Dark tema ayarları
      colorScheme: ColorScheme.dark(
        primary: Colors.purple,
        secondary: Colors.purpleAccent,
      ),
    );
  }
}
