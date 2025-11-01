import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../app_shell.dart';
import 'tps_home_screen.dart'; // Akan kita buat
import 'select_role_screen.dart'; // Akan kita buat

class RoleDispatcher extends StatelessWidget {
  final User user;
  const RoleDispatcher({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    // FutureBuilder digunakan untuk mengambil data 'satu kali' dari Firestore
    return FutureBuilder<DocumentSnapshot>(
      // Ambil dokumen user dari koleksi 'users' berdasarkan uid
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get(),
      builder: (context, snapshot) {
        // 1. Saat sedang loading data
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. Jika terjadi error
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        // 3. Jika data tidak ada (seharusnya tidak terjadi jika register benar)
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            body: Center(child: Text('Data pengguna tidak ditemukan.')),
          );
        }

        // 4. JIKA DATA DITEMUKAN
        // Ambil datanya sebagai Map
        final data = snapshot.data!.data() as Map<String, dynamic>;
        final String? role = data['role']; // Ambil role

        if (role == 'Masyarakat') {
          // Arahkan ke Dashboard Masyarakat (AppNavigation)
          // Sebaiknya AppNavigation dipindah ke file sendiri, misal 'app_shell.dart'
          // Untuk saat ini, kita panggil dari 'main.dart' (dengan asumsi masih di sana)
          return const AppNavigation();
        } else if (role == 'TPS') {
          // Arahkan ke Dashboard TPS
          return const TpsHomeScreen();
        } else if (role == null) {
          // (PENGGUNA GOOGLE BARU) Arahkan ke halaman pilih role
          return const SelectRoleScreen();
        } else {
          // Fallback jika role tidak dikenali
          return const Scaffold(
            body: Center(child: Text('Peran tidak dikenali.')),
          );
        }
      },
    );
  }
}
