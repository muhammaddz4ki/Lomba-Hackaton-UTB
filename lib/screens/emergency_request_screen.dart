import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- (BARU) Impor paket-paket baru ---
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'location_picker_screen.dart'; // Halaman baru

class EmergencyRequestScreen extends StatefulWidget {
  const EmergencyRequestScreen({super.key});

  @override
  State<EmergencyRequestScreen> createState() => _EmergencyRequestScreenState();
}

class _EmergencyRequestScreenState extends State<EmergencyRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  // Hapus controller alamat
  // final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final double _emergencyFee = 25000.00;
  bool _isLoading = false;

  // State baru untuk lokasi
  Position? _currentPosition;
  String _locationMessage = 'Lokasi belum diambil';

  // State untuk TPS
  String? _selectedTpsId;
  List<DropdownMenuItem<String>> _tpsListItems = [];
  bool _isTpsLoading = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchTpsList();
  }

  // Fungsi _fetchTpsList (Tidak berubah)
  Future<void> _fetchTpsList() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'TPS')
          .get();
      final tpsItems = snapshot.docs.map((doc) {
        final data = doc.data();
        final String tpsId = doc.id;
        final String tpsName = data['name'] ?? 'TPS Tanpa Nama';
        final String tpsAddress = data['tpsAddress'] ?? 'Alamat belum diatur';
        return DropdownMenuItem<String>(
          value: tpsId,
          child: Text('$tpsName - ($tpsAddress)'),
        );
      }).toList();
      setState(() {
        _tpsListItems = tpsItems;
        _isTpsLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat daftar TPS: $e')));
      }
      setState(() {
        _isTpsLoading = false;
      });
    }
  }

  // --- (FUNGSI LOKASI BARU: _getCurrentLocation) ---
  Future<void> _getCurrentLocation() async {
    setState(() {
      _locationMessage = 'Sedang mengambil lokasi...';
    });
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Izin lokasi ditolak.');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Izin lokasi ditolak permanen.');
      }
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
      );
      Position position = await Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).first;
      _updateLocationState(position.latitude, position.longitude);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mengambil lokasi: $e')));
      }
      setState(() {
        _locationMessage = 'Lokasi belum diambil';
      });
    }
  }

  // --- (FUNGSI LOKASI BARU: _openLocationPicker) ---
  Future<void> _openLocationPicker() async {
    final latlng.LatLng initialLoc = _currentPosition != null
        ? latlng.LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : const latlng.LatLng(-6.9175, 107.6191); // Default Bandung

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(initialLocation: initialLoc),
      ),
    );

    if (result != null && result is latlng.LatLng) {
      _updateLocationState(result.latitude, result.longitude);
    }
  }

  // --- (FUNGSI LOKASI BARU: _updateLocationState) ---
  void _updateLocationState(double latitude, double longitude) {
    setState(() {
      _currentPosition = Position(
        latitude: latitude,
        longitude: longitude,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );
      _locationMessage =
          'Lokasi terpilih:\nLat: ${latitude.toStringAsFixed(4)}, Lon: ${longitude.toStringAsFixed(4)}';
    });
  }

  // --- (FUNGSI _submitEmergencyRequest DIPERBARUI) ---
  Future<void> _submitEmergencyRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedTpsId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Harap pilih TPS tujuan.')));
      return;
    }
    // (BARU) Validasi Lokasi
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap pilih lokasi penjemputan.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final User? user = _auth.currentUser;
      if (user == null) throw Exception('Pengguna tidak login.');

      final data = {
        // Hapus 'locationAddress'
        'description': _descriptionController.text.trim(),
        'fee': _emergencyFee,
        'status': 'Pending',
        'requesterUid': user.uid,
        'requesterEmail': user.email,
        'createdAt': Timestamp.now(),
        'tpsId': null,
        'proofImageUrl': null,
        'selectedTpsId': _selectedTpsId,
        // --- (FIELD BARU) ---
        'locationGps': GeoPoint(
          // Simpan lokasi sebagai GeoPoint
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        ),
      };

      await _firestore.collection('emergency_requests').add(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permintaan darurat berhasil dikirim!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim permintaan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    // Hapus controller alamat
    // _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permintaan Darurat'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Kartu Info Biaya
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Biaya Layanan Darurat',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Rp $_emergencyFee',
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Biaya ini akan dibayarkan kepada TPS setelah pengangkutan selesai dan Anda konfirmasi.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24.0),

          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pilihan TPS
                DropdownButtonFormField<String>(
                  value: _selectedTpsId,
                  hint: Text(
                    _isTpsLoading ? 'Memuat daftar TPS...' : 'Pilih TPS Tujuan',
                  ),
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Kirim Ke',
                    border: OutlineInputBorder(),
                    icon: Icon(Icons.store_mall_directory_outlined),
                  ),
                  onChanged: _isTpsLoading
                      ? null
                      : (String? newValue) {
                          setState(() {
                            _selectedTpsId = newValue;
                          });
                        },
                  items: _tpsListItems,
                  validator: (value) =>
                      (value == null) ? 'Harap pilih TPS' : null,
                ),
                const SizedBox(height: 20.0),

                // --- (WIDGET LOKASI DIPERBARUI) ---
                Text(
                  'Lokasi Penjemputan',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8.0),
                OutlinedButton.icon(
                  onPressed: _getCurrentLocation,
                  icon: const Icon(Icons.my_location),
                  label: Text(_locationMessage, textAlign: TextAlign.center),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(
                      double.infinity,
                      50,
                    ), // Buat tombol lebih tinggi
                    side: BorderSide(
                      color: _currentPosition != null
                          ? Colors.green
                          : Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
                const SizedBox(height: 8.0),
                ElevatedButton.icon(
                  onPressed: _openLocationPicker,
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Pilih Manual di Peta'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(
                      double.infinity,
                      50,
                    ), // Buat tombol lebih tinggi
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Theme.of(context).colorScheme.onSecondary,
                  ),
                ),

                // --- (AKHIR PERUBAHAN) ---
                const SizedBox(height: 20.0),

                // Field Deskripsi
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi Sampah',
                    hintText: 'Misal: Tumpukan 3 karung sampah sisa pesta',
                    border: OutlineInputBorder(),
                    icon: Icon(Icons.description_outlined),
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Deskripsi tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32.0),

                // Tombol Submit
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _submitEmergencyRequest,
                    icon: _isLoading
                        ? const SizedBox.shrink()
                        : const Icon(Icons.send_rounded),
                    label: _isLoading
                        ? const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          )
                        : const Text(
                            'Kirim Permintaan Darurat',
                            style: TextStyle(fontSize: 16.0),
                          ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
