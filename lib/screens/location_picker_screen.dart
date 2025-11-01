import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:geolocator/geolocator.dart'; // Kita butuh ini untuk tombol 'my location'

class LocationPickerScreen extends StatefulWidget {
  // Kita terima lokasi awal (bisa dari GPS pengguna)
  // agar peta langsung terbuka di lokasi yang relevan
  final latlng.LatLng initialLocation;

  const LocationPickerScreen({super.key, required this.initialLocation});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  // Controller untuk mengontrol peta
  final MapController _mapController = MapController();
  // Variabel untuk menyimpan lokasi di tengah peta saat digeser
  late latlng.LatLng _selectedLocation;

  @override
  void initState() {
    super.initState();
    // Set lokasi awal
    _selectedLocation = widget.initialLocation;
  }

  // --- (FUNGSI BARU) Untuk pindah ke lokasi GPS saat ini ---
  Future<void> _goToMyLocation() async {
    try {
      // Cek izin
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Izin lokasi ditolak.');
        }
      }

      // Ambil lokasi
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
      );
      Position position = await Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).first;

      final myLatLng = latlng.LatLng(position.latitude, position.longitude);

      // Gerakkan peta ke lokasi baru
      _mapController.move(myLatLng, 17.0);
      // Simpan juga sebagai lokasi yang dipilih
      setState(() {
        _selectedLocation = myLatLng;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil lokasi saat ini: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geser Peta untuk Pilih Lokasi'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        actions: [
          // Tombol konfirmasi di AppBar
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Konfirmasi Lokasi',
            onPressed: () {
              // Kirim lokasi yang dipilih (di tengah) kembali ke halaman form
              Navigator.pop(context, _selectedLocation);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. PETA
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation, // Gunakan lokasi awal
              initialZoom: 17.0, // Zoom lebih dekat agar akurat
              // Ini dipanggil setiap kali peta digeser
              onPositionChanged: (position, hasGesture) {
                if (hasGesture) {
                  // Simpan koordinat tengah peta yang baru
                  _selectedLocation = position.center;
                }
              },
            ),
            children: [
              // Lapisan tile OpenStreetMap
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'id.sib bersih.eco_manage',
              ),
            ],
          ),

          // 2. PIN PENANDA (Di tengah)
          Center(
            // Abaikan sentuhan agar bisa geser peta di bawahnya
            child: IgnorePointer(
              child: Icon(
                Icons.location_pin,
                color: Theme.of(context).colorScheme.error,
                size: 50,
              ),
            ),
          ),

          // 3. Tombol Konfirmasi (Di Bawah)
          Positioned(
            bottom: 30.0,
            left: 20.0,
            right: 20.0,
            child: ElevatedButton.icon(
              onPressed: () {
                // Kirim lokasi yang dipilih kembali ke halaman form
                Navigator.pop(context, _selectedLocation);
              },
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Konfirmasi Lokasi Ini'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),

          // 4. Tombol "Ke Lokasi Saya" (Bonus)
          Positioned(
            top: 16.0,
            right: 16.0,
            child: FloatingActionButton(
              heroTag: 'myLocationFab', // Tag unik
              mini: true,
              onPressed: _goToMyLocation, // Panggil fungsi baru
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
}
