import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../comentarios/botao_comentarios.dart';
import 'perfil_page.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});
  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final _texto = TextEditingController();
  late final _publicacoes = FirebaseFirestore.instance.collection('publicacoes')
    .orderBy('criadoEm', descending: true).snapshots(includeMetadataChanges: true);
  bool _enviando = false;
  @override
  void dispose() { _texto.dispose(); super.dispose(); }

  Future<void> _publicar() async {
    if (_enviando || _texto.text.trim().isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final nome = user.displayName?.trim();
    if (nome == null || nome.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Defina seu nome no perfil antes de publicar.')));
      return;
    }
    setState(() => _enviando = true);
    try {
      await FirebaseFirestore.instance.collection('publicacoes').add({
        'texto': _texto.text.trim(), 'nome': nome, 'uid': user.uid,
        'criadoEm': FieldValue.serverTimestamp(),
      });
      if (mounted) _texto.clear();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Erro ao publicar. Confira sua conexão e as regras do Firestore.')));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Widget _conteudo(Map<String, dynamic> d) => Card(child: Padding(
    padding: const EdgeInsets.all(16), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(d['nome'] as String? ?? 'Usuário', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10), Text(d['texto'] as String? ?? ''),
      ],
    ),
  ));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Conecta • Publicações'), actions: [
      IconButton(tooltip: 'Meu perfil', icon: const Icon(Icons.account_circle_outlined),
        onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const PerfilPage()))),
      IconButton(tooltip: 'Sair', icon: const Icon(Icons.logout), onPressed: () async {
        try { await FirebaseAuth.instance.signOut(); }
        catch (_) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível sair.')));
        }
      }),
    ]),
    body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 800),
      child: Column(children: [
        Padding(padding: const EdgeInsets.all(16), child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TextField(controller: _texto, enabled: !_enviando, minLines: 2, maxLines: 4, maxLength: 2000,
              decoration: const InputDecoration(labelText: 'O que você quer compartilhar?')),
            FilledButton.icon(onPressed: _enviando ? null : _publicar,
              icon: const Icon(Icons.send), label: Text(_enviando ? 'Publicando...' : 'Publicar')),
          ],
        )),
        Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _publicacoes,
          builder: (context, snapshot) {
            if (snapshot.hasError) return const Center(child: Text('Erro ao carregar publicações. Confira as regras do Firebase.'));
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snapshot.data!.docs;
            if (docs.isEmpty) return const Center(child: Text('Nenhuma publicação. Publique a primeira!'));
            return ListView.builder(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: docs.length, itemBuilder: (context, index) {
                final doc = docs[index];
                return Padding(padding: const EdgeInsets.only(bottom: 12), child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(width: double.infinity, child: _conteudo(doc.data())),
                    if (doc.metadata.hasPendingWrites) const Text('Enviando publicação...')
                    else BotaoComentarios(publicacaoRef: doc.reference,
                      publicacaoWidget: _conteudo(doc.data())),
                  ],
                ));
              },
            );
          },
        )),
      ]),
    )),
  );
}
