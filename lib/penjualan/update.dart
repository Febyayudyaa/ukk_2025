
import 'package:flutter/material.dart';
import 'package:ukk_2025/homepage.dart';
import 'package:ukk_2025/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UpdatePenjualan extends StatefulWidget {
  final int PenjualanID;

  const UpdatePenjualan({super.key, required this.PenjualanID});

  @override
  State<UpdatePenjualan> createState() => _UpdatePenjualanState();
}

class _UpdatePenjualanState extends State<UpdatePenjualan> {
  final _tgl = TextEditingController();
  final _total = TextEditingController();
  final _plnggnId = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadPenjualan();
  }

  Future<void> _loadPenjualan() async {
    try {
      final data = await Supabase.instance.client
          .from('penjualan')
          .select()
          .eq('PenjualanID', widget.PenjualanID)
          .single();

      setState(() {
        _tgl.text = data['TanggalPenjualan'] ?? '';
        _total.text = (data['TotalHarga'] as double?)?.toString() ?? '';
        _plnggnId.text = data['PelangganID']?.toString() ?? '';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Data tidak ditemukan: $e')),
      );
    }
  }

  Future<void> updatePenjualan() async {
    if (_formKey.currentState!.validate()) {
      try {
        final response = await Supabase.instance.client.from('penjualan').update({
          'TanggalPenjualan': DateTime.parse(_tgl.text).toIso8601String(),
          'TotalHarga': double.tryParse(_total.text) ?? 0.0,
          'PelangganID': int.tryParse(_plnggnId.text) ?? 0,
        }).eq('PenjualanID', widget.PenjualanID).select();

        if (response.isNotEmpty) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
            (route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Update gagal, coba lagi!')),
          );
        }
      } catch (e) {
        print('Error updating penjualan: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Terjadi kesalahan saat memperbarui data')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Penjualan', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF4E342E),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6D4C41), Color(0xFF8D6E63), Color(0xFFA1887F)], 
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _tgl,
                decoration: const InputDecoration(
                  labelText: 'Tanggal Penjualan',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Tanggal tidak boleh kosong';
                  }
                  try {
                    DateTime.parse(value); 
                  } catch (e) {
                    return 'Format tanggal tidak valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _total,
                decoration: const InputDecoration(
                  labelText: 'Total Harga',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Total tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _plnggnId,
                decoration: const InputDecoration(
                  labelText: 'ID Pelanggan',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'ID tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: updatePenjualan,
                child: const Text(
                  'Update',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.brown,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}