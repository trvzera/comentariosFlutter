import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'comentario.dart';
import 'comentarios_service.dart';

class ComentariosPage extends StatefulWidget {
  final DocumentReference<Map<String, dynamic>> publicacaoRef;
  final Widget publicacaoWidget;

  const ComentariosPage({super.key, required this.publicacaoRef,
    required this.publicacaoWidget});

  @override
  State<ComentariosPage> createState() => _ComentariosPageState();
}

class _ComentariosPageState extends State<ComentariosPage> {
  final _texto = TextEditingController();
  final Set<String> _excluindo = {};
  late final ComentariosService _service;
  late final Stream<List<Comentario>> _stream;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _service = ComentariosService(widget.publicacaoRef);
    _stream = _service.acompanhar();
  }

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  void _erro(Object erro) {
    if (!mounted) return;
    final mensagem = erro is FirebaseException
      ? 'Não foi possível concluir (${erro.code}). Confira a conexão e as regras do Firestore.'
      : erro.toString();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  Future<void> _enviar() async {
    if (_enviando || _texto.text.trim().isEmpty) return;
    setState(() => _enviando = true);
    try {
      await _service.enviar(_texto.text);
      if (mounted) _texto.clear();
    } catch (e) {
      _erro(e);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _excluir(Comentario comentario) async {
    final confirmar = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Excluir seu comentário?'),
      content: const Text('O comentário será removido para todas as contas.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir')),
      ],
    ));
    if (confirmar != true || !mounted || _excluindo.contains(comentario.id)) return;
    setState(() => _excluindo.add(comentario.id));
    try {
      await _service.excluir(comentario);
    } catch (e) {
      _erro(e);
    } finally {
      if (mounted) setState(() => _excluindo.remove(comentario.id));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Comentários')),
    body: SafeArea(child: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 800),
      child: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        initialData: FirebaseAuth.instance.currentUser,
        builder: (context, auth) {
          final user = auth.data;
          if (user == null) {
            return const Center(child: Text('Entre na sua conta para abrir os comentários.'));
          }
          return Column(children: [
            Expanded(child: StreamBuilder<List<Comentario>>(
              stream: _stream,
              builder: (context, snapshot) => ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  widget.publicacaoWidget,
                  const Divider(height: 32),
                  Text('Comentários', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  if (snapshot.hasError)
                    const Padding(padding: EdgeInsets.all(16), child: Text(
                      'Erro ao carregar comentários. Confira a conexão e as regras de acesso.'))
                  else if (!snapshot.hasData)
                    const Center(child: CircularProgressIndicator())
                  else if (snapshot.data!.isEmpty)
                    const Padding(padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text('Nenhum comentário. Seja o primeiro a comentar!'))
                  else
                    for (final c in snapshot.data!)
                      Card(child: Padding(padding: const EdgeInsets.all(12), child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CircleAvatar(child: Icon(Icons.person_outline)),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(c.texto),
                              if (c.pendente) const Text('Enviando...', style: TextStyle(fontSize: 12)),
                            ],
                          )),
                          if (c.uid == user.uid)
                            IconButton(
                              tooltip: 'Excluir meu comentário',
                              onPressed: c.pendente || _excluindo.contains(c.id) ? null : () => _excluir(c),
                              icon: const Icon(Icons.delete_outline),
                            ),
                        ],
                      ))),
                ],
              ),
            )),
            const Divider(height: 1),
            Padding(padding: const EdgeInsets.all(12), child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: TextField(
                  controller: _texto,
                  enabled: !_enviando,
                  minLines: 1, maxLines: 4, maxLength: 1000,
                  decoration: const InputDecoration(
                    labelText: 'Seu comentário', border: OutlineInputBorder()),
                )),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: 'Enviar comentário',
                  onPressed: _enviando ? null : _enviar,
                  icon: _enviando
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send),
                ),
              ],
            )),
          ]);
        },
      ),
    ))),
  );
}
