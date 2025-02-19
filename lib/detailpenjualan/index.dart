import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class IndexDetailAdmin extends StatefulWidget {
  final int penjualanID; // Tambahkan parameter

  const IndexDetailAdmin({Key? key, required this.penjualanID})
      : super(key: key);

  @override
  State<IndexDetailAdmin> createState() => _IndexDetailAdminState();
}

class _IndexDetailAdminState extends State<IndexDetailAdmin> {
  List<Map<String, dynamic>> detailList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDetail();
  }

  Future<void> fetchDetail() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await Supabase.instance.client
          .from('detailpenjualan')
          .select('*, penjualan(*, pelanggan(*)), produk(*)')
          .eq('PenjualanID',
              widget.penjualanID); // Filter berdasarkan penjualanID

      setState(() {
        detailList = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error saat mengambil data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.brown[800],
        title: const Text('Detail Penjualan',
            style: TextStyle(color: Colors.white)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : detailList.isEmpty
              ? const Center(child: Text('Tidak ada detail penjualan'))
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: detailList.length,
                  itemBuilder: (context, index) {
                    final dtl = detailList[index];
                    final penjualan = dtl['penjualan'] ?? {};
                    final pelanggan = penjualan['pelanggan'] ?? {};
                    final produk = dtl['produk'] ?? {};

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SizedBox(
                        height: 180,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nama Pelanggan: ${pelanggan['NamaPelanggan'] ?? 'Tidak tersedia'}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Nama Produk: ${produk['NamaProduk'] ?? 'Tidak tersedia'}',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Jumlah Produk: ${dtl['JumlahProduk'] ?? 'Tidak tersedia'}',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'SubTotal: Rp${dtl['Subtotal'] != null ? NumberFormat("#,###", "id_ID").format(int.tryParse(dtl['Subtotal'].toString()) ?? 0) : 'tidak tersedia'}',
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.brown),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
