import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'request_pickup_screen.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- (Fungsi _completeRequest dan _buildStatusWidget - TIDAK BERUBAH) ---
  // (Kita masih butuh ini untuk bagian Riwayat)
  String? _getTransformedUrl(String? imageUrl) {
    if (imageUrl == null) return null;
    return imageUrl.replaceFirst('/upload/', '/upload/w_600,q_auto:good/');
  }

  Future<void> _completeRequest(String docId, {String? imageUrl}) async {
    final String? transformedUrl = _getTransformedUrl(imageUrl);
    final bool? didConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Selesai'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (transformedUrl != null) ...[
              Text(
                'Bukti Foto dari TPS:',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8.0),
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Image.network(
                  transformedUrl,
                  height: 250,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 250,
                      color: Colors.grey[300],
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 250,
                      color: Colors.grey[300],
                      child: const Center(
                        child: Text(
                          'Gagal memuat bukti foto.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16.0),
              const Divider(),
              const SizedBox(height: 16.0),
            ] else ...[
              const Text(
                'TPS belum meng-upload bukti foto.',
                style: TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16.0),
            ],
            const Text(
              'Apakah Anda yakin pekerjaan telah selesai?',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Selesai'),
          ),
        ],
      ),
    );
    if (didConfirm != true) return;
    try {
      await _firestore.collection('emergency_requests').doc(docId).update({
        'status': 'Completed',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permintaan telah ditandai selesai!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyelesaikan permintaan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildStatusWidget(Map<String, dynamic> data, String docId) {
    String status = data['status'];
    switch (status) {
      case 'Pending':
        return const Chip(
          label: Text('Menunggu TPS'),
          backgroundColor: Colors.amber,
          labelStyle: TextStyle(color: Colors.black87),
        );
      case 'On Progress':
        bool hasProof =
            data['proofImageUrl'] != null && data['proofImageUrl'].isNotEmpty;
        if (hasProof) {
          return ElevatedButton(
            onPressed: () {
              _completeRequest(docId, imageUrl: data['proofImageUrl']);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Lihat Bukti & Selesai'),
          );
        } else {
          return const Chip(
            label: Text('Dikerjakan TPS'),
            backgroundColor: Colors.blue,
            labelStyle: TextStyle(color: Colors.white),
          );
        }
      case 'Completed':
        return const Chip(
          label: Text('Selesai'),
          avatar: Icon(Icons.check, color: Colors.white),
          backgroundColor: Colors.green,
          labelStyle: TextStyle(color: Colors.white),
        );
      default:
        return Text(status);
    }
  }
  // --- (AKHIR FUNGSI TIDAK BERUBAH) ---

  // --- (WIDGET BARU) Untuk Menampilkan Jadwal Umum ---
  Widget _buildPublicScheduleList(BuildContext context) {
    return Container(
      height: 140.0, // Tentukan tinggi 'carousel'
      child: StreamBuilder<QuerySnapshot>(
        // Ambil SEMUA jadwal umum, urutkan berdasarkan area
        stream: _firestore
            .collection('public_schedules')
            .orderBy('areaName')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Gagal memuat jadwal.'));
          }
          if (snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada jadwal umum dari TPS.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          // Tampilkan sebagai ListView horizontal
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              Map<String, dynamic> data =
                  snapshot.data!.docs[index].data() as Map<String, dynamic>;

              List<String> days = List<String>.from(data['days'] ?? []);
              String daysString = days.join(', ');

              // Kartu Jadwal
              return Card(
                color: Theme.of(context).colorScheme.surfaceVariant,
                child: Container(
                  width: 250.0, // Tentukan lebar kartu
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['areaName'],
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'Hari: $daysString',
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(), // Dorong info jam ke bawah
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_outlined,
                            size: 16.0,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 4.0),
                          Text(
                            '${data['timeStart']} - ${data['timeEnd']}',
                            style: TextStyle(
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
            },
          );
        },
      ),
    );
  }
  // --- (AKHIR WIDGET BARU) ---

  @override
  Widget build(BuildContext context) {
    final User? user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal & Riwayat'), // Ganti judul
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      // --- (STRUCTURE DIPERBARUI) ---
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Tombol Permintaan Reguler
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RequestPickupScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add_location_alt),
              label: const Text('Buat Permintaan Jemput (Reguler)'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),

          const SizedBox(height: 24.0),

          // --- (BAGIAN BARU) ---
          // 2. Judul Jadwal Umum
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Jadwal Pengangkutan Umum',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 10.0),
          // 3. List Jadwal Umum (Horizontal)
          _buildPublicScheduleList(context),

          // --- (AKHIR BAGIAN BARU) ---
          const SizedBox(height: 24.0),
          const Divider(indent: 16.0, endIndent: 16.0),

          // 4. Judul Riwayat
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 10.0),
            child: Text(
              'Riwayat Permintaan Darurat:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),

          // 5. List Riwayat (Expanded)
          Expanded(
            child: user == null
                ? const Center(
                    child: Text('Silakan login untuk melihat riwayat.'),
                  )
                : StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('emergency_requests')
                        .where('requesterUid', isEqualTo: user.uid)
                        .orderBy('createdAt', descending: true)
                        .snapshots(),

                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text(
                            'Belum ada riwayat permintaan darurat.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }

                      return ListView(
                        // Hapus padding atas, beri padding bawah
                        padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                        children: snapshot.data!.docs.map((doc) {
                          Map<String, dynamic> data =
                              doc.data() as Map<String, dynamic>;
                          String docId = doc.id;
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            child: ListTile(
                              isThreeLine: true,
                              title: Text(data['description']),
                              subtitle: Text(
                                'Lokasi: ${data['locationAddress']}\nBiaya: Rp ${data['fee']}',
                              ),
                              trailing: _buildStatusWidget(data, docId),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
