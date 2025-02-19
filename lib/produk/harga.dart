import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class HargaProdukAdmin extends StatefulWidget {
  const HargaProdukAdmin({Key? key}) : super(key: key);

  @override
  _HargaProdukAdminState createState() => _HargaProdukAdminState();
}

class _HargaProdukAdminState extends State<HargaProdukAdmin> {
  final formatCurrency =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  List<Map<String, dynamic>> produkList = [];
  Map<int, bool> productSelected = {};
  Map<int, int> productQuantity = {};

  int? selectedPelangganId;
  List<Map<String, dynamic>> pelangganList = [];

  bool isLoadingProducts = true;

  @override
  void initState() {
    super.initState();
    fetchPelanggan();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('produk')
        .select()
        .order('ProdukID', ascending: true);
    if (response != null && response is List) {
      setState(() {
        produkList = List<Map<String, dynamic>>.from(response);
        for (var produk in produkList) {
          int productId = produk['ProdukID'] ?? 0;
          productSelected[productId] = false;
          productQuantity[productId] = 0;
        }
        isLoadingProducts = false;
      });
    } else {
      setState(() {
        isLoadingProducts = false;
      });
    }
  }

  /// Mengambil data pelanggan dari tabel 'pelanggan'
  Future<void> fetchPelanggan() async {
    final supabase = Supabase.instance.client;
    final response =
        await supabase.from('pelanggan').select('PelangganID, NamaPelanggan');
    if (response != null && response is List) {
      setState(() {
        pelangganList = List<Map<String, dynamic>>.from(response);
      });
    }
  }

  /// Mengubah status pemilihan produk.
  /// Jika produk dicentang, jumlah default di-set ke 1 (jika sebelumnya 0).
  /// Jika tidak dipilih, jumlah di-reset ke 0.
  void updateProductSelection(int productId, bool isSelected) {
    setState(() {
      productSelected[productId] = isSelected;
      if (isSelected && (productQuantity[productId] ?? 0) == 0) {
        productQuantity[productId] = 1;
      } else if (!isSelected) {
        productQuantity[productId] = 0;
      }
    });
  }

  /// Mengubah jumlah produk (minimal 1 jika produk sudah dipilih).
  void updateProductQuantity(int productId, int delta) {
    setState(() {
      int current = productQuantity[productId] ?? 0;
      int newQuantity = current + delta;
      if (newQuantity < 1) newQuantity = 1;
      productQuantity[productId] = newQuantity;
    });
  }

  /// Menghitung total harga pesanan berdasarkan produk yang dipilih dan jumlahnya.
  int getTotalPrice() {
    int total = 0;
    for (var produk in produkList) {
      int productId = produk['ProdukID'] ?? 0;
      int harga = produk['Harga'] ?? 0;
      if (productSelected[productId] ?? false) {
        int qty = productQuantity[productId] ?? 0;
        total += harga * qty;
      }
    }
    return total;
  }

  /// Menyimpan pesanan ke database (tabel 'penjualan' dan 'detailpenjualan')
  Future<void> saveOrder() async {
    if (selectedPelangganId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pilih pelanggan terlebih dahulu.')),
      );
      return;
    }
    if (!productSelected.containsValue(true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pilih produk yang akan dipesan.')),
      );
      return;
    }

    final supabase = Supabase.instance.client;
    try {
      // Simpan data penjualan ke tabel 'penjualan'
      final penjualan = await supabase
          .from('penjualan')
          .insert({
            'TanggalPenjualan': DateTime.now().toIso8601String(),
            'TotalHarga': getTotalPrice(),
            'PelangganID': selectedPelangganId,
          })
          .select()
          .single();

      if (penjualan != null && penjualan.isNotEmpty) {
        final penjualanId = penjualan['PenjualanID'];
        // Simpan detail penjualan untuk tiap produk yang dipilih
        for (var produk in produkList) {
          int productId = produk['ProdukID'] ?? 0;
          if (productSelected[productId] ?? false) {
            int harga = produk['Harga'] ?? 0;
            int qty = productQuantity[productId] ?? 0;
            await supabase.from('detailpenjualan').insert({
              'PenjualanID': penjualanId,
              'ProdukID': productId,
              'JumlahProduk': qty,
              'Subtotal': harga * qty,
            });
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pesanan berhasil disimpan.')),
        );

        // Setelah menyimpan data, tampilkan dialog konfirmasi untuk cetak
        _showPrintConfirmation();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving order: $e')),
      );
    }
  }

  /// Menampilkan dialog konfirmasi untuk mencetak struk
  void _showPrintConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Konfirmasi'),
          content: Text('Apakah Anda ingin mencetak struk?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Tidak'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _printPdf();
              },
              child: Text('Ya'),
            ),
          ],
        );
      },
    );
  }

  /// Mencetak data pesanan dalam bentuk PDF seperti struk
  Future<void> _printPdf() async {
    final pdf = pw.Document();

    // Format tanggal dan waktu
    final dateTime = DateTime.now();
    final formattedDate =
        "${dateTime.day}-${dateTime.month}-${dateTime.year} ${dateTime.hour}:${dateTime.minute}";

    final totalPrice = getTotalPrice();

    pdf.addPage(
      pw.Page(
        // Format kertas untuk struk, roll80 adalah format lebar 80mm (umum pada printer struk)
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text("STRUK PEMBELIAN",
                    style: pw.TextStyle(
                        fontSize: 18, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 5),
              pw.Center(
                child:
                    pw.Text(formattedDate, style: pw.TextStyle(fontSize: 10)),
              ),
              pw.Divider(),
              pw.Row(
                children: [
                  pw.Expanded(
                    flex: 4,
                    child: pw.Text("Produk",
                        style: pw.TextStyle(
                            fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text("Produk",
                        style: pw.TextStyle(
                            fontSize: 10, fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.right),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text("Subtotal",
                        style: pw.TextStyle(
                            fontSize: 10, fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.right),
                  ),
                ],
              ),
              pw.Divider(),
              // Tampilkan setiap produk yang dipilih
              ...produkList.map((produk) {
                int productId = produk['ProdukID'] ?? 0;
                if (productSelected[productId] ?? false) {
                  int harga = produk['Harga'] ?? 0;
                  int qty = productQuantity[productId] ?? 0;
                  int subtotal = harga * qty;
                  return pw.Padding(
                    padding: pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 4,
                          child: pw.Text(produk['NamaProduk'] ?? "",
                              style: pw.TextStyle(fontSize: 10)),
                        ),
                        pw.Expanded(
                          flex: 1,
                          child: pw.Text("$qty",
                              style: pw.TextStyle(fontSize: 10),
                              textAlign: pw.TextAlign.right),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text("Rp $subtotal",
                              style: pw.TextStyle(fontSize: 10),
                              textAlign: pw.TextAlign.right),
                        ),
                      ],
                    ),
                  );
                }
                return pw.Container();
              }).toList(),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Total",
                      style: pw.TextStyle(
                          fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.Text(formatCurrency.format(totalPrice))
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Center(
                  child: pw.Text("Terima Kasih",
                      style: pw.TextStyle(fontSize: 12))),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pilih Produk'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Dropdown untuk memilih pelanggan
            DropdownButtonFormField<int>(
              value: selectedPelangganId,
              items: pelangganList.map((pelanggan) {
                return DropdownMenuItem<int>(
                  value: pelanggan['PelangganID'],
                  child: Text(pelanggan['NamaPelanggan'] ?? ''),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedPelangganId = value;
                });
              },
              decoration: InputDecoration(
                labelText: 'Pilih Pelanggan',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Menampilkan daftar produk
            Expanded(
              child: isLoadingProducts
                  ? Center(child: CircularProgressIndicator())
                  : (produkList.isNotEmpty
                      ? ListView.builder(
                          itemCount: produkList.length,
                          itemBuilder: (context, index) {
                            final produk = produkList[index];
                            int productId = produk['ProdukID'] ?? 0;
                            int harga = produk['Harga'] ?? 0;
                            return ListTile(
                              leading: Checkbox(
                                value: productSelected[productId] ?? false,
                                onChanged: (bool? isSelected) {
                                  updateProductSelection(
                                      productId, isSelected!);
                                },
                              ),
                              title: Text(produk['NamaProduk'] ?? ''),
                              subtitle: Text(formatCurrency.format(harga)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.remove),
                                    onPressed: productQuantity[productId]! > 0
                                        ? () =>
                                            updateProductQuantity(productId, -1)
                                        : null,
                                  ),
                                  Text('${productQuantity[productId] ?? 0}'),
                                  IconButton(
                                    icon: Icon(Icons.add),
                                    onPressed: () =>
                                        updateProductQuantity(productId, 1),
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                      : Center(child: Text('Tidak ada produk'))),
            ),
            // Tombol Pesan Sekarang
            ElevatedButton(
              onPressed: saveOrder,
              child: Text('Pesan Sekarang'),
            ),
          ],
        ),
      ),
    );
  }
}
