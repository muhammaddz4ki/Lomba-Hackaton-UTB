import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:intl/intl.dart';
import 'location_picker_screen.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedReportType;
  final List<String> _reportTypes = [
    'Tumpukan Sampah Ilegal',
    'Fasilitas Rusak',
    'Lainnya',
  ];
  File? _imageFile;
  Position? _currentPosition;
  String _locationMessage = 'Lokasi belum diambil';
  bool _isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();
  final CloudinaryPublic cloudinary = CloudinaryPublic(
    'dofcteuvu',
    'SiBersih',
    cache: false,
  );

  // SiBersih Color Palette
  static const Color _primaryEmerald = Color(0xFF10B981);
  static const Color _darkEmerald = Color(0xFF047857);
  static const Color _lightEmerald = Color(0xFF34D399);
  static const Color _tealAccent = Color(0xFF14B8A6);
  static const Color _ultraLightEmerald = Color(0xFFECFDF5);
  static const Color _pureWhite = Color(0xFFFFFFFF);
  static const Color _background = Color(0xFFF8FDFD);

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil lokasi: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      setState(() {
        _locationMessage = 'Lokasi belum diambil';
      });
    }
  }

  Future<void> _openLocationPicker() async {
    final latlng.LatLng initialLoc = _currentPosition != null
        ? latlng.LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : const latlng.LatLng(-6.9175, 107.6191);

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
          'Lokasi terpilih:\n${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
    });
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil gambar: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'Pilih Bukti Foto',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.w600,
                    color: _darkEmerald,
                  ),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: _ultraLightEmerald,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Icon(Icons.photo_library, color: _primaryEmerald),
                ),
                title: Text(
                  'Pilih dari Galeri',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: _ultraLightEmerald,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Icon(Icons.photo_camera, color: _primaryEmerald),
                ),
                title: Text(
                  'Ambil Foto (Kamera)',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 16.0),
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

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap lampirkan bukti foto.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap ambil lokasi GPS.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
        'reporterEmail': user.email,
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
            behavior: SnackBarBehavior.floating,
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

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text(
          'Buat Laporan',
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
        child: Column(
          children: [
            // Form Section
            Container(
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    _buildSectionHeader(
                      icon: Icons.report_problem_rounded,
                      title: 'Laporkan Masalah',
                      subtitle: 'Bantu kami menjaga kebersihan lingkungan',
                    ),
                    const SizedBox(height: 24.0),

                    // Form Fields
                    _buildTextField(
                      controller: _titleController,
                      label: 'Judul Laporan',
                      hintText: 'Misal: Sampah di Depan Pasar',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Judul tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),

                    _buildDropdownField(),
                    const SizedBox(height: 16.0),

                    _buildTextField(
                      controller: _descriptionController,
                      label: 'Deskripsi Laporan',
                      hintText: 'Jelaskan detail masalah yang ditemukan...',
                      maxLines: 4,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Deskripsi tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24.0),

                    // Location Section
                    _buildLocationSection(),
                    const SizedBox(height: 24.0),

                    // Image Section
                    _buildImageSection(),
                    const SizedBox(height: 24.0),

                    // Submit Button
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),

            // History Section
            const SizedBox(height: 32.0),
            _buildHistorySection(),
          ],
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

  Widget _buildDropdownField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipe Laporan',
          style: TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.w600,
            color: _darkEmerald,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8.0),
        DropdownButtonFormField<String>(
          value: _selectedReportType,
          hint: const Text('Pilih tipe laporan'),
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
          items: _reportTypes.map((String type) {
            return DropdownMenuItem<String>(value: type, child: Text(type));
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedReportType = newValue;
            });
          },
          validator: (value) {
            if (value == null) {
              return 'Harap pilih tipe laporan';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lokasi Kejadian',
          style: TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.w600,
            color: _darkEmerald,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8.0),
        Text(
          'Tentukan lokasi masalah yang dilaporkan',
          style: TextStyle(fontSize: 12.0, color: Colors.grey[600]),
        ),
        const SizedBox(height: 12.0),

        // Current Location Button
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: OutlinedButton.icon(
            onPressed: _getCurrentLocation,
            icon: Icon(
              Icons.my_location,
              color: _currentPosition != null
                  ? _primaryEmerald
                  : Colors.grey[600],
            ),
            label: Text(
              _locationMessage,
              style: TextStyle(
                color: _currentPosition != null
                    ? _darkEmerald
                    : Colors.grey[600],
                fontWeight: _currentPosition != null
                    ? FontWeight.w500
                    : FontWeight.normal,
              ),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              side: BorderSide(
                color: _currentPosition != null
                    ? _primaryEmerald
                    : Colors.grey[400]!,
                width: _currentPosition != null ? 1.5 : 1.0,
              ),
              backgroundColor: _pureWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12.0),

        // Map Picker Button
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: _primaryEmerald.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: _openLocationPicker,
            icon: const Icon(Icons.map_outlined, size: 20),
            label: const Text(
              'Pilih Manual di Peta',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              backgroundColor: _primaryEmerald,
              foregroundColor: _pureWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bukti Foto',
          style: TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.w600,
            color: _darkEmerald,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8.0),
        GestureDetector(
          onTap: _showImagePickerOptions,
          child: Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _pureWhite,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: _imageFile != null ? _primaryEmerald : Colors.grey[300]!,
                width: _imageFile != null ? 2.0 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _imageFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16.0),
                    child: Image.file(_imageFile!, fit: BoxFit.cover),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'Lampirkan Bukti Foto',
                        style: TextStyle(
                          fontSize: 14.0,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        'Ketuk untuk memilih foto',
                        style: TextStyle(
                          fontSize: 12.0,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
          ),
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
        onPressed: _isLoading ? null : _submitReport,
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
                    'Kirim Laporan',
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

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            'Riwayat Laporan Saya',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.w600,
              color: _darkEmerald,
            ),
          ),
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
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(_primaryEmerald),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(40.0),
                decoration: BoxDecoration(
                  color: _pureWhite,
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.history_outlined,
                      size: 64,
                      color: _lightEmerald.withOpacity(0.4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada riwayat laporan',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Laporan yang Anda kirim akan muncul di sini',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: snapshot.data!.docs.map((doc) {
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                final timestamp = data['createdAt'] as Timestamp?;
                final date = timestamp != null
                    ? DateFormat(
                        'dd MMM yyyy, HH:mm',
                      ).format(timestamp.toDate())
                    : 'Tanggal tidak tersedia';

                Color statusColor = Colors.amber;
                if (data['status'] == 'Completed') statusColor = Colors.green;
                if (data['status'] == 'Rejected') statusColor = Colors.red;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: _pureWhite,
                    borderRadius: BorderRadius.circular(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (data['imageUrl'] != null)
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16.0),
                              topRight: Radius.circular(16.0),
                            ),
                            child: Image.network(
                              data['imageUrl'],
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  height: 180,
                                  color: _ultraLightEmerald,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        _primaryEmerald,
                                      ),
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 180,
                                  color: _ultraLightEmerald,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.broken_image_outlined,
                                        size: 40,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Gambar tidak tersedia',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['title'],
                                style: const TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              Text(
                                data['description'],
                                style: TextStyle(
                                  fontSize: 14.0,
                                  color: Colors.grey[700],
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 12.0),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12.0,
                                      vertical: 6.0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8.0),
                                      border: Border.all(
                                        color: statusColor.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      data['status'] ?? 'Pending',
                                      style: TextStyle(
                                        fontSize: 12.0,
                                        fontWeight: FontWeight.w600,
                                        color: statusColor,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    data['reportType'] ?? 'Lainnya',
                                    style: TextStyle(
                                      fontSize: 12.0,
                                      color: Colors.grey[600],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8.0),
                              Text(
                                date,
                                style: TextStyle(
                                  fontSize: 11.0,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
