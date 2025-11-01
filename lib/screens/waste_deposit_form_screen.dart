import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';

class WasteDepositFormScreen extends StatefulWidget {
  const WasteDepositFormScreen({super.key});

  @override
  State<WasteDepositFormScreen> createState() => _WasteDepositFormScreenState();
}

class _WasteDepositFormScreenState extends State<WasteDepositFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _weightController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Variabel state
  String? _selectedWasteType;
  final List<String> _wasteTypes = [
    'Plastik (Botol, Gelas)',
    'Kertas (Kardus, HVS)',
    'Logam (Kaleng)',
    'Kaca (Botol Sirup, dll)',
    'Lainnya',
  ];
  File? _imageFile;
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

  // --- (Fungsi Helper untuk Gambar) ---
  // (Sama seperti di report_screen.dart)
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80, // Kompresi
      );
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
  // --- (AKHIR FUNGSI HELPER GAMBAR) ---

  // --- (FUNGSI UTAMA: Kirim Setoran) ---
  Future<void> _submitDeposit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap masukkan foto sampah.')),
      );
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
        'wasteType': _selectedWasteType,
        'estimatedWeight':
            double.tryParse(_weightController.text.trim()) ?? 0.0,
        'description': _descriptionController.text.trim(),
        'imageUrl': imageUrl,
        'status': 'Pending', // Menunggu konfirmasi TPS
        'requesterUid': user.uid,
        'requesterEmail': user.email,
        'createdAt': Timestamp.now(),
        'pointsAwarded': 0, // Akan diisi oleh TPS
        'approverTpsId': null, // Akan diisi oleh TPS
      };

      // 3. Simpan ke koleksi BARU 'waste_deposits'
      await _firestore.collection('waste_deposits').add(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permintaan setoran berhasil dikirim!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Kembali ke halaman Bank Sampah
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim setoran: $e'),
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
    _weightController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Formulir Setor Sampah'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Isi detail sampah daur ulang yang ingin Anda setorkan untuk mendapatkan poin.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16.0),
          ),
          const SizedBox(height: 24.0),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Tipe Sampah (Dropdown)
                DropdownButtonFormField<String>(
                  value: _selectedWasteType,
                  hint: const Text('Pilih Tipe Sampah'),
                  decoration: const InputDecoration(
                    labelText: 'Tipe Sampah',
                    border: OutlineInputBorder(),
                  ),
                  items: _wasteTypes.map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedWasteType = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Harap pilih tipe sampah';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20.0),

                // 2. Estimasi Berat
                TextFormField(
                  controller: _weightController,
                  decoration: const InputDecoration(
                    labelText: 'Estimasi Berat (Kg)',
                    hintText: 'Misal: 3.5',
                    border: OutlineInputBorder(),
                    suffixText: 'Kg',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Estimasi berat tidak boleh kosong';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Masukkan angka yang valid (contoh: 3.5)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20.0),

                // 3. Deskripsi
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Catatan (Opsional)',
                    hintText: 'Misal: Botol sudah bersih, kardus diikat',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24.0),

                // 4. Foto Bukti
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
                              Text('Upload Foto Bukti Setoran'),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 32.0),

                // 5. Tombol Submit
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitDeposit,
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
                          'Ajukan Setoran',
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
