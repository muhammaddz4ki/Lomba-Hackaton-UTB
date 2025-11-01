import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'waste_deposit_form_screen.dart';
import 'waste_deposit_detail_screen.dart';

class WasteBankScreen extends StatelessWidget {
  const WasteBankScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Anda harus login untuk mengakses fitur ini.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank Sampah Saya'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WasteDepositFormScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('Setor Sampah'),
      ),

      body: Column(
        children: [
          // BAGIAN 1: TAMPILAN POIN (Tidak berubah)
          _buildPointsCard(context, user.uid),

          // BAGIAN 2: RIWAYAT SETORAN SAYA
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
            child: Text(
              'Riwayat Setoran Saya',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Expanded(child: _buildHistoryList(context, user.uid)),
        ],
      ),
    );
  }

  // WIDGET KARTU POIN (Tidak berubah)
  Widget _buildPointsCard(BuildContext context, String uid) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            margin: EdgeInsets.all(16.0),
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('Gagal memuat poin.'));
        }

        int points = 0;
        try {
          points = snapshot.data!.get('points') ?? 0;
        } catch (e) {
          points = 0;
        }

        return Card(
          margin: const EdgeInsets.all(16.0),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: Column(
                children: [
                  Text(
                    'TOTAL POIN ANDA',
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    points.toString(),
                    style: TextStyle(
                      fontSize: 48.0,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- (PERBAIKAN OVERFLOW DI WIDGET INI) ---
  Widget _buildHistoryList(BuildContext context, String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('waste_deposits')
          .where('requesterUid', isEqualTo: uid)
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
              'Belum ada riwayat setoran.',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 80.0),
          children: snapshot.data!.docs.map((doc) {
            Map<String, dynamic> data = doc.data()! as Map<String, dynamic>;
            String docId = doc.id;
            String status = data['status'] ?? 'Unknown';
            int points = data['pointsAwarded'] ?? 0;
            Color statusColor = Colors.amber.shade800; // Pending
            if (status == 'Completed') statusColor = Colors.green.shade800;
            if (status == 'Rejected') statusColor = Colors.red.shade800;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6.0),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          WasteDepositDetailScreen(docId: docId),
                    ),
                  );
                },
                child: ListTile(
                  isThreeLine: false, // <-- (DIUBAH) Tidak perlu 3 baris
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(data['imageUrl'] ?? ''),
                    onBackgroundImageError: (e, s) =>
                        const Icon(Icons.recycling),
                  ),
                  title: Text(data['wasteType'] ?? 'Setoran'),
                  subtitle: Text('Estimasi: ${data['estimatedWeight']} Kg'),

                  // --- (PERBAIKAN OVERFLOW) ---
                  // Ganti 'Chip' yang tinggi dengan 'Text' yang ramping
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$points Poin',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 15.0, // Sedikit lebih besar
                        ),
                      ),
                      const SizedBox(height: 4.0), // Jarak kecil
                      Text(
                        status,
                        style: TextStyle(
                          fontSize: 12.0,
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  // --- (AKHIR PERBAIKAN) ---
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
