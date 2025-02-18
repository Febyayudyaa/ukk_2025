import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ukk_2025/homepage.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class InsertPenjualan extends StatefulWidget {
  final Map<String, dynamic> produk;
  const InsertPenjualan({Key? key, required this.produk}) : super(key: key);

  @override
  State<InsertPenjualan> createState() => _InsertPenjualanState();
}

class _InsertPenjualanState extends State<InsertPenjualan> {
  int jumlahPesanan = 0;
  int stokakhir = 0;
  int totalharga = 0;
  int? selectedPelangganId;
  List<Map<String, dynamic>> pelangganlist = [];

  @override
  void initState() {
    super.initState();
    stokakhir = widget.produk['Stok'] ?? 0;
    fetchPelanggan();
  }

  Future<void> fetchPelanggan() async {
    final response = await Supabase.instance.client
        .from('pelanggan')
        .select('PelangganID, NamaPelanggan');
    setState(() {
      pelangganlist = List<Map<String, dynamic>>.from(response);
    });
  }

  void updatedata(int harga, int delta) {
    setState(() {
      if (jumlahPesanan + delta >= 0 && jumlahPesanan + delta <= stokakhir) {
        jumlahPesanan += delta;
        totalharga = jumlahPesanan * harga;
      }
    });
  }

  Future<void> simpanpesanan() async {
    final produkId = widget.produk['ProdukID'];
    if (produkId == null || selectedPelangganId == null || jumlahPesanan <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Gagal menyimpan data, pastikan semua data telah terisi.')),
      );
      return;
    }
    try {
      final penjualan = await Supabase.instance.client
          .from('penjualan')
          .insert(
              {'TotalHarga': totalharga, 'PelangganID': selectedPelangganId})
          .select()
          .single();

      if (penjualan.isNotEmpty) {
        final penjualanId = penjualan['PenjualanID'];
        await Supabase.instance.client.from('detailpenjualan').insert({
          'PenjualanID': penjualanId,
          'ProdukID': produkId,
          'JumlahProduk': jumlahPesanan,
          'Subtotal': totalharga
        });

        await Supabase.instance.client.from('produk').update(
            {'Stok': stokakhir - jumlahPesanan}).eq('ProdukID', produkId);

        cetak(penjualanId);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan saat menyimpan data.')));
    }
  }

  Future<void> cetak(int penjualanId) async {
    final confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konfirmasi Cetak'),
        content: Text('Apakah Anda ingin mencetak struk pembelian ini?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Batal')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Cetak')),
        ],
      ),
    );
    if (confirm == true) {
      pdf(penjualanId);
    } else {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => HomePage()));
    }
  }

  Future<void> pdf(int penjualanId) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Struk Pembelian',
                style:
                    pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
            pw.Text('ID Penjualan: $penjualanId'),
            pw.Text('Nama Produk: ${widget.produk['NamaProduk']}'),
            pw.Text('Jumlah: $jumlahPesanan'),
            pw.Text('Total Harga: Rp $totalharga'),
            pw.SizedBox(height: 16),
            pw.Text('Terima Kasih!',
                style:
                    pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => HomePage()));
  }

  @override
  Widget build(BuildContext context) {
    final produk = widget.produk;
    final harga = produk['Harga'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Produk'),
        backgroundColor: Colors.brown[800],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<int>(
              value: selectedPelangganId,
              items: pelangganlist.map((pelanggan) {
                return DropdownMenuItem<int>(
                  value: pelanggan['PelangganID'],
                  child: Text(pelanggan['NamaPelanggan']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedPelangganId = value;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Pilih Pelanggan',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => updatedata(harga, -1),
                  icon: const Icon(Icons.remove),
                ),
                Text('$jumlahPesanan', style: const TextStyle(fontSize: 20)),
                IconButton(
                  onPressed: () => updatedata(harga, 1),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: jumlahPesanan > 0 ? simpanpesanan : null,
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.brown[800]),
              child: Text('Pesan ($totalharga)',
                  style: const TextStyle(fontSize: 20)),
            ),
          ],
        ),
      ),
    );
  }
}
