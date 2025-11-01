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

      // FAB dengan Gradient & Shadow
      floatingActionButton: Container(
        width: 60.0,
        height: 60.0,
        margin: const EdgeInsets.only(bottom: 5.0), // Reduced margin
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

      // Bottom Navigation Bar dengan Enhanced Design
      bottomNavigationBar: Container(
        height: 70.0, // Fixed height
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -4),
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
          height: 70.0, // Match container height
          padding: EdgeInsets.zero,
          surfaceTintColor: Colors.transparent,
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0, // Reduced notch margin
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 4.0,
            ), // Reduced padding
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                // Tombol 1: Jadwal
                _buildTabItem(
                  icon: Icons.calendar_today_rounded,
                  iconFilled: Icons.calendar_month_rounded,
                  label: 'Jadwal',
                  index: 1,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF14B8A6)],
                  ),
                ),

                // Tombol 2: Lapor
                _buildTabItem(
                  icon: Icons.report_problem_outlined,
                  iconFilled: Icons.report_problem_rounded,
                  label: 'Lapor',
                  index: 2,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEF5350), Color(0xFFE53935)],
                  ),
                ),

                // Spacer untuk FAB - Lebih kecil
                const SizedBox(width: 50.0),

                // Tombol 3: Peta TPS
                _buildTabItem(
                  icon: Icons.map_outlined,
                  iconFilled: Icons.map_rounded,
                  label: 'Peta',
                  index: 3,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9CCC65), Color(0xFF7CB342)],
                  ),
                ),

                // Tombol 4: Profil
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
          borderRadius: BorderRadius.circular(10.0),
          splashColor: isSelected
              ? const Color(0xFF10B981).withOpacity(0.2)
              : Colors.grey.withOpacity(0.1),
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: 6.0,
            ), // Reduced padding
            margin: const EdgeInsets.symmetric(
              horizontal: 2.0,
            ), // Reduced margin
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon Container dengan Gradient saat selected
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.all(
                    isSelected ? 6.0 : 0.0,
                  ), // Reduced padding
                  decoration: isSelected
                      ? BoxDecoration(
                          gradient: gradient,
                          borderRadius: BorderRadius.circular(
                            10.0,
                          ), // Reduced radius
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withOpacity(0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        )
                      : null,
                  child: Icon(
                    isSelected ? iconFilled : icon,
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                    size: isSelected ? 22.0 : 20.0, // Reduced size
                  ),
                ),
                const SizedBox(height: 3.0), // Reduced spacing
                // Label dengan animasi
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    color: isSelected
                        ? const Color(0xFF047857) // Dark Emerald
                        : Colors.grey.shade600,
                    fontSize: isSelected ? 10.0 : 9.0, // Reduced font size
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    letterSpacing: isSelected ? 0.2 : 0.0,
                    height: 1.1, // Reduced line height
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
