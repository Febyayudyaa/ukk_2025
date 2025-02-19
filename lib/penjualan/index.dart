import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ukk_2025/produk/harga.dart';
import 'package:intl/intl.dart';

class IndexPenjualanAdmin extends StatefulWidget {
  const IndexPenjualanAdmin({super.key});

  @override
  State<IndexPenjualanAdmin> createState() => _IndexPenjualanAdminState();
}

class _IndexPenjualanAdminState extends State<IndexPenjualanAdmin> {
  List<Map<String, dynamic>> penjualan = [];
  List<int> selectedPenjualan = [];

  @override
  void initState() {
    super.initState();
    fetchPenjualan();
  }

  Future<void> fetchPenjualan() async {
    try {
      final response = await Supabase.instance.client
          .from('penjualan')
          .select('*, pelanggan(*)');
      setState(() {
        penjualan = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: penjualan.isEmpty
          ? const Center(child: Text('Data penjualan belum ditambahkan'))
          : ListView.builder(
              itemCount: penjualan.length,
              itemBuilder: (context, index) {
                final pjl = penjualan[index];
                return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    child: SizedBox(
                        height: 180,
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nama Pelanggan: ${pjl['pelanggan']['NamaPelanggan'] ?? 'Tidak tersedia'}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 20),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Tanggal: ${pjl['TanggalPenjualan'] ?? 'Tidak tersedia'}',
                                style: TextStyle(fontSize: 18),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Total Harga: Rp${pjl['TotalHarga'] != null ? NumberFormat("#,###", "id_ID").format(int.tryParse(pjl['TotalHarga'].toString()) ?? 0) : 'tidak tersedia'}',
                                style: TextStyle(fontSize: 18),
                              )
                            ],
                          ),
                        )));
              }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => HargaProdukAdmin()));
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
