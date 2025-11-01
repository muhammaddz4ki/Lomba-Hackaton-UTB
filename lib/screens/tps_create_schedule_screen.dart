import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TpsCreateScheduleScreen extends StatefulWidget {
  const TpsCreateScheduleScreen({super.key});

  @override
  State<TpsCreateScheduleScreen> createState() =>
      _TpsCreateScheduleScreenState();
}

class _TpsCreateScheduleScreenState extends State<TpsCreateScheduleScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _areaNameController = TextEditingController();
  final _timeStartController = TextEditingController();
  final _timeEndController = TextEditingController();

  // State untuk hari (Checkboxes)
  // Kita gunakan Map agar mudah dikelola
  final Map<String, bool> _days = {
    'Senin': false,
    'Selasa': false,
    'Rabu': false,
    'Kamis': false,
    'Jumat': false,
    'Sabtu': false,
    'Minggu': false,
  };

  bool _isLoading = false;

  // --- (FUNGSI BARU) Helper untuk memilih jam ---
  Future<void> _selectTime(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        controller.text = picked.format(context); // Format: 10:30 AM
      });
    }
  }

  // --- (FUNGSI BARU) Kirim Jadwal ---
  Future<void> _submitSchedule() async {
    if (!_formKey.currentState!.validate()) return;

    // Ambil hari-hari yang dicentang
    final List<String> selectedDays = [];
    _days.forEach((day, isSelected) {
      if (isSelected) {
        selectedDays.add(day);
      }
    });

    // Validasi: Pastikan setidaknya 1 hari dipilih
    if (selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap pilih minimal satu hari.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final tpsUser = FirebaseAuth.instance.currentUser;
      if (tpsUser == null) throw Exception('TPS tidak login');

      // Siapkan data untuk koleksi BARU 'public_schedules'
      final data = {
        'tpsId': tpsUser.uid,
        'areaName': _areaNameController.text.trim(),
        'timeStart': _timeStartController.text,
        'timeEnd': _timeEndController.text,
        'days': selectedDays, // Simpan sebagai array
        'createdAt': Timestamp.now(),
      };

      // Simpan ke database
      await FirebaseFirestore.instance.collection('public_schedules').add(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Jadwal baru berhasil ditambahkan!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Kembali
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _areaNameController.dispose();
    _timeStartController.dispose();
    _timeEndController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Jadwal Umum Baru'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // 1. Nama Area
            TextFormField(
              controller: _areaNameController,
              decoration: const InputDecoration(
                labelText: 'Nama Area/Wilayah',
                hintText: 'Contoh: Komplek Sukajadi, Kecamatan Antapani',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama area tidak boleh kosong';
                }
                return null;
              },
            ),
            const SizedBox(height: 24.0),

            // 2. Hari Pengangkutan
            Text(
              'Hari Pengangkutan',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8.0),
            // Kita gunakan Wrap agar rapi
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: _days.keys.map((String day) {
                return ChoiceChip(
                  label: Text(day),
                  selected: _days[day]!,
                  onSelected: (bool selected) {
                    setState(() {
                      _days[day] = selected;
                    });
                  },
                  selectedColor: Theme.of(context).colorScheme.primaryContainer,
                );
              }).toList(),
            ),
            const SizedBox(height: 24.0),

            // 3. Jam Operasi
            Text('Jam Operasi', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8.0),
            Row(
              children: [
                // Jam Mulai
                Expanded(
                  child: TextFormField(
                    controller: _timeStartController,
                    readOnly: true, // Tidak bisa diketik
                    decoration: const InputDecoration(
                      labelText: 'Jam Mulai',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.access_time),
                    ),
                    onTap: () => _selectTime(context, _timeStartController),
                    validator: (value) =>
                        (value == null || value.isEmpty) ? 'Harus diisi' : null,
                  ),
                ),
                const SizedBox(width: 16.0),
                // Jam Selesai
                Expanded(
                  child: TextFormField(
                    controller: _timeEndController,
                    readOnly: true, // Tidak bisa diketik
                    decoration: const InputDecoration(
                      labelText: 'Jam Selesai',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.access_time),
                    ),
                    onTap: () => _selectTime(context, _timeEndController),
                    validator: (value) =>
                        (value == null || value.isEmpty) ? 'Harus diisi' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32.0),

            // Tombol Simpan
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _submitSchedule,
              icon: _isLoading
                  ? const SizedBox.shrink()
                  : const Icon(Icons.save_outlined),
              label: _isLoading
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                  : const Text(
                      'Simpan Jadwal',
                      style: TextStyle(fontSize: 16.0),
                    ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
