// Regras do jogo, em Dart puro (sem Flutter): dá para testar com `flutter test`.

import 'dart:math';

import '../modelos/tema.dart';

const minJogadores = 3;
const maxJogadores = 20;

/// Chance de uma rodada virar surpresa quando a opção está ligada.
const chanceSurpresa = 0.15;

/// Rodada surpresa: todo mundo é impostor, ou ninguém é.
enum Surpresa { todosImpostores, ninguemImpostor }

/// Como a rodada terminou. A tela de resultado escolhe o texto a partir disso.
enum FimDeJogo {
  jogadoresVenceram,
  impostorAdivinhou,
  impostorEscapou,
  ninguemErrado,
  ninguemCerto,
  ninguemAcusou,
  todosImpostores;

  bool get jogadoresGanharam => this == jogadoresVenceram || this == ninguemCerto;
}

/// Máximo de impostores: sempre menos da metade da mesa.
int maxImpostores(int jogadores) => max(1, (jogadores - 1) ~/ 2);

int impostoresRecomendados(int jogadores) {
  final sugestao = jogadores >= 11
      ? 3
      : jogadores >= 7
      ? 2
      : 1;
  return min(sugestao, maxImpostores(jogadores));
}

/// Fisher–Yates: embaralha em O(n) e cada ordem tem a mesma chance.
/// Recebe o [Random] de fora para os testes poderem usar uma semente fixa.
List<T> embaralhar<T>(List<T> lista, Random rng) {
  final a = [...lista];
  for (var i = a.length - 1; i > 0; i--) {
    final j = rng.nextInt(i + 1);
    // (a[i], a[j]) = (a[j], a[i]) não compila: o destructuring do Dart
    // só aceita variáveis, não posições de lista. Troca clássica:
    final temp = a[i];
    a[i] = a[j];
    a[j] = temp;
  }
  return a;
}

class Rodada {
  Rodada({
    required this.palavra,
    required this.tema,
    required this.impostores,
    required this.quemComeca,
    this.surpresa,
  });

  final Palavra palavra;
  final Tema tema;

  /// Índices de quem é impostor. Set: "fulano é impostor?" em O(1).
  final Set<int> impostores;
  final int quemComeca;
  final Surpresa? surpresa;

  // Estado que muda durante a rodada:
  int vez = 0;
  bool visto = false;
  final List<int> acusados = [];
  FimDeJogo? fim;
  int? culpado;

  bool ehImpostor(int jogador) => impostores.contains(jogador);
}

/// Sorteia palavra e impostores.
///
/// Devolve um *record* com a rodada e o histórico atualizado de palavras já
/// usadas, para não repetir palavra entre rodadas. Função pura: não altera
/// [vistas]; quem chama decide o que fazer com o novo histórico.
(Rodada, Map<String, Set<String>>) sortearRodada({
  required int jogadores,
  required List<Tema> temas,
  required Map<String, Set<String>> vistas,
  required int impostores,
  required bool surpresaLigada,
  required Random rng,
}) {
  assert(jogadores >= minJogadores, 'precisa de pelo menos $minJogadores jogadores');
  final usaveis = temas.where((t) => t.palavras.isNotEmpty).toList();
  assert(usaveis.isNotEmpty, 'nenhum tema com palavras');

  final historico = {for (final e in vistas.entries) e.key: {...e.value}};

  List<(Tema, Palavra)> montarSaco() => [
    for (final t in usaveis)
      for (final p in t.palavras)
        if (!(historico[t.id]?.contains(p.texto) ?? false)) (t, p),
  ];

  var saco = montarSaco();
  if (saco.isEmpty) {
    // Todas as palavras desses temas já saíram: zera e recomeça.
    for (final t in usaveis) {
      historico.remove(t.id);
    }
    saco = montarSaco();
  }

  final (tema, palavra) = saco[rng.nextInt(saco.length)];
  historico.putIfAbsent(tema.id, () => <String>{}).add(palavra.texto);

  Surpresa? surpresa;
  if (surpresaLigada && rng.nextDouble() < chanceSurpresa) {
    surpresa = rng.nextBool() ? Surpresa.todosImpostores : Surpresa.ninguemImpostor;
  }

  final ordem = embaralhar(List.generate(jogadores, (i) => i), rng);
  final escolhidos = switch (surpresa) {
    Surpresa.todosImpostores => ordem.toSet(),
    Surpresa.ninguemImpostor => <int>{},
    null => ordem.take(impostores.clamp(1, maxImpostores(jogadores))).toSet(),
  };

  final rodada = Rodada(
    palavra: palavra,
    tema: tema,
    impostores: escolhidos,
    quemComeca: rng.nextInt(jogadores),
    surpresa: surpresa,
  );
  return (rodada, historico);
}

/// O que acontece depois de uma acusação.
/// `sealed`: o compilador sabe todos os casos e obriga o `switch` a tratar cada um.
sealed class ResultadoAcusacao {
  const ResultadoAcusacao();
}

/// Acertaram um impostor, mas ainda há outros escondidos.
class AindaFaltam extends ResultadoAcusacao {
  const AindaFaltam(this.quantos);
  final int quantos;
}

/// Pegaram todos: o impostor ainda pode roubar a vitória chutando a palavra.
class UltimaChance extends ResultadoAcusacao {
  const UltimaChance();
}

class Terminou extends ResultadoAcusacao {
  const Terminou(this.fim);
  final FimDeJogo fim;
}

ResultadoAcusacao acusar(Rodada r, int jogador) {
  r.acusados.add(jogador);

  if (r.surpresa == Surpresa.todosImpostores) {
    return _terminar(r, FimDeJogo.todosImpostores);
  }
  if (!r.ehImpostor(jogador)) {
    r.culpado = jogador;
    return _terminar(
      r,
      r.surpresa == Surpresa.ninguemImpostor ? FimDeJogo.ninguemAcusou : FimDeJogo.impostorEscapou,
    );
  }

  final faltam = r.impostores.where((i) => !r.acusados.contains(i)).length;
  return faltam == 0 ? const UltimaChance() : AindaFaltam(faltam);
}

/// O grupo aposta que não tem impostor nesta rodada.
Terminou apostarNinguem(Rodada r) => _terminar(r, switch (r.surpresa) {
  Surpresa.todosImpostores => FimDeJogo.todosImpostores,
  Surpresa.ninguemImpostor => FimDeJogo.ninguemCerto,
  null => FimDeJogo.ninguemErrado,
});

/// Chute final do impostor depois de ser pego.
Terminou chuteFinal(Rodada r, {required bool acertou}) =>
    _terminar(r, acertou ? FimDeJogo.impostorAdivinhou : FimDeJogo.jogadoresVenceram);

Terminou _terminar(Rodada r, FimDeJogo fim) {
  r.fim = fim;
  return Terminou(fim);
}
