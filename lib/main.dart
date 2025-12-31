import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'package:google_fonts/google_fonts.dart';
import 'screens/dashboard_screen.dart';
// import 'services/notification_service.dart';
import 'firebase_options.dart'; 
import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Try to initialize Firebase using DefaultFirebaseOptions if available
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully.');
  } catch (e) {
    debugPrint('Firebase init failed (Likely missing API Key or Config): $e');
    debugPrint('Falling back to MOCK data.');
    DatabaseService.enableMock();
  }

  // Initialize Notifications
  /*
  final notificationService = NotificationService();
  try {
    await notificationService.init();
    await notificationService.scheduleDailyMorningNotification();
  } catch (e) {
    debugPrint('Notification init failed: $e');
  }
  */

  runApp(const AJStocksApp());
}

class AJStocksApp extends StatelessWidget {
  const AJStocksApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AJ Stocks',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          primary: Colors.teal,
          secondary: Colors.orangeAccent,
        ),
        useMaterial3: true,
        // textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const DashboardScreen(),
    );
  }
}
