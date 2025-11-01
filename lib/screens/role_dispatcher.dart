import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../app_shell.dart';
import 'tps_home_screen.dart';
import 'select_role_screen.dart';

class RoleDispatcher extends StatelessWidget {
  final User user;
  const RoleDispatcher({super.key, required this.user});

  // SiBersih Color Palette
  static const Color _primaryEmerald = Color(0xFF10B981);
  static const Color _darkEmerald = Color(0xFF047857);
  static const Color _ultraLightEmerald = Color(0xFFECFDF5);
  static const Color _pureWhite = Color(0xFFFFFFFF);
  static const Color _background = Color(0xFFF8FDFD);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get(),
      builder: (context, snapshot) {
        // Loading State
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen(context);
        }

        // Error State
        if (snapshot.hasError) {
          return _buildErrorScreen(context, snapshot.error.toString());
        }

        // Data Not Found
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _buildDataNotFoundScreen(context);
        }

        // Data Found - Process Role
        final data = snapshot.data!.data() as Map<String, dynamic>;
        final String? role = data['role'];

        return _handleRoleNavigation(context, role, data);
      },
    );
  }

  Widget _buildLoadingScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _pureWhite,
                borderRadius: BorderRadius.circular(20.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _primaryEmerald,
                      ),
                      strokeWidth: 3,
                    ),
                  ),
                  Center(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _ultraLightEmerald,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Icon(
                        Icons.eco_rounded,
                        color: _primaryEmerald,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24.0),
            Text(
              'Memuat...',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.w600,
                color: _darkEmerald,
              ),
            ),
            const SizedBox(height: 8.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Text(
                'Menyiapkan pengalaman terbaik untuk Anda',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.0, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(BuildContext context, String error) {
    return Scaffold(
      backgroundColor: _background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: _pureWhite,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 24.0),
              Text(
                'Terjadi Kesalahan',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.w700,
                  color: _darkEmerald,
                ),
              ),
              const SizedBox(height: 12.0),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  'Maaf, terjadi masalah saat memuat data Anda',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15.0, color: Colors.grey[600]),
                ),
              ),
              const SizedBox(height: 8.0),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  error,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.0,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 32.0),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryEmerald.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    // Try to rebuild the widget
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => RoleDispatcher(user: user),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryEmerald,
                    foregroundColor: _pureWhite,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 16.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                  ),
                  child: const Text(
                    'Coba Lagi',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataNotFoundScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: _pureWhite,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.person_off_rounded,
                  size: 48,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 24.0),
              Text(
                'Data Tidak Ditemukan',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.w700,
                  color: _darkEmerald,
                ),
              ),
              const SizedBox(height: 12.0),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  'Data pengguna tidak ditemukan dalam sistem.\nSilakan daftar ulang atau hubungi administrator.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15.0, color: Colors.grey[600]),
                ),
              ),
              const SizedBox(height: 32.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryEmerald.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        FirebaseAuth.instance.signOut();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryEmerald,
                        foregroundColor: _pureWhite,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20.0,
                          vertical: 12.0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      child: const Text('Keluar'),
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

  Widget _buildUnknownRoleScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: _pureWhite,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  size: 48,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(height: 24.0),
              Text(
                'Peran Tidak Dikenali',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.w700,
                  color: _darkEmerald,
                ),
              ),
              const SizedBox(height: 12.0),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  'Peran akun Anda tidak dikenali oleh sistem.\nSilakan hubungi administrator untuk bantuan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15.0, color: Colors.grey[600]),
                ),
              ),
              const SizedBox(height: 32.0),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryEmerald.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    FirebaseAuth.instance.signOut();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryEmerald,
                    foregroundColor: _pureWhite,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 16.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                  ),
                  child: const Text(
                    'Keluar & Login Ulang',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _handleRoleNavigation(
    BuildContext context,
    String? role,
    Map<String, dynamic> data,
  ) {
    switch (role) {
      case 'Masyarakat':
        return const AppNavigation();
      case 'TPS':
        return const TpsHomeScreen();
      case null:
        return const SelectRoleScreen();
      default:
        return _buildUnknownRoleScreen(context);
    }
  }
}
