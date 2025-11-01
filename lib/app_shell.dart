import 'package:flutter/material.dart';

// Impor halaman-halaman
import 'screens/home_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/report_screen.dart';
import 'screens/map_screen.dart';
import 'screens/profile_screen.dart'; // Diubah dari Inbox

class AppNavigation extends StatefulWidget {
  const AppNavigation({super.key});

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation> {
  // 0 = Home, 1 = Jadwal, 2 = Lapor, 3 = Peta, 4 = Profil
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),      // Indeks 0
    ScheduleScreen(),  // Indeks 1
    ReportScreen(),    // Indeks 2
    MapScreen(),       // Indeks 3
    ProfileScreen(),   // Indeks 4 (Diubah dari Inbox)
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _onItemTapped(0),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: _selectedIndex == 0 ? 2.0 : 8.0, 
        child: Icon( 
          _selectedIndex == 0 ? Icons.home_filled : Icons.home_outlined,
          size: 30.0,
        ),
      ),
      
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(

        shape: const CircularNotchedRectangle(), 
        notchMargin: 8.0, 
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            // Tombol 1: Jadwal
            _buildTabItem(
              icon: Icons.schedule_outlined,
              label: 'Jadwal',
              index: 1,
            ),
            // Tombol 2: Lapor
            _buildTabItem(
              icon: Icons.report_problem_outlined,
              label: 'Lapor',
              index: 2,
            ),
            
            const SizedBox(width: 48.0), // Spacer
            
            // Tombol 3: Peta TPS
            _buildTabItem(
              icon: Icons.map_outlined,
              label: 'Peta TPS',
              index: 3,
            ),
            
            // Tombol 4: Profil
            _buildTabItem(
              icon: Icons.person_outline, 
              label: 'Profil',             
              index: 4,
            ),
          ],
        ),
      ),
    );
  }

  // --- (PERBAIKAN FINAL DI SINI) ---
  Widget _buildTabItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final bool isSelected = (_selectedIndex == index);
    final Color activeColor = Theme.of(context).colorScheme.primary;
    final Color inactiveColor = Colors.grey.shade600;

    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index),
        child: Padding(
          // Kurangi padding vertikal lagi untuk memperbaiki 1.0 pixel
          padding: const EdgeInsets.symmetric(
            vertical: 4.0, 
          ), // <-- DIUBAH DARI 6.0
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isSelected ? activeColor : inactiveColor),
              const SizedBox(height: 4.0), // Jarak ini OK
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? activeColor : inactiveColor,
                  fontSize: 12.0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}