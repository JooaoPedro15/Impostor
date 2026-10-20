import 'package:flutter/material.dart';

import 'src/logica/armazenamento.dart';
import 'src/logica/jogo.dart';
import 'src/ui/estilo.dart';
import 'src/ui/telas/inicio.dart';

Future<void> main() async {
  // Necessário para usar plugins (shared_preferences) antes do runApp.
  WidgetsFlutterBinding.ensureInitialized();
  final jogo = Jogo(await Armazenamento.abrir())..carregar();
  runApp(ImpostorApp(jogo: jogo));
}

class ImpostorApp extends StatelessWidget {
  const ImpostorApp({super.key, required this.jogo});

  final Jogo jogo;

  @override
  Widget build(BuildContext context) => JogoScope(
    notifier: jogo,
    child: MaterialApp(
      title: 'Impostor CC',
      debugShowCheckedModeBanner: false,
      theme: temaDoApp(),
      home: const TelaInicio(),
    ),
  );
}
