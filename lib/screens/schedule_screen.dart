import 'package:flutter/material.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Penjemputan Sampah'),
        backgroundColor: Colors.blue[100],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch, // Agar tombol jadi lebar
          children: [
            const Text(
              'Ajukan permintaan penjemputan sampah di lokasimu.',
              style: TextStyle(fontSize: 16.0),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24.0), // Jarak
            // Tombol untuk mengajukan
            // Nanti, tombol ini akan membuka halaman form baru
            ElevatedButton.icon(
              onPressed: () {
                // Aksi saat tombol ditekan
                // Untuk saat ini, kita tampilkan notifikasi sederhana (SnackBar)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fitur formulir akan segera dibuat!'),
                  ),
                );
              },
              icon: const Icon(Icons.add_location_alt),
              label: const Text('Buat Permintaan Jemput Baru'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 24.0), // Jarak

            const Text(
              'Riwayat Permintaan:',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10.0), // Jarak
            // Nanti di sini kita akan tampilkan daftar riwayat
            // Untuk sekarang, kita tampilkan placeholder
            const Expanded(
              child: Center(
                child: Text(
                  'Belum ada riwayat penjemputan.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
