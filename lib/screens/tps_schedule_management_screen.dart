import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'tps_create_schedule_screen.dart';

class TpsScheduleManagementScreen extends StatelessWidget {
  const TpsScheduleManagementScreen({super.key});

  // Color Palette
  static const Color _primaryEmerald = Color(0xFF10B981);
  static const Color _darkEmerald = Color(0xFF047857);
  static const Color _lightEmerald = Color(0xFF34D399);
  static const Color _tealAccent = Color(0xFF14B8A6);
  static const Color _ultraLightEmerald = Color(0xFFECFDF5);
  static const Color _pureWhite = Color(0xFFFFFFFF);
  static const Color _background = Color(0xFFF8FDFD);
  static const Color _warningColor = Color(0xFFF59E0B);
  static const Color _errorColor = Color(0xFFEF4444);

  Future<void> _deleteSchedule(BuildContext context, String docId) async {
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
            child: Text('Hapus', style: TextStyle(color: _errorColor)),
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

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Jadwal berhasil dihapus!'),
              backgroundColor: _primaryEmerald,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menghapus: $e'),
              backgroundColor: _errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Widget _buildScheduleCard(
    Map<String, dynamic> data,
    String docId,
    BuildContext context,
  ) {
    List<String> days = List<String>.from(data['days'] ?? []);
    String daysString = days.join(', ');

    final timestamp = data['createdAt'] as Timestamp?;
    final dateTime = timestamp?.toDate() ?? DateTime.now();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      decoration: BoxDecoration(
        color: _pureWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header dengan nama area dan tombol hapus
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    data['areaName'] ?? 'Area Tanpa Nama',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: _errorColor),
                  onPressed: () => _deleteSchedule(context, docId),
                  tooltip: 'Hapus Jadwal',
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Informasi Hari
            _buildInfoRow(
              Icons.calendar_today_outlined,
              'Hari Operasi',
              daysString.isNotEmpty ? daysString : 'Tidak ada hari ditentukan',
            ),

            const SizedBox(height: 8),

            // Informasi Jam
            _buildInfoRow(
              Icons.access_time_outlined,
              'Jam Operasi',
              '${data['timeStart'] ?? '--:--'} - ${data['timeEnd'] ?? '--:--'}',
            ),

            const SizedBox(height: 8),

            // Tanggal Dibuat
            _buildInfoRow(
              Icons.date_range_outlined,
              'Dibuat Pada',
              '${dateTime.day}/${dateTime.month}/${dateTime.year}',
            ),

            const SizedBox(height: 12),

            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _ultraLightEmerald,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _lightEmerald, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 14,
                    color: _darkEmerald,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Aktif',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _darkEmerald,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Belum Ada Jadwal',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Tekan tombol + di bawah untuk membuat jadwal operasional TPS',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: _errorColor),
          const SizedBox(height: 16),
          Text(
            'Terjadi Error',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              error,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? tpsUid = FirebaseAuth.instance.currentUser?.uid;

    if (tpsUid == null) {
      return Scaffold(
        backgroundColor: _background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'Harap login sebagai TPS',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _background,
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _primaryEmerald.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TpsCreateScheduleScreen(),
              ),
            );
          },
          backgroundColor: _primaryEmerald,
          foregroundColor: _pureWhite,
          child: const Icon(Icons.add, size: 28),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),

          // Content
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('public_schedules')
                  .where('tpsId', isEqualTo: tpsUid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder:
                  (
                    BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot,
                  ) {
                    if (snapshot.hasError) {
                      return _buildErrorState(
                        'Terjadi error: ${snapshot.error}',
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.data!.docs.isEmpty) {
                      return _buildEmptyState();
                    }

                    return RefreshIndicator(
                      backgroundColor: _pureWhite,
                      color: _primaryEmerald,
                      onRefresh: () async {
                        // Trigger rebuild
                      },
                      child: ListView(
                        padding: const EdgeInsets.only(bottom: 16, top: 16),
                        children: snapshot.data!.docs.map((
                          DocumentSnapshot document,
                        ) {
                          Map<String, dynamic> data =
                              document.data()! as Map<String, dynamic>;
                          String docId = document.id;

                          return _buildScheduleCard(data, docId, context);
                        }).toList(),
                      ),
                    );
                  },
            ),
          ),
        ],
      ),
    );
  }
}
