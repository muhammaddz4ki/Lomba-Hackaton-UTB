import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'my_listings_screen.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'location_picker_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool _isUploading = false;

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

  Future<void> _changeProfilePicture() async {
    final source = await _showImageSourceDialog();
    if (source == null) return;
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 600,
        maxHeight: 600,
      );
      if (pickedFile == null) return;
      setState(() => _isUploading = true);
      File imageFile = File(pickedFile.path);
      CloudinaryFile file = CloudinaryFile.fromFile(
        imageFile.path,
        folder: 'profile_pictures',
        publicId: user!.uid,
        resourceType: CloudinaryResourceType.Image,
      );
      CloudinaryResponse response = await cloudinary.uploadFile(file);
      String imageUrl = response.secureUrl;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({'photoUrl': imageUrl});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto profil berhasil diperbarui!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal meng-upload foto: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showModalBottomSheet<ImageSource>(
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
                  'Pilih Foto Profil',
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
                  Navigator.of(context).pop(ImageSource.gallery);
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
                  Navigator.of(context).pop(ImageSource.camera);
                },
              ),
              const SizedBox(height: 16.0),
            ],
          ),
        );
      },
    );
  }

  Future<void> _changePassword() async {
    final bool? didConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ganti Password'),
        content: Text(
          'Kami akan mengirimkan link untuk reset password ke email Anda:\n\n${user?.email}\n\nLanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Kirim Email'),
          ),
        ],
      ),
    );
    if (didConfirm != true) return;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Link ganti password telah dikirim ke email Anda!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim email: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _performLogout() async {
    final bool? didRequestSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Keluar',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (didRequestSignOut == true) {
      if (mounted) Navigator.pop(context);
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
    }
  }

  Future<void> _showTpsLocationDialog(Map<String, dynamic> currentData) async {
    final addressController = TextEditingController(
      text: currentData['tpsAddress'],
    );

    GeoPoint? selectedLocation = currentData['tpsLocation'];

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Izin lokasi ditolak.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        return;
      }
    }

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            String locationStatus = "Ambil Lokasi GPS Saat Ini";
            if (selectedLocation != null) {
              locationStatus =
                  'Lokasi: ${selectedLocation!.latitude.toStringAsFixed(4)}, ${selectedLocation!.longitude.toStringAsFixed(4)}';
            }

            return AlertDialog(
              title: const Text('Update Info Lokasi TPS'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: addressController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Jalan / Alamat',
                        hintText: 'Misal: Jl. Merdeka No. 10',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16.0),

                    OutlinedButton.icon(
                      onPressed: () async {
                        setState(() {
                          locationStatus = 'Mencari lokasi...';
                        });
                        try {
                          const LocationSettings locationSettings =
                              LocationSettings(accuracy: LocationAccuracy.high);
                          Position position =
                              await Geolocator.getCurrentPosition(
                                desiredAccuracy: LocationAccuracy.high,
                              );

                          selectedLocation = GeoPoint(
                            position.latitude,
                            position.longitude,
                          );
                          setState(() {
                            locationStatus = 'Lokasi GPS berhasil diambil!';
                          });
                        } catch (e) {
                          setState(() {
                            locationStatus = 'Gagal! Coba lagi.';
                          });
                        }
                      },
                      icon: const Icon(Icons.my_location),
                      label: Text(locationStatus),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: (selectedLocation != null)
                            ? Colors.green
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8.0),

                    ElevatedButton.icon(
                      onPressed: () async {
                        final latlng.LatLng initialLoc =
                            selectedLocation != null
                            ? latlng.LatLng(
                                selectedLocation!.latitude,
                                selectedLocation!.longitude,
                              )
                            : const latlng.LatLng(-6.9175, 107.6191);

                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LocationPickerScreen(
                              initialLocation: initialLoc,
                            ),
                          ),
                        );

                        if (result != null && result is latlng.LatLng) {
                          setState(() {
                            selectedLocation = GeoPoint(
                              result.latitude,
                              result.longitude,
                            );
                            locationStatus =
                                'Lokasi: ${selectedLocation!.latitude.toStringAsFixed(4)}, ${selectedLocation!.longitude.toStringAsFixed(4)}';
                          });
                        }
                      },
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('Pilih Manual di Peta'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryEmerald,
                        foregroundColor: _pureWhite,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedLocation == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Anda harus mengambil lokasi GPS atau memilih di peta.',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }
                    _updateTpsLocation(
                      addressController.text,
                      selectedLocation,
                    );
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateTpsLocation(String address, GeoPoint? location) async {
    if (user == null || location == null) return;

    Map<String, dynamic> updateData = {
      'tpsAddress': address.trim(),
      'tpsLocation': location,
    };

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update(updateData);

      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lokasi TPS berhasil diperbarui!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal update lokasi: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        backgroundColor: _background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_off_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Pengguna tidak ditemukan',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text(
          'Profil Saya',
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
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_primaryEmerald),
              ),
            );
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Data pengguna tidak ditemukan',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          Map<String, dynamic> data =
              snapshot.data!.data() as Map<String, dynamic>;
          String? photoUrl = data['photoUrl'];
          String name = data['name'] ?? 'Nama Tidak Ada';
          String email = data['email'] ?? 'Email Tidak Ada';
          String role = data['role'] ?? 'Peran Tidak Diketahui';
          int points = data['points'] ?? 0;
          final timestamp = data['createdAt'] as Timestamp?;
          final joinDate = timestamp != null
              ? DateFormat('dd MMMM yyyy').format(timestamp.toDate())
              : 'Tanggal tidak tersedia';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Profile Header
                Container(
                  padding: const EdgeInsets.all(24.0),
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
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _primaryEmerald.withOpacity(0.3),
                                width: 3,
                              ),
                            ),
                            child: ClipOval(
                              child: _isUploading
                                  ? Center(
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              _primaryEmerald,
                                            ),
                                      ),
                                    )
                                  : (photoUrl != null
                                        ? Image.network(
                                            photoUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Icon(
                                                    Icons.person,
                                                    size: 50,
                                                    color: _primaryEmerald,
                                                  );
                                                },
                                          )
                                        : Icon(
                                            Icons.person,
                                            size: 50,
                                            color: _primaryEmerald,
                                          )),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: _primaryEmerald,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: _primaryEmerald.withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                onPressed: _isUploading
                                    ? null
                                    : _changeProfilePicture,
                                icon: const Icon(
                                  Icons.camera_alt,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: _primaryEmerald,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16.0),
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.w700,
                          color: _darkEmerald,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 15.0,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8.0),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 6.0,
                        ),
                        decoration: BoxDecoration(
                          color: _ultraLightEmerald,
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(
                            color: _primaryEmerald.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          role,
                          style: TextStyle(
                            fontSize: 12.0,
                            color: _darkEmerald,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'Bergabung sejak $joinDate',
                        style: TextStyle(
                          fontSize: 12.0,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20.0),

                // Points Card (Masyarakat) atau TPS Card
                if (role == 'Masyarakat')
                  _buildPointsCard(context, points)
                else
                  _buildTpsCard(context, data),

                const SizedBox(height: 20.0),

                // Action Buttons
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
                  child: Column(
                    children: [
                      if (role == 'Masyarakat')
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12.0),
                            boxShadow: [
                              BoxShadow(
                                color: _primaryEmerald.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const MyListingsScreen(),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.storefront_outlined,
                              size: 20,
                            ),
                            label: const Text('Kelola Barang Jualan Saya'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryEmerald,
                              foregroundColor: _pureWhite,
                              padding: const EdgeInsets.symmetric(
                                vertical: 16.0,
                                horizontal: 16.0,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                            ),
                          ),
                        ),
                      if (role == 'Masyarakat') const SizedBox(height: 12.0),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: ElevatedButton.icon(
                          onPressed:
                              user!.providerData.any(
                                (info) => info.providerId == 'password',
                              )
                              ? _changePassword
                              : null,
                          icon: const Icon(Icons.lock_reset_outlined, size: 20),
                          label: Text(
                            user!.providerData.any(
                                  (info) => info.providerId == 'password',
                                )
                                ? 'Ganti Password'
                                : 'Ganti Password (Nonaktif untuk Google)',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _pureWhite,
                            foregroundColor: Colors.grey[700],
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              vertical: 16.0,
                              horizontal: 16.0,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12.0),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                          ),
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _performLogout,
                          icon: const Icon(Icons.logout, size: 20),
                          label: const Text('Logout'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.withOpacity(0.05),
                            foregroundColor: Colors.red,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              vertical: 16.0,
                              horizontal: 16.0,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPointsCard(BuildContext context, int points) {
    return Container(
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: _ultraLightEmerald,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Icon(Icons.star_rounded, color: _primaryEmerald, size: 32),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Poin SiBersih Anda',
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  points.toString(),
                  style: TextStyle(
                    fontSize: 28.0,
                    fontWeight: FontWeight.w700,
                    color: _primaryEmerald,
                  ),
                ),
                Text(
                  'Tukarkan poin Anda untuk mendapatkan manfaat',
                  style: TextStyle(fontSize: 12.0, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTpsCard(BuildContext context, Map<String, dynamic> data) {
    String tpsAddress = data['tpsAddress'] ?? 'Alamat belum diatur';
    GeoPoint? tpsLocation = data['tpsLocation'];
    String locationString = 'Lokasi GPS belum diatur';
    if (tpsLocation != null) {
      locationString =
          '${tpsLocation.latitude.toStringAsFixed(4)}, ${tpsLocation.longitude.toStringAsFixed(4)}';
    }

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: _ultraLightEmerald,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(
                  Icons.verified_user_rounded,
                  size: 20,
                  color: _primaryEmerald,
                ),
              ),
              const SizedBox(width: 12.0),
              Text(
                'Akun Petugas TPS Terverifikasi',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                  color: _darkEmerald,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          _buildInfoRow(
            icon: Icons.store_mall_directory_outlined,
            title: 'Alamat TPS',
            value: tpsAddress,
          ),
          const SizedBox(height: 12.0),
          _buildInfoRow(
            icon: Icons.location_on_outlined,
            title: 'Koordinat GPS',
            value: locationString,
          ),
          const SizedBox(height: 16.0),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: _primaryEmerald.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                _showTpsLocationDialog(data);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryEmerald,
                foregroundColor: _pureWhite,
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              child: const Text('Update Alamat & Lokasi TPS'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: _primaryEmerald),
        const SizedBox(width: 12.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13.0,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2.0),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14.0,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
