import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _cadastro = false;
  bool _ocupado = false;
  String? _erro;

  @override
  void dispose() {
    _nome.dispose(); _email.dispose(); _senha.dispose(); super.dispose();
  }

  Future<void> _enviar() async {
    if (!_form.currentState!.validate() || _ocupado) return;
    final nome = _nome.text.trim();
    final email = _email.text.trim();
    final senha = _senha.text;
    setState(() { _ocupado = true; _erro = null; });
    try {
      final auth = FirebaseAuth.instance;
      if (_cadastro) {
        final conta = await auth.createUserWithEmailAndPassword(
          email: email, password: senha);
        await conta.user!.updateDisplayName(nome);
      } else {
        await auth.signInWithEmailAndPassword(email: email, password: senha);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _erro = switch (e.code) {
        'email-already-in-use' => 'Este e-mail já está cadastrado. Entre na sua conta.',
        'invalid-credential' || 'wrong-password' || 'user-not-found' => 'E-mail ou senha incorretos.',
        'operation-not-allowed' => 'Habilite E-mail/senha no Authentication do Firebase.',
        'weak-password' => 'Escolha uma senha com pelo menos 6 caracteres.',
        _ => 'Não foi possível entrar: ${e.code}.',
      });
    } catch (_) {
      if (mounted) setState(() => _erro = 'Não foi possível concluir. Confira sua conexão.');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: SingleChildScrollView(
    padding: const EdgeInsets.all(24), child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420), child: Form(key: _form,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.forum_outlined, size: 64), const SizedBox(height: 16),
            Text(_cadastro ? 'Criar conta' : 'Conecta', textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 24),
            if (_cadastro) ...[
              TextFormField(controller: _nome, enabled: !_ocupado, maxLength: 80,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Informe seu nome.' : null),
              const SizedBox(height: 12),
            ],
            TextFormField(controller: _email, enabled: !_ocupado,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'E-mail'),
              validator: (v) => v == null || !v.contains('@') ? 'Informe um e-mail válido.' : null),
            const SizedBox(height: 16),
            TextFormField(controller: _senha, enabled: !_ocupado, obscureText: true,
              decoration: const InputDecoration(labelText: 'Senha'),
              validator: (v) => v == null || v.length < 6 ? 'Use pelo menos 6 caracteres.' : null),
            const SizedBox(height: 16),
            if (_erro != null) Padding(padding: const EdgeInsets.only(bottom: 12),
              child: Text(_erro!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
            FilledButton(onPressed: _ocupado ? null : _enviar,
              child: Text(_ocupado ? 'Aguarde...' : _cadastro ? 'Cadastrar' : 'Entrar')),
            TextButton(onPressed: _ocupado ? null : () => setState(() {
              _cadastro = !_cadastro; _erro = null;
            }), child: Text(_cadastro ? 'Já tenho conta' : 'Criar uma conta')),
          ],
        ),
      ),
    ),
  )));
}
