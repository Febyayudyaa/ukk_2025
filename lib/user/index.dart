import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ukk_2025/user/update.dart';
import 'package:ukk_2025/user/insert.dart';
import 'package:ukk_2025/homepage.dart';
import 'package:ukk_2025/main.dart';

class IndexUser extends StatefulWidget {
  const IndexUser({super.key});

  @override
  State<IndexUser> createState() => _IndexUserState();
}

class _IndexUserState extends State<IndexUser> {
  List<Map<String, dynamic>> user = [];

  @override
  void initState() {
    super.initState();
    fetchUser();
  }

  Future<void> fetchUser() async {
    try {
      final response = await Supabase.instance.client.from('user').select();
      setState(() {
        user = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print('Error fetching user: $e');
    }
  }

  Future<void> deleteUserfetchUser(int id) async {
    try {
      await Supabase.instance.client.from('user').delete().eq('id', id);
      fetchUser();
    } catch (e) {
      print('Error menghapus user: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.brown[800],
        title: Text('Data User', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          color: Colors.white,
          onPressed: () {
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => HomePage()));
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(color: Colors.white),
        child: user.isEmpty
            ? const Center(
                child: Text(
                  'Tidak ada user',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: user.length,
                itemBuilder: (context, index) {
                  final langgan = user[index];
                  return SizedBox(
                    height: 145,
                    child: Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                       shape: RoundedRectangleBorder(
                           borderRadius: BorderRadius.circular(12)),
                       child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                const SizedBox(height: 5),
                                  Text(
                                    langgan['username'] ??
                                     'Username tidak tersedia',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(

                                    langgan['password'] ??
                                        'Password Tidak tersedia',
                                    style: const TextStyle(
                                      fontStyle: FontStyle.italic,
                                      fontSize: 15,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    langgan['role'] ?? 'Tidak tersedia',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.justify,
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.brown, size: 28),
                                      onPressed: () {
                                        final userId = langgan['id'] ?? 0;
                                        if (userId != 0) {
                                             Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                            builder: (context) =>
                                            (id: userId),
                                            ),
                                            );
                                        } else {
                                          print('ID user tidak valid');
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.brown, size: 28),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: const Text('Hapus User'),
                                              content: const Text(
                                                  'Apakah Anda yakin ingin menghapus user ini?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: const Text('Batal'),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    final userid =
                                                        langgan['id'];
                                                    if (userid != null) {
                                                      deleteUserfetchUser(
                                                          userid);
                                                    }
                                                    Navigator.pop(context);
                                                  },
                                                  child: const Text('Hapus'),
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
                          ],
                          ),
                        ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
           Navigator.push(
            context, MaterialPageRoute(builder: (context) => InsertUsr()));
        },
        backgroundColor: Colors.brown[800],
        child: const Icon(
          Icons.add,
          color: Colors.white,
         ),
      ),
      );
  }
}
