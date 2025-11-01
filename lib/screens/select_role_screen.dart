import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../app_shell.dart';
import 'tps_home_screen.dart';

class SelectRoleScreen extends StatefulWidget {
  const SelectRoleScreen({super.key});

  @override
  State<SelectRoleScreen> createState() => _SelectRoleScreenState();
}

class _SelectRoleScreenState extends State<SelectRoleScreen> {
  bool _isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // SiBersih Color Palette
  static const Color _primaryEmerald = Color(0xFF10B981);
  static const Color _darkEmerald = Color(0xFF047857);
  static const Color _lightEmerald = Color(0xFF34D399);
  static const Color _tealAccent = Color(0xFF14B8A6);
  static const Color _ultraLightEmerald = Color(0xFFECFDF5);
  static const Color _pureWhite = Color(0xFFFFFFFF);
  static const Color _background = Color(0xFFF8FDFD);

  Future<void> _selectRole(String role) async {
    setState(() => _isLoading = true);

    try {
      final User? user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).update({'role': role});

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => role == 'Masyarakat'
                ? const AppNavigation()
                : const TpsHomeScreen(),
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
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Logo & Header Section
              Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: _pureWhite,
                  borderRadius: BorderRadius.circular(20.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _ultraLightEmerald,
                        borderRadius: BorderRadius.circular(20.0),
                        border: Border.all(
                          color: _primaryEmerald.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.people_alt_rounded,
                        size: 40,
                        color: _primaryEmerald,
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    Text(
                      'Satu Langkah Lagi!',
                      style: TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.w700,
                        color: _darkEmerald,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'Bantu kami mengenalimu lebih baik',
                      style: TextStyle(
                        fontSize: 16.0,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32.0),

              // Role Selection Cards
              if (_isLoading)
                Container(
                  padding: const EdgeInsets.all(40.0),
                  decoration: BoxDecoration(
                    color: _pureWhite,
                    borderRadius: BorderRadius.circular(20.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _primaryEmerald,
                        ),
                      ),
                      const SizedBox(height: 20.0),
                      Text(
                        'Menyimpan pilihan...',
                        style: TextStyle(
                          fontSize: 16.0,
                          color: _darkEmerald,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: [
                    // Masyarakat Card
                    Container(
                      margin: const EdgeInsets.only(bottom: 20.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.0),
                        boxShadow: [
                          BoxShadow(
                            color: _primaryEmerald.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _selectRole('Masyarakat'),
                          borderRadius: BorderRadius.circular(20.0),
                          child: Container(
                            padding: const EdgeInsets.all(24.0),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_primaryEmerald, _tealAccent],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12.0),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  child: Icon(
                                    Icons.people_outline_rounded,
                                    color: _pureWhite,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(width: 16.0),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Masyarakat',
                                        style: TextStyle(
                                          fontSize: 18.0,
                                          fontWeight: FontWeight.w700,
                                          color: _pureWhite,
                                        ),
                                      ),
                                      const SizedBox(height: 4.0),
                                      Text(
                                        'Pengguna biasa yang ingin mengelola sampah dan berpartisipasi dalam program kebersihan',
                                        style: TextStyle(
                                          fontSize: 13.0,
                                          color: _pureWhite.withOpacity(0.9),
                                          height: 1.4,
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: _pureWhite.withOpacity(0.8),
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // TPS Card
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _selectRole('TPS'),
                          borderRadius: BorderRadius.circular(20.0),
                          child: Container(
                            padding: const EdgeInsets.all(24.0),
                            decoration: BoxDecoration(
                              color: _pureWhite,
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12.0),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  child: Icon(
                                    Icons.local_shipping_rounded,
                                    color: Colors.blue,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(width: 16.0),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Petugas TPS',
                                        style: TextStyle(
                                          fontSize: 18.0,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.blue[800],
                                        ),
                                      ),
                                      const SizedBox(height: 4.0),
                                      Text(
                                        'Petugas Tempat Pembuangan Sementara yang mengelola penjemputan dan pengolahan sampah',
                                        style: TextStyle(
                                          fontSize: 13.0,
                                          color: Colors.grey[700],
                                          height: 1.4,
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: Colors.grey[600],
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 40.0),

              // Info Text
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: _ultraLightEmerald,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: _primaryEmerald.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: _primaryEmerald,
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Text(
                        'Pilihan ini akan menentukan fitur yang tersedia untuk Anda',
                        style: TextStyle(
                          fontSize: 13.0,
                          color: _darkEmerald,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
