import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';

class TpsInProgressScreen extends StatefulWidget {
  const TpsInProgressScreen({super.key});

  @override
  State<TpsInProgressScreen> createState() => _TpsInProgressScreenState();
}

class _TpsInProgressScreenState extends State<TpsInProgressScreen> {
  final String? tpsUid = FirebaseAuth.instance.currentUser?.uid;

  final CloudinaryPublic cloudinary = CloudinaryPublic(
    'dofcteuvu', // Cloud Name-mu
    'SiBersih', // Upload Preset-mu
    cache: false,
  );
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;

  // --- (FUNGSI INI YANG DIPERBARUI) ---
  Future<void> _uploadProof(String docId) async {
    final XFile? pickedFile;
    try {
      // --- (PERUBAHAN DI SINI) ---
      // Kita tambahkan 'imageQuality: 80'
      // Ini akan mengkompres gambar menjadi 80% dari kualitas aslinya
      // sebelum di-upload. (0=jelek, 100=asli)
      pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80, // Kompresi 80%
      );
      // --- (AKHIR PERUBAHAN) ---

      if (pickedFile == null) return; // Pengguna membatalkan
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal membuka kamera: $e')));
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      // (Sisa fungsi ini tidak berubah...)
      File imageFile = File(pickedFile.path);
      CloudinaryFile file = CloudinaryFile.fromFile(
        imageFile.path,
        resourceType: CloudinaryResourceType.Image,
      );
      CloudinaryResponse response = await cloudinary.uploadFile(file);
      String imageUrl = response.secureUrl;

      await FirebaseFirestore.instance
          .collection('emergency_requests')
          .doc(docId)
          .update({'proofImageUrl': imageUrl});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bukti berhasil di-upload!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal meng-upload bukti: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
  // --- (AKHIR FUNGSI DIPERBARUI) ---

  @override
  Widget build(BuildContext context) {
    if (tpsUid == null) {
      return const Center(child: Text('Error: Tidak bisa memuat data TPS.'));
    }

    return Scaffold(
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('emergency_requests')
                .where('status', isEqualTo: 'On Progress')
                .where('tpsId', isEqualTo: tpsUid)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Terjadi error: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    'Tidak ada pekerjaan yang sedang dikerjakan.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.all(8.0),
                children: snapshot.data!.docs.map((DocumentSnapshot document) {
                  Map<String, dynamic> data =
                      document.data()! as Map<String, dynamic>;
                  String docId = document.id;
                  bool hasProof =
                      data['proofImageUrl'] != null &&
                      data['proofImageUrl'].isNotEmpty;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      isThreeLine: true,
                      title: Text(
                        data['description'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Pelapor: ${data['requesterEmail']}\nLokasi: ${data['locationAddress']}',
                      ),
                      trailing: hasProof
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle, color: Colors.green),
                                Text('Terkirim'),
                              ],
                            )
                          : ElevatedButton.icon(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      _uploadProof(docId);
                                    },
                              icon: const Icon(
                                Icons.camera_alt_outlined,
                                size: 18,
                              ),
                              label: const Text('Upload\nBukti'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.secondary,
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.onSecondary,
                              ),
                            ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Meng-upload bukti...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
