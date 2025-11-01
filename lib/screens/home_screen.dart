import 'package:flutter/material.dart';

// Halaman Home (StatelessWidget karena halamannya statis, tidak berubah)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Scaffold adalah kerangka halaman
    return Scaffold(
      // AppBar adalah baris judul di bagian atas
      appBar: AppBar(
        title: const Text('Dashboard Lingkungan'),
        backgroundColor: Colors.green[100],
      ),

      // body adalah isi utama halaman
      // Kita gunakan ListView agar bisa di-scroll jika kontennya panjang
      body: ListView(
        // Padding agar konten tidak menempel di tepi layar
        padding: const EdgeInsets.all(16.0),
        children: [
          // Widget Card untuk menampilkan info
          Card(
            elevation: 4.0, // Efek bayangan
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selamat Datang!',
                    // Mengambil gaya teks (misal: ukuran, tebal) dari tema
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8.0), // Jarak
                  const Text(
                    'Aplikasi ini membantumu mengelola sampah dan belajar lebih banyak tentang lingkungan.',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20.0), // Jarak
          // Contoh Kartu Info Status
          Card(
            color: Colors.green[50],
            child: const ListTile(
              leading: Icon(Icons.recycling, color: Colors.green, size: 40),
              title: Text('Status Daur Ulang'),
              subtitle: Text('Kamu telah mendaur ulang 5kg sampah bulan ini!'),
            ),
          ),

          const SizedBox(height: 10.0), // Jarak
          // Contoh Kartu Info Jadwal
          Card(
            color: Colors.blue[50],
            child: const ListTile(
              leading: Icon(Icons.calendar_month, color: Colors.blue, size: 40),
              title: Text('Jadwal Jemput Berikutnya'),
              subtitle: Text('Rabu, 5 November 2025'),
            ),
          ),
        ],
      ),
    );
  }
}
