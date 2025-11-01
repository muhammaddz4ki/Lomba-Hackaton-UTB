import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';

// --- (BARU) Impor Google Sign In untuk Logout ---
import 'package:google_sign_in/google_sign_in.dart';

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
    'dofcteuvu', // Cloud Name-mu
    'SiBersih',  // Upload Preset-mu
    cache: false,
  );

  // Fungsi _changeProfilePicture (Tidak Berubah)
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal meng-upload foto: $e')),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  // Fungsi _showImageSourceDialog (Tidak Berubah)
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

  // Fungsi _changePassword (Tidak Berubah)
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
  
  // --- (FUNGSI BARU) Untuk Logout ---
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
          // Beri warna merah untuk tombol keluar
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Keluar', 
              style: TextStyle(color: Theme.of(context).colorScheme.error)
            ),
          ),
        ],
      ),
    );
    
    if (didRequestSignOut == true) {
      // (PENTING) Kita pop dulu halaman Profile agar kembali ke Home,
      // baru AuthGate akan mendeteksi logout & pindah ke Login
      if (mounted) Navigator.pop(context); 
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
    }
  }
  // --- (AKHIR FUNGSI BARU) ---

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Pengguna tidak ditemukan.')));
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
              // Foto Profil
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: (photoUrl != null) ? NetworkImage(photoUrl) : null,
                      child: (photoUrl == null && !_isUploading)
                          ? const Icon(Icons.person, size: 60, color: Colors.white)
                          : null,
                    ),
                    if (_isUploading)
                      const Positioned.fill(
                        child: CircularProgressIndicator(),
                      ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: IconButton.filled(
                        onPressed: _isUploading ? null : _changeProfilePicture, 
                        icon: const Icon(Icons.camera_alt, size: 20),
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 16.0),
              
              // Info Nama & Email
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

              // Poin / Badge
              if (role == 'Masyarakat')
                _buildPointsCard(context, points)
              else
                _buildTpsBadge(context),

              const SizedBox(height: 32.0),
              const Divider(),
              const SizedBox(height: 16.0),

              // Tombol Ganti Password
              ElevatedButton.icon(
                onPressed: user!.providerData
                        .any((info) => info.providerId == 'password')
                    ? _changePassword 
                    : null, 
                icon: const Icon(Icons.lock_reset_outlined),
                label: Text(
                  user!.providerData.any((info) => info.providerId == 'password')
                    ? 'Ganti Password'
                    : 'Ganti Password (Nonaktif u/ Google)'
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                ),
              ),
              
              // --- (TOMBOL BARU) ---
              const SizedBox(height: 16.0),
              OutlinedButton.icon(
                onPressed: _performLogout, // Panggil fungsi logout
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.error,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                ),
              ),
              // --- (AKHIR TOMBOL BARU) ---
            ],
          );
        },
      ),
    );
  }
  // ... (Widget _buildPointsCard dan _buildTpsBadge tidak berubah) ...
  Widget _buildPointsCard(BuildContext context, int points) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star, color: Theme.of(context).colorScheme.primary, size: 30),
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
            )
          ],
        ),
      ),
    );
  }
  Widget _buildTpsBadge(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_user_outlined, color: Theme.of(context).colorScheme.onSecondaryContainer, size: 30),
            const SizedBox(width: 16.0),
            Text(
              'Akun Petugas TPS Terverifikasi',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}