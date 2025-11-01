import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  final String chatRoomId;
  final String chatTitle; // Judul barang yang dibicarakan

  const ChatScreen({
    super.key,
    required this.chatRoomId,
    required this.chatTitle,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- (FUNGSI BARU) Untuk Mengirim Pesan ---
  Future<void> _sendMessage() async {
    final String? currentUserId = _auth.currentUser?.uid;
    if (_messageController.text.trim().isEmpty || currentUserId == null) {
      return; // Jangan kirim pesan kosong
    }

    // Ambil teks pesan dan bersihkan controller
    final String messageText = _messageController.text.trim();
    _messageController.clear();

    // 1. Siapkan data pesan
    final messageData = {
      'text': messageText,
      'senderId': currentUserId,
      'timestamp': Timestamp.now(),
    };

    try {
      // 2. Tambahkan pesan baru ke sub-koleksi 'messages'
      await _firestore
          .collection('chat_rooms')
          .doc(widget.chatRoomId)
          .collection('messages')
          .add(messageData);

      // 3. Update dokumen 'chat_room' utama
      //    (Ini penting untuk halaman Inbox/Riwayat nanti)
      await _firestore.collection('chat_rooms').doc(widget.chatRoomId).update({
        'lastMessage': messageText,
        'lastTimestamp': Timestamp.now(),
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mengirim pesan: $e')));
      }
    }
  }

  // --- (WIDGET BARU) Untuk Tampilan Gelembung Pesan ---
  Widget _buildMessageBubble(Map<String, dynamic> data) {
    final String? currentUserId = _auth.currentUser?.uid;
    final bool isMe = (data['senderId'] == currentUserId);

    return Container(
      // Atur alignment gelembung (kanan jika saya, kiri jika orang lain)
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: isMe
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12.0),
            topRight: const Radius.circular(12.0),
            bottomLeft: isMe
                ? const Radius.circular(12.0)
                : const Radius.circular(0),
            bottomRight: isMe
                ? const Radius.circular(0)
                : const Radius.circular(12.0),
          ),
        ),
        child: Text(data['text'], style: const TextStyle(fontSize: 16.0)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatTitle, overflow: TextOverflow.ellipsis),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      body: Column(
        children: [
          // 1. Daftar Pesan (Real-time)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // "Dengarkan" sub-koleksi 'messages'
              stream: _firestore
                  .collection('chat_rooms')
                  .doc(widget.chatRoomId)
                  .collection('messages')
                  .orderBy(
                    'timestamp',
                    descending: true,
                  ) // Pesan terbaru di bawah
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Mulai percakapan...'));
                }

                // Tampilkan sebagai ListView
                return ListView.builder(
                  reverse: true, // Mulai dari bawah (penting untuk chat)
                  padding: const EdgeInsets.all(8.0),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> data =
                        snapshot.data!.docs[index].data()
                            as Map<String, dynamic>;
                    return _buildMessageBubble(data);
                  },
                );
              },
            ),
          ),

          // 2. Input Teks
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8.0,
              vertical: 12.0,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4.0,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Ketik pesan...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(24.0)),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                const SizedBox(width: 8.0),
                // Tombol Kirim
                IconButton.filled(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
