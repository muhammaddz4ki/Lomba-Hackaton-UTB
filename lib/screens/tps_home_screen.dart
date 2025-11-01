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
  // Index sekarang mewakili 5 tab
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    TpsInProgressScreen(), // Tab 0: Dikerjakan
    TpsDepositApprovalScreen(), // Tab 1: Setoran
    TpsIncomingScreen(), // Tab 2: Darurat (Widget aslinya)
    TpsScheduleManagementScreen(), // Tab 3: Jadwal
    TpsHistoryScreen(), // Tab 4: Riwayat
  ];

  void _onItemTapped(int index) {
    // Jika tombol yang ditekan adalah indeks 2 (Darurat), panggil fungsi navigasi
    if (index == 2) {
      _openEmergencyScreen();
    } else {
      // Untuk 4 tab lainnya, ganti indeks terpilih
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _openEmergencyScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TpsIncomingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tentukan Judul AppBar berdasarkan indeks
    String appBarTitle;
    switch (_selectedIndex) {
      case 0:
        appBarTitle = 'Sedang Dikerjakan';
        break;
      case 1:
        appBarTitle = 'Setoran Bank Sampah';
        break;
      case 2:
        // Walaupun index 2 tidak pernah terpilih, kita berikan judul default
        appBarTitle = 'Permintaan Darurat';
        break;
      case 3:
        appBarTitle = 'Kelola Jadwal Umum';
        break;
      case 4:
        appBarTitle = 'Riwayat & Rekap';
        break;
      default:
        appBarTitle = 'Dashboard TPS';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profil Saya',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),

      // Tampilkan widget sesuai index.
      // Jika index 2 (Darurat) terpilih, ganti ke index terdekat (misal 0)
      // atau pastikan logika di _onItemTapped hanya menjalankan navigasi saja.
      body: Center(
        child: _widgetOptions.elementAt(
          (_selectedIndex == 2) ? 0 : _selectedIndex,
        ),
      ),

      // --- Floating Action Button untuk Darurat yang Menonjol ---
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        onPressed: _openEmergencyScreen,
        tooltip: 'Permintaan Darurat',
        elevation: 5.0,
        backgroundColor: Theme.of(context).colorScheme.error, // Warna Mencolok
        foregroundColor: Theme.of(context).colorScheme.onError,
        child: const Icon(Icons.downloading_outlined, size: 30),
      ),

      // --- Posisi FAB di tengah bawah
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // --- (DIUBAH) BottomAppBar dengan lekukan untuk FAB ---
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(), // Membuat lekukan melingkar
        notchMargin: 6.0, // Jarak lekukan ke FAB
        child: BottomNavigationBar(
          backgroundColor:
              Colors.transparent, // Transparan agar BottomAppBar terlihat
          elevation: 0, // Hilangkan bayangan bawaan
          type: BottomNavigationBarType.fixed,
          unselectedFontSize: 10.0,
          selectedFontSize: 12.0,
          items: const <BottomNavigationBarItem>[
            // Tab 0
            BottomNavigationBarItem(
              icon: Icon(Icons.directions_run_outlined),
              label: 'Dikerjakan',
            ),
            // Tab 1
            BottomNavigationBarItem(
              icon: Icon(Icons.recycling_outlined),
              label: 'Setoran',
            ),
            // Tab 2: Item Kosong yang akan ditutup oleh FAB
            BottomNavigationBarItem(
              icon: SizedBox.shrink(), // Icon Kosong
              label: 'Darurat', // Label Darurat tetap ada
            ),
            // Tab 3
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              label: 'Jadwal',
            ),
            // Tab 4
            BottomNavigationBarItem(
              icon: Icon(Icons.history_edu_outlined),
              label: 'Rekap',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
