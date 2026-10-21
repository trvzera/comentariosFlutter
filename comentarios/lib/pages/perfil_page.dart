import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});
  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  final _nome = TextEditingController(text: FirebaseAuth.instance.currentUser?.displayName ?? '');
  bool _salvando = false;
  @override
  void dispose() { _nome.dispose(); super.dispose(); }

  Future<void> _salvar() async {
    if (_salvando || _nome.text.trim().isEmpty) return;
    setState(() => _salvando = true);
    try {
      await FirebaseAuth.instance.currentUser!.updateDisplayName(_nome.text.trim());
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível salvar o perfil.')));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Meu perfil')),
    body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 500),
      child: ListView(padding: const EdgeInsets.all(24), children: [
        const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
        const SizedBox(height: 24),
        Text(FirebaseAuth.instance.currentUser?.email ?? ''), const SizedBox(height: 16),
        TextField(controller: _nome, maxLength: 80, enabled: !_salvando,
          decoration: const InputDecoration(labelText: 'Nome')),
        const SizedBox(height: 16),
        FilledButton(onPressed: _salvando ? null : _salvar,
          child: Text(_salvando ? 'Salvando...' : 'Salvar perfil')),
      ]),
    )),
  );
}
