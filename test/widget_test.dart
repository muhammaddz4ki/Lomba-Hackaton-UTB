// Ini adalah basic Flutter widget test.
import 'package.flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Pastikan kita mengimpor file main.dart yang benar
import 'package:eco_manage/main.dart'; 

void main() {
  // Kita ubah nama tesnya agar lebih deskriptif
  testWidgets('App navigation smoke test', (WidgetTester tester) async {
    // 1. Build aplikasi kita.
    // Kita ganti 'MyApp' menjadi 'EcoManageApp' sesuai nama di main.dart
    await tester.pumpWidget(const EcoManageApp());

    // 2. Verifikasi halaman Home (layar awal) tampil dengan benar.
    // Kita cari teks 'Selamat Datang!' yang ada di HomeScreen.
    expect(find.text('Selamat Datang!'), findsOneWidget);
    
    // Kita juga pastikan teks dari halaman lain (Tips) tidak ada di layar.
    expect(find.text('Gunakan Tas Belanja Pakai Ulang'), findsNothing);

    // 3. Uji navigasi. Tekan tombol tab 'Tips Lingkungan'.
    // Kita cari berdasarkan icon-nya.
    await tester.tap(find.byIcon(Icons.lightbulb_outline));
    
    // Tunggu aplikasi selesai membangun ulang UI (pindah halaman).
    await tester.pump();

    // 4. Verifikasi halaman Tips sekarang tampil.
    // Kita cari teks yang ada di TipsScreen.
    expect(find.text('Gunakan Tas Belanja Pakai Ulang'), findsOneWidget);

    // Pastikan juga teks dari halaman Home sudah hilang.
    expect(find.text('Selamat Datang!'), findsNothing);
  });
}