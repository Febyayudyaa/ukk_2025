import 'package:flutter/material.dart';
//import 'package:ukk_2025/penjualan/insert';
import 'package:ukk_2025/produk/insert.dart'; 
import 'package:ukk_2025/produk/update.dart';
import 'package:ukk_2025/homepage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ukk_2025/produk/harga.dart';
import 'package:intl/intl.dart';

class IndexProduk extends StatefulWidget {
  final bool showFAB;

  const IndexProduk({Key? key, this.showFAB = true}) : super(key: key);

  @override
  _IndexProdukState createState() => _IndexProdukState();
}

class _IndexProdukState extends State<IndexProduk> {
  List<Map<String, dynamic>> produk = [];
  List<Map<String, dynamic>> filteredProduk = [];
  List<Map<String, dynamic>> keranjang = [];
  TextEditingController searchController = TextEditingController();
  bool isSearching = false;
  TextEditingController jumlahController = TextEditingController();
  final formatCurrency =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    fetchProduk();
  }

  Future<void> fetchProduk() async {
    try {
      final response = await Supabase.instance.client.from('produk').select();
      setState(() {
        produk = List<Map<String, dynamic>>.from(response);
        filteredProduk = produk;
      });
    } catch (e) {
      print('Error fetching produk: $e');
    }
  }

  void addToKeranjang(Map<String, dynamic> produk, int quantity) {
    setState(() {
      keranjang.add({
        'ProdukID': produk['ProdukID'],
        'NamaProduk': produk['NamaProduk'],
        'Harga': produk['Harga'],
        'Jumlah': quantity,
        'Subtotal': produk['Harga'] * quantity,
      });
    });
  }

  void filterSearch(String query) {
    setState(() {
      filteredProduk = produk
          .where((item) =>
              item['NamaProduk'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> deleteProduk(int produkID) async {
    try {
      await Supabase.instance.client
          .from('produk')
          .delete()
          .eq('ProdukID', produkID);

      setState(() {
        produk.removeWhere((item) => item['ProdukID'] == produkID);
        filteredProduk = List.from(produk);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produk berhasil dihapus!'),
          backgroundColor: Colors.brown,
        ),
      );
    } catch (e) {
      print('Error menghapus produk: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus produk: $e'),
          backgroundColor: Colors.brown,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
        title: isSearching
            ? TextField(
                controller: searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Cari Produk...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) => filterSearch(value),
              )
            : const Text(
                'Daftar Produk',
                style: TextStyle(color: Colors.white),
              ),
        actions: [
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search,
                color: Colors.white),
            onPressed: () {
              setState(() {
                isSearching = !isSearching;
                if (!isSearching) {
                  searchController.clear();
                  filteredProduk = produk;
                }
              });
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.white,
        child: filteredProduk.isEmpty
            ? const Center(
                child: Text(
                  'Tidak ada produk',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              )
            : GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1 / 1,
                ),
                itemCount: filteredProduk.length,
                itemBuilder: (context, index) {
                  final produkItem = filteredProduk[index];
                  return SizedBox(
                    width: 140, // Lebar Card diperkecil
                    child: Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8), 
                        child: Column(
                          mainAxisSize:
                              MainAxisSize.min, 
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              produkItem['NamaProduk'] ??
                                  'Produk tidak tersedia',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14, // Font lebih kecil
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Rp ${NumberFormat.decimalPattern('id_ID').format(produkItem['Harga'])}',
                              style: const TextStyle(
                                fontSize: 12, // Font lebih kecil
                                color: Colors.brown,
                              ),
                            ),
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      size: 18, color: Colors.brown),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => UpdateProduk(
                                            ProdukID: produkItem['ProdukID']),
                                      ),
                                    ).then((value) {
                                      if (value == true) {
                                        fetchProduk();
                                      }
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      size: 18, color: Colors.brown),
                                  onPressed: () {
                                    deleteProduk(produkItem['ProdukID']);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.brown[800],
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  HargaProdukAdmin(),
            ),
          );
        },
        child: const Icon(Icons.attach_money,
            color: Colors.white), 
      ),
    );
  }
}
