import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Beliproduk extends StatefulWidget {
  final Map<String, dynamic> produk;
  const Beliproduk({Key? key, required this.produk}) : super(key: key);

  @override
  _BeliprodukState createState() => _BeliprodukState();
}

class _BeliprodukState extends State<Beliproduk> {
  int jumlahProduk = 0;
  int subtotal = 0;
  int? selectedPelangganID;

  @override
  void initState() {
    super.initState();
  }

  void updateJumlahProduk(int harga, int delta) {
    setState(() {
      jumlahProduk += delta;
      if (jumlahProduk < 0) jumlahProduk = 0;
      subtotal = jumlahProduk * harga;
    });
  }

  Future<void> insertPenjualan(int totalHarga) async {
    final supabase = Supabase.instance.client;
    try {
      await supabase.from('penjualan').insert({
        'TanggalPenjualan': DateTime.now().toIso8601String(),
        'TotalHarga': totalHarga,
        'PelangganID': selectedPelangganID ?? 1,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pesanan berhasil disimpan!')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan pesanan: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final produk = widget.produk;
    final harga = produk['Harga'] ?? 0;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          produk['NamaProduk'] ?? 'Detail Produk',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.brown[800],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        color: Colors.white,
        child: Center(
          child: Card(
            margin: const EdgeInsets.all(20),
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    produk['NamaProduk'] ?? 'Nama Produk Tidak Tersedia',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text('Harga: Rp$harga', style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 16),
                  Text(
                    'Stok Tersedia: ${produk['Stok'] ?? 'Tidak Tersedia'}',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () => updateJumlahProduk(harga, -1),
                        icon: const Icon(Icons.remove_circle,
                            size: 32, color: Colors.brown),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          '$jumlahProduk',
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        onPressed: () => updateJumlahProduk(harga, 1),
                        icon: const Icon(Icons.add_circle,
                            size: 32, color: Colors.brown),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (jumlahProduk > 0) {
                              await insertPenjualan(subtotal);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.brown[800],
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            'Pesan (Rp$subtotal)',
                            style: const TextStyle(
                                fontSize: 18, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
