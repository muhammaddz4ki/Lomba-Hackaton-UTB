import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'tps_create_schedule_screen.dart'; // Impor form

class TpsScheduleManagementScreen extends StatelessWidget {
  const TpsScheduleManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String? tpsUid = FirebaseAuth.instance.currentUser?.uid;

    if (tpsUid == null) {
      return const Center(child: Text('Harap login sebagai TPS.'));
    }

    return Scaffold(
      // Tombol FAB untuk 'Tambah Jadwal'
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TpsCreateScheduleScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),

      body: StreamBuilder<QuerySnapshot>(
        // 1. Stream: Mendengarkan 'public_schedules'
        stream: FirebaseFirestore.instance
            .collection('public_schedules')
            // 2. Filter: Hanya yang dibuat oleh TPS ini
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
                'Anda belum membuat jadwal umum.\nTekan tombol + untuk menambah.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          // Tampilkan daftar jadwal yang sudah dibuat
          return ListView(
            padding: const EdgeInsets.all(8.0),
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data =
                  document.data()! as Map<String, dynamic>;

              // Ambil array 'days' dan gabungkan
              List<String> days = List<String>.from(data['days'] ?? []);
              String daysString = days.join(', ');

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  isThreeLine: true,
                  title: Text(
                    data['areaName'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Hari: $daysString\nJam: ${data['timeStart']} - ${data['timeEnd']}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () {
                      // Fungsi Hapus (sederhana)
                      _deleteSchedule(context, document.id);
                    },
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  // --- (FUNGSI BARU) Untuk Hapus Jadwal ---
  Future<void> _deleteSchedule(BuildContext context, String docId) async {
    // Tampilkan konfirmasi
    final bool? didConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Jadwal?'),
        content: const Text('Apakah Anda yakin ingin menghapus jadwal ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Hapus',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (didConfirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('public_schedules')
            .doc(docId)
            .delete();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Gagal menghapus: $e')));
        }
      }
    }
  }
}
