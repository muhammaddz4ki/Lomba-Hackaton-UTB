import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Untuk format tanggal

class WasteDepositDetailScreen extends StatelessWidget {
  final String docId;

  const WasteDepositDetailScreen({super.key, required this.docId});

  // --- (FUNGSI HELPER) Kompresi URL Cloudinary ---
  String? _getTransformedUrl(String? imageUrl) {
    if (imageUrl == null) return null;
    // Minta lebar 600px, kualitas 'good'
    return imageUrl.replaceFirst('/upload/', '/upload/w_600,q_auto:good/');
  }

  // --- (FUNGSI HELPER) Tampilan Status ---
  Widget _buildStatusChip(String status) {
    Color chipColor = Colors.amber;
    if (status == 'Completed') chipColor = Colors.green;
    if (status == 'Rejected') chipColor = Colors.red;

    return Chip(
      label: Text(status),
      labelStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      backgroundColor: chipColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Setoran'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        // Ambil data 1x dari 'waste_deposits'
        future: FirebaseFirestore.instance
            .collection('waste_deposits')
            .doc(docId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Gagal memuat data setoran.'));
          }

          // Ambil data
          Map<String, dynamic> data =
              snapshot.data!.data() as Map<String, dynamic>;

          // Format tanggal
          String formattedDate = 'Tanggal tidak diketahui';
          if (data['createdAt'] != null) {
            Timestamp ts = data['createdAt'] as Timestamp;
            formattedDate = DateFormat(
              'dd MMMM yyyy, HH:mm',
            ).format(ts.toDate());
          }

          return ListView(
            children: [
              // 1. FOTO BUKTI (Sudah dikompres)
              if (data['imageUrl'] != null)
                Image.network(
                  _getTransformedUrl(data['imageUrl'])!,
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

              // 2. INFO UTAMA
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tipe Sampah
                    Text(
                      data['wasteType'] ?? 'Tipe Tidak Diketahui',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16.0),

                    // Poin & Status
                    Row(
                      children: [
                        _buildStatusChip(data['status'] ?? 'Unknown'),
                        const Spacer(),
                        Text(
                          '${data['pointsAwarded'] ?? 0} Poin',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    const Divider(),
                    const SizedBox(height: 16.0),

                    // Detail Lainnya
                    ListTile(
                      leading: const Icon(Icons.fitness_center_outlined),
                      title: const Text('Estimasi Berat'),
                      subtitle: Text('${data['estimatedWeight'] ?? 0} Kg'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.calendar_month_outlined),
                      title: const Text('Tanggal Pengajuan'),
                      subtitle: Text(formattedDate),
                    ),
                    if (data['description'] != null &&
                        data['description'].isNotEmpty)
                      ListTile(
                        leading: const Icon(Icons.notes_outlined),
                        title: const Text('Catatan'),
                        subtitle: Text(data['description']),
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
