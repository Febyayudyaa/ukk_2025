import 'package:flutter/material.dart';
import 'package:ukk_2025/produk/insert.dart';
import 'package:ukk_2025/produk/beliproduk.dart';
import 'package:ukk_2025/produk/update.dart';
import 'package:ukk_2025/homepage.dart';
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

  void filterSearch(String query) {
    setState(() {
      filteredProduk = produk
          .where((item) =>
              item['NamaProduk'].toLowerCase().contains(query.toLowerCase()))
          .toList();
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
          'Menu Produk',
          style: TextStyle(color: Colors.white),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(50.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Cari...',
                filled: true,
                fillColor: Colors.white,
                prefixIcon: Icon(Icons.search, color: Colors.brown),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => filterSearch(value),
            ),
          ),
        ),
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
                            builder: (context) => Beliproduk(produk: langgan)),
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
