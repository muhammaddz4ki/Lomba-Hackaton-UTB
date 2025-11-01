import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class TpsDepositApprovalScreen extends StatefulWidget {
  const TpsDepositApprovalScreen({super.key});

  @override
  State<TpsDepositApprovalScreen> createState() =>
      _TpsDepositApprovalScreenState();
}

class _TpsDepositApprovalScreenState extends State<TpsDepositApprovalScreen> {
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

  String? _getTransformedUrl(String? imageUrl) {
    if (imageUrl == null) return null;
    return imageUrl.replaceFirst('/upload/', '/upload/w_600,q_auto:good/');
  }

  Future<void> _showFullImageDialog(
    BuildContext context,
    String? imageUrl,
  ) async {
    final String? transformedUrl = _getTransformedUrl(imageUrl);
    if (transformedUrl == null) return;
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    transformedUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        height: 400,
                        color: Colors.grey.shade200,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: progress.expectedTotalBytes != null
                                ? progress.cumulativeBytesLoaded /
                                      progress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: CircleAvatar(
                  backgroundColor: Colors.black.withOpacity(0.5),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  int _calculatePoints(String wasteType, double weight) {
    int pointsPerKg = 0;
    if (wasteType.startsWith('Plastik')) {
      pointsPerKg = 100;
    } else if (wasteType.startsWith('Kertas')) {
      pointsPerKg = 80;
    } else if (wasteType.startsWith('Logam')) {
      pointsPerKg = 150;
    } else if (wasteType.startsWith('Kaca')) {
      pointsPerKg = 50;
    } else {
      pointsPerKg = 30;
    }
    return (weight * pointsPerKg).round();
  }

  Future<void> _showApprovalDialog(
    BuildContext context,
    String docId,
    String requesterUid,
    Map<String, dynamic> data,
  ) async {
    final double estimatedWeight = data['estimatedWeight'] ?? 0.0;
    final String wasteType = data['wasteType'] ?? 'Lainnya';
    final int calculatedPoints = _calculatePoints(wasteType, estimatedWeight);
    final String? transformedUrl = _getTransformedUrl(data['imageUrl']);
    final timestamp = data['createdAt'] as Timestamp?;
    final dateTime = timestamp?.toDate() ?? DateTime.now();

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      Icons.recycling_outlined,
                      color: _primaryEmerald,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Konfirmasi Setoran',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Informasi dasar
                        _buildDialogInfoRow(
                          'Pelapor',
                          data['requesterEmail'] ?? 'Tidak diketahui',
                        ),
                        _buildDialogInfoRow('Tipe Sampah', wasteType),
                        _buildDialogInfoRow(
                          'Estimasi Berat',
                          '$estimatedWeight Kg',
                        ),
                        _buildDialogInfoRow(
                          'Tanggal',
                          DateFormat('dd/MM/yyyy HH:mm').format(dateTime),
                        ),

                        const SizedBox(height: 16),

                        // Gambar
                        if (transformedUrl != null)
                          Column(
                            children: [
                              Text(
                                'Foto Bukti',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pop(dialogContext);
                                  _showFullImageDialog(
                                    context,
                                    data['imageUrl'],
                                  );
                                },
                                child: Container(
                                  height: 150,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      transformedUrl,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, progress) {
                                        if (progress == null) return child;
                                        return Container(
                                          color: Colors.grey.shade200,
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              value:
                                                  progress.expectedTotalBytes !=
                                                      null
                                                  ? progress.cumulativeBytesLoaded /
                                                        progress
                                                            .expectedTotalBytes!
                                                  : null,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),

                        // Poin
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _ultraLightEmerald,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _lightEmerald),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Poin yang Akan Diberikan',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _darkEmerald,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$calculatedPoints Poin',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: _primaryEmerald,
                                ),
                              ),
                              Text(
                                '($estimatedWeight Kg × ${_getPointsPerKgText(wasteType)})',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _approveDeposit(
                            docId,
                            requesterUid,
                            data,
                            calculatedPoints,
                          );
                          Navigator.pop(dialogContext);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryEmerald,
                          foregroundColor: _pureWhite,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Konfirmasi'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _getPointsPerKgText(String wasteType) {
    if (wasteType.startsWith('Plastik')) return '100 poin/Kg';
    if (wasteType.startsWith('Kertas')) return '80 poin/Kg';
    if (wasteType.startsWith('Logam')) return '150 poin/Kg';
    if (wasteType.startsWith('Kaca')) return '50 poin/Kg';
    return '30 poin/Kg';
  }

  Future<void> _approveDeposit(
    String docId,
    String requesterUid,
    Map<String, dynamic> data,
    int pointsToAward,
  ) async {
    if (_tpsUid == null) return;

    WriteBatch batch = _firestore.batch();
    DocumentReference depositRef = _firestore
        .collection('waste_deposits')
        .doc(docId);
    batch.update(depositRef, {
      'status': 'Completed',
      'pointsAwarded': pointsToAward,
      'approverTpsId': _tpsUid,
    });
    DocumentReference userRef = _firestore
        .collection('users')
        .doc(requesterUid);
    batch.update(userRef, {'points': FieldValue.increment(pointsToAward)});

    try {
      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Setoran dikonfirmasi dan $pointsToAward poin diberikan!',
            ),
            backgroundColor: _successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal konfirmasi: $e'),
            backgroundColor: _errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildDepositCard(Map<String, dynamic> data, String docId) {
    final timestamp = data['createdAt'] as Timestamp?;
    final dateTime = timestamp?.toDate() ?? DateTime.now();
    final double estimatedWeight = data['estimatedWeight'] ?? 0.0;
    final int calculatedPoints = _calculatePoints(
      data['wasteType'] ?? 'Lainnya',
      estimatedWeight,
    );

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
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gambar
                GestureDetector(
                  onTap: () => _showFullImageDialog(context, data['imageUrl']),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _getTransformedUrl(data['imageUrl']) ?? '',
                        fit: BoxFit.cover,
                        errorBuilder: (context, e, s) => Container(
                          color: Colors.grey.shade200,
                          child: Icon(
                            Icons.recycling,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: Colors.grey.shade200,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['wasteType'] ?? 'Tipe Sampah',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data['requesterEmail'] ?? 'Tidak diketahui',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
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
              ],
            ),

            const SizedBox(height: 12),

            // Informasi
            Row(
              children: [
                Icon(
                  Icons.fitness_center_outlined,
                  size: 16,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 6),
                Text(
                  '${estimatedWeight} Kg',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _warningColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    '$calculatedPoints Poin',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _warningColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Tombol Konfirmasi
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showApprovalDialog(
                  context,
                  docId,
                  data['requesterUid'],
                  data,
                ),
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text(
                  'Konfirmasi Setoran',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryEmerald,
                  foregroundColor: _pureWhite,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Tidak Ada Setoran',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Belum ada setoran yang menunggu konfirmasi',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_tpsUid == null) {
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
      appBar: AppBar(
        title: const Text(
          'Setoran Bank Sampah',
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
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('waste_deposits')
            .where('status', isEqualTo: 'Pending')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 50, color: _errorColor),
                  const SizedBox(height: 16),
                  Text(
                    'Terjadi error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.grey),
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
              children: snapshot.data!.docs.map((DocumentSnapshot document) {
                Map<String, dynamic> data =
                    document.data()! as Map<String, dynamic>;
                String docId = document.id;
                return _buildDepositCard(data, docId);
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}
