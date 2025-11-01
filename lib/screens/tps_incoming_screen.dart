import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TpsIncomingScreen extends StatefulWidget {
  const TpsIncomingScreen({super.key});

  @override
  State<TpsIncomingScreen> createState() => _TpsIncomingScreenState();
}

class _TpsIncomingScreenState extends State<TpsIncomingScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? _tpsUid = FirebaseAuth.instance.currentUser?.uid;

  // --- (FUNGSI LAMA) Untuk Menerima Permintaan EMERGENSI ---
  Future<void> _acceptEmergencyRequest(String docId) async {
    if (_tpsUid == null) return;
    try {
      await _firestore
          .collection('emergency_requests')
          .doc(docId)
          .update({
        'status': 'On Progress',
        'tpsId': _tpsUid, // 'tpsId' adalah ID TPS yang MENERIMA
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permintaan darurat diterima!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menerima permintaan: $e')),
        );
      }
    }
  }

  // --- (FUNGSI BARU) Untuk Menerima Permintaan REGULER ---
  Future<void> _acceptRegularRequest(String docId) async {
    if (_tpsUid == null) return;
    try {
      // Pergi ke koleksi 'requests'
      await _firestore
          .collection('requests')
          .doc(docId)
          .update({
        'status': 'On Progress',
        'tpsId': _tpsUid, // 'tpsId' adalah ID TPS yang MENERIMA
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permintaan reguler diterima!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menerima permintaan: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_tpsUid == null) {
      return const Center(child: Text('Harap login sebagai TPS.'));
    }

    return Scaffold(
      // (Kita hapus AppBar dari sini, karena sudah ada di tps_home_screen.dart)
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- DAFTAR 1: PERMINTAAN DARURAT ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: Text(
              'Permintaan Darurat',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Expanded(
            child: _buildRequestList(
              context: context,
              collection: 'emergency_requests',
              tpsUid: _tpsUid,
              onAccept: _acceptEmergencyRequest,
            ),
          ),

          const Divider(indent: 16.0, endIndent: 16.0),

          // --- DAFTAR 2: PERMINTAAN REGULER ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: Text(
              'Permintaan Jemput Reguler',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Expanded(
            child: _buildRequestList(
              context: context,
              collection: 'requests',
              tpsUid: _tpsUid,
              onAccept: _acceptRegularRequest,
            ),
          ),
        ],
      ),
    );
  }

  // --- (WIDGET HELPER BARU) Untuk membuat daftar ---
  Widget _buildRequestList({
    required BuildContext context,
    required String collection,
    required String tpsUid,
    required Future<void> Function(String) onAccept,
  }) {
    return StreamBuilder<QuerySnapshot>(
      // 1. Stream: Mendengarkan koleksi yang diberikan
      stream: _firestore
          .collection(collection)
          // 2. Filter BARU:
          //    HANYA tampilkan yang 'selectedTpsId'-nya
          //    sama dengan ID TPS yang sedang login
          .where('selectedTpsId', isEqualTo: tpsUid)
          //    DAN statusnya masih 'Pending'
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
              'Tidak ada permintaan masuk.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          children: snapshot.data!.docs.map((DocumentSnapshot document) {
            Map<String, dynamic> data =
                document.data()! as Map<String, dynamic>;
            String docId = document.id;

            // Ambil data (nama/deskripsi)
            String title = data['description'] ?? data['name'] ?? 'Permintaan';
            String subtitle = data['locationAddress'] ?? data['address'] ?? 'Alamat tidak ada';

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6.0),
              child: ListTile(
                isThreeLine: true,
                title: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Pelapor: ${data['requesterEmail'] ?? data['name']}\nLokasi: $subtitle',
                ),
                trailing: ElevatedButton(
                  onPressed: () {
                    onAccept(docId); // Panggil fungsi "Terima" yang sesuai
                  },
                  child: const Text('Terima'),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}