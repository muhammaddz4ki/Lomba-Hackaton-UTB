import 'package:flutter/material.dart';

// --- (BARU) Impor paket Cloud Firestore ---
import 'package:cloud_firestore/cloud_firestore.dart';

class RequestPickupScreen extends StatefulWidget {
  const RequestPickupScreen({super.key});

  @override
  State<RequestPickupScreen> createState() => _RequestPickupScreenState();
}

class _RequestPickupScreenState extends State<RequestPickupScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String? _selectedWasteType;
  final List<String> _wasteTypes = [
    'Organik',
    'Anorganik',
    'B3 (Bahan Berbahaya)',
  ];

  // --- (BARU) State untuk melacak proses loading ---
  bool _isLoading = false;

  // --- (BARU) Ubah fungsi _submitForm menjadi async ---
  Future<void> _submitForm() async {
    // Validasi formulir
    if (_formKey.currentState!.validate()) {
      // --- (BARU) Mulai loading ---
      setState(() {
        _isLoading = true;
      });

      try {
        // --- (BAGIAN INTI BARU) ---
        // 1. Dapatkan referensi ke koleksi 'requests' di Firestore.
        //    Jika 'requests' belum ada, Firestore akan membuatnya otomatis.
        final collection = FirebaseFirestore.instance.collection('requests');

        // 2. Siapkan data yang akan dikirim
        final data = {
          'name': _nameController.text,
          'address': _addressController.text,
          'wasteType': _selectedWasteType,
          'notes': _notesController.text,
          'status': 'Pending', // Kita tambahkan status awal
          'createdAt':
              FieldValue.serverTimestamp(), // Tambah stempel waktu server
        };

        // 3. Tambahkan (add) data ke koleksi
        await collection.add(data);

        // --- (AKHIR BAGIAN INTI) ---

        // Tampilkan notifikasi sukses
        if (mounted) {
          // Pastikan widget masih ada di tree
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permintaan berhasil dikirim!'),
              backgroundColor: Colors.green,
            ),
          );
          // Kembali ke halaman sebelumnya
          Navigator.pop(context);
        }
      } catch (e) {
        // Jika terjadi error (misal: tidak ada internet)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal mengirim data: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        // --- (BARU) Hentikan loading, baik sukses maupun gagal ---
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Formulir Permintaan Jemput'),
        backgroundColor: Colors.blue[100],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // (Field Nama, Alamat, Dropdown, Catatan
                //  tidak ada perubahan di sini, sama seperti sebelumnya)

                // 1. Field Nama
                const Text(
                  'Nama Lengkap',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8.0),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'Masukkan nama lengkap Anda',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nama tidak boleh kosong';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20.0), // Jarak
                // 2. Field Alamat
                const Text(
                  'Alamat Lengkap',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8.0),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    hintText: 'Masukkan alamat lengkap penjemputan',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Alamat tidak boleh kosong';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20.0), // Jarak
                // 3. Field Jenis Sampah (Dropdown)
                const Text(
                  'Jenis Sampah',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8.0),
                DropdownButtonFormField<String>(
                  value: _selectedWasteType,
                  hint: const Text('Pilih jenis sampah'),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Harap pilih jenis sampah';
                    }
                    return null;
                  },
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
                ),

                const SizedBox(height: 20.0), // Jarak
                // 4. Field Catatan (Opsional)
                const Text(
                  'Catatan (Opsional)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8.0),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    hintText: 'Misal: "Ambil di depan pagar hijau"',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),

                const SizedBox(height: 32.0), // Jarak besar sebelum tombol
                // 5. Tombol Submit (DIPERBARUI)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    // --- (BARU) ---
                    // Jika _isLoading true, onPressed jadi null (tombol nonaktif)
                    // Jika false, jalankan _submitForm
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                    ),
                    // --- (BARU) Tampilkan teks 'Mengirim...' atau loading ---
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            // Indikator putar
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          )
                        : const Text(
                            'Kirim Permintaan',
                            style: TextStyle(fontSize: 16.0),
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
