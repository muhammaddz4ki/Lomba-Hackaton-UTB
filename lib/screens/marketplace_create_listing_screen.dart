import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloudinary_public/cloudinary_public.dart';

// --- (BARU) Impor paket peta & halaman pemilih ---
import 'package:latlong2/latlong.dart' as latlng;
import 'location_picker_screen.dart';

class MarketplaceCreateListingScreen extends StatefulWidget {
  const MarketplaceCreateListingScreen({super.key});

  @override
  State<MarketplaceCreateListingScreen> createState() =>
      _MarketplaceCreateListingScreenState();
}

class _MarketplaceCreateListingScreenState
    extends State<MarketplaceCreateListingScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  // Variabel state (sudah ada, kita hanya ganti nama _locationMessage)
  File? _imageFile;
  Position? _currentPosition;
  String _locationMessage = 'Lokasi COD belum diambil'; // Teks diubah
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();
  final CloudinaryPublic cloudinary = CloudinaryPublic(
    'dofcteuvu',
    'SiBersih',
    cache: false,
  );

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
        _locationMessage = 'Lokasi COD belum diambil';
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

  // Fungsi _pickImage, _showImagePickerOptions, _uploadImage (Tidak Berubah)
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mengambil gambar: $e')));
      }
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Ambil Foto (Kamera)'),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String> _uploadImage(File image) async {
    try {
      CloudinaryFile file = CloudinaryFile.fromFile(
        image.path,
        resourceType: CloudinaryResourceType.Image,
      );
      CloudinaryResponse response = await cloudinary.uploadFile(file);
      return response.secureUrl;
    } catch (e) {
      throw Exception('Gagal meng-upload gambar: $e');
    }
  }

  // Fungsi _submitListing (Tidak Berubah, sudah pakai _currentPosition)
  Future<void> _submitListing() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap masukkan foto barang.')),
      );
      return;
    }
    if (_currentPosition == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Harap ambil lokasi COD.')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final User? user = _auth.currentUser;
      if (user == null) throw Exception('Anda harus login.');
      String imageUrl = await _uploadImage(_imageFile!);
      final data = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
        'status': 'Available',
        'sellerUid': user.uid,
        'sellerEmail': user.email,
        'createdAt': Timestamp.now(),
        'imageUrl': imageUrl,
        'location': GeoPoint(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        ),
      };
      await _firestore.collection('marketplace_listings').add(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Barang berhasil di-posting!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mem-posting barang: $e'),
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
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jual Barang Daur Ulang'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // (Field Judul, Harga, Deskripsi - tidak berubah)
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Barang',
                    hintText: 'Misal: Botol plastik Aqua 1 karung',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama barang tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20.0),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Harga (Rp)',
                    hintText: 'Misal: 15000',
                    border: OutlineInputBorder(),
                    prefixText: 'Rp ',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Harga tidak boleh kosong';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Masukkan angka yang valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20.0),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi Barang',
                    hintText: 'Jelaskan kondisi, jumlah, dll.',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Deskripsi tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24.0),

                // Foto Barang (Tidak berubah)
                GestureDetector(
                  onTap: _showImagePickerOptions,
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _imageFile != null
                            ? Colors.green
                            : Theme.of(context).colorScheme.outline,
                      ),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: _imageFile != null
                        ? Image.file(_imageFile!, fit: BoxFit.cover)
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined),
                              SizedBox(height: 8.0),
                              Text('Upload Foto Barang'),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16.0),

                // --- (WIDGET LOKASI DIPERBARUI) ---
                Text(
                  'Lokasi COD',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8.0),
                OutlinedButton.icon(
                  onPressed: _getCurrentLocation,
                  icon: const Icon(Icons.my_location),
                  label: Text(_locationMessage, textAlign: TextAlign.center),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
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
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Theme.of(context).colorScheme.onSecondary,
                  ),
                ),

                // --- (AKHIR PERUBAHAN) ---
                const SizedBox(height: 32.0),

                // Tombol Submit (Tidak berubah)
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitListing,
                  icon: _isLoading
                      ? const SizedBox.shrink()
                      : const Icon(Icons.check_circle_outline),
                  label: _isLoading
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        )
                      : const Text(
                          'Posting Barang',
                          style: TextStyle(fontSize: 16.0),
                        ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
