import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:ukk_2025/user/index.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UpdateUser extends StatefulWidget {
  final int id;

  const UpdateUser({super.key, required this.id});

  @override
  State<UpdateUser> createState() => _UpdateUserState();
}

class _UpdateUserState extends State<UpdateUser> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _role = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _oldPasswordHash;
  String? _oldSalt;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  /// Fungsi untuk menghasilkan salt
  String generateSalt() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    return base64UrlEncode(values);
  }

  /// Fungsi untuk mengenkripsi password dengan salt
  String hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _loadUser() async {
    try {
      final data = await Supabase.instance.client
          .from('user')
          .select()
          .eq('id', widget.id)
          .maybeSingle();

      if (data == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User tidak ditemukan')));
        Navigator.pop(context);
        return;
      }

      setState(() {
        _username.text = data['username'] ?? '';
        _role.text = data['role'] ?? '';
        _oldPasswordHash = data['password'];
        _oldSalt = data['salt'];
      });
    } catch (e) {
      print('Error loading user: $e');
    }
  }

  Future<void> updateUser() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      String newSalt = generateSalt();
      String hashedPassword = _password.text.isNotEmpty
          ? hashPassword(_password.text, newSalt)
          : _oldPasswordHash!;
      String saltToSave = _password.text.isNotEmpty ? newSalt : _oldSalt!;

      await Supabase.instance.client.from('user').update({
        'username': _username.text,
        'password': hashedPassword,
        'salt': saltToSave,
        'role': _role.text,
      }).eq('id', widget.id);

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data berhasil diperbarui')));
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const IndexUser()));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit User', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.brown[800],
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(
                context, MaterialPageRoute(builder: (context) => IndexUser()));
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(color: Colors.white),
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _username,
                decoration: const InputDecoration(
                  labelText: 'username',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Username tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _password,
                decoration: const InputDecoration(
                  labelText: 'password',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  return null; // Password boleh kosong jika tidak ingin diubah
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _role,
                decoration: const InputDecoration(
                  labelText: 'role',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Role tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: updateUser,
                    child: Text(
                      'Update',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.brown[800],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
