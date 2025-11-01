import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'emergency_request_screen.dart';
import 'marketplace_screen.dart';
import 'inbox_screen.dart';
import 'waste_bank_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // SiBersih Color Palette
  static const Color _primaryEmerald = Color(0xFF10B981);
  static const Color _darkEmerald = Color(0xFF047857);
  static const Color _lightEmerald = Color(0xFF34D399);
  static const Color _tealAccent = Color(0xFF14B8A6);
  static const Color _ultraLightEmerald = Color(0xFFECFDF5);
  static const Color _pureWhite = Color(0xFFFFFFFF);
  static const Color _background = Color(0xFFF8FDFD);

  Widget _buildTodayScheduleCard(BuildContext context) {
    final String todayString = DateFormat(
      'EEEE',
      'id_ID',
    ).format(DateTime.now());

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('public_schedules')
          .where('days', arrayContains: todayString)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSkeletonScheduleCard();
        }

        if (snapshot.hasError ||
            !snapshot.hasData ||
            snapshot.data!.docs.isEmpty) {
          return _buildNoScheduleCard();
        }

        Map<String, dynamic> data =
            snapshot.data!.docs[0].data() as Map<String, dynamic>;
        return _buildActiveScheduleCard(data);
      },
    );
  }

  Widget _buildSkeletonScheduleCard() {
    return Container(
      height: 100.0,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primaryEmerald, _tealAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: _primaryEmerald.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }

  Widget _buildNoScheduleCard() {
    return Container(
      decoration: BoxDecoration(
        color: _pureWhite,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14.0),
              decoration: BoxDecoration(
                color: _ultraLightEmerald,
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Icon(
                Icons.calendar_today_rounded,
                size: 28,
                color: _primaryEmerald,
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tidak Ada Jadwal Hari Ini',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                      color: _darkEmerald,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    'Tidak ada penjemputan terjadwal untuk hari ini',
                    style: TextStyle(fontSize: 13.0, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveScheduleCard(Map<String, dynamic> data) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primaryEmerald, _tealAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: _primaryEmerald.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20.0),
          onTap: () {
            // Navigate to schedule details
          },
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: const Icon(
                    Icons.calendar_today_rounded,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Jadwal Jemput Hari Ini 🚛',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6.0),
                      Text(
                        'Area: ${data['areaName']}',
                        style: TextStyle(
                          fontSize: 14.0,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        '${data['timeStart']} - ${data['timeEnd']}',
                        style: TextStyle(
                          fontSize: 13.0,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 6.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/Logo/LOGO SiBersih.png',
              height: 32,
              width: 32,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 12),
            const Text(
              'SiBersih',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        backgroundColor: _pureWhite,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryEmerald, _tealAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: _primaryEmerald.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        foregroundColor: _pureWhite,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12.0),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: IconButton(
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              tooltip: 'Pesan Masuk',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const InboxScreen()),
                );
              },
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          // Welcome Header dengan Logo
          _buildWelcomeHeader(),
          const SizedBox(height: 24.0),

          // Jadwal Hari Ini
          _buildTodayScheduleCard(context),
          const SizedBox(height: 20.0),

          // Menu Grid
          _buildMenuGrid(context),
          const SizedBox(height: 24.0),

          // Info Card
          _buildInfoCard(),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: _pureWhite,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo SiBersih
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: _ultraLightEmerald,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: _primaryEmerald.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Image.asset(
              'assets/Logo/LOGO SiBersih.png',
              height: 40,
              width: 40,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selamat Datang! 👋',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.w700,
                    color: _darkEmerald,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  'Mari bersama menjaga kebersihan lingkungan',
                  style: TextStyle(fontSize: 14.0, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16.0,
      mainAxisSpacing: 16.0,
      childAspectRatio: 0.85,
      children: [
        _buildMenuCard(
          title: 'Jemput Darurat',
          subtitle: 'Butuh jemput sekarang',
          icon: Icons.emergency_rounded,
          gradientColors: const [Color(0xFFEF5350), Color(0xFFE53935)],
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const EmergencyRequestScreen(),
              ),
            );
          },
        ),
        _buildMenuCard(
          title: 'Marketplace',
          subtitle: 'Jual/beli sampah',
          icon: Icons.storefront_rounded,
          gradientColors: const [Color(0xFF9CCC65), Color(0xFF7CB342)],
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MarketplaceScreen(),
              ),
            );
          },
        ),
        _buildMenuCard(
          title: 'Bank Sampah',
          subtitle: 'Setor & dapat poin',
          icon: Icons.account_balance_wallet_rounded,
          gradientColors: const [Color(0xFF66BB6A), Color(0xFF4CAF50)],
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const WasteBankScreen()),
            );
          },
        ),
        _buildMenuCard(
          title: 'Pesan',
          subtitle: 'Lihat percakapan',
          icon: Icons.chat_bubble_rounded,
          gradientColors: const [Color(0xFFBA68C8), Color(0xFF9C27B0)],
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const InboxScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMenuCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20.0),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14.0),
                    ),
                    child: Icon(icon, size: 28, color: Colors.white),
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.0,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: _pureWhite,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6.0),
                decoration: BoxDecoration(
                  color: _ultraLightEmerald,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Image.asset(
                  'assets/Logo/LOGO SiBersih.png',
                  height: 20,
                  width: 20,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 8.0),
              Text(
                'Tentang SiBersih',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                  color: _darkEmerald,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          Text(
            'Aplikasi SiBersih membantu Anda mengelola sampah dengan lebih efisien. '
            'Dapatkan poin dari setiap sampah yang disetor dan jaga lingkungan tetap bersih! 🌱',
            style: TextStyle(
              fontSize: 14.0,
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.start,
          ),
        ],
      ),
    );
  }
}
