import 'package:flutter/material.dart';
import 'package:ukk_2025/homepage.dart';
import 'package:ukk_2025/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InsertPenjualan extends StatefulWidget {
  const InsertPenjualan({super.key});

  @override
  State<InsertPenjualan> createState() => _InsertPenjualanState();
}

class _InsertPenjualanState extends State<InsertPenjualan> {
  final _formKey = GlobalKey<FormState>();
  final _tglController = TextEditingController();
  final _totalController = TextEditingController();
  final _plnggnIdController = TextEditingController();

  final SupabaseClient supabase = Supabase.instance.client;

  Future<void> _saveData() async {
  if (!_formKey.currentState!.validate()) return;

  final TanggalPenjualan = DateTime.parse(_tglController.text); 
  final TotalHarga = double.tryParse(_totalController.text) ?? 0.0;
  final PelangganID = int.tryParse(_plnggnIdController.text) ?? 0;

  try {
    final response = await supabase.from('penjualan').insert({
      'TanggalPenjualan': TanggalPenjualan.toIso8601String(), 
      'TotalHarga': TotalHarga,
      'PelangganID': PelangganID,
    }).select();

    if (response.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data berhasil disimpan!')),
      );
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage()));
    } else {
      throw Exception('Gagal menyimpan data.');
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Terjadi kesalahan: $e')),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tambah Penjualan',
          style: TextStyle(color: Colors.white),
        ),
        elevation: 0,
        backgroundColor: Colors.brown[800],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,color: Colors.white),
          onPressed: () {
            Navigator.pop(context, MaterialPageRoute(builder: (context) => const InsertPenjualan()));
          },
        ),
      ),
      body: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _tglController,
                decoration: const InputDecoration(
                  labelText: 'Tanggal Penjualan',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Tanggal tidak boleh kosong'
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _totalController,
                decoration: const InputDecoration(
                  labelText: 'Total Harga',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Total harga tidak boleh kosong'
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _plnggnIdController,
                decoration: const InputDecoration(
                  labelText: 'ID Pelanggan',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'ID Pelanggan tidak boleh kosong'
                    : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
              onPressed: _saveData,
              child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  width: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.brown[800],
                    borderRadius: BorderRadius.circular(30)
                  ),
                  child: const Text(
                    'SIMPAN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                )
              ),
            ],
          ),
        ),
      ),
    );
  }
}

