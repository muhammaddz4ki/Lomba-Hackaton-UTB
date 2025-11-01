import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TpsDepositApprovalScreen extends StatefulWidget {
  const TpsDepositApprovalScreen({super.key});

  @override
  State<TpsDepositApprovalScreen> createState() =>
      _TpsDepositApprovalScreenState();
}

class _TpsDepositApprovalScreenState extends State<TpsDepositApprovalScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? _tpsUid = FirebaseAuth.instance.currentUser?.uid;

  // --- (Fungsi Helper untuk kompresi URL Cloudinary) ---
  String? _getTransformedUrl(String? imageUrl) {
    if (imageUrl == null) return null;
    return imageUrl.replaceFirst(
      '/upload/',
      '/upload/w_600,q_auto:good/',
    );
  }

  // --- (Fungsi Helper untuk Preview Gambar) ---
  Future<void> _showFullImageDialog(BuildContext context, String? imageUrl) async {
    final String? transformedUrl = _getTransformedUrl(imageUrl);
    if (transformedUrl == null) return;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          insetPadding: const EdgeInsets.all(10.0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.network(
                transformedUrl,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    height: 300,
                    color: Colors.grey[300],
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            )
          ],
        );
      },
    );
  }

  // --- (FUNGSI Logika Poin Otomatis) ---
  int _calculatePoints(String wasteType, double weight) {
    int pointsPerKg = 0;
    if (wasteType.startsWith('Plastik')) {
      pointsPerKg = 100;
    } else if (wasteType.startsWith('Kertas')) {
      pointsPerKg = 80;
    } else if (wasteType.startsWith('Logam')) {
      pointsPerKg = 150;
    } else if (wasteType.startsWith('Kaca')) {
      pointsPerKg = 50;
    } else {
      pointsPerKg = 30;
    }
    return (weight * pointsPerKg).round();
  }

  // --- (FUNGSI Menampilkan Dialog Konfirmasi) ---
  Future<void> _showApprovalDialog(
    BuildContext context,
    String docId,
    String requesterUid,
    Map<String, dynamic> data,
  ) async {
    final double estimatedWeight = data['estimatedWeight'] ?? 0.0;
    final String wasteType = data['wasteType'] ?? 'Lainnya';
    final int calculatedPoints = _calculatePoints(wasteType, estimatedWeight);
    final String? transformedUrl = _getTransformedUrl(data['imageUrl']);

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Konfirmasi Setoran'),
          content: SingleChildScrollView( 
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pelapor: ${data['requesterEmail']}'),
                Text('Tipe: $wasteType'),
                Text('Estimasi: $estimatedWeight Kg'),
                const SizedBox(height: 16.0),
                if (transformedUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      transformedUrl,
                      height: 200,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          height: 200,
                          color: Colors.grey[300],
                          child: const Center(child: CircularProgressIndicator()),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 16.0),
                const Divider(),
                Text(
                  'Poin yang Akan Diberikan:',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                Text(
                  '$calculatedPoints Poin',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '($estimatedWeight Kg x $wasteType)',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Konfirmasi & Beri Poin'),
              onPressed: () {
                // (Kita hapus validasi FormKey karena inputnya sudah dihapus)
                _approveDeposit(
                  docId,
                  requesterUid,
                  data,
                  calculatedPoints,
                );
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // --- (FUNGSI Memproses Konfirmasi & Poin) ---
  Future<void> _approveDeposit(
    String docId,
    String requesterUid,
    Map<String, dynamic> data,
    int pointsToAward,
  ) async {
    if (_tpsUid == null) return; 

    WriteBatch batch = _firestore.batch();
    DocumentReference depositRef =
        _firestore.collection('waste_deposits').doc(docId);
    batch.update(depositRef, {
      'status': 'Completed',
      'pointsAwarded': pointsToAward,
      'approverTpsId': _tpsUid,
    });
    DocumentReference userRef =
        _firestore.collection('users').doc(requesterUid);
    batch.update(userRef, {
      'points': FieldValue.increment(pointsToAward),
    });

    try {
      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Setoran dikonfirmasi dan $pointsToAward poin diberikan!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal konfirmasi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_tpsUid == null) {
      // --- (PERBAIKAN 1) ---
      // 'const Center' dihapus menjadi 'Center'
      return Center(child: Text('Harap login sebagai TPS.'));
      // --- (AKHIR PERBAIKAN) ---
    }

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('waste_deposits')
            .where('status', isEqualTo: 'Pending')
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
            
            // --- (PERBAIKAN 2: line 224) ---
            // 'const Center' dihapus menjadi 'Center'
            return Center(
              child: Text(
                'Belum ada setoran yang masuk.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
            // --- (AKHIR PERBAIKAN) ---
          }

          // Tampilkan sebagai ListView
          return ListView(
            padding: const EdgeInsets.all(8.0),
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data =
                  document.data()! as Map<String, dynamic>;
              String docId = document.id;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  isThreeLine: true,
                  leading: GestureDetector(
                    onTap: () {
                      _showFullImageDialog(context, data['imageUrl']);
                    },
                    child: Container(
                      width: 60.0,
                      height: 60.0,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Image.network(
                        _getTransformedUrl(data['imageUrl']) ?? '',
                        fit: BoxFit.cover,
                        errorBuilder: (context, e, s) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.recycling),
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    data['wasteType'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Pelapor: ${data['requesterEmail']}\nEstimasi: ${data['estimatedWeight']} Kg',
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      _showApprovalDialog(context, docId, data['requesterUid'], data);
                    },
                    child: const Text('Konfirmasi'),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}