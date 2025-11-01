import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'screens/auth_screen.dart';
import 'screens/role_dispatcher.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // StreamBuilder adalah widget yang "mendengarkan" perubahan
    // Di sini, ia mendengarkan perubahan status login dari Firebase Auth
    return StreamBuilder<User?>(
      // FirebaseAuth.instance.authStateChanges() adalah stream-nya
      // Ia akan mengirim 'null' jika logout, atau 'User' jika login
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Jika masih menunggu koneksi (jarang terjadi di sini)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. Jika snapshot punya data (artinya 'user' tidak null -> SUDAH LOGIN)
        if (snapshot.hasData) {
          // Kirim ke RoleDispatcher untuk dicek perannya
          // Kita kirim User object-nya agar tahu uid-nya
          return RoleDispatcher(user: snapshot.data!);
        }

        // 3. Jika snapshot tidak punya data (artinya 'user' adalah null -> BELUM LOGIN)
        return const AuthScreen();
      },
    );
  }
}
