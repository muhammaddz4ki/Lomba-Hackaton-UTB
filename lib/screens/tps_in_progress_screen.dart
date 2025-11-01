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
    'dofcteuvu',
    'SiBersih',
    cache: false,
  );
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  // Color Palette
  static const Color _primaryEmerald = Color(0xFF10B981);
  static const Color _darkEmerald = Color(0xFF047857);
  static const Color _lightEmerald = Color(0xFF34D399);
  static const Color _tealAccent = Color(0xFF14B8A6);
  static const Color _ultraLightEmerald = Color(0xFFECFDF5);
  static const Color _pureWhite = Color(0xFFFFFFFF);
  static const Color _background = Color(0xFFF8FDFD);
  static const Color _warningColor = Color(0xFFF59E0B);
  static const Color _successColor = Color(0xFF10B981);
  static const Color _errorColor = Color(0xFFEF4444);

  Future<void> _uploadProof(String docId) async {
    final XFile? pickedFile;
    try {
      pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (pickedFile == null) return;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka kamera: $e'),
            backgroundColor: _errorColor,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
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
          SnackBar(
            content: const Text('Bukti berhasil di-upload!'),
            backgroundColor: _successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal meng-upload bukti: $e'),
            backgroundColor: _errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_turned_in_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak Ada Pekerjaan Aktif',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Semua pekerjaan telah selesai',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(
    Map<String, dynamic> data,
    String docId,
    bool hasProof,
  ) {
    final timestamp = data['createdAt'] as Timestamp?;
    final dateTime = timestamp?.toDate() ?? DateTime.now();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      decoration: BoxDecoration(
        color: _pureWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header dengan status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _ultraLightEmerald,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _lightEmerald, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule, size: 14, color: _darkEmerald),
                      const SizedBox(width: 4),
                      Text(
                        'Dalam Proses',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _darkEmerald,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${dateTime.day}/${dateTime.month}/${dateTime.year}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Deskripsi
            Text(
              data['description'] ?? 'Tidak ada deskripsi',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),

            // Informasi Pelapor
            _buildInfoRow(
              Icons.person_outline,
              'Pelapor',
              data['requesterEmail'] ?? 'Tidak diketahui',
            ),

            const SizedBox(height: 8),

            // Informasi Lokasi
            _buildInfoRow(
              Icons.location_on_outlined,
              'Lokasi',
              data['locationAddress'] ?? 'Lokasi tidak tersedia',
            ),

            const SizedBox(height: 16),

            // Tombol Aksi
            if (!hasProof) _buildUploadButton(docId),
            if (hasProof) _buildProofUploaded(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUploadButton(String docId) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : () => _uploadProof(docId),
        icon: const Icon(Icons.camera_alt, size: 18),
        label: const Text(
          'Upload Bukti Foto',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryEmerald,
          foregroundColor: _pureWhite,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildProofUploaded() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: _ultraLightEmerald,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _lightEmerald, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: _successColor, size: 20),
          const SizedBox(width: 8),
          Text(
            'Bukti Telah Dikirim',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _darkEmerald,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (tpsUid == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Tidak bisa memuat data TPS',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: _background,
      body: Stack(
        children: [
          // Content
          Column(
            children: [
              const SizedBox(height: 16),

              // List Content
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('emergency_requests')
                      .where('status', isEqualTo: 'On Progress')
                      .where('tpsId', isEqualTo: tpsUid)
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder:
                      (
                        BuildContext context,
                        AsyncSnapshot<QuerySnapshot> snapshot,
                      ) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 50,
                                  color: _errorColor,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Terjadi error: ${snapshot.error}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.data!.docs.isEmpty) {
                          return _buildEmptyState();
                        }

                        return RefreshIndicator(
                          backgroundColor: _pureWhite,
                          color: _primaryEmerald,
                          onRefresh: () async {
                            setState(() {});
                          },
                          child: ListView(
                            padding: const EdgeInsets.only(bottom: 16),
                            children: snapshot.data!.docs.map((
                              DocumentSnapshot document,
                            ) {
                              Map<String, dynamic> data =
                                  document.data()! as Map<String, dynamic>;
                              String docId = document.id;
                              bool hasProof =
                                  data['proofImageUrl'] != null &&
                                  data['proofImageUrl'].isNotEmpty;

                              return _buildRequestCard(data, docId, hasProof);
                            }).toList(),
                          ),
                        );
                      },
                ),
              ),
            ],
          ),

          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _pureWhite,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Meng-upload bukti...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
