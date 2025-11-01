import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  String? _selectedTpsId;
  List<DropdownMenuItem<String>> _tpsListItems = [];
  bool _isTpsLoading = true;
  bool _isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // SiBersih Color Palette
  static const Color _primaryEmerald = Color(0xFF10B981);
  static const Color _darkEmerald = Color(0xFF047857);
  static const Color _lightEmerald = Color(0xFF34D399);
  static const Color _tealAccent = Color(0xFF14B8A6);
  static const Color _ultraLightEmerald = Color(0xFFECFDF5);
  static const Color _pureWhite = Color(0xFFFFFFFF);
  static const Color _background = Color(0xFFF8FDFD);

  @override
  void initState() {
    super.initState();
    _fetchTpsList();
  }

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tpsName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                tpsAddress,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      }).toList();

      setState(() {
        _tpsListItems = tpsItems;
        _isTpsLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat daftar TPS: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      setState(() {
        _isTpsLoading = false;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedTpsId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Harap pilih TPS tujuan.'),
            behavior: SnackBarBehavior.floating,
          ),
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
          'status': 'Pending',
          'createdAt': FieldValue.serverTimestamp(),
          'requesterUid': _auth.currentUser?.uid,
          'selectedTpsId': _selectedTpsId,
        };

        await collection.add(data);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permintaan berhasil dikirim!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
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
              behavior: SnackBarBehavior.floating,
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
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text(
          'Formulir Jemput Reguler',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: _pureWhite,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryEmerald, _tealAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: _primaryEmerald.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        foregroundColor: _pureWhite,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: _pureWhite,
            borderRadius: BorderRadius.circular(20.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                _buildSectionHeader(
                  icon: Icons.recycling_rounded,
                  title: 'Permintaan Jemput Sampah',
                  subtitle: 'Isi formulir untuk penjemputan sampah reguler',
                ),
                const SizedBox(height: 24.0),

                // TPS Selection
                _buildDropdownField(
                  label: 'TPS Tujuan',
                  hintText: _isTpsLoading
                      ? 'Memuat daftar TPS...'
                      : 'Pilih TPS Tujuan',
                  value: _selectedTpsId,
                  items: _tpsListItems,
                  onChanged: _isTpsLoading
                      ? (String? newValue) {} // Empty function instead of null
                      : (String? newValue) {
                          setState(() {
                            _selectedTpsId = newValue;
                          });
                        },
                  validator: (value) =>
                      (value == null) ? 'Harap pilih TPS' : null,
                ),
                const SizedBox(height: 16.0),

                // Name Field
                _buildTextField(
                  controller: _nameController,
                  label: 'Nama Lengkap',
                  hintText: 'Masukkan nama lengkap Anda',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nama tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),

                // Address Field
                _buildTextField(
                  controller: _addressController,
                  label: 'Alamat Lengkap',
                  hintText: 'Masukkan alamat lengkap penjemputan',
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Alamat tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),

                // Waste Type Dropdown
                _buildDropdownField(
                  label: 'Jenis Sampah',
                  hintText: 'Pilih jenis sampah',
                  value: _selectedWasteType,
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
                      return 'Harap pilih jenis sampah';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),

                // Notes Field
                _buildTextField(
                  controller: _notesController,
                  label: 'Catatan (Opsional)',
                  hintText: 'Misal: "Ambil di depan pagar hijau"',
                  maxLines: 2,
                  validator: (value) =>
                      null, // No validation for optional field
                ),
                const SizedBox(height: 32.0),

                // Submit Button
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: _ultraLightEmerald,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Icon(icon, size: 28, color: _primaryEmerald),
        ),
        const SizedBox(width: 12.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w600,
                  color: _darkEmerald,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                subtitle,
                style: TextStyle(fontSize: 13.0, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
    String? hintText,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.w600,
            color: _darkEmerald,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8.0),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: Colors.grey[400]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: Colors.grey[400]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: _primaryEmerald, width: 2.0),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: Colors.red, width: 2.0),
            ),
            filled: true,
            fillColor: _pureWhite,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 14.0,
            ),
          ),
          maxLines: maxLines,
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String hintText,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.w600,
            color: _darkEmerald,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8.0),
        DropdownButtonFormField<String>(
          value: value,
          hint: Text(hintText),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: Colors.grey[400]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: Colors.grey[400]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: _primaryEmerald, width: 2.0),
            ),
            filled: true,
            fillColor: _pureWhite,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 14.0,
            ),
          ),
          isExpanded: true,
          onChanged: onChanged,
          items: items,
          validator: validator,
          style: const TextStyle(fontSize: 14.0, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: _primaryEmerald.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryEmerald,
          foregroundColor: _pureWhite,
          padding: const EdgeInsets.symmetric(vertical: 18.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Kirim Permintaan',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
