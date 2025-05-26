import 'package:bullbearnews/connectivity_service.dart';
import 'package:bullbearnews/models/news_model.dart';
import 'package:bullbearnews/screens/home/home_screen.dart';
import 'package:bullbearnews/services/local_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'firebase_options.dart';
import 'screens/auth/auth_wrapper.dart';
import 'providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive ve Firebase başlatma
  await _initializeApp();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
      ],
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
    try {
      await Hive.deleteBoxFromDisk('savedNews');
      await LocalStorageService.init();
    } catch (e) {
      print('Recovery failed: $e');
    }
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _checkConnection();
    ConnectivityService.connectivityStream.listen((result) {
      // ignore: unrelated_type_equality_checks
      _updateConnectionStatus(result != ConnectivityResult.none);
    });
  }

  Future<void> _checkConnection() async {
    final isConnected = await ConnectivityService.isConnected();
    _updateConnectionStatus(isConnected);
  }

  void _updateConnectionStatus(bool isOnline) {
    if (mounted) {
      setState(() => _isOnline = isOnline);
      if (!isOnline) {
        Fluttertoast.showToast(
          msg: "You are offline. Some features may not be available.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
          timeInSecForIosWeb: 2,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'BullBearNews',
      debugShowCheckedModeBanner: false,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: themeProvider.themeMode,
      home: AuthWrapper(showOfflineBanner: !_isOnline),
      routes: {
        '/home': (context) => HomeScreen(),
        '/auth': (context) => AuthWrapper(),
      },
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.grey[400],
      colorScheme: ColorScheme.light(
        primary: Colors.purple[300]!,
        secondary: Colors.purpleAccent[100]!,
        background: Colors.grey[100]!,
        primaryContainer: Colors.grey[400]!,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData.dark().copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.grey[900],
      colorScheme: ColorScheme.dark(
        primary: Colors.purple[800]!,
        secondary: Colors.purpleAccent[700]!,
        background: Colors.grey[900]!,
        primaryContainer: Colors.grey[800]!,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
    );
  }
}
