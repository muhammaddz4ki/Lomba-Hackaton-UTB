import 'package:flutter/material.dart';

class TipsScreen extends StatelessWidget {
  const TipsScreen({super.key});

  // Kita buat data dummy (palsu) untuk daftar tips
  final List<Map<String, String>> dummyTips = const [
    {
      "title": "Pisahkan Sampah Organik dan Anorganik",
      "subtitle": "Memudahkan proses daur ulang dan kompos.",
      "icon": "recycle",
    },
    {
      "title": "Gunakan Tas Belanja Pakai Ulang",
      "subtitle": "Kurangi penggunaan kantong plastik sekali pakai.",
      "icon": "bag",
    },
    {
      "title": "Matikan Listrik Saat Tidak Digunakan",
      "subtitle": "Hemat energi dan kurangi emisi karbon.",
      "icon": "power",
    },
    {
      "title": "Buat Kompos dari Sisa Makanan",
      "subtitle": "Mengurangi sampah TPA dan menyuburkan tanaman.",
      "icon": "compost",
    },
  ];

  // Fungsi kecil untuk memilih ikon berdasarkan teks
  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'recycle':
        return Icons.recycling;
      case 'bag':
        return Icons.shopping_bag;
      case 'power':
        return Icons.power_settings_new;
      case 'compost':
        return Icons.eco;
      default:
        return Icons.lightbulb;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tips & Artikel Lingkungan'),
        backgroundColor: Colors.orange[100],
      ),

      // Kita gunakan ListView.builder
      // Ini cara yang efisien untuk menampilkan daftar yang panjang
      // Karena item hanya dibuat (render) saat akan tampil di layar
      body: ListView.builder(
        // Jumlah item di dalam daftar
        itemCount: dummyTips.length,

        // Fungsi 'builder' yang akan dipanggil untuk setiap item
        itemBuilder: (BuildContext context, int index) {
          // Ambil data tips untuk item di 'index' ini
          final tip = dummyTips[index];

          // Kita gunakan Card agar terlihat rapi
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ListTile(
              // Ikon di sebelah kiri
              leading: Icon(
                _getIcon(tip['icon']!),
                color: Colors.orange[800],
                size: 40,
              ),
              // Judul tips
              title: Text(
                tip['title']!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              // Subtitle (penjelasan singkat)
              subtitle: Text(tip['subtitle']!),
              // Tanda panah di kanan, menandakan bisa ditekan
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Aksi saat item ditekan
                // Nanti ini bisa membuka halaman detail artikel
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Membuka detail untuk: ${tip['title']}'),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
