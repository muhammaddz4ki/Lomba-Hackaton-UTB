import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'emergency_request_screen.dart';
import 'marketplace_screen.dart';
import 'inbox_screen.dart';
import 'waste_bank_screen.dart';
// Impor profile screen tidak lagi dibutuhkan di sini
// import 'profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // --- (WIDGET BARU) Kartu "Jadwal Hari Ini" ---
  Widget _buildTodayScheduleCard(BuildContext context) {
    // 1. Dapatkan nama hari ini dalam Bahasa Indonesia
    final String todayString = DateFormat(
      'EEEE',
      'id_ID',
    ).format(DateTime.now());

    // 2. Buat StreamBuilder
    return StreamBuilder<QuerySnapshot>(
      // 3. Query: Cari di 'public_schedules'
      //    di mana array 'days' mengandung nama hari ini
      stream: FirebaseFirestore.instance
          .collection('public_schedules')
          .where('days', arrayContains: todayString)
          .snapshots(),

      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Tampilkan placeholder loading yang rapi
          return Card(
            elevation: 2.0,
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: const SizedBox(
              height: 70.0,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        if (snapshot.hasError ||
            !snapshot.hasData ||
            snapshot.data!.docs.isEmpty) {
          // Jika tidak ada jadwal hari ini, JANGAN TAMPILKAN APAPUN
          return const SizedBox.shrink();
        }

        // 4. Jika ADA jadwal, tampilkan kartunya
        // (Kita ambil jadwal pertama saja sebagai notifikasi)
        Map<String, dynamic> data =
            snapshot.data!.docs[0].data() as Map<String, dynamic>;

        return Card(
          elevation: 4.0,
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 40,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jadwal Jemput Hari Ini!',
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        'Area: ${data['areaName']} (${data['timeStart']} - ${data['timeEnd']})',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  // --- (AKHIR WIDGET BARU) ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        actions: [
          // Tombol Chat/Inbox (satu-satunya ikon di AppBar)
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: 'Pesan Masuk',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const InboxScreen()),
              );
            },
          ),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Kartu Jadwal Hari Ini
          _buildTodayScheduleCard(context),

          // Kartu Emergensi
          Card(
            elevation: 4.0,
            color: Theme.of(context).colorScheme.errorContainer,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EmergencyRequestScreen(),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.emergency_outlined,
                      size: 40,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Butuh Jemput Darurat?',
                            style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(
                                context,
                              ).colorScheme.onErrorContainer,
                            ),
                          ),
                          Text(
                            'Minta penjemputan sekarang (berbayar).',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onErrorContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Kartu Marketplace
          Card(
            elevation: 4.0,
            color: Theme.of(context).colorScheme.tertiaryContainer,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MarketplaceScreen(),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.storefront_outlined,
                      size: 40,
                      color: Theme.of(context).colorScheme.onTertiaryContainer,
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Marketplace Sampah',
                            style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(
                                context,
                              ).colorScheme.onTertiaryContainer,
                            ),
                          ),
                          Text(
                            'Jual atau beli sampah daur ulang di sini.',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onTertiaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Kartu Bank Sampah
          Card(
            elevation: 4.0,
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WasteBankScreen(),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 40,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bank Sampah',
                            style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSecondaryContainer,
                            ),
                          ),
                          Text(
                            'Setor sampahmu dan dapatkan poin.',
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
            ),
          ),

          const SizedBox(height: 24.0),

          // Kartu Selamat Datang
          Card(
            elevation: 2.0,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selamat Datang di SiBersih!',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8.0),
                  const Text(
                    'Aplikasi ini membantumu mengelola sampah dan belajar lebih banyak tentang lingkungan.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
