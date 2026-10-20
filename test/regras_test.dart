import 'dart:math';
import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:impostor_cc/src/dados/temas_padrao.dart';
import 'package:impostor_cc/src/logica/regras.dart';
import 'package:impostor_cc/src/modelos/tema.dart';

Tema temaDeTeste(String id, List<String> palavras) => Tema(
  id: id,
  nome: id,
  emoji: '🧪',
  cor: const Color(0xFF000000),
  palavras: [for (final p in palavras) Palavra(p)],
);

void main() {
  group('embaralhar (Fisher–Yates)', () {
    test('mantém os mesmos elementos e não altera a lista original', () {
      final original = [1, 2, 3, 4, 5];
      final resultado = embaralhar(original, Random(42));
      expect(resultado..sort(), original);
      expect(original, [1, 2, 3, 4, 5]);
    });

    test('todas as 6 ordens de 3 itens aparecem', () {
      final rng = Random(7);
      final ordens = {for (var i = 0; i < 600; i++) embaralhar([1, 2, 3], rng).join()};
      expect(ordens, hasLength(6));
    });
  });

  group('número de impostores', () {
    test('nunca chega à metade da mesa', () {
      expect(maxImpostores(3), 1);
      expect(maxImpostores(5), 2);
      expect(maxImpostores(10), 4);
    });

    test('recomendado cresce com o grupo', () {
      expect(impostoresRecomendados(4), 1);
      expect(impostoresRecomendados(7), 2);
      expect(impostoresRecomendados(12), 3);
    });
  });

  group('sortearRodada', () {
    final temas = [temaDeTeste('t', ['a', 'b', 'c'])];

    test('sorteia a quantidade pedida de impostores', () {
      final (rodada, _) = sortearRodada(
        jogadores: 8,
        temas: temas,
        vistas: {},
        impostores: 2,
        surpresaLigada: false,
        rng: Random(1),
      );
      expect(rodada.impostores, hasLength(2));
      expect(rodada.impostores.every((i) => i >= 0 && i < 8), isTrue);
    });

    test('não repete palavra até esgotar o tema, depois recomeça', () {
      var vistas = <String, Set<String>>{};
      final saidas = <String>[];
      for (var i = 0; i < 3; i++) {
        final (rodada, novas) = sortearRodada(
          jogadores: 4,
          temas: temas,
          vistas: vistas,
          impostores: 1,
          surpresaLigada: false,
          rng: Random(i),
        );
        saidas.add(rodada.palavra.texto);
        vistas = novas;
      }
      expect(saidas.toSet(), {'a', 'b', 'c'});

      // 4ª rodada: tudo já saiu, então o histórico zera e só fica a nova palavra.
      final (_, depois) = sortearRodada(
        jogadores: 4,
        temas: temas,
        vistas: vistas,
        impostores: 1,
        surpresaLigada: false,
        rng: Random(99),
      );
      expect(depois['t'], hasLength(1));
    });

    test('é pura: não altera o histórico recebido', () {
      final vistas = {'t': {'a'}};
      sortearRodada(jogadores: 4, temas: temas, vistas: vistas, impostores: 1, surpresaLigada: false, rng: Random(3));
      expect(vistas, {'t': {'a'}});
    });

    test('com surpresa ligada, às vezes todos ou ninguém são impostores', () {
      final tipos = <Surpresa?>{};
      for (var i = 0; i < 300; i++) {
        final (rodada, _) = sortearRodada(
          jogadores: 5,
          temas: temas,
          vistas: {},
          impostores: 1,
          surpresaLigada: true,
          rng: Random(i),
        );
        tipos.add(rodada.surpresa);
        if (rodada.surpresa == Surpresa.todosImpostores) expect(rodada.impostores, hasLength(5));
        if (rodada.surpresa == Surpresa.ninguemImpostor) expect(rodada.impostores, isEmpty);
      }
      expect(tipos, containsAll([null, Surpresa.todosImpostores, Surpresa.ninguemImpostor]));
    });
  });

  group('acusar', () {
    Rodada rodadaCom(Set<int> impostores, {Surpresa? surpresa}) => Rodada(
      palavra: const Palavra('Pilha'),
      tema: temaDeTeste('t', ['Pilha']),
      impostores: impostores,
      quemComeca: 0,
      surpresa: surpresa,
    );

    test('acusar inocente: impostor escapa', () {
      final r = rodadaCom({2});
      final resultado = acusar(r, 0);
      expect(resultado, isA<Terminou>().having((t) => t.fim, 'fim', FimDeJogo.impostorEscapou));
      expect(r.culpado, 0);
    });

    test('pegar todos leva à última chance', () {
      final r = rodadaCom({1, 3});
      expect(acusar(r, 1), isA<AindaFaltam>().having((a) => a.quantos, 'quantos', 1));
      expect(acusar(r, 3), isA<UltimaChance>());
      expect(chuteFinal(r, acertou: false).fim, FimDeJogo.jogadoresVenceram);
    });

    test('apostar que ninguém é impostor', () {
      expect(apostarNinguem(rodadaCom({}, surpresa: Surpresa.ninguemImpostor)).fim, FimDeJogo.ninguemCerto);
      expect(apostarNinguem(rodadaCom({0})).fim, FimDeJogo.ninguemErrado);
    });
  });

  group('temas', () {
    test('lerPalavras entende "palavra | dica" e ignora linhas vazias', () {
      final lista = lerPalavras('Pilha | Pratos\n\n  Fila  \nA|B|C');
      expect(lista.map((p) => (p.texto, p.dica)), [('Pilha', 'Pratos'), ('Fila', ''), ('A', 'B|C')]);
    });

    test('fromJson rejeita tema com menos de 3 palavras diferentes', () {
      expect(Tema.fromJson({'nome': 'x', 'palavras': 'a\nA\nb'}, id: '1'), isNull);
      expect(Tema.fromJson({'nome': 'x', 'palavras': 'a\nb\nc'}, id: '1'), isNotNull);
      expect(Tema.fromJson({'nome': 123, 'palavras': 'a\nb\nc'}, id: '1'), isNull);
    });

    test('cor inválida vira a cor padrão em vez de quebrar', () {
      final tema = Tema.fromJson({'nome': 'x', 'cor': 'vermelho', 'palavras': 'a\nb\nc'}, id: '1')!;
      expect(corParaHex(tema.cor), '#2F6BFF');
    });

    test('temas padrão: todos com pelo menos 20 palavras, sem repetição', () {
      for (final t in temasPadrao) {
        expect(t.palavras.length, greaterThanOrEqualTo(20), reason: t.nome);
        expect(semRepetidas(t.palavras).length, t.palavras.length, reason: t.nome);
      }
      expect(temasPadrao.map((t) => t.id).toSet(), hasLength(temasPadrao.length));
    });
  });
}
