import 'package:flutter/material.dart';

// Impor halaman-halaman
import 'screens/home_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/report_screen.dart';
import 'screens/map_screen.dart';
import 'screens/profile_screen.dart';

class AppNavigation extends StatefulWidget {
  const AppNavigation({super.key});

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(), // Indeks 0
    ScheduleScreen(), // Indeks 1
    ReportScreen(), // Indeks 2
    MapScreen(), // Indeks 3
    ProfileScreen(), // Indeks 4
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

      // FAB dengan Gradient & Shadow - POSISI DI TENGAH
      floatingActionButton: Container(
        width: 64.0, // Sedikit lebih besar untuk emphasis
        height: 64.0,
        margin: const EdgeInsets.only(bottom: 25.0), // Position dari bottom
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF10B981), // Emerald
              Color(0xFF14B8A6), // Teal
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: const Color(0xFF14B8A6).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _onItemTapped(0),
            customBorder: const CircleBorder(),
            child: Center(
              child: Icon(
                _selectedIndex == 0 ? Icons.home_rounded : Icons.home_outlined,
                size: 28.0,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // Bottom Navigation Bar dengan Layout yang Diperbaiki
      bottomNavigationBar: Container(
        height: 75.0, // Tinggi konsisten
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, -2),
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomAppBar(
            color: Colors.transparent,
            elevation: 0,
            height: 75.0,
            padding: EdgeInsets.zero,
            surfaceTintColor: Colors.transparent,
            shape: const CircularNotchedRectangle(),
            notchMargin: 10.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  // Bagian Kiri: 2 Item pertama
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildTabItem(
                          icon: Icons.calendar_today_outlined,
                          iconFilled: Icons.calendar_month_rounded,
                          label: 'Jadwal',
                          index: 1,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF14B8A6)],
                          ),
                        ),
                        _buildTabItem(
                          icon: Icons.report_problem_outlined,
                          iconFilled: Icons.report_problem_rounded,
                          label: 'Lapor',
                          index: 2,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEF5350), Color(0xFFE53935)],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Spacer untuk FAB - Lebar disesuaikan
                  const SizedBox(width: 70.0),

                  // Bagian Kanan: 2 Item terakhir
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildTabItem(
                          icon: Icons.map_outlined,
                          iconFilled: Icons.map_rounded,
                          label: 'Peta',
                          index: 3,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF9CCC65), Color(0xFF7CB342)],
                          ),
                        ),
                        _buildTabItem(
                          icon: Icons.person_outline_rounded,
                          iconFilled: Icons.person_rounded,
                          label: 'Profil',
                          index: 4,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF66BB6A), Color(0xFF4CAF50)],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required IconData icon,
    required IconData iconFilled,
    required String label,
    required int index,
    required Gradient gradient,
  }) {
    final bool isSelected = (_selectedIndex == index);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onItemTapped(index),
          borderRadius: BorderRadius.circular(12.0),
          splashColor: isSelected
              ? const Color(0xFF10B981).withOpacity(0.2)
              : Colors.grey.withOpacity(0.1),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon dengan animasi smooth
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: EdgeInsets.all(isSelected ? 8.0 : 4.0),
                  decoration: isSelected
                      ? BoxDecoration(
                          gradient: gradient,
                          borderRadius: BorderRadius.circular(12.0),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        )
                      : BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                  child: Icon(
                    isSelected ? iconFilled : icon,
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                    size: isSelected ? 22.0 : 20.0,
                  ),
                ),
                const SizedBox(height: 4.0),
                // Label dengan animasi
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 250),
                  style: TextStyle(
                    color: isSelected
                        ? const Color(0xFF047857) // Dark Emerald
                        : Colors.grey.shade600,
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
