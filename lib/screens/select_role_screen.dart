import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../app_shell.dart';
import 'tps_home_screen.dart'; // Lokasi TpsHomeScreen (TPS)

class SelectRoleScreen extends StatefulWidget {
  const SelectRoleScreen({super.key});

  @override
  State<SelectRoleScreen> createState() => _SelectRoleScreenState();
}

class _SelectRoleScreenState extends State<SelectRoleScreen> {
  bool _isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _selectRole(String role) async {
    setState(() => _isLoading = true);

    try {
      final User? user = _auth.currentUser;
      if (user == null) return; // Seharusnya tidak terjadi

      // Update dokumen user di Firestore dengan role yang dipilih
      await _firestore.collection('users').doc(user.uid).update({'role': role});

      // Navigasi manual ke dashboard yang sesuai
      if (mounted) {
        // 'pushReplacement' mengganti halaman ini agar pengguna tidak bisa 'back'
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => role == 'Masyarakat'
                ? const AppNavigation() // Ke dashboard Masyarakat
                : const TpsHomeScreen(), // Ke dashboard TPS
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih peran: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Satu Langkah Lagi!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16.0),
              const Text(
                'Bantu kami mengenalimu. Kamu mendaftar sebagai siapa?',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32.0),

              if (_isLoading)
                const CircularProgressIndicator()
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Tombol Masyarakat
                    ElevatedButton(
                      onPressed: () => _selectRole('Masyarakat'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                      ),
                      child: const Text(
                        'Saya Masyarakat',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 16.0),

                    // Tombol TPS
                    ElevatedButton(
                      onPressed: () => _selectRole('TPS'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                      ),
                      child: const Text(
                        'Saya Petugas/TPS',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
