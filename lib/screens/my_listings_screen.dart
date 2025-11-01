import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  // --- (FUNGSI DIPERBARUI: Menjadi Toggle) ---
  Future<void> _toggleListingStatus(String docId, bool isCurrentlySold) async {
    // Tentukan status baru (kebalikannya)
    final String newStatus = isCurrentlySold ? 'Available' : 'Sold';
    final String message = isCurrentlySold
        ? 'Barang ditandai tersedia kembali.'
        : 'Barang telah ditandai sebagai terjual.';

    try {
      await _firestore
          .collection('marketplace_listings')
          .doc(docId)
          .update({'status': newStatus}); // Update ke status baru

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal update: $e')),
        );
      }
    }
  }

  // --- (Fungsi Hapus - Tidak Berubah) ---
  Future<void> _deleteListing(String docId) async {
    final bool? didConfirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Hapus Barang?'),
              content: const Text(
                  'Anda yakin ingin menghapus postingan ini secara permanen?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('Hapus',
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
              ],
            ));

    if (didConfirm != true) return;

    try {
      await _firestore
          .collection('marketplace_listings')
          .doc(docId)
          .delete(); 

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Barang berhasil dihapus.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus: $e')),
        );
      }
    }
  }

  // --- (Fungsi Helper Kompresi URL - Tidak Berubah) ---
  String? _getTransformedUrl(String? imageUrl) {
    if (imageUrl == null) return null;
    return imageUrl.replaceFirst(
      '/upload/',
      '/upload/w_150,q_auto:good/',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
          body: Center(child: Text('Anda harus login.')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Barang Jualan Saya'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('marketplace_listings')
            .where('sellerUid', isEqualTo: _currentUser.uid)
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
                'Anda belum menjual barang apapun.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(8.0),
            children: snapshot.data!.docs.map((doc) {
              Map<String, dynamic> data =
                  doc.data()! as Map<String, dynamic>;
              String docId = doc.id;
              bool isSold = data['status'] == 'Sold';

              return Card(
                color: isSold
                    ? Colors.grey[200] 
                    : Theme.of(context).cardColor,
                margin: const EdgeInsets.symmetric(vertical: 6.0),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      _getTransformedUrl(data['imageUrl']) ?? '',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, e, s) => Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[300],
                        child: const Icon(Icons.inventory_2_outlined),
                      ),
                    ),
                  ),
                  title: Text(
                    data['title'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration:
                          isSold ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  subtitle: Text(
                    'Rp ${data['price']} - Status: ${data['status']}',
                    style: TextStyle(
                      color: isSold ? Colors.grey[700] : null,
                    ),
                  ),
                  
                  // --- (MENU POPUP DIPERBARUI) ---
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'toggle_status') {
                        // Panggil fungsi toggle
                        _toggleListingStatus(docId, isSold);
                      } else if (value == 'delete') {
                        _deleteListing(docId);
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      
                      // 1. Tombol Toggle (Teks & Ikon berubah)
                      PopupMenuItem<String>(
                        value: 'toggle_status',
                        // Tombol ini selalu aktif
                        child: ListTile(
                          leading: Icon(
                            isSold ? Icons.replay_outlined : Icons.check_circle_outline,
                          ),
                          title: Text(
                            isSold ? 'Tandai Tersedia' : 'Tandai Terjual',
                          ),
                        ),
                      ),
                      
                      // 2. Tombol Hapus (Tidak berubah)
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete_outline, color: Colors.red),
                          title: Text('Hapus', style: TextStyle(color: Colors.red)),
                        ),
                      ),
                    ],
                  ),
                  // --- (AKHIR PERUBAHAN) ---
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}