import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloudinary_public/cloudinary_public.dart';

class MarketplaceCreateListingScreen extends StatefulWidget {
  const MarketplaceCreateListingScreen({super.key});

  @override
  State<MarketplaceCreateListingScreen> createState() =>
      _MarketplaceCreateListingScreenState();
}

class _MarketplaceCreateListingScreenState
    extends State<MarketplaceCreateListingScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController(); // <-- BARU

  // Variabel state
  File? _imageFile;
  Position? _currentPosition;
  String _locationMessage = 'Ambil Lokasi COD';
  bool _isLoading = false;

  // Instance Firebase, Cloudinary, dll.
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();
  final CloudinaryPublic cloudinary = CloudinaryPublic(
    'dofcteuvu', // Cloud Name-mu
    'SiBersih', // Upload Preset-mu
    cache: false,
  );

  // --- (Fungsi _getCurrentLocation, _pickImage, _showImagePickerOptions) ---
  // --- (Ini sama persis seperti di report_screen.dart) ---
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
      Position? position = await Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).first;
      setState(() {
        _currentPosition = position;
        _locationMessage =
            'Lokasi COD berhasil diambil!\nLat: ${position.latitude.toStringAsFixed(4)}, Lon: ${position.longitude.toStringAsFixed(4)}';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mengambil lokasi: $e')));
      }
      setState(() {
        _locationMessage = 'Ambil Lokasi COD';
      });
    }
  }

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
  // --- (AKHIR FUNGSI COPY-PASTE) ---

  // --- (Fungsi Upload ke Cloudinary) ---
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

  // --- (FUNGSI UTAMA: Kirim Listing) ---
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

      // 1. Upload gambar dulu
      String imageUrl = await _uploadImage(_imageFile!);

      // 2. Siapkan data untuk Firestore
      final data = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price':
            double.tryParse(_priceController.text.trim()) ??
            0.0, // Ubah ke angka
        'status': 'Available', // Status awal
        'sellerUid': user.uid,
        'sellerEmail': user.email, // Kita simpan email penjual
        'createdAt': Timestamp.now(),
        'imageUrl': imageUrl, // Link Cloudinary
        'location': GeoPoint(
          // Lokasi GPS
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        ),
      };

      // 3. Simpan ke koleksi BARU 'marketplace_listings'
      await _firestore.collection('marketplace_listings').add(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Barang berhasil di-posting!'),
            backgroundColor: Colors.green,
          ),
        );
        // Kembali ke halaman sebelumnya
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
                // 1. Judul Barang
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

                // 2. Harga
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Harga (Rp)',
                    hintText: 'Misal: 15000',
                    border: OutlineInputBorder(),
                    prefixText: 'Rp ',
                  ),
                  keyboardType: TextInputType.number, // Keyboard angka
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

                // 3. Deskripsi
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

                // 4. Foto Barang
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

                // 5. Lokasi COD
                OutlinedButton.icon(
                  onPressed: _getCurrentLocation,
                  icon: const Icon(Icons.location_on_outlined),
                  label: Text(_locationMessage, textAlign: TextAlign.center),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    side: BorderSide(
                      color: _currentPosition != null
                          ? Colors.green
                          : Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
                const SizedBox(height: 32.0),

                // 6. Tombol Submit
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
