import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'request_pickup_screen.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // SiBersih Color Palette
  static const Color _primaryEmerald = Color(0xFF10B981);
  static const Color _darkEmerald = Color(0xFF047857);
  static const Color _lightEmerald = Color(0xFF34D399);
  static const Color _tealAccent = Color(0xFF14B8A6);
  static const Color _ultraLightEmerald = Color(0xFFECFDF5);
  static const Color _pureWhite = Color(0xFFFFFFFF);
  static const Color _background = Color(0xFFF8FDFD);

  String? _getTransformedUrl(String? imageUrl) {
    if (imageUrl == null) return null;
    return imageUrl.replaceFirst('/upload/', '/upload/w_600,q_auto:good/');
  }

  Future<void> _completeRequest(String docId, {String? imageUrl}) async {
    final String? transformedUrl = _getTransformedUrl(imageUrl);
    final bool? didConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Selesai'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (transformedUrl != null) ...[
              Text(
                'Bukti Foto dari TPS:',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8.0),
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Image.network(
                  transformedUrl,
                  height: 250,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 250,
                      color: Colors.grey[300],
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 250,
                      color: Colors.grey[300],
                      child: const Center(
                        child: Text(
                          'Gagal memuat bukti foto.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16.0),
              const Divider(),
              const SizedBox(height: 16.0),
            ] else ...[
              const Text(
                'TPS belum meng-upload bukti foto.',
                style: TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16.0),
            ],
            const Text(
              'Apakah Anda yakin pekerjaan telah selesai?',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Selesai'),
          ),
        ],
      ),
    );
    if (didConfirm != true) return;
    try {
      await _firestore.collection('emergency_requests').doc(docId).update({
        'status': 'Completed',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permintaan telah ditandai selesai!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyelesaikan permintaan: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildStatusWidget(Map<String, dynamic> data, String docId) {
    String status = data['status'];
    switch (status) {
      case 'Pending':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.amber),
          ),
          child: Text(
            'Menunggu TPS',
            style: TextStyle(
              color: Colors.amber[800],
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        );
      case 'On Progress':
        bool hasProof =
            data['proofImageUrl'] != null && data['proofImageUrl'].isNotEmpty;
        if (hasProof) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: _primaryEmerald.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                _completeRequest(docId, imageUrl: data['proofImageUrl']);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryEmerald,
                foregroundColor: _pureWhite,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              child: const Text(
                'Lihat Bukti & Selesai',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          );
        } else {
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 6.0,
            ),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.blue),
            ),
            child: Text(
              'Dikerjakan TPS',
              style: TextStyle(
                color: Colors.blue[800],
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          );
        }
      case 'Completed':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.green),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check, size: 14, color: Colors.green[800]),
              const SizedBox(width: 4),
              Text(
                'Selesai',
                style: TextStyle(
                  color: Colors.green[800],
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      default:
        return Text(status);
    }
  }

  Widget _buildPublicScheduleList(BuildContext context) {
    return Container(
      height: 160.0,
      child: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('public_schedules')
            .orderBy('areaName')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_primaryEmerald),
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.grey[400], size: 40),
                  const SizedBox(height: 8),
                  Text(
                    'Gagal memuat jadwal',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }
          if (snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    color: Colors.grey[400],
                    size: 40,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Belum ada jadwal umum',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              Map<String, dynamic> data =
                  snapshot.data!.docs[index].data() as Map<String, dynamic>;

              List<String> days = List<String>.from(data['days'] ?? []);
              String daysString = days.join(', ');

              return Container(
                width: 280.0,
                margin: const EdgeInsets.only(right: 12.0),
                decoration: BoxDecoration(
                  color: _pureWhite,
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
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
                            child: Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: _primaryEmerald,
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          Expanded(
                            child: Text(
                              data['areaName'] ?? 'Area',
                              style: const TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12.0),
                      Text(
                        'Hari: $daysString',
                        style: TextStyle(
                          fontSize: 13.0,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: _ultraLightEmerald,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time_outlined,
                              size: 16.0,
                              color: _primaryEmerald,
                            ),
                            const SizedBox(width: 6.0),
                            Text(
                              '${data['timeStart']} - ${data['timeEnd']}',
                              style: TextStyle(
                                color: _darkEmerald,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
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
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? user = _auth.currentUser;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text(
          'Jadwal & Riwayat',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: _pureWhite,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryEmerald, _tealAccent],
              begin: Alignment.topLeft,
            ),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Request Button
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: _primaryEmerald.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RequestPickupScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add_location_alt, size: 20),
                label: const Text(
                  'Buat Permintaan Jemput Reguler',
                  style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryEmerald,
                  foregroundColor: _pureWhite,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8.0),

          // Public Schedule Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6.0),
                  decoration: BoxDecoration(
                    color: _ultraLightEmerald,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Icon(
                    Icons.schedule_rounded,
                    size: 18,
                    color: _primaryEmerald,
                  ),
                ),
                const SizedBox(width: 8.0),
                Text(
                  'Jadwal Pengangkutan Umum',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w600,
                    color: _darkEmerald,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12.0),
          _buildPublicScheduleList(context),

          const SizedBox(height: 24.0),
          const Divider(indent: 20.0, endIndent: 20.0, height: 1),

          // History Section Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 12.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6.0),
                  decoration: BoxDecoration(
                    color: _ultraLightEmerald,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Icon(
                    Icons.history_rounded,
                    size: 18,
                    color: _primaryEmerald,
                  ),
                ),
                const SizedBox(width: 8.0),
                Text(
                  'Riwayat Permintaan Darurat',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w600,
                    color: _darkEmerald,
                  ),
                ),
              ],
            ),
          ),

          // History List
          Expanded(
            child: user == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_off_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Silakan login untuk melihat riwayat',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('emergency_requests')
                        .where('requesterUid', isEqualTo: user.uid)
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Terjadi kesalahan',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _primaryEmerald,
                            ),
                          ),
                        );
                      }
                      if (snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.history_toggle_off_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Belum ada riwayat permintaan',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Permintaan darurat akan muncul di sini',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView(
                        padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                        children: snapshot.data!.docs.map((doc) {
                          Map<String, dynamic> data =
                              doc.data() as Map<String, dynamic>;
                          String docId = doc.id;
                          final timestamp = data['createdAt'] as Timestamp?;
                          final date = timestamp != null
                              ? DateFormat(
                                  'dd MMM yyyy, HH:mm',
                                ).format(timestamp.toDate())
                              : 'Tanggal tidak tersedia';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12.0),
                            decoration: BoxDecoration(
                              color: _pureWhite,
                              borderRadius: BorderRadius.circular(16.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16.0),
                              title: Text(
                                data['description'] ??
                                    'Deskripsi tidak tersedia',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 6),
                                  Text(
                                    'Lokasi: ${data['locationAddress'] ?? 'Tidak tersedia'}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Biaya: ${_formatPrice(data['fee'])}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    date,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                              trailing: _buildStatusWidget(data, docId),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(dynamic price) {
    if (price == null) return 'Rp 0';

    final numberFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    try {
      if (price is String) {
        return numberFormat.format(double.parse(price));
      } else if (price is int) {
        return numberFormat.format(price);
      } else if (price is double) {
        return numberFormat.format(price);
      } else {
        return 'Rp 0';
      }
    } catch (e) {
      return 'Rp 0';
    }
  }
}
