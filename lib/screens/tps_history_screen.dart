import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TpsHistoryScreen extends StatelessWidget {
  const TpsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Ambil ID TPS yang sedang login
    final String? tpsUid = FirebaseAuth.instance.currentUser?.uid;

    if (tpsUid == null) {
      return const Center(child: Text('Error: Tidak bisa memuat data TPS.'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat & Rekap Pendapatan'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 1. Stream: Mendengarkan 'emergency_requests'
        stream: FirebaseFirestore.instance
            .collection('emergency_requests')
            // 2. Filter: Hanya yang 'Completed' DAN tpsId-nya sesuai
            .where('status', isEqualTo: 'Completed')
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

          // --- (BAGIAN BARU: Kalkulasi Total Pendapatan) ---
          double totalIncome = 0.0;
          // Loop melalui setiap dokumen dan tambahkan 'fee'
          for (var doc in snapshot.data!.docs) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            // Pastikan 'fee' ada dan bertipe number
            if (data['fee'] != null && data['fee'] is num) {
              totalIncome += (data['fee'] as num);
            }
          }
          // --- (AKHIR KALKULASI) ---

          return Column(
            children: [
              // 1. Tampilkan Kartu Total Pendapatan
              Card(
                margin: const EdgeInsets.all(16.0),
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Center(
                    child: Column(
                      children: [
                        Text(
                          'TOTAL PENDAPATAN SELESAI',
                          style: TextStyle(
                            fontSize: 14.0,
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          'Rp $totalIncome',
                          style: TextStyle(
                            fontSize: 32.0,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. Tampilkan Daftar Riwayat
              Text(
                'Riwayat Pekerjaan Selesai',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8.0),

              // Jika tidak ada data
              if (snapshot.data!.docs.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      'Belum ada pekerjaan yang selesai.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                // Jika ada data, tampilkan ListView
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    children: snapshot.data!.docs.map((
                      DocumentSnapshot document,
                    ) {
                      Map<String, dynamic> data =
                          document.data()! as Map<String, dynamic>;

                      return Card(
                        child: ListTile(
                          title: Text(data['description']),
                          subtitle: Text('Oleh: ${data['requesterEmail']}'),
                          trailing: Chip(
                            label: Text('Rp ${data['fee']}'),
                            backgroundColor: Colors.green[100],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
