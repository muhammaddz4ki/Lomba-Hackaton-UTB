import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TpsIncomingScreen extends StatefulWidget {
  const TpsIncomingScreen({super.key});

  @override
  State<TpsIncomingScreen> createState() => _TpsIncomingScreenState();
}

class _TpsIncomingScreenState extends State<TpsIncomingScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? _tpsUid = FirebaseAuth.instance.currentUser?.uid;

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
  static const Color _urgentColor = Color(0xFFDC2626);

  Future<void> _acceptEmergencyRequest(String docId) async {
    if (_tpsUid == null) return;
    try {
      await _firestore.collection('emergency_requests').doc(docId).update({
        'status': 'On Progress',
        'tpsId': _tpsUid,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Permintaan darurat diterima!'),
            backgroundColor: _successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menerima permintaan: $e'),
            backgroundColor: _errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _acceptRegularRequest(String docId) async {
    if (_tpsUid == null) return;
    try {
      await _firestore.collection('requests').doc(docId).update({
        'status': 'On Progress',
        'tpsId': _tpsUid,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Permintaan reguler diterima!'),
            backgroundColor: _successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menerima permintaan: $e'),
            backgroundColor: _errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildRequestCard({
    required Map<String, dynamic> data,
    required String docId,
    required Future<void> Function(String) onAccept,
    required bool isEmergency,
  }) {
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
        border: Border.all(
          color: isEmergency
              ? _urgentColor.withOpacity(0.2)
              : Colors.grey.shade100,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header dengan status dan tanggal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isEmergency
                        ? _urgentColor.withOpacity(0.1)
                        : _ultraLightEmerald,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isEmergency ? _urgentColor : _lightEmerald,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isEmergency
                            ? Icons.warning_amber_outlined
                            : Icons.schedule_outlined,
                        size: 14,
                        color: isEmergency ? _urgentColor : _darkEmerald,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isEmergency ? 'Darurat' : 'Reguler',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isEmergency ? _urgentColor : _darkEmerald,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${dateTime.day}/${dateTime.month}/${dateTime.year}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Deskripsi
            Text(
              data['description'] ?? data['name'] ?? 'Permintaan',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),

            // Informasi Pelapor
            _buildInfoRow(
              Icons.person_outline,
              'Pelapor',
              data['requesterEmail'] ?? data['name'] ?? 'Tidak diketahui',
            ),

            const SizedBox(height: 8),

            // Informasi Lokasi
            _buildInfoRow(
              Icons.location_on_outlined,
              'Lokasi',
              data['locationAddress'] ??
                  data['address'] ??
                  'Lokasi tidak tersedia',
            ),

            const SizedBox(height: 16),

            // Tombol Terima
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => onAccept(docId),
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: Text(
                  'Terima Permintaan',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isEmergency ? _urgentColor : _primaryEmerald,
                  foregroundColor: _pureWhite,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
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

  Widget _buildRequestSection({
    required String title,
    required String collection,
    required bool isEmergency,
  }) {
    return Expanded(
      child: Column(
        children: [
          // Section Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isEmergency
                  ? _urgentColor.withOpacity(0.05)
                  : _ultraLightEmerald,
              border: Border(
                bottom: BorderSide(
                  color: isEmergency
                      ? _urgentColor.withOpacity(0.2)
                      : _lightEmerald.withOpacity(0.5),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isEmergency
                      ? Icons.emergency_outlined
                      : Icons.calendar_today_outlined,
                  color: isEmergency ? _urgentColor : _darkEmerald,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isEmergency ? _urgentColor : _darkEmerald,
                  ),
                ),
              ],
            ),
          ),

          // Request List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection(collection)
                  .where('selectedTpsId', isEqualTo: _tpsUid)
                  .where('status', isEqualTo: 'Pending')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder:
                  (
                    BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot,
                  ) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 50,
                              color: _errorColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Terjadi error: ${snapshot.error}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
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
                              isEmergency
                                  ? Icons.emergency_outlined
                                  : Icons.inbox_outlined,
                              size: 60,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Tidak Ada Permintaan ${isEmergency ? 'Darurat' : 'Reguler'}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Semua permintaan telah diproses',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      backgroundColor: _pureWhite,
                      color: isEmergency ? _urgentColor : _primaryEmerald,
                      onRefresh: () async {
                        setState(() {});
                      },
                      child: ListView(
                        padding: const EdgeInsets.only(bottom: 16),
                        children: snapshot.data!.docs.map((
                          DocumentSnapshot document,
                        ) {
                          Map<String, dynamic> data =
                              document.data()! as Map<String, dynamic>;
                          String docId = document.id;

                          return _buildRequestCard(
                            data: data,
                            docId: docId,
                            onAccept: isEmergency
                                ? _acceptEmergencyRequest
                                : _acceptRegularRequest,
                            isEmergency: isEmergency,
                          );
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

  @override
  Widget build(BuildContext context) {
    if (_tpsUid == null) {
      return Center(
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
      );
    }

    return Scaffold(
      backgroundColor: _background,
      body: Column(
        children: [
          // Permintaan Darurat
          _buildRequestSection(
            title: 'Permintaan Darurat',
            collection: 'emergency_requests',
            isEmergency: true,
          ),

          // Divider dengan styling
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey.shade200,
                  Colors.grey.shade400,
                  Colors.grey.shade200,
                ],
              ),
            ),
          ),

          // Permintaan Reguler
          _buildRequestSection(
            title: 'Permintaan Jemput Reguler',
            collection: 'requests',
            isEmergency: false,
          ),
        ],
      ),
    );
  }
}
