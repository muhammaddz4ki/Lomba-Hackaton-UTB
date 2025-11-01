import 'package:flutter/material.dart';
import 'tps_incoming_screen.dart';
import 'tps_in_progress_screen.dart';
import 'tps_deposit_approval_screen.dart';
import 'tps_schedule_management_screen.dart';
import 'tps_history_screen.dart';
import 'profile_screen.dart';

class TpsHomeScreen extends StatefulWidget {
  const TpsHomeScreen({super.key});

  @override
  State<TpsHomeScreen> createState() => _TpsHomeScreenState();
}

class _TpsHomeScreenState extends State<TpsHomeScreen> {
  // SETEL INDEKS AWAL KE 2 (TpsIncomingScreen) agar menjadi layar default.
  int _selectedIndex = 2;

  // SiBersih Color Palette
  static const Color _primaryEmerald = Color(0xFF10B981);
  static const Color _darkEmerald = Color(0xFF047857);
  static const Color _lightEmerald = Color(0xFF34D399);
  static const Color _tealAccent = Color(0xFF14B8A6);
  static const Color _ultraLightEmerald = Color(0xFFECFDF5);
  static const Color _pureWhite = Color(0xFFFFFFFF);
  static const Color _background = Color(0xFFF8FDFD);
  static const Color _urgentColor = Color(0xFFDC2626); // Tambahkan warna urgent

  // DAFTAR LAYAR SESUAI URUTAN BOTTOM NAV BAR (tanpa index 2 yang dipisahkan)
  // Urutan: 0:Dikerjakan, 1:Setoran, 2:Darurat, 3:Jadwal, 4:Rekap
  static const List<Widget> _widgetOptions = <Widget>[
    TpsInProgressScreen(),
    TpsDepositApprovalScreen(),
    TpsIncomingScreen(), // Index 2: Permintaan Darurat
    TpsScheduleManagementScreen(),
    TpsHistoryScreen(),
  ];

  void _onItemTapped(int index) {
    // Navigasi yang diperbarui.
    // Index 2 sekarang langsung masuk ke TpsIncomingScreen.
    setState(() {
      _selectedIndex = index;
    });
  }

  // Hapus _openEmergencyScreen karena sekarang ditangani oleh _onItemTapped
  // void _openEmergencyScreen() { ... }

  String get _appBarTitle {
    switch (_selectedIndex) {
      case 0:
        return 'Sedang Dikerjakan';
      case 1:
        return 'Setoran Bank Sampah';
      case 2:
        return 'Permintaan Darurat'; // Judul untuk layar default yang baru
      case 3:
        return 'Kelola Jadwal Umum';
      case 4:
        return 'Riwayat & Rekap';
      default:
        return 'Dashboard TPS';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: Text(
          _appBarTitle,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: _pureWhite,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryEmerald, _tealAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: _primaryEmerald.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        foregroundColor: _pureWhite,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8.0),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: IconButton(
              icon: const Icon(Icons.person_outline, size: 22),
              tooltip: 'Profil Saya',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Center(
        // Cukup tampilkan widget pada _selectedIndex
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _urgentColor.withOpacity(0.4), // Gunakan _urgentColor
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: _urgentColor.withOpacity(0.3), // Gunakan _urgentColor
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: FloatingActionButton(
          shape: const CircleBorder(),
          // Langsung ganti index ke 2 (Incoming/Darurat)
          onPressed: () => _onItemTapped(2),
          tooltip: 'Permintaan Darurat',
          elevation: 0,
          backgroundColor: _urgentColor, // Gunakan _urgentColor
          foregroundColor: _pureWhite,
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.emergency_outlined, size: 24),
              SizedBox(height: 2),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _pureWhite,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomAppBar(
          color: Colors.transparent,
          elevation: 0,
          height: 70,
          padding: EdgeInsets.zero,
          surfaceTintColor: Colors.transparent,
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBottomNavItem(
                  icon: Icons.directions_run_outlined,
                  label: 'Dikerjakan',
                  index: 0,
                ),
                _buildBottomNavItem(
                  icon: Icons.recycling_outlined,
                  label: 'Setoran',
                  index: 1,
                ),
                const SizedBox(width: 50.0), // Spacer untuk FAB
                _buildBottomNavItem(
                  icon: Icons.calendar_month_outlined,
                  label: 'Jadwal',
                  index: 3,
                ),
                _buildBottomNavItem(
                  icon: Icons.history_edu_outlined,
                  label: 'Rekap',
                  index: 4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    // Periksa apakah item yang dipilih adalah Permintaan Darurat (index 2)
    // Walaupun index 2 tidak ada di baris nav item utama, FAB akan mengarahkan ke sana.
    // Kita cek jika _selectedIndex adalah 2, kita ingin FAB terlihat 'terpilih'.
    final bool isSelected = _selectedIndex == index;
    final bool isFabSelected = _selectedIndex == 2 && index == 2;

    // Untuk memastikan indikator terpilih berfungsi pada item Darurat (index 2)
    // saat diklik via FAB, kita akan membuat item Darurat (index 2) secara implisit
    // terwakili oleh FAB, tapi untuk BottomNavItem ini, kita tetap menggunakan
    // index 0, 1, 3, 4. Kita tidak perlu membuat nav item untuk index 2 di sini.

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onItemTapped(index),
          borderRadius: BorderRadius.circular(10.0),
          splashColor: isSelected
              ? _primaryEmerald.withOpacity(0.2)
              : Colors.grey.withOpacity(0.1),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.all(isSelected ? 8.0 : 0.0),
                  decoration: isSelected
                      ? BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_primaryEmerald, _tealAccent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12.0),
                          boxShadow: [
                            BoxShadow(
                              color: _primaryEmerald.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        )
                      : null,
                  child: Icon(
                    icon,
                    color: isSelected ? _pureWhite : Colors.grey.shade600,
                    size: isSelected ? 22.0 : 20.0,
                  ),
                ),
                const SizedBox(height: 4.0),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    color: isSelected ? _darkEmerald : Colors.grey.shade600,
                    fontSize: isSelected ? 10.5 : 9.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: isSelected ? 0.2 : 0.0,
                    height: 1.1,
                  ),
                  textAlign: TextAlign.center,
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
