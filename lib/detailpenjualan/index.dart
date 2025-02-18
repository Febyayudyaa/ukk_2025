import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ukk_2025/homepage.dart';

class DetailPenjualanIndex extends StatefulWidget {
  final int penjualanI;
  const DetailPenjualanIndex({super.key, required this.penjualanI});

  @override
  State<DetailPenjualanIndex> createState() => _DetailPenjualanIndexState();
}

class _DetailPenjualanIndexState extends State<DetailPenjualanIndex> {
  List<Map<String, dynamic>> detail = [];
  bool isLoading = true;
  Map<int, bool> selectedProduk = {};
  double totalHarga = 0.0;

  @override
  void initState() {
    super.initState();
    fetchdetail();
  }

  Future<void> fetchdetail() async {
    setState(() => isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('detailpenjualan')
          .select('*, penjualan(*, pelanggan(*)), produk(*)');

      setState(() {
        detail = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => isLoading = false);
    }
  }

  void toggleProdukSelection(int ProdukID, double harga) {
    setState(() {
      selectedProduk[ProdukID] = !(selectedProduk[ProdukID] ?? false);
      totalHarga =
          selectedProduk[ProdukID]! ? totalHarga + harga : totalHarga - harga;
    });
  }

  Future<void> insertDetailPenjualan() async {
    List<Map<String, dynamic>> produkDipilih = detail.where((dtl) {
      int? produkID = dtl['produk']?['ProdukID'] as int?;
      return produkID != null && selectedProduk[produkID] == true;
    }).map((dtl) {
      return {
        'PelangganID': dtl['pelanggan']?['PelangganID'],
        'TotalHarga': (dtl['Subtotal'] as num?)?.toDouble() ?? 0.0,
      };
    }).toList();

    if (produkDipilih.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Pilih minimal satu produk!")),
      );
      return;
    }

    try {
      await Supabase.instance.client.from('penjualan').insert(produkDipilih);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Produk berhasil dipesan!")),
      );
      setState(() {
        selectedProduk.clear();
        totalHarga = 0.0;
      });
    } catch (e) {
      debugPrint("Error saat insert: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal memesan produk: $e")),
      );
    }
  }

  void showOrderDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Pilih Opsi"),
        content: Text("Ingin pesan produk atau mencetak PDF?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              insertDetailPenjualan();
            },
            child: Text("Pesan Produk"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text("Cetak PDF"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.brown[800],
        title: const Text('Detail Penjualan',
            style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => HomePage()));
          },
        ),
      ),
      body: detail.isEmpty
          ? Center(
              child: Text('Detail Penjualan',
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.all(8),
                    itemCount: detail.length,
                    itemBuilder: (context, index) {
                      final dtl = detail[index];
                      int produkID = dtl['produk']?['ProdukID'] ?? 0;
                      double harga =
                          (dtl['Subtotal'] as num?)?.toDouble() ?? 0.0;
                      return Card(
                        key: ValueKey(produkID),
                        elevation: 4,
                        margin: EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          title: Text(
                            'Nama Produk: ${dtl['produk']?['NamaProduk'] ?? '-'}',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nama Pelanggan: ${dtl['penjualan']?['pelanggan']?['NamaPelanggan'] ?? '-'}',
                              ),
                              Text(
                                  'Jumlah Produk: ${dtl['JumlahProduk'] ?? 'tidak tersedia'}'),
                              Text(
                                'Total Harga: Rp${harga.toStringAsFixed(2)}',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
