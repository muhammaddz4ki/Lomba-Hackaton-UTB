import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:geolocator/geolocator.dart';
import 'my_listings_screen.dart';

// Impor paket peta & halaman pemilih
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

  // --- (Fungsi _changeProfilePicture, _showImageSourceDialog, _changePassword, _performLogout) ---
  // (Dibiarkan sama, asumsikan kodenya sudah disalin dari respons sebelumnya)

  // Fungsi _changeProfilePicture
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
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal meng-upload foto: $e')));
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  // Fungsi _showImageSourceDialog
  Future<ImageSource?> _showImageSourceDialog() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.of(context).pop(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Ambil Foto (Kamera)'),
                onTap: () {
                  Navigator.of(context).pop(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Fungsi _changePassword
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
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim email: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Fungsi _performLogout
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

  // --- (FUNGSI DIALOG TPS DIPERBAIKI LOGIKA MAPPINGNYA) ---
  Future<void> _showTpsLocationDialog(Map<String, dynamic> currentData) async {
    final addressController = TextEditingController(
      text: currentData['tpsAddress'],
    );

    // selectedLocation sekarang adalah GeoPoint yang bisa berubah
    GeoPoint? selectedLocation = currentData['tpsLocation'];

    String locationStatus = "Ambil Lokasi GPS Saat Ini";
    if (selectedLocation != null) {
      locationStatus =
          'Lokasi: ${selectedLocation.latitude.toStringAsFixed(4)}, ${selectedLocation.longitude.toStringAsFixed(4)}';
    }

    StateSetter? dialogSetState;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Izin lokasi ditolak.')));
        return;
      }
    }

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            dialogSetState = setState;

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
                        dialogSetState!(() {
                          locationStatus = 'Mencari lokasi...';
                        });
                        try {
                          const LocationSettings locationSettings =
                              LocationSettings(accuracy: LocationAccuracy.high);
                          Position position =
                              await Geolocator.getPositionStream(
                                locationSettings: locationSettings,
                              ).first;
                          selectedLocation = GeoPoint(
                            position.latitude,
                            position.longitude,
                          );
                          dialogSetState!(() {
                            locationStatus = 'Lokasi GPS berhasil diambil!';
                          });
                        } catch (e) {
                          dialogSetState!(() {
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

                        // Tutup dialog
                        Navigator.pop(dialogContext);

                        // Buka Peta Pemilih
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LocationPickerScreen(
                              initialLocation: initialLoc,
                            ),
                          ),
                        );

                        // --- (PERBAIKAN LOGIKA PEMANGGILAN ULANG) ---
                        // Jika dapat hasil, update state dan panggil dialog lagi
                        if (result != null && result is latlng.LatLng) {
                          selectedLocation = GeoPoint(
                            result.latitude,
                            result.longitude,
                          );
                        }

                        // Buka kembali dialog dengan lokasi terbaru
                        _showTpsLocationDialog(currentData);
                        // --- (AKHIR PERBAIKAN) ---
                      },
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('Pilih Manual di Peta'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.secondary,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onSecondary,
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
                            'Anda harus mengambil lokasi GPS baru.',
                          ),
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

  // --- (FUNGSI PENYIMPANAN) ---
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
          ),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal update lokasi: $e'),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Pengguna tidak ditemukan.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Data pengguna tidak ditemukan.'));
          }

          Map<String, dynamic> data =
              snapshot.data!.data() as Map<String, dynamic>;
          String? photoUrl = data['photoUrl'];
          String name = data['name'] ?? 'Nama Tidak Ada';
          String email = data['email'] ?? 'Email Tidak Ada';
          String role = data['role'] ?? 'Peran Tidak Diketahui';
          int points = data['points'] ?? 0;

          return ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              // Info Profil
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: (photoUrl != null)
                          ? NetworkImage(photoUrl)
                          : null,
                      child: (photoUrl == null && !_isUploading)
                          ? const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    if (_isUploading)
                      const Positioned.fill(child: CircularProgressIndicator()),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: IconButton.filled(
                        onPressed: _isUploading ? null : _changeProfilePicture,
                        icon: const Icon(Icons.camera_alt, size: 20),
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),
              Center(
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 4.0),
              Center(
                child: Text(
                  email,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24.0),

              // Poin (Masyarakat) atau Info Lokasi (TPS)
              if (role == 'Masyarakat')
                _buildPointsCard(context, points)
              else
                _buildTpsCard(context, data),

              const SizedBox(height: 32.0),
              const Divider(),
              const SizedBox(height: 16.0),

              // Tombol Aksi
              if (role == 'Masyarakat')
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyListingsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.storefront_outlined),
                  label: const Text('Kelola Barang Jualan Saya'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    backgroundColor: Theme.of(context).colorScheme.tertiary,
                    foregroundColor: Theme.of(context).colorScheme.onTertiary,
                  ),
                ),
              if (role == 'Masyarakat') const SizedBox(height: 16.0),
              ElevatedButton.icon(
                onPressed:
                    user!.providerData.any(
                      (info) => info.providerId == 'password',
                    )
                    ? _changePassword
                    : null,
                icon: const Icon(Icons.lock_reset_outlined),
                label: Text(
                  user!.providerData.any(
                        (info) => info.providerId == 'password',
                      )
                      ? 'Ganti Password'
                      : 'Ganti Password (Nonaktif u/ Google)',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                ),
              ),

              const SizedBox(height: 16.0),
              OutlinedButton.icon(
                onPressed: _performLogout,
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  side: BorderSide(color: Theme.of(context).colorScheme.error),
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Widget Poin (Masyarakat)
  Widget _buildPointsCard(BuildContext context, int points) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.star,
              color: Theme.of(context).colorScheme.primary,
              size: 30,
            ),
            const SizedBox(width: 16.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Poin SiBersih Anda:'),
                Text(
                  points.toString(),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget Info Lokasi (TPS)
  Widget _buildTpsCard(BuildContext context, Map<String, dynamic> data) {
    String tpsAddress = data['tpsAddress'] ?? 'Alamat belum diatur';
    GeoPoint? tpsLocation = data['tpsLocation'];
    String locationString = 'Lokasi GPS belum diatur';
    if (tpsLocation != null) {
      locationString =
          'Lat: ${tpsLocation.latitude.toStringAsFixed(4)}, Lon: ${tpsLocation.longitude.toStringAsFixed(4)}';
    }

    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                  size: 24,
                ),
                const SizedBox(width: 12.0),
                Text(
                  'Akun Petugas TPS Terverifikasi',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24.0),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.store_mall_directory_outlined,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
              title: Text(
                tpsAddress,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(locationString),
            ),
            const SizedBox(height: 8.0),
            ElevatedButton(
              onPressed: () {
                _showTpsLocationDialog(data);
              },
              child: const Text('Update Alamat & Lokasi TPS'),
            ),
          ],
        ),
      ),
    );
  }
}
