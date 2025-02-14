import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ukk_2025/user/index.dart';

class InsertUser extends StatefulWidget {
  const InsertUser({super.key});

  @override
  State<InsertUser> createState() => _InsertUserState();
}

class _InsertUserState extends State<InsertUser> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
   String? _selectedRole;

  final SupabaseClient supabase = Supabase.instance.client;

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;

    final username = _usernameController.text;
     final password = _passwordController.text;
    final role = _selectedRole;

    try {
      final response = await supabase.from('user').insert({
        'username': username,
        'password':  password, 
        'role': role,
      }).select();

      if (response != null && response.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar( content: Text('Data berhasil disimpan!')),
        );
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const IndexUser()));
      } else {
        throw Exception('Gagal menyimpan data.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
       );
    }
  }

  @override
  Widget build (BuildContext context) {
    return Scaffold(
      appBar: AppBar (
        title: const Text('Tambah Data User', style: TextStyle(color: Colors.white)),
        elevation: 0,
        backgroundColor: Colors.brown[800],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () { Navigator.pop(context );},
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        padding: const EdgeInsets.all(16.0 ),
        child: Form(
          key: _formKey,
          child: Column( crossAxisAlignment: CrossAxisAlignment.start,
            children: [ TextFormField (
                controller: _usernameController,
                decoration: const InputDecoration( labelText: 'username',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Username tidak boleh kosong'
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField( controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'password',
                    border: OutlineInputBorder(),
                ),
                 obscureText: true,
                validator: (value) => value == null || value.isEmpty
                     ? 'Password tidak boleh kosong'
                    : null,
              ),
               const SizedBox(height: 10),
                 DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'role',
                  border: OutlineInputBorder(),
                ),
                items: ['Admin', 'Petugas', 'Pembeli']
                    .map((role) => DropdownMenuItem(value: role, child: Text(role)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedRole = value),
                validator: (value) => value == null || value.isEmpty
                    ? 'Role tidak boleh kosong'
                    : null,
              ),
              const SizedBox(height: 20),
             ElevatedButton(
                onPressed: _saveData,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  width: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: Colors.brown[800],
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text('SIMPAN',style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                   ),
              ),
               ],
          ),
         ),
       ),
    );
   }
}