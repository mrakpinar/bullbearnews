// ignore: depend_on_referenced_packages
// import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:bullbearnews/connectivity_service.dart';
import 'package:bullbearnews/constants/colors.dart';
import 'package:bullbearnews/models/news_model.dart';
import 'package:bullbearnews/screens/auth/email_verification_screen.dart';
import 'package:bullbearnews/screens/home/home_screen.dart';
import 'package:bullbearnews/services/local_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'firebase_options.dart';
import 'screens/auth/auth_wrapper.dart';
import 'providers/theme_provider.dart';
import 'services/push_notification_service.dart';
import 'utils/notification_navigation_handler.dart';

// Top-level function for background message handling
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Handling a background message: ${message.messageId}');
  print('Background message data: ${message.data}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // FlutterNativeSplash.preserve(
  //     widgetsBinding: WidgetsFlutterBinding.ensureInitialized());

  // Initialize Firebase first
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Set background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize other services
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
    // Hive initialization
    await Hive.initFlutter();
    Hive.registerAdapter(NewsModelAdapter());
    await LocalStorageService.init();

    // Initialize Push Notifications
    await PushNotificationService.initialize();

    print('App initialization completed successfully');
  } catch (e) {
    print('Initialization error: $e');
    try {
      await Hive.deleteBoxFromDisk('savedNews');
      await LocalStorageService.init();

      // Retry push notification initialization
      await PushNotificationService.initialize();
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
    _setupPushNotifications();

    ConnectivityService.connectivityStream.listen((result) {
      // ignore: unrelated_type_equality_checks
      _updateConnectionStatus(result != ConnectivityResult.none);
    });

    // FlutterNativeSplash.remove();
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

  void _setupPushNotifications() async {
    try {
      // Request permissions
      await PushNotificationService.requestPermission();

      // Handle initial message when app is opened from notification
      RemoteMessage? initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        print('App opened from notification: ${initialMessage.data}');
        // Wait a bit for the app to fully load
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          await NotificationNavigationHandler.handleNotificationTap(
              initialMessage.data);
        }
      }

      // Handle message when app is in background and user taps on notification
      FirebaseMessaging.onMessageOpenedApp.listen((message) async {
        print('Notification tapped while app in background: ${message.data}');
        if (mounted) {
          await NotificationNavigationHandler.handleNotificationTap(
              message.data);
        }
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Received a message while app is in foreground!');
        print('Message data: ${message.data}');

        if (message.notification != null) {
          print('Message notification: ${message.notification!.title}');
          print('Message body: ${message.notification!.body}');
        }
      });

      print('Push notifications setup completed');
    } catch (e) {
      print('Error setting up push notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'BullBearNews',
      debugShowCheckedModeBanner: false,
      navigatorKey:
          NotificationNavigationHandler.navigatorKey, // Add navigator key
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: themeProvider.themeMode,
      home: AuthWrapper(showOfflineBanner: !_isOnline),
      routes: {
        '/home': (context) => HomeScreen(),
        '/main': (context) => AuthWrapper(), // Bu satırı ekleyin
        '/email-verification': (context) => EmailVerificationScreen(),
        '/auth': (context) => AuthWrapper(),
      },
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        background: AppColors.lightBackground,
        surface: AppColors.whiteText,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onBackground: AppColors.darkText,
        onSurface: AppColors.darkText,
        tertiary: AppColors.lightBackground,
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightCard,
        elevation: 2,
        margin: EdgeInsets.all(8),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.dividerLight,
        thickness: 1,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData.dark().copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        background: AppColors.darkBackground,
        surface: AppColors.whiteText,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onBackground: AppColors.lightText,
        onSurface: AppColors.lightText,
        tertiary: AppColors.lightBackground,
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 2,
        margin: EdgeInsets.all(8),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.dividerDark,
        thickness: 1,
      ),
    );
  }
}
