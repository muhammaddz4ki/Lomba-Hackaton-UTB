// Impor paket material dari Flutter
import 'package:flutter/material.dart';

// Impor file-file halaman (screens) yang akan kita buat
import 'screens/home_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/tips_screen.dart';

// Fungsi main() adalah titik awal di mana aplikasi Flutter mulai dieksekusi
void main() {
  // runApp() menjalankan aplikasi kita
  runApp(const EcoManageApp());
}

// Ini adalah widget utama aplikasi kita
class EcoManageApp extends StatelessWidget {
  const EcoManageApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MaterialApp adalah widget dasar yang membungkus seluruh aplikasi
    return MaterialApp(
      // Judul aplikasi
      title: 'Eco Manage',

      // Tema aplikasi (skema warna, font, dll.)
      theme: ThemeData(
        // Kita gunakan skema warna dasar hijau untuk tema lingkungan
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),

      // Halaman utama yang akan ditampilkan saat aplikasi dibuka
      home: const AppNavigation(),

      // Menyembunyikan banner "DEBUG" di pojok kanan atas
      debugShowCheckedModeBanner: false,
    );
  }
}

// Ini adalah widget yang akan mengatur navigasi utama (Bottom Tab Bar)
// Kita gunakan StatefulWidget karena kita perlu 'mengingat' tab mana yang sedang aktif
class AppNavigation extends StatefulWidget {
  const AppNavigation({super.key});

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation> {
  // Variabel untuk menyimpan indeks (nomor) tab yang sedang dipilih
  // 0 = Home, 1 = Jadwal, 2 = Tips
  int _selectedIndex = 0;

  // Daftar (List) dari semua halaman/layar yang kita miliki
  // Urutannya harus sesuai dengan urutan tab
  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(), // Indeks 0
    ScheduleScreen(), // Indeks 1
    TipsScreen(), // Indeks 2
  ];

  // Fungsi yang akan dipanggil ketika sebuah tab ditekan
  void _onItemTapped(int index) {
    // setState() memberitahu Flutter untuk membangun ulang UI
    // dengan nilai _selectedIndex yang baru
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold adalah kerangka dasar untuk sebuah halaman (bisa punya app bar, body, dll.)
    return Scaffold(
      // Body (isi utama) halaman adalah halaman yang sedang dipilih dari daftar _widgetOptions
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),

      // BottomNavigationBar adalah menu tab di bagian bawah layar
      bottomNavigationBar: BottomNavigationBar(
        // Daftar item (tombol) di navigasi
        items: const <BottomNavigationBarItem>[
          // Item 1: Home
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          // Item 2: Jadwal
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: 'Jadwal Jemput',
          ),
          // Item 3: Tips
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb_outline),
            label: 'Tips Lingkungan',
          ),
        ],
        // Memberitahu tab mana yang sedang aktif (agar warnanya beda)
        currentIndex: _selectedIndex,
        // Warna item yang sedang dipilih
        selectedItemColor: Colors.green[800],
        // Fungsi yang dipanggil saat item ditekan
        onTap: _onItemTapped,
      ),
    );
  }
}
