import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:url_launcher/url_launcher.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  String _selectedTpsId = '';

  // Data TPS dengan informasi lengkap - Lokasi di Garut
  final List<Map<String, dynamic>> tpsLocations = [
    {
      "id": "tps_1",
      "name": "TPS SiBersih - Tarogong",
      "lat": -7.1975,
      "lng": 107.8902,
      "address": "Jl. Raya Tarogong No. 123, Tarogong Kidul",
      "operationalHours": "06:00 - 18:00",
      "capacity": "85%",
      "wasteTypes": ["Organik", "Anorganik", "B3"],
      "phone": "0262-1234567",
      "rating": 4.5,
      "type": "tps",
    },
    {
      "id": "tps_2",
      "name": "TPS SiBersih - Cibatu",
      "lat": -7.1253,
      "lng": 107.9425,
      "address": "Jl. Raya Cibatu No. 45, Cibatu",
      "operationalHours": "07:00 - 17:00",
      "capacity": "60%",
      "wasteTypes": ["Organik", "Anorganik"],
      "phone": "0262-2345678",
      "rating": 4.2,
      "type": "tps",
    },
    {
      "id": "tps_3",
      "name": "TPS SiBersih - Garut Kota",
      "lat": -7.2272,
      "lng": 107.9027,
      "address": "Jl. Jend. Sudirman No. 16, Garut Kota",
      "operationalHours": "06:00 - 19:00",
      "capacity": "40%",
      "wasteTypes": ["Organik", "Anorganik", "Elektronik"],
      "phone": "0262-3456789",
      "rating": 4.7,
      "type": "tps",
    },
    {
      "id": "bank_1",
      "name": "Bank Sampah - Wanaraja",
      "lat": -7.1970,
      "lng": 107.9733,
      "address": "Jl. Raya Wanaraja No. 78",
      "operationalHours": "08:00 - 16:00",
      "capacity": "70%",
      "wasteTypes": ["Plastik", "Kertas", "Logam", "Kaca"],
      "phone": "0262-4567890",
      "rating": 4.8,
      "type": "bank",
    },
    {
      "id": "tps_4",
      "name": "TPS SiBersih - Samarang",
      "lat": -7.1875,
      "lng": 107.8123,
      "address": "Jl. Raya Samarang No. 56, Samarang",
      "operationalHours": "06:00 - 17:00",
      "capacity": "75%",
      "wasteTypes": ["Organik", "Anorganik", "Kertas"],
      "phone": "0262-5678901",
      "rating": 4.3,
      "type": "tps",
    },
    {
      "id": "bank_2",
      "name": "Bank Sampah - Leles",
      "lat": -7.1578,
      "lng": 107.8536,
      "address": "Jl. Raya Leles No. 34, Leles",
      "operationalHours": "08:00 - 15:00",
      "capacity": "55%",
      "wasteTypes": ["Plastik", "Kertas", "Logam"],
      "phone": "0262-6789012",
      "rating": 4.6,
      "type": "bank",
    },
  ];

  Future<void> _launchUrl(Uri url) async {
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  void _showTpsDetails(Map<String, dynamic> tps) {
    setState(() {
      _selectedTpsId = tps['id'];
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildTpsDetailsSheet(tps),
    );
  }

  Widget _buildTpsDetailsSheet(Map<String, dynamic> tps) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25.0),
          topRight: Radius.circular(25.0),
        ),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Header dengan Icon & Nama
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: tps['type'] == 'tps'
                                ? [
                                    const Color(0xFF4DD0E1),
                                    const Color(0xFF26C6DA),
                                  ]
                                : [
                                    const Color(0xFF9CCC65),
                                    const Color(0xFF7CB342),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        child: Icon(
                          tps['type'] == 'tps'
                              ? Icons.delete_outline_rounded
                              : Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tps['name'],
                              style: const TextStyle(
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00838F),
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Color(0xFFFFC107),
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${tps['rating']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF00838F),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Alamat
                  _buildInfoRow(
                    Icons.location_on_rounded,
                    'Alamat',
                    tps['address'],
                    const Color(0xFFEF5350),
                  ),
                  const SizedBox(height: 16),

                  // Jam Operasional
                  _buildInfoRow(
                    Icons.access_time_rounded,
                    'Jam Operasional',
                    tps['operationalHours'],
                    const Color(0xFF4DD0E1),
                  ),
                  const SizedBox(height: 16),

                  // Kapasitas
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFF9CCC65).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.pie_chart_rounded,
                              color: Color(0xFF9CCC65),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Kapasitas',
                            style: TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF546E7A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value:
                                    double.parse(
                                      tps['capacity'].replaceAll('%', ''),
                                    ) /
                                    100,
                                minHeight: 12,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _getCapacityColor(tps['capacity']),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            tps['capacity'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _getCapacityColor(tps['capacity']),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Jenis Sampah
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFF66BB6A).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.category_rounded,
                              color: Color(0xFF66BB6A),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Jenis Sampah Diterima',
                            style: TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF546E7A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: (tps['wasteTypes'] as List<String>)
                            .map((type) => _buildWasteTypeChip(type))
                            .toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.phone_rounded,
                          label: 'Telepon',
                          gradient: const LinearGradient(
                            colors: [Color(0xFF66BB6A), Color(0xFF4CAF50)],
                          ),
                          onTap: () {
                            _launchUrl(Uri.parse('tel:${tps['phone']}'));
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.directions_rounded,
                          label: 'Navigasi',
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4DD0E1), Color(0xFF26C6DA)],
                          ),
                          onTap: () {
                            final url =
                                'https://www.google.com/maps/dir/?api=1&destination=${tps['lat']},${tps['lng']}';
                            _launchUrl(Uri.parse(url));
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF546E7A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15.0,
                  color: Color(0xFF00838F),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWasteTypeChip(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF9CCC65), Color(0xFF7CB342)],
        ),
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9CCC65).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        type,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 13.0,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF26C6DA).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getCapacityColor(String capacity) {
    final value = double.parse(capacity.replaceAll('%', ''));
    if (value < 50) return const Color(0xFF66BB6A); // Green
    if (value < 75) return const Color(0xFFFFC107); // Yellow
    return const Color(0xFFEF5350); // Red
  }

  @override
  Widget build(BuildContext context) {
    final List<Marker> markers = tpsLocations.map((tps) {
      final bool isSelected = _selectedTpsId == tps['id'];
      return Marker(
        width: 50.0,
        height: 50.0,
        point: latlng.LatLng(tps['lat'], tps['lng']),
        child: GestureDetector(
          onTap: () => _showTpsDetails(tps),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Shadow/Glow Effect
                Container(
                  width: isSelected ? 40 : 35,
                  height: isSelected ? 40 : 35,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: tps['type'] == 'tps'
                            ? const Color(0xFF26C6DA).withOpacity(0.5)
                            : const Color(0xFF9CCC65).withOpacity(0.5),
                        blurRadius: isSelected ? 20 : 15,
                        spreadRadius: isSelected ? 5 : 3,
                      ),
                    ],
                  ),
                ),
                // Icon
                Icon(
                  tps['type'] == 'tps'
                      ? Icons.delete_rounded
                      : Icons.account_balance_wallet_rounded,
                  color: tps['type'] == 'tps'
                      ? const Color(0xFF26C6DA)
                      : const Color(0xFF9CCC65),
                  size: isSelected ? 40.0 : 35.0,
                  shadows: const [
                    Shadow(
                      color: Colors.black26,
                      offset: Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FDFD),
      appBar: AppBar(
        title: const Text(
          'Peta Lokasi TPS - Garut',
          style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF26C6DA), Color(0xFF00ACC1), Color(0xFF00BCD4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Peta
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: latlng.LatLng(-7.2035, 107.9057), // Pusat Garut
              initialZoom: 12.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'id.sibersih.eco_manage',
              ),
              MarkerLayer(markers: markers),
              RichAttributionWidget(
                alignment: AttributionAlignment.bottomLeft,
                attributions: [
                  TextSourceAttribution(
                    '© OpenStreetMap contributors',
                    onTap: () => _launchUrl(
                      Uri.parse('https://openstreetmap.org/copyright'),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Legend Card di pojok kanan atas
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Legenda',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.0,
                      color: Color(0xFF00838F),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.delete_rounded,
                        color: const Color(0xFF26C6DA),
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      const Text('TPS', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.account_balance_wallet_rounded,
                        color: const Color(0xFF9CCC65),
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      const Text('Bank Sampah', style: TextStyle(fontSize: 12)),
                    ],
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
