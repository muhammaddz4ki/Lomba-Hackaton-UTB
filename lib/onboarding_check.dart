import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_gate.dart';
import 'onboarding_screen.dart';

class OnboardingCheck extends StatefulWidget {
  const OnboardingCheck({super.key});

  @override
  State<OnboardingCheck> createState() => _OnboardingCheckState();
}

class _OnboardingCheckState extends State<OnboardingCheck> {
  late Future<bool> _hasSeenOnboarding;

  @override
  void initState() {
    super.initState();
    _hasSeenOnboarding = _checkOnboardingStatus();
  }

  // Fungsi untuk mengecek SharedPreferences
  Future<bool> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    // Kembalikan 'true' jika 'hasSeenOnboarding' ada,
    // atau 'false' jika tidak ada (null)
    return prefs.getBool('hasSeenOnboarding') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    // Gunakan FutureBuilder untuk menunggu hasil pengecekan
    return FutureBuilder<bool>(
      future: _hasSeenOnboarding,
      builder: (context, snapshot) {
        // 1. Saat sedang mengecek...
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. Jika sudah selesai mengecek
        if (snapshot.hasData) {
          final bool hasSeen = snapshot.data!;
          if (hasSeen) {
            // 2a. JIKA SUDAH LIHAT -> langsung ke Login
            return const AuthGate();
          } else {
            // 2b. JIKA BELUM LIHAT -> tampilkan Onboarding
            return const OnboardingScreen();
          }
        }

        // 3. Jika ada error (jarang terjadi)
        return const Scaffold(body: Center(child: Text('Error memuat data.')));
      },
    );
  }
}
