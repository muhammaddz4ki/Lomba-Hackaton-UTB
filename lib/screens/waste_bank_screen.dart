import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'waste_deposit_form_screen.dart';
import 'waste_deposit_detail_screen.dart';

class WasteBankScreen extends StatelessWidget {
  const WasteBankScreen({super.key});

  // Color Palette
  static const Color _primaryEmerald = Color(0xFF10B981);
  static const Color _darkEmerald = Color(0xFF047857);
  static const Color _lightEmerald = Color(0xFF34D399);
  static const Color _tealAccent = Color(0xFF14B8A6);
  static const Color _ultraLightEmerald = Color(0xFFECFDF5);
  static const Color _pureWhite = Color(0xFFFFFFFF);
  static const Color _background = Color(0xFFF8FDFD);
  static const Color _warningColor = Color(0xFFF59E0B);
  static const Color _successColor = Color(0xFF10B981);
  static const Color _errorColor = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: _background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'Anda harus login untuk mengakses fitur ini',
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
      appBar: AppBar(
        title: const Text(
          'Bank Sampah Saya',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
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
        iconTheme: const IconThemeData(color: Colors.white),
      ),
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
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WasteDepositFormScreen(),
              ),
            );
          },
          icon: const Icon(Icons.add_circle_outline, size: 20),
          label: const Text(
            'Setor Sampah',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: _primaryEmerald,
          foregroundColor: _pureWhite,
        ),
      ),
      body: Column(
        children: [
          // BAGIAN 1: TAMPILAN POIN
          _buildPointsCard(context, user.uid),

          // BAGIAN 2: RIWAYAT SETORAN SAYA
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _ultraLightEmerald,
              border: Border(
                bottom: BorderSide(
                  color: _lightEmerald.withOpacity(0.5),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.history_outlined, color: _darkEmerald, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Riwayat Setoran Saya',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _darkEmerald,
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildHistoryList(context, user.uid)),
        ],
      ),
    );
  }

  // WIDGET KARTU POIN - Diperbarui
  Widget _buildPointsCard(BuildContext context, String uid) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryEmerald.withOpacity(0.9), _tealAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _primaryEmerald.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Center(
              child: CircularProgressIndicator(color: _pureWhite),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _errorColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _errorColor.withOpacity(0.3)),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.error_outline, color: _errorColor),
                  const SizedBox(height: 8),
                  Text(
                    'Gagal memuat poin',
                    style: TextStyle(
                      color: _errorColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        int points = 0;
        try {
          points = snapshot.data!.get('points') ?? 0;
        } catch (e) {
          points = 0;
        }

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryEmerald.withOpacity(0.9), _tealAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _primaryEmerald.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.eco_outlined, color: _pureWhite, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'TOTAL POIN ANDA',
                      style: TextStyle(
                        fontSize: 14.0,
                        color: _pureWhite.withOpacity(0.9),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  points.toString(),
                  style: TextStyle(
                    fontSize: 48.0,
                    fontWeight: FontWeight.bold,
                    color: _pureWhite,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Poin terkumpul',
                  style: TextStyle(
                    fontSize: 14.0,
                    color: _pureWhite.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // RIWAYAT SETORAN - Diperbarui
  Widget _buildHistoryList(BuildContext context, String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('waste_deposits')
          .where('requesterUid', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 50, color: _errorColor),
                const SizedBox(height: 16),
                Text(
                  'Terjadi error: ${snapshot.error}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 60,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'Belum Ada Riwayat Setoran',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Mulai setor sampah untuk melihat riwayat',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          backgroundColor: _pureWhite,
          color: _primaryEmerald,
          onRefresh: () async {
            // Trigger rebuild
          },
          child: ListView(
            padding: const EdgeInsets.only(bottom: 16, top: 8),
            children: snapshot.data!.docs.map((doc) {
              Map<String, dynamic> data = doc.data()! as Map<String, dynamic>;
              String docId = doc.id;
              String status = data['status'] ?? 'Unknown';
              int points = data['pointsAwarded'] ?? 0;
              final timestamp = data['createdAt'] as Timestamp?;
              final dateTime = timestamp?.toDate() ?? DateTime.now();

              Color statusColor;
              Color statusBgColor;
              IconData statusIcon;

              switch (status) {
                case 'Completed':
                  statusColor = _successColor;
                  statusBgColor = _successColor.withOpacity(0.1);
                  statusIcon = Icons.check_circle_outline;
                  break;
                case 'Rejected':
                  statusColor = _errorColor;
                  statusBgColor = _errorColor.withOpacity(0.1);
                  statusIcon = Icons.cancel_outlined;
                  break;
                default:
                  statusColor = _warningColor;
                  statusBgColor = _warningColor.withOpacity(0.1);
                  statusIcon = Icons.pending_outlined;
              }

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
                child: Material(
                  color: Colors.transparent,
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
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Gambar sampah
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: data['imageUrl'] != null
                                  ? DecorationImage(
                                      image: NetworkImage(data['imageUrl']!),
                                      fit: BoxFit.cover,
                                      onError: (e, s) =>
                                          const Icon(Icons.recycling),
                                    )
                                  : null,
                              color: data['imageUrl'] == null
                                  ? _lightEmerald.withOpacity(0.2)
                                  : null,
                            ),
                            child: data['imageUrl'] == null
                                ? Icon(
                                    Icons.recycling,
                                    color: _darkEmerald,
                                    size: 24,
                                  )
                                : null,
                          ),

                          const SizedBox(width: 12),

                          // Informasi setoran
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['wasteType'] ?? 'Setoran Sampah',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${data['estimatedWeight'] ?? '0'} Kg',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${dateTime.day}/${dateTime.month}/${dateTime.year}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Poin dan status
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: statusBgColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: statusColor.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      statusIcon,
                                      size: 12,
                                      color: statusColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      status,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: statusColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$points Poin',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: _primaryEmerald,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
