import 'package:cloud_firestore/cloud_firestore.dart';

class Comentario {
  final String id;
  final String texto;
  final String nome;
  final String uid;
  final String publicacaoId;
  final DateTime? criadoEm;
  final bool pendente;

  const Comentario({required this.id, required this.texto, required this.nome,
    required this.uid, required this.publicacaoId, required this.criadoEm,
    required this.pendente});

  factory Comentario.fromDocument(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    return Comentario(
      id: doc.id,
      texto: d['texto'] as String,
      nome: d['nome'] as String,
      uid: d['uid'] as String,
      publicacaoId: d['publicacaoId'] as String,
      criadoEm: (d['criadoEm'] as Timestamp?)?.toDate(),
      pendente: doc.metadata.hasPendingWrites,
    );
  }
}
