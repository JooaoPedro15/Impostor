import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:impostor_cc/src/logica/armazenamento.dart';
import 'package:impostor_cc/src/logica/jogo.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Jogo> novoJogo() async {
  final jogo = Jogo(await Armazenamento.abrir(), rng: Random(1));
  jogo.carregar();
  return jogo;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('jogadores ficam salvos entre aberturas do app', () async {
    final jogo = await novoJogo();
    expect(jogo.adicionarJogador('  Ana  '), isNull);
    expect(jogo.adicionarJogador('ana'), contains('já está na lista'));
    jogo.adicionarJogador('Bia');

    final reaberto = await novoJogo();
    expect(reaberto.jogadores, ['Ana', 'Bia']);
  });

  test('criar tema valida e já marca o tema para a rodada', () async {
    final jogo = await novoJogo();
    final erro = jogo.salvarTema(nome: 'Profs', emoji: '👩‍🏫', cor: Colors.red, descricao: '', palavras: 'a\nb');
    expect(erro, contains('pelo menos 3'));

    jogo.salvarTema(nome: 'Profs', emoji: '👩‍🏫', cor: Colors.red, descricao: '', palavras: 'a\nb\nc | dica');
    final tema = jogo.temasCustom.single;
    expect(jogo.temasSelecionados, contains(tema.id));
    expect(tema.palavras.last.dica, 'dica');
  });

  test('exportar e importar devolve os mesmos temas', () async {
    final origem = await novoJogo();
    origem.salvarTema(nome: 'Turma', emoji: '🎉', cor: Colors.blue, descricao: 'piadas', palavras: 'x | 1\ny\nz');
    final texto = origem.exportarTemas();

    SharedPreferences.setMockInitialValues({});
    final destino = await novoJogo();
    final (qtd, erro) = destino.importarTemas(texto);
    expect(erro, isNull);
    expect(qtd, 1);
    expect(destino.temasCustom.single.nome, 'Turma');
    expect(destino.temasCustom.single.palavras.map((p) => p.texto), ['x', 'y', 'z']);

    expect(destino.importarTemas('isso não é json').$2, isNotNull);
  });

  test('rodada completa: todo mundo vê e a rodada termina', () async {
    final jogo = await novoJogo();
    for (final nome in ['A', 'B', 'C', 'D']) {
      jogo.adicionarJogador(nome);
    }
    jogo.novaRodada();
    final r = jogo.rodada!;
    var continua = true;
    while (continua) {
      jogo.marcarVisto();
      continua = jogo.proximoJogador();
    }
    expect(r.vez, 4);
    expect(r.impostores.length, lessThanOrEqualTo(1));
  });
}
