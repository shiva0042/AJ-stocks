import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/dashboard_screen.dart';
import 'services/notification_service.dart';
import 'firebase_options.dart'; 
import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  String? initError;
  try {
    // Check if Firebase is already initialized (by native plugin)
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('Firebase initialized explicitly.');
    } else {
      debugPrint('Firebase already initialized by native plugin.');
    }
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
       debugPrint('Firebase ignored duplicate initialization.');
    } else {
       debugPrint('Firebase init failed: $e');
       debugPrint('Falling back to MOCK data.');
       initError = e.toString();
       DatabaseService.enableMock();
    }
  }

  // Initialize Notifications (do NOT schedule on startup - wait for user to set time)
  try {
     final notificationService = NotificationService();
     await notificationService.init();
     // Request permission (important for Android 13+)
     await notificationService.requestPermissions();
     debugPrint('Notification service initialized (not scheduling on startup).');
  } catch (e) {
     debugPrint('Notification init failed: $e');
  }

  runApp(AJStocksApp(initError: initError));
}

class AJStocksApp extends StatelessWidget {
  final String? initError;
  const AJStocksApp({super.key, this.initError});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AJ Stocks',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F6F8),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4C4DDC),
          primary: const Color(0xFF4C4DDC),
          secondary: const Color(0xFF00D2B6),
          tertiary: const Color(0xFFFF8A65),
          surface: Colors.white,
          background: const Color(0xFFF4F6F8),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF4C4DDC),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        // cardTheme: CardTheme(
        //   elevation: 0,
        //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        //   color: Colors.white,
        //   surfaceTintColor: Colors.white,
        // ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4C4DDC),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF4C4DDC), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
      home: DashboardScreen(initError: initError),
    );
  }
}
