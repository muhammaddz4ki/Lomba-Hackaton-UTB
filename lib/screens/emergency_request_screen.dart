import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyRequestScreen extends StatefulWidget {
  const EmergencyRequestScreen({super.key});

  @override
  State<EmergencyRequestScreen> createState() => _EmergencyRequestScreenState();
}

class _EmergencyRequestScreenState extends State<EmergencyRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers untuk input
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Biaya darurat (kita tetapkan dulu, nanti bisa diatur)
  final double _emergencyFee = 25000.00;

  bool _isLoading = false;

  // Instance Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fungsi untuk kirim permintaan
  Future<void> _submitEmergencyRequest() async {
    if (!_formKey.currentState!.validate()) {
      return; // Stop jika form tidak valid
    }

    setState(() => _isLoading = true);

    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('Pengguna tidak login.');
      }

      // Siapkan data untuk dikirim
      final data = {
        'locationAddress': _locationController.text.trim(),
        'description': _descriptionController.text.trim(),
        'fee': _emergencyFee,
        'status': 'Pending', // Status awal, menunggu TPS menerima
        'requesterUid': user.uid, // ID Masyarakat yang meminta
        'requesterEmail': user.email,
        'createdAt': Timestamp.now(),
        'tpsId': null, // Akan diisi oleh TPS yang menerima
        'proofImageUrl': null, // Akan diisi oleh TPS
      };

      // Kirim ke koleksi 'emergency_requests'
      await _firestore.collection('emergency_requests').add(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permintaan darurat berhasil dikirim!'),
            backgroundColor: Colors.green,
          ),
        );
        // Kembali ke halaman sebelumnya (Home)
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
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permintaan Darurat'),
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Kartu Informasi Biaya
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
                    'Rp $_emergencyFee', // Tampilkan biaya
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

          // Formulir Permintaan
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Field Lokasi
                // (Nanti kita akan ganti ini dengan tombol 'Ambil Lokasi GPS')
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Alamat Lokasi Penjemputan',
                    hintText: 'Tulis alamat lengkap atau patokan',
                    border: OutlineInputBorder(),
                    icon: Icon(Icons.location_on_outlined),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Lokasi tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20.0),

                // 2. Field Deskripsi
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

                // 3. Tombol Submit
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
                      // Gunakan warna 'error' untuk menandakan 'darurat'
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
