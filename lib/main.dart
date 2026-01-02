import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'package:google_fonts/google_fonts.dart';
import 'screens/dashboard_screen.dart';
// import 'services/notification_service.dart';
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          primary: Colors.teal,
          secondary: Colors.orangeAccent,
        ),
        useMaterial3: true,
      ),
      home: DashboardScreen(initError: initError),
    );
  }
}
