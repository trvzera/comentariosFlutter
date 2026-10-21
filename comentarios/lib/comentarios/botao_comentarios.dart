import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'comentarios_page.dart';

/// Acrescente este widget às ações do card de publicação já existente.
/// Passe a referência REAL do documento e o widget que apresenta a publicação.
class BotaoComentarios extends StatelessWidget {
  final DocumentReference<Map<String, dynamic>> publicacaoRef;
  final Widget publicacaoWidget;

  const BotaoComentarios({super.key, required this.publicacaoRef,
    required this.publicacaoWidget});

  @override
  Widget build(BuildContext context) => TextButton.icon(
    icon: const Icon(Icons.chat_bubble_outline),
    label: const Text('Comentários'),
    onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => ComentariosPage(
        publicacaoRef: publicacaoRef,
        publicacaoWidget: publicacaoWidget,
      ),
    )),
  );
}
