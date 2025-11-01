import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloudinary_public/cloudinary_public.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Variabel state
  String? _selectedReportType;
  final List<String> _reportTypes = [
    'Tumpukan Sampah Ilegal',
    'Fasilitas Rusak',
    'Lainnya'
  ];
  File? _imageFile;
  Position? _currentPosition;
  String _locationMessage = 'Lokasi belum diambil';
  bool _isLoading = false;

  // Instance Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Instance Cloudinary
  final CloudinaryPublic cloudinary = CloudinaryPublic(
    'dofcteuvu', // Cloud Name-mu
    'SiBersih', // Upload Preset-mu
    cache: false,
  );

  // Instance ImagePicker
  final ImagePicker _picker = ImagePicker();

  // --- (FUNGSI LOKASI DIPERBARUI) ---
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
        throw Exception(
          'Izin lokasi ditolak permanen. Harap aktifkan di pengaturan HP.',
        );
      }

      // --- (PERBAIKAN) Menggunakan 'locationSettings' untuk API baru ---
      // Ini menggantikan 'desiredAccuracy' yang deprecated
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
      );
      
      // Menggunakan .getPositionStream().first adalah cara modern
      // untuk mendapatkan satu kali lokasi
      Position? position = await Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).first;
      // --- (AKHIR PERBAIKAN) ---

      setState(() {
        _currentPosition = position;
        _locationMessage =
            'Lokasi berhasil diambil!\nLat: ${position.latitude.toStringAsFixed(4)}, Lon: ${position.longitude.toStringAsFixed(4)}';
      });
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

  // --- (Fungsi _pickImage, _showImagePickerOptions - TIDAK BERUBAH) ---
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

  // --- (Fungsi _uploadImage & _submitReport - TIDAK BERUBAH) ---
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

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap lampirkan bukti foto.')),
      );
      return;
    }
    if (_currentPosition == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Harap ambil lokasi GPS.')));
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
        'reportType': _selectedReportType,
        'status': 'Pending',
        'reporterUid': user.uid,
        'createdAt': Timestamp.now(),
        'imageUrl': imageUrl,
        'location': GeoPoint(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        ),
      };
      await _firestore.collection('reports').add(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Laporan berhasil dikirim!'),
            backgroundColor: Colors.green,
          ),
        );
        _formKey.currentState!.reset();
        _titleController.clear();
        _descriptionController.clear();
        setState(() {
          _selectedReportType = null;
          _imageFile = null;
          _currentPosition = null;
          _locationMessage = 'Lokasi belum diambil';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim laporan: $e'),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Laporan Baru'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- FORMULIR (DIMULAI DARI SINI) ---
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Judul
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Judul Laporan',
                    hintText: 'Misal: Sampah di Depan Pasar',
                    border: OutlineInputBorder(),
                  ),
                  // --- (PERBAIKAN VALIDATOR) ---
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Judul tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20.0),

                // 2. Tipe
                DropdownButtonFormField<String>(
                  value: _selectedReportType,
                  decoration: const InputDecoration(
                    labelText: 'Tipe Laporan',
                    border: OutlineInputBorder(),
                  ),
                  // --- (PERBAIKAN 'items') ---
                  items: _reportTypes.map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  // --- (PERBAIKAN 'onChanged') ---
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedReportType = newValue;
                    });
                  },
                  // --- (PERBAIKAN VALIDATOR) ---
                  validator: (value) {
                    if (value == null) {
                      return 'Harap pilih tipe laporan';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20.0),

                // 3. Deskripsi
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi Laporan',
                    hintText: 'Jelaskan detail masalah...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                  // --- (PERBAIKAN VALIDATOR) ---
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Deskripsi tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24.0),

                // 4. Lokasi
                OutlinedButton.icon(
                  onPressed: _getCurrentLocation,
                  icon: const Icon(Icons.my_location),
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
                const SizedBox(height: 16.0),

                // 5. Gambar
                GestureDetector(
                  onTap: _showImagePickerOptions,
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    // --- (PERBAIKAN 'decoration') ---
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
                              Icon(Icons.camera_alt_outlined),
                              SizedBox(height: 8.0),
                              Text('Lampirkan Bukti Foto'),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 32.0),

                // 6. Tombol Submit
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitReport,
                  icon: _isLoading
                      ? const SizedBox.shrink()
                      : const Icon(Icons.send),
                  label: _isLoading
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        )
                      : const Text(
                          'Kirim Laporan',
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
          // --- FORMULIR (SELESAI DI SINI) ---

          // --- (BAGIAN RIWAYAT - TIDAK BERUBAH) ---
          const SizedBox(height: 32.0),
          const Divider(),
          const SizedBox(height: 16.0),
          Text(
            'Riwayat Laporan Saya',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16.0),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('reports')
                .where('reporterUid', isEqualTo: _auth.currentUser?.uid)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text('Anda belum memiliki riwayat laporan.'),
                );
              }
              return Column(
                children: snapshot.data!.docs.map((doc) {
                  Map<String, dynamic> data =
                      doc.data() as Map<String, dynamic>;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (data['imageUrl'] != null)
                          Image.network(
                            data['imageUrl'],
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                height: 200,
                                color: Colors.grey[300],
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    color: Colors.red,
                                  ),
                                ),
                              );
                            },
                          ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['title'],
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4.0),
                              Text(data['description']),
                              const SizedBox(height: 8.0),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Chip(
                                    label: Text('Status: ${data['status']}'),
                                    backgroundColor: Colors.amber[200],
                                  ),
                                  Text(
                                    data['reportType'],
                                    style: const TextStyle(
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}