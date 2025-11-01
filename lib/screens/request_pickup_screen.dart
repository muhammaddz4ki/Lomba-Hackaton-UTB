import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- (DIUBAH) Menjadi StatefulWidget ---
class RequestPickupScreen extends StatefulWidget {
  const RequestPickupScreen({super.key});

  @override
  State<RequestPickupScreen> createState() => _RequestPickupScreenState();
}

class _RequestPickupScreenState extends State<RequestPickupScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String? _selectedWasteType;
  final List<String> _wasteTypes = ['Organik', 'Anorganik', 'B3 (Bahan Berbahaya)'];

  // --- (STATE BARU) ---
  String? _selectedTpsId; // Untuk menyimpan ID TPS yang dipilih
  List<DropdownMenuItem<String>> _tpsListItems = []; // Untuk daftar Dropdown
  bool _isTpsLoading = true; // Untuk loading daftar TPS
  // --------------------

  bool _isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    // Panggil fungsi untuk mengambil daftar TPS saat halaman dibuka
    _fetchTpsList();
  }

  // --- (FUNGSI BARU) Mengambil daftar TPS dari Firestore ---
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat daftar TPS: $e')),
        );
      }
      setState(() {
        _isTpsLoading = false;
      });
    }
  }

  // --- (FUNGSI DIPERBARUI) Kirim permintaan ---
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // (BARU) Validasi: Pastikan TPS sudah dipilih
      if (_selectedTpsId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Harap pilih TPS tujuan.')),
        );
        return;
      }
      
      setState(() => _isLoading = true);

      try {
        final collection = FirebaseFirestore.instance.collection('requests');

        final data = {
          'name': _nameController.text,
          'address': _addressController.text,
          'wasteType': _selectedWasteType,
          'notes': _notesController.text,
          'status': 'Pending', // Status awal
          'createdAt': FieldValue.serverTimestamp(), 
          'requesterUid': _auth.currentUser?.uid, // Simpan ID peminta
          // --- (FIELD BARU) ---
          'selectedTpsId': _selectedTpsId, // ID TPS yang dipilih
        };

        await collection.add(data);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permintaan berhasil dikirim!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal mengirim data: $e'),
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
        title: const Text('Formulir Jemput Reguler'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- (WIDGET BARU: Pilihan TPS) ---
                Text('Pilih TPS Tujuan', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8.0),
                DropdownButtonFormField<String>(
                  value: _selectedTpsId,
                  hint: Text(
                    _isTpsLoading ? 'Memuat daftar TPS...' : 'Pilih TPS Tujuan',
                  ),
                  isExpanded: true, 
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  onChanged: _isTpsLoading ? null : (String? newValue) {
                    setState(() {
                      _selectedTpsId = newValue;
                    });
                  },
                  items: _tpsListItems,
                  validator: (value) => (value == null) ? 'Harap pilih TPS' : null,
                ),
                const SizedBox(height: 20.0),
                // --------------------------------
                
                // (Field Nama, Alamat, dll. - tidak berubah)
                const Text('Nama Lengkap', style: TextStyle(fontWeight: FontWeight.bold)),
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
                const SizedBox(height: 20.0), 
                const Text('Alamat Lengkap', style: TextStyle(fontWeight: FontWeight.bold)),
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
                const SizedBox(height: 20.0), 
                const Text('Jenis Sampah', style: TextStyle(fontWeight: FontWeight.bold)),
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
                const SizedBox(height: 20.0), 
                const Text('Catatan (Opsional)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8.0),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    hintText: 'Misal: "Ambil di depan pagar hijau"',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 32.0), 

                // Tombol Submit
                SizedBox(
                  width: double.infinity, 
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm, 
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
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