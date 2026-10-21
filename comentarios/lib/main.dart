import 'package:device_preview/device_preview.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'pages/login_page.dart';
import 'pages/feed_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    runApp(DevicePreview(enabled: !kReleaseMode, builder: (_) => const MeuApp()));
  } catch (e) {
    runApp(MaterialApp(home: Scaffold(body: Center(child: Padding(
      padding: const EdgeInsets.all(24),
      child: SelectableText('Configure o Firebase conforme o LEIA-ME e reinicie o app.\n\n$e'),
    )))));
  }
}

class MeuApp extends StatelessWidget {
  const MeuApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Conecta', debugShowCheckedModeBanner: false,
    locale: DevicePreview.locale(context), builder: DevicePreview.appBuilder,
    theme: ThemeData(useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4654C0)),
      inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder())),
    home: StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return snapshot.data == null ? const LoginPage() : FeedPage(key: ValueKey(snapshot.data!.uid));
      },
    ),
  );
}
