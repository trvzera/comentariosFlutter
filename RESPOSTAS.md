# Questões

1. O Firebase Authentication identifica a conta pelo UID. Ao gravar um comentário,
   o app salva currentUser.uid; as regras conferem se ele corresponde a request.auth.uid.

2. Cada comentário fica na subcoleção publicacoes/{id}/comentarios e também guarda
   publicacaoId. Assim cada discussão consulta somente os comentários daquela publicação.

3. StreamBuilder acompanha o stream de snapshots do Firestore e reconstrói a lista
   quando chegam alterações, sem exigir atualização manual da página.

4. Todas as contas usam o mesmo projeto Firebase e escutam a mesma subcoleção
   com snapshots(). Quando um comentário é salvo, o Firestore envia a alteração
   aos usuários conectados que estão acompanhando a discussão.
