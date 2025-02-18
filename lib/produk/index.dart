import 'package:flutter/material.dart';
import 'package:ukk_2025/produk/insert.dart';
import 'package:ukk_2025/produk/update.dart';
import 'package:ukk_2025/homepage.dart';
import 'package:ukk_2025/produk/beliproduk.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class IndexProduk extends StatefulWidget {
  final bool showFAB;

  const IndexProduk({Key? key, this.showFAB = true}) : super(key: key);

  @override
  _IndexProdukState createState() => _IndexProdukState();
}

class _IndexProdukState extends State<IndexProduk> {
  List<Map<String, dynamic>> produk = [];
  List<Map<String, dynamic>> filteredProduk = [];
  TextEditingController searchController = TextEditingController();
  TextEditingController minPriceController = TextEditingController();
  TextEditingController maxPriceController = TextEditingController();
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    fetchProduk();
  }

  // Fungsi untuk mengambil produk dari Supabase
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

  // Fungsi untuk menghapus produk
  Future<void> deleteProduk(int ProdukID) async {
    try {
      print('Menghapusproduk dengan ID: $ProdukID');

      await Supabase.instance.client
          .from('produk')
          .delete()
          .eq('ProdukID', ProdukID);

      print('Produk berhasil dihapus.');

      setState(() {
        produk.removeWhere((item) => item['ProdukID'] == ProdukID);
        filteredProduk = List.from(produk);
      });
    } catch (e) {
      print('Error menghapus produk: $e');
    }
  }

  void filterSearch(String value) {
    double? minPrice = double.tryParse(minPriceController.text);
    double? maxPrice = double.tryParse(maxPriceController.text);

    setState(() {
      filteredProduk = produk.where((item) {
        bool matchesName = item['NamaProduk']
            .toString()
            .toLowerCase()
            .contains(value.toLowerCase());
        bool matchesPrice = true;

        if (minPrice != null && item['Harga'] < minPrice) {
          matchesPrice = false;
        }
        if (maxPrice != null && item['Harga'] > maxPrice) {
          matchesPrice = false;
        }

        return matchesName && matchesPrice;
      }).toList();
    });
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
        title: const Text(
          'Beranda Produk',
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
                  minPriceController.clear();
                  maxPriceController.clear();
                  filteredProduk = produk;
                }
              });
            },
          ),
        ],
        bottom: isSearching
            ? PreferredSize(
                preferredSize: Size.fromHeight(100.0),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: searchController,
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
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: minPriceController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Harga Min',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onChanged: (value) =>
                                  filterSearch(searchController.text),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: maxPriceController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Harga Max',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onChanged: (value) =>
                                  filterSearch(searchController.text),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            : null,
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
                  final langgan = filteredProduk[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => harga(produk: langgan)),
                      );
                    },
                    child: Container(
                      width: 160,
                      height: 200,
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                langgan['NamaProduk'] ??
                                    'Produk tidak tersedia',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Harga: ${langgan['Harga'] ?? 'Tidak tersedia'}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.brown,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Stok: ${langgan['Stok'] ?? 'Tidak tersedia'}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const Spacer(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (widget.showFAB)
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.brown),
                                      onPressed: () {
                                        final ProdukID =
                                            langgan['ProdukID'] ?? 0;
                                        if (ProdukID != 0) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  UpdateProduk(
                                                      ProdukID: ProdukID),
                                            ),
                                          );
                                        } else {
                                          print('ID produk tidak valid');
                                        }
                                      },
                                    ),
                                  if (widget.showFAB)
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Color(0xFF8D6E63)),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: const Text('Hapus Produk'),
                                              content: const Text(
                                                  'Apakah Anda yakin ingin menghapus produk ini?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: const Text('Batal'),
                                                ),
                                                TextButton(
                                                  onPressed: () async {
                                                    await deleteProduk(
                                                        langgan['ProdukID']);
                                                    Navigator.pop(context);
                                                  },
                                                  child: const Text(
                                                    'Hapus',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  style: TextButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.brown[800],
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: widget.showFAB
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => InsertProduk()));
              },
              backgroundColor: Colors.brown[800],
              child: const Icon(
                Icons.add,
                color: Colors.white,
              ),
            )
          : null,
    );
  }
}
