import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'onboarding_check.dart';

// --- (BARU) Impor untuk inisialisasi tanggal ---
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // --- (BARU) Inisialisasi format tanggal Indonesia ---
  // Ini akan memperbaiki error LocaleDataException
  await initializeDateFormatting('id_ID', null);
  // --------------------------------------------------
  
  runApp(const EcoManageApp());
}

class EcoManageApp extends StatelessWidget {
  const EcoManageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SiBersih',
      
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      
      home: const OnboardingCheck(),
      
      debugShowCheckedModeBanner: false,
    );
  }
}