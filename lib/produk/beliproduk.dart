import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:ukk_2025/homepage.dart';

class harga extends StatefulWidget {
  final Map<String, dynamic> produk;
  const harga({Key? key, required this.produk}) : super(key: key);

  @override
  _hargaState createState() => _hargaState();
}

class _hargaState extends State<harga> {
  int jumlahPesanan = 0;
  int stokakhir = 0;
  int totalHarga = 0;
  int? selectedPelangganId;
  List<Map<String, dynamic>> pelangganList = [];

  @override
  void initState() {
    super.initState();
    fetchPelanggan();
    stokakhir = widget.produk['Stok'];
  }

  Future<void> fetchPelanggan() async {
    final supabase = Supabase.instance.client;
    final response =
        await supabase.from('pelanggan').select('PelangganID, NamaPelanggan');

    if (response.isNotEmpty) {
      setState(() {
        pelangganList = List<Map<String, dynamic>>.from(response);
      });
    }
  }

  void updateJumlahPesanan(int harga, int delta) {
    setState(() {
      if (jumlahPesanan + delta >= 0 && jumlahPesanan + delta <= stokakhir) {
        jumlahPesanan += delta;
        totalHarga = jumlahPesanan * harga;
      }
    });
  }

  void simpanPesanan() async {
    try {
      if (totalHarga == 0) {
        print("Total harga tidak boleh 0.");
        return;
      }

      final penjualan = await Supabase.instance.client
          .from('penjualan')
          .insert({
            'TotalHarga': totalHarga,
            'PelangganID': selectedPelangganId,
          })
          .select()
          .single();

      if (penjualan == null) {
        print("Gagal menyimpan penjualan.");
        return;
      }

      final penjualanId = penjualan['PenjualanID'];
      print("Penjualan berhasil disimpan dengan ID: $penjualanId");

      // Menyimpan detail penjualan untuk produk yang dibeli
      final produk = widget.produk;
      final produkid = produk['ProdukID'];
      final jumlahPesanan = this.jumlahPesanan;
      final subtotal = totalHarga;
      if (produkid == null || jumlahPesanan == null || jumlahPesanan <= 0) {
        print("Produk ID atau jumlah tidak valid: $produk");
        return;
      }

      final response = await Supabase.instance.client
          .from('detailpenjualan')
          .insert({
            'PenjualanID': penjualanId,
            'ProdukID': produkid,
            'JumlahProduk': jumlahPesanan,
            'Subtotal': subtotal,
            'PelangganID': selectedPelangganId,
          })
          .select()
          .single();

      if (response == null) {
        print("Gagal menyimpan detail penjualan untuk ProdukID: $produkid");
      } else {
        print("Detail penjualan berhasil disimpan untuk ProdukID: $produkid");
      }

      setState(() {
        jumlahPesanan;
        totalHarga = 0;
      });

      print("Pesanan berhasil disimpan!");
    } catch (e) {
      print("Terjadi kesalahan: $e");
    }
  }

  Future<void> showPrintConfirmation(int penjualanId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: const Text('Apakah Anda ingin mencetak struk pembelian?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tidak'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cetak'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      generatePDF(penjualanId);
    } else {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => HomePage()));
    }
  }

  Future<void> generatePDF(int penjualanId) async {
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
            pw.Text('Total Harga: Rp $totalHarga'),
            pw.SizedBox(height: 16),
            pw.Text('Terima kasih telah berbelanja!',
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
        foregroundColor: Colors.white,
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nama Produk: ${produk['NamaProduk'] ?? 'Tidak Tersedia'}',
                    style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 16),
                Text('Harga: $harga', style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 16),
                Text('Stok: ${produk['Stok'] ?? 'Tidak Tersedia'}',
                    style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: selectedPelangganId,
                  items: pelangganList.map((pelanggan) {
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
                      onPressed: jumlahPesanan > 0
                          ? () => updateJumlahPesanan(harga, -1)
                          : null,
                      icon: const Icon(Icons.remove),
                    ),
                    Text('$jumlahPesanan',
                        style: const TextStyle(fontSize: 20)),
                    IconButton(
                      onPressed: jumlahPesanan < stokakhir
                          ? () => updateJumlahPesanan(harga, 1)
                          : null,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Tutup',
                          style: TextStyle(fontSize: 20, color: Colors.black)),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: jumlahPesanan > 0 ? simpanPesanan : null,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown[800]),
                      child: Text(
                        'Pesan ($totalHarga)',
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white,
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
    );
  }
}
