import 'package:flutter/material.dart';
import 'tps_incoming_screen.dart';
import 'tps_in_progress_screen.dart';
import 'tps_deposit_approval_screen.dart';
import 'tps_schedule_management_screen.dart'; // File baru
import 'tps_history_screen.dart';
import 'profile_screen.dart';

class TpsHomeScreen extends StatefulWidget {
  const TpsHomeScreen({super.key});

  @override
  State<TpsHomeScreen> createState() => _TpsHomeScreenState();
}

class _TpsHomeScreenState extends State<TpsHomeScreen> {
  int _selectedIndex = 0;

  // --- (DIUBAH) Daftar halaman/layar untuk 5 tab ---
  static const List<Widget> _widgetOptions = <Widget>[
    TpsIncomingScreen(), // Tab 0
    TpsInProgressScreen(), // Tab 1
    TpsDepositApprovalScreen(), // Tab 2
    TpsScheduleManagementScreen(), // Tab 3 (BARU)
    TpsHistoryScreen(), // Tab 4
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0
              ? 'Permintaan Darurat'
              : _selectedIndex == 1
              ? 'Sedang Dikerjakan'
              : _selectedIndex == 2
              ? 'Setoran Bank Sampah'
              : _selectedIndex == 3
              ? 'Kelola Jadwal Umum'
              : 'Riwayat & Rekap',
        ),
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

      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),

      // --- (DIUBAH) Navigasi Tab di Bawah (5 item) ---
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        // Perkecil font agar muat 5 item
        unselectedFontSize: 10.0,
        selectedFontSize: 12.0,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.downloading_outlined),
            label: 'Darurat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_run_outlined),
            label: 'Dikerjakan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.recycling_outlined),
            label: 'Setoran',
          ),
          // --- (ITEM BARU) ---
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            label: 'Jadwal',
          ),
          // ---
          BottomNavigationBarItem(
            icon: Icon(Icons.history_edu_outlined),
            label: 'Rekap',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        onTap: _onItemTapped,
      ),
    );
  }
}
