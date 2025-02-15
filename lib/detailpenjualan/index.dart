import 'package:flutter/material.dart';
import 'package:ukk_2025/homepage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class IndexDetailJual extends StatefulWidget {
  final Map<String, dynamic> prd;
  const IndexDetailJual({Key? key, required this.prd}) : super(key: key);

  @override
  State<IndexDetailJual> createState() => _IndexDetailJualState();
}

class _IndexDetailJualState extends State<IndexDetailJual> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> detailpenjualan = [];
  bool isLoading = false;
  bool isOrdering = false;

  @override
  void initState() {
    super.initState();
    fetchDetailPenjualan();
  }

  Future<void> fetchDetailPenjualan() async {
    setState(() => isLoading = true);
    try {
      final response = await supabase
          .from('detailpenjualan')
          .select('*'); // Mengambil semua kolom tanpa join

      setState(
          () => detailpenjualan = List<Map<String, dynamic>>.from(response));
    } catch (e) {
      print('Error fetching detail penjualan: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> transaksi(int pelangganID, int subtotal) async {
    setState(() => isOrdering = true);
    try {
      final response = await supabase.from('penjualan').insert({
        'PelangganID': pelangganID,
        'TotalHarga': subtotal,
      }).select();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(response.isNotEmpty
                ? 'Pesanan berhasil disimpan!'
                : 'Gagal menyimpan pesanan')),
      );
      if (response.isNotEmpty) Navigator.pop(context);
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terjadi kesalahan saat memesan')),
      );
    } finally {
      setState(() => isOrdering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Penjualan',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.brown[800],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => HomePage()));
          },
        ),
      ),
      body: isLoading
          ? Center(
              child: LoadingAnimationWidget.twoRotatingArc(
                color: Colors.grey,
                size: 30,
              ),
            )
          : detailpenjualan.isEmpty
              ? const Center(
                  child: Text('Detail penjualan tidak ada',
                      style: TextStyle(fontSize: 18)),
                )
              : ListView.builder(
                  itemCount: detailpenjualan.length,
                  itemBuilder: (context, index) {
                    final detail = detailpenjualan[index];
                    final int pelangganID = detail['PelangganID'] ?? 1;
                    final int subtotal = (detail['Subtotal'] is int)
                        ? detail['Subtotal']
                        : int.tryParse(detail['Subtotal']?.toString() ?? '0') ??
                            0;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'Detail ID: ${detail['DetailID']?.toString() ?? 'tidak tersedia'}',
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(
                                'Penjualan ID: ${detail['PenjualanID']?.toString() ?? 'tidak tersedia'}',
                                style: const TextStyle(fontSize: 16)),
                            Text(
                                'Produk ID: ${detail['ProdukID']?.toString() ?? 'tidak tersedia'}',
                                style: const TextStyle(fontSize: 16)),
                            Text(
                                'Jumlah Produk: ${detail['JumlahProduk']?.toString() ?? 'tidak tersedia'}',
                                style: const TextStyle(fontSize: 16)),
                            Text(
                                'Subtotal: ${detail['Subtotal']?.toString() ?? 'tidak tersedia'}',
                                style: const TextStyle(fontSize: 16)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: isOrdering
                                  ? null
                                  : () async =>
                                      await transaksi(pelangganID, subtotal),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.brown[800],
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              child: isOrdering
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : const Text('Pesan',
                                      style: TextStyle(
                                          fontSize: 16, color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
