import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// --- (HAPUS) 'url_launcher.dart' ---
// import 'package:url_launcher/url_launcher.dart';

// --- (BARU) Impor halaman chat ---
import 'chat_screen.dart';

class MarketplaceDetailScreen extends StatelessWidget {
  final String docId;

  const MarketplaceDetailScreen({super.key, required this.docId});

  // --- (FUNGSI LAMA DIHAPUS) ---
  // Fungsi _contactSeller (email) sudah dihapus

  // --- (FUNGSI BARU) Untuk Memulai Chat ---
  Future<void> _startOrNavigateToChat(
    BuildContext context,
    Map<String, dynamic> itemData,
  ) async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda harus login untuk memulai chat.')),
      );
      return;
    }

    final String currentUserId = currentUser.uid;
    final String sellerId = itemData['sellerUid'];

    // 1. Buat ID Chat Room yang unik tapi konsisten
    //    Kita gabungkan ID penjual & pembeli, lalu urutkan
    //    Ini memastikan hanya ada 1 chat room untuk 1 barang
    List<String> participants = [currentUserId, sellerId];
    participants.sort(); // Urutkan [A, B] -> [A, B] dan [B, A] -> [A, B]
    String chatRoomId = '${participants[0]}_${participants[1]}_${docId}';

    // 2. Buat dokumen chat room di Firestore JIKA belum ada
    final docRef = FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(chatRoomId);

    await docRef.set(
      {
        'participants': participants, // Simpan daftar peserta
        'participantNames': {
          // Simpan nama untuk Inbox nanti
          currentUserId: currentUser.displayName ?? currentUser.email,
          sellerId: itemData['sellerEmail'],
        },
        'listingId': docId,
        'listingTitle': itemData['title'],
        'listingImage': itemData['imageUrl'],
        'lastTimestamp': FieldValue.serverTimestamp(), // Update timestamp
      },
      SetOptions(merge: true), // 'merge: true' tidak akan menimpa data
      // jika dokumen sudah ada
    );

    // 3. Navigasi ke Halaman Chat
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ChatScreen(chatRoomId: chatRoomId, chatTitle: itemData['title']),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Barang'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('marketplace_listings')
            .doc(docId)
            .get(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              !snapshot.data!.exists) {
            return const Center(
              child: Text(
                'Gagal memuat data barang atau barang tidak ditemukan.',
              ),
            );
          }

          Map<String, dynamic> data =
              snapshot.data!.data() as Map<String, dynamic>;

          final bool isMyOwnListing = (data['sellerUid'] == currentUserId);

          return ListView(
            children: [
              // 1. GAMBAR (BESAR)
              Image.network(
                data['imageUrl'],
                height: 300,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    height: 300,
                    color: Colors.grey[300],
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
              ),

              // 2. INFO BARANG
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // (Harga, Judul, Deskripsi - tidak berubah)
                    Text(
                      'Rp ${data['price']}',
                      style: TextStyle(
                        fontSize: 28.0,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      data['title'],
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16.0),
                    const Divider(),
                    const SizedBox(height: 16.0),
                    Text(
                      'Deskripsi Barang',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8.0),
                    Text(data['description']),
                    const SizedBox(height: 24.0),

                    // (Info Penjual - tidak berubah)
                    Text(
                      'Info Penjual (COD)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8.0),
                    ListTile(
                      leading: const Icon(Icons.email_outlined),
                      title: Text(data['sellerEmail']),
                    ),
                    ListTile(
                      leading: const Icon(Icons.location_on_outlined),
                      title: const Text('Lokasi COD sesuai GPS'),
                      subtitle: Text(
                        'Lat: ${data['location'].latitude}, Lon: ${data['location'].longitude}',
                      ),
                    ),
                    const SizedBox(height: 32.0),

                    // 3. TOMBOL HUBUNGI (DIPERBARUI)
                    if (!isMyOwnListing)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // --- (PANGGIL FUNGSI CHAT BARU) ---
                            _startOrNavigateToChat(context, data);
                          },
                          // --- (IKON & TEKS DIUBAH) ---
                          icon: const Icon(Icons.chat_bubble_outline),
                          label: const Text('Chat Penjual'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.secondary,
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onSecondary,
                          ),
                        ),
                      )
                    // Info "Barang Anda" (Tidak berubah)
                    else
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSecondaryContainer,
                            ),
                            const SizedBox(width: 12.0),
                            Text(
                              'Ini adalah barang jualan Anda',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
