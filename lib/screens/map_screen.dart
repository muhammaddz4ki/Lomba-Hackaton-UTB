import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // Paket Peta
import 'package:latlong2/latlong.dart' as latlng; // Paket Koordinat
import 'package:url_launcher/url_launcher.dart'; // Paket untuk buka link

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // --- (DATA DUMMY) ---
  final List<Map<String, dynamic>> dummyTpsLocations = [
    {"name": "TPS SiBersih - Dago", "lat": -6.8887, "lng": 107.6152},
    {"name": "TPS SiBersih - Kopo", "lat": -6.9453, "lng": 107.5925},
    {"name": "TPS SiBersih - Gedebage", "lat": -6.9472, "lng": 107.7027},
    {"name": "Bank Sampah - Cihampelas", "lat": -6.8970, "lng": 107.6033},
  ];
  // --- (AKHIR DATA DUMMY) ---

  // Fungsi untuk membuka URL
  Future<void> _launchUrl(Uri url) async {
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Kita buat dulu daftar 'Marker' (pin) dari data dummy kita
    final List<Marker> markers = dummyTpsLocations.map((tps) {
      return Marker(
        width: 40.0,
        height: 40.0,
        // Tentukan koordinat pin
        point: latlng.LatLng(tps['lat'], tps['lng']),
        // Tampilan pin (Icon)
        child: Tooltip(
          // Tooltip akan menampilkan nama saat ditahan
          message: tps['name'],
          child: Icon(
            Icons.location_pin,
            color: Colors.teal.shade700, // Sesuaikan dengan tema
            size: 40.0,
          ),
        ),
      );
    }).toList();

    // 2. Tampilkan Scaffold dan FlutterMap
    return Scaffold(
      appBar: AppBar(
        title: const Text('Peta Lokasi TPS'),
        
        // --- (PERBAIKAN 1: Peringatan Deprecated) ---
        // Mengganti 'surfaceVariant' dengan 'surfaceContainerHighest'
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        // ------------------------------------------
      ),
      body: FlutterMap(
        // Opsi Peta (koordinat tengah & zoom awal)
        options: const MapOptions(
          initialCenter: latlng.LatLng(-6.9175, 107.6191), // Pusat kota Bandung
          initialZoom: 12.0,
        ),
        // children berisi semua "lapisan" (layer) dari peta
        children: [
          // Lapisan 1: Gambar Peta (Tiles) dari OpenStreetMap
          TileLayer(
            // URL template untuk tile server OSM
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',

            // (PENTING) OSM mewajibkan kita mencantumkan User-Agent
            userAgentPackageName: 'id.sib bersih.eco_manage',
          ),

          // Lapisan 2: Marker (Pin) Lokasi TPS
          MarkerLayer(markers: markers),

          // Lapisan 3: Atribusi (WAJIB untuk OpenStreetMap)
          RichAttributionWidget(
            
            // --- (PERBAIKAN 2: Error Tipe Argumen) ---
            // Mengganti 'Alignment' dengan 'AttributionAlignment'
            alignment: AttributionAlignment.bottomLeft,
            // --------------------------------------

            attributions: [
              // Teks yang bisa diklik
              TextSourceAttribution(
                '© OpenStreetMap contributors',
                onTap: () => _launchUrl(
                  Uri.parse('https://openstreetmap.org/copyright'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}