import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'firebase_options.dart';
import 'screens/customer_login.dart';
import 'theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Google Sign-In 
  if (!kIsWeb) {
    await GoogleSignIn.instance.initialize(
      serverClientId:
          '409583834407-tht899lmle1vvcf3n1m0qbb7vjf6r3ed.apps.googleusercontent.com',
    );
  }

  runApp(const DinelyApp());
}

class DinelyApp extends StatelessWidget {
  const DinelyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dinely',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.cream,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          background: AppColors.cream,
        ),
      ),
      home: const CustomerLoginScreen(),
    );
  }
}