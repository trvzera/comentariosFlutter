import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'comentario.dart';

class ComentariosService {
  final DocumentReference<Map<String, dynamic>> publicacao;
  ComentariosService(this.publicacao);

  CollectionReference<Map<String, dynamic>> get _comentarios =>
      publicacao.collection('comentarios');

  Stream<List<Comentario>> acompanhar() => _comentarios
      .orderBy('criadoEm')
      .snapshots(includeMetadataChanges: true)
      .map((s) => s.docs.map(Comentario.fromDocument).toList());

  Future<void> enviar(String texto) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Entre na sua conta para comentar.');
    final conteudo = texto.trim();
    if (conteudo.isEmpty || conteudo.length > 1000) {
      throw ArgumentError('Escreva um comentário de 1 a 1000 caracteres.');
    }
    final nome = user.displayName?.trim();
    await _comentarios.add({
      'texto': conteudo,
      'nome': nome == null || nome.isEmpty ? 'Usuário' : nome,
      'uid': user.uid,
      'publicacaoId': publicacao.id,
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }

  Future<void> excluir(Comentario comentario) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || comentario.uid != user.uid) {
      throw StateError('Você só pode excluir seus próprios comentários.');
    }
    await _comentarios.doc(comentario.id).delete();
  }
}
