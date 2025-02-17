import 'package:flutter/material.dart';
import 'package:ukk_2025/homepage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DetailPenjualanIndex extends StatefulWidget {
  const DetailPenjualanIndex({Key? key}) : super(key: key);

  @override
  _DetailPenjualanIndexState createState() => _DetailPenjualanIndexState();
}

class _DetailPenjualanIndexState extends State<DetailPenjualanIndex> {
  List<Map<String, dynamic>> riwayatPesanan = [];

  @override
  void initState() {
    super.initState();
    fetchRiwayatPesanan();
  }

  Future<void> fetchRiwayatPesanan() async {
    final supabase = Supabase.instance.client;
    final response = await supabase.from('detailpenjualan').select('''
          DetailID, 
          PenjualanID, 
          ProdukID, 
          JumlahProduk, 
          Subtotal, 
          PelangganID,
          produk(NamaProduk, Harga), 
          pelanggan(NamaPelanggan)
      ''');
    // PelangganID,
    //  pelanggan(NamaPelanggan)

    print(response);

    setState(() {
      riwayatPesanan = List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> hapusPesanan(int detailID) async {
    final supabase = Supabase.instance.client;
    await supabase
        .from('detailpenjualan')
        .delete()
        .match({'DetailID': detailID});
    fetchRiwayatPesanan();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pesanan Produk berhasil di hapus')),
    );
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
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
              (route) => false,
            );
          },
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: riwayatPesanan.length,
        itemBuilder: (context, index) {
          final pesanan = riwayatPesanan[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              title: Text(
                '${pesanan['produk']['NamaProduk'] ?? 'Produk Tidak Diketahui'} - ${pesanan['pelanggan']['NamaPelanggan'] ?? 'Tanpa Nama'}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                  'Jumlah: ${pesanan['JumlahProduk']} - Total: Rp${pesanan['Subtotal']}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.brown),
                onPressed: () => hapusPesanan(pesanan['DetailID']),
              ),
            ),
          );
        },
      ),
    );
  }
}
