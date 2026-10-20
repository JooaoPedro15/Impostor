import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../estilo.dart';
import '../widgets/comuns.dart';
import '../widgets/disquete.dart';
import 'preparacao.dart';
import 'temas.dart';

class TelaInicio extends StatelessWidget {
  const TelaInicio({super.key});

  @override
  Widget build(BuildContext context) {
    final larguraTela = MediaQuery.sizeOf(context).width.clamp(320.0, 480.0);
    return Tela(
      voltar: false,
      corpo: [
        const SizedBox(height: 20),
        Semantics(
          header: true,
          // FittedBox: diminui o texto até caber numa linha, sem quebrar a palavra.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Impostor',
              maxLines: 1,
              style: anybody(tamanho: larguraTela * 0.19, peso: 900, largura: 150, altura: 0.95),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Edição Ciência da Computação\nPUC Minas, 40 anos',
          textAlign: TextAlign.center,
          style: anybody(peso: 600, cor: Cores.texto2),
        ),
        const SizedBox(height: 28),
        Transform.rotate(
          angle: -4 * math.pi / 180,
          child: Disquete(
            cor: Cores.amarelo,
            etiqueta: 'Quem está fingindo?',
            modo: ModoTampa.espiar,
            conteudo: Text('?', style: anybody(tamanho: 80, peso: 900, largura: 150, cor: Cores.amarelo, altura: 1)),
          ),
        ),
      ],
      rodape: [
        BotaoTecla('Novo jogo', aoTocar: () => abrir(context, const TelaJogadores(), nome: TelaJogadores.rota)),
        // IntrinsicHeight + stretch: os dois botões ficam com a altura do maior.
        IntrinsicHeight(
          child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: BotaoTecla(
                'Meus temas',
                tipo: TipoBotao.secundario,
                aoTocar: () => abrir(context, const TelaMeusTemas()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: BotaoTecla(
                'Como jogar',
                tipo: TipoBotao.secundario,
                aoTocar: () => abrir(context, const TelaRegras()),
              ),
            ),
          ],
          ),
        ),
      ],
    );
  }
}

class TelaRegras extends StatelessWidget {
  const TelaRegras({super.key});

  static const _passos = [
    'Juntem 3 ou mais pessoas e escrevam os nomes, na ordem em que o celular vai passar.',
    'Escolham os temas. A palavra secreta sai de um deles.',
    'Passem o celular. Cada um arrasta a tampa do disquete escondido: quase todos veem a palavra secreta, o impostor não.',
    'Na ordem, cada um diz uma palavra ou frase sobre o segredo. Nem muito óbvio (o impostor descobre), nem muito vago (vira suspeito).',
    'Votem em quem está fingindo. Se pegarem o impostor, ele ainda pode roubar a vitória adivinhando a palavra.',
  ];

  static const _opcoes = [
    ('Dicas para o impostor', 'O impostor vê o tema e uma pista vaga, para conseguir blefar.'),
    ('Rodada surpresa', 'Em algumas rodadas, todo mundo é impostor. Em outras, ninguém é. Desconfiem de tudo.'),
    ('Temas próprios', 'Em Meus temas, criem listas com o que quiserem: matérias, professores, piadas da turma.'),
  ];

  @override
  Widget build(BuildContext context) => Tela(
    titulo: 'Como jogar',
    corpo: [
      // Os passos são uma sequência de verdade, então a numeração faz sentido.
      for (final (i, passo) in _passos.indexed)
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 30,
                child: Text('${i + 1}.', style: anybody(peso: 800, cor: Cores.amarelo)),
              ),
              Expanded(child: Text(passo, style: anybody())),
            ],
          ),
        ),
      const Secao('Opções'),
      for (final (titulo, texto) in _opcoes)
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: anybody(peso: 750)),
              const SizedBox(height: 2),
              Text(texto, style: anybody(cor: Cores.texto2)),
            ],
          ),
        ),
    ],
  );
}
