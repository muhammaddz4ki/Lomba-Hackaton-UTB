import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Untuk memformat tanggal

// Impor halaman chat room
import 'chat_screen.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Ambil ID pengguna yang sedang login
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      return const Scaffold(
        body: Center(child: Text('Silakan login untuk melihat pesan.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesan Masuk (Inbox)'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 1. Stream: Mendengarkan 'chat_rooms'
        stream: FirebaseFirestore.instance
            .collection('chat_rooms')
            // 2. Filter: Ambil chat room DI MANA 'participants'
            //    mengandung ID pengguna yang sedang login
            .where('participants', arrayContains: currentUserId)
            // 3. Urutkan: Tampilkan chat dengan pesan terakhir di paling atas
            .orderBy('lastTimestamp', descending: true)
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
                'Belum ada percakapan.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          // Tampilkan sebagai ListView
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              Map<String, dynamic> data =
                  snapshot.data!.docs[index].data() as Map<String, dynamic>;
              String docId = snapshot.data!.docs[index].id;

              // Logika untuk menampilkan waktu
              String lastMessageTime = 'Baru saja';
              if (data['lastTimestamp'] != null) {
                Timestamp ts = data['lastTimestamp'] as Timestamp;
                lastMessageTime = DateFormat('HH:mm').format(ts.toDate());
              }

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                child: ListTile(
                  // Tampilkan foto barang
                  leading: CircleAvatar(
                    radius: 25.0,
                    backgroundImage: NetworkImage(data['listingImage'] ?? ''),
                    onBackgroundImageError: (e, s) =>
                        const Icon(Icons.inventory_2_outlined),
                  ),

                  // Tampilkan judul barang
                  title: Text(
                    data['listingTitle'] ?? 'Percakapan',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  // Tampilkan pesan terakhir
                  subtitle: Text(
                    data['lastMessage'] ?? '...',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Tampilkan waktu pesan terakhir
                  trailing: Text(lastMessageTime),

                  // Saat di-klik, buka chat room-nya
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          chatRoomId: docId,
                          chatTitle: data['listingTitle'] ?? 'Chat',
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
