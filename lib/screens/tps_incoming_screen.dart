import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TpsIncomingScreen extends StatefulWidget {
  const TpsIncomingScreen({super.key});

  @override
  State<TpsIncomingScreen> createState() => _TpsIncomingScreenState();
}

class _TpsIncomingScreenState extends State<TpsIncomingScreen> {
  // Fungsi Untuk Menerima Permintaan
  Future<void> _acceptRequest(String docId) async {
    final tpsUser = FirebaseAuth.instance.currentUser;
    if (tpsUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Akun TPS Anda tidak terverifikasi.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // 1. Update dokumen di Firestore
      await FirebaseFirestore.instance
          .collection('emergency_requests')
          .doc(docId)
          .update({
            'status': 'On Progress', // Ubah status
            'tpsId': tpsUser.uid, // Tetapkan TPS yang mengambil
          });

      // 2. Tampilkan notifikasi sukses
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permintaan diterima! Anda bisa mulai menjemput.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // 3. Tampilkan notifikasi error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menerima permintaan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permintaan Darurat Masuk'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 1. Stream: Mendengarkan 'emergency_requests'
        stream: FirebaseFirestore.instance
            .collection('emergency_requests')
            // 2. Filter: Hanya yang 'Pending'
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
            return const Center(
              child: Text(
                'Belum ada permintaan darurat.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
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
                  title: Text(
                    data['description'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Lokasi: ${data['locationAddress']}\nBiaya: Rp ${data['fee']}',
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      _acceptRequest(docId);
                    },
                    child: const Text('Terima'),
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
