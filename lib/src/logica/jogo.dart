import 'dart:convert';
import 'dart:math';

import 'package:flutter/widgets.dart';

import '../dados/temas_padrao.dart';
import '../modelos/tema.dart';
import 'armazenamento.dart';
import 'regras.dart';

abstract final class _Chaves {
  static const jogadores = 'jogadores';
  static const config = 'config';
  static const temas = 'temasCustom';
  static const vistas = 'vistas';
}

/// Estado do app inteiro. `ChangeNotifier` é o padrão Observer do Flutter:
/// quando algo muda, chamamos `notifyListeners()` e as telas que dependem
/// do jogo são reconstruídas.
class Jogo extends ChangeNotifier {
  Jogo(this._armazenamento, {Random? rng}) : _rng = rng ?? Random();

  final Armazenamento _armazenamento;
  final Random _rng;

  List<String> jogadores = [];
  List<Tema> temasCustom = [];
  Map<String, Set<String>> _vistas = {};
  Rodada? rodada;

  // Configuração da rodada
  int? _impostoresManual; // null = automático
  bool dicas = true;
  bool surpresa = false;
  int tempo = 180;
  Set<String> temasSelecionados = {'aeds', 'grafos', 'vida-cc', '40-anos'};

  List<Tema> get todosTemas => [...temasCustom, ...temasPadrao];

  Tema? acharTema(String id) {
    for (final t in todosTemas) {
      if (t.id == id) return t;
    }
    return null;
  }

  bool get impostoresAutomatico => _impostoresManual == null;

  int get impostores {
    final n = jogadores.length;
    if (n < minJogadores) return 1;
    return (_impostoresManual ?? impostoresRecomendados(n)).clamp(1, maxImpostores(n));
  }

  bool get podeComecar =>
      jogadores.length >= minJogadores &&
      temasSelecionados.any((id) => acharTema(id)?.palavras.isNotEmpty ?? false);

  // ---------- Carregar e salvar ----------

  void carregar() {
    if (_armazenamento.ler(_Chaves.jogadores) case List<Object?> lista) {
      jogadores = lista.whereType<String>().toList();
    }
    if (_armazenamento.ler(_Chaves.temas) case List<Object?> lista) {
      temasCustom = [
        for (final item in lista)
          if (item case {'id': String id}) ?Tema.fromJson(item, id: id),
      ];
    }
    if (_armazenamento.ler(_Chaves.vistas) case Map<String, Object?> mapa) {
      _vistas = {
        for (final MapEntry(:key, :value) in mapa.entries)
          if (value is List) key: value.whereType<String>().toSet(),
      };
    }
    if (_armazenamento.ler(_Chaves.config) case Map<String, Object?> c) {
      _impostoresManual = c['impostores'] as int?;
      dicas = c['dicas'] as bool? ?? dicas;
      surpresa = c['surpresa'] as bool? ?? surpresa;
      tempo = c['tempo'] as int? ?? tempo;
      if (c['temas'] case List<Object?> ids) temasSelecionados = ids.whereType<String>().toSet();
    }
  }

  void _salvarConfig() => _armazenamento.gravar(_Chaves.config, {
    'impostores': _impostoresManual,
    'dicas': dicas,
    'surpresa': surpresa,
    'tempo': tempo,
    'temas': temasSelecionados.toList(),
  });

  void _salvarJogadores() => _armazenamento.gravar(_Chaves.jogadores, jogadores);

  void _salvarTemas() =>
      _armazenamento.gravar(_Chaves.temas, [for (final t in temasCustom) t.toJson()]);

  void _salvarVistas() => _armazenamento.gravar(_Chaves.vistas, {
    for (final e in _vistas.entries) e.key: e.value.toList(),
  });

  /// Atalho: muda, salva e avisa as telas.
  void _mudar(void Function() mudanca, {void Function()? salvar}) {
    mudanca();
    salvar?.call();
    notifyListeners();
  }

  // ---------- Jogadores ----------

  /// Devolve uma mensagem de erro, ou `null` se deu certo.
  String? adicionarJogador(String nomeBruto) {
    final nome = nomeBruto.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (nome.isEmpty) return null;
    if (jogadores.length >= maxJogadores) return 'Limite de $maxJogadores jogadores.';
    if (jogadores.any((j) => j.toLowerCase() == nome.toLowerCase())) {
      return '$nome já está na lista. Use um apelido para diferenciar.';
    }
    _mudar(() => jogadores.add(nome), salvar: _salvarJogadores);
    return null;
  }

  void removerJogador(int i) => _mudar(() => jogadores.removeAt(i), salvar: _salvarJogadores);

  void sortearOrdem() => _mudar(() => jogadores = embaralhar(jogadores, _rng), salvar: _salvarJogadores);

  // ---------- Configuração ----------

  void mudarImpostores(int delta) => _mudar(
    () => _impostoresManual = (impostores + delta).clamp(1, maxImpostores(jogadores.length)),
    salvar: _salvarConfig,
  );

  void impostoresAuto() => _mudar(() => _impostoresManual = null, salvar: _salvarConfig);

  void alternarDicas() => _mudar(() => dicas = !dicas, salvar: _salvarConfig);

  void alternarSurpresa() => _mudar(() => surpresa = !surpresa, salvar: _salvarConfig);

  void mudarTempo(int segundos) => _mudar(() => tempo = segundos, salvar: _salvarConfig);

  void alternarTema(String id) => _mudar(
    () => temasSelecionados.contains(id) ? temasSelecionados.remove(id) : temasSelecionados.add(id),
    salvar: _salvarConfig,
  );

  void marcarTodos() =>
      _mudar(() => temasSelecionados = todosTemas.map((t) => t.id).toSet(), salvar: _salvarConfig);

  void desmarcarTodos() => _mudar(() => temasSelecionados = {}, salvar: _salvarConfig);

  // ---------- Rodada ----------

  void novaRodada() {
    final temas = [for (final id in temasSelecionados) ?acharTema(id)];
    final (nova, historico) = sortearRodada(
      jogadores: jogadores.length,
      temas: temas,
      vistas: _vistas,
      impostores: impostores,
      surpresaLigada: surpresa,
      rng: _rng,
    );
    _mudar(() {
      rodada = nova;
      _vistas = historico;
    }, salvar: _salvarVistas);
  }

  void marcarVisto() {
    final r = rodada;
    if (r == null || r.visto) return;
    _mudar(() => r.visto = true);
  }

  /// Passa o celular. Devolve `true` se ainda falta alguém ver.
  bool proximoJogador() {
    final r = rodada!;
    _mudar(() {
      r.vez++;
      r.visto = false;
    });
    return r.vez < jogadores.length;
  }

  ResultadoAcusacao acusarJogador(int i) {
    final resultado = acusar(rodada!, i);
    notifyListeners();
    return resultado;
  }

  void apostarNinguemTemImpostor() => _mudar(() => apostarNinguem(rodada!));

  void registrarChute({required bool acertou}) => _mudar(() => chuteFinal(rodada!, acertou: acertou));

  void encerrarRodada() => _mudar(() => rodada = null);

  // ---------- Temas próprios ----------

  String _novoId() =>
      'meu-${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}-${_rng.nextInt(1 << 20).toRadixString(36)}';

  /// Cria ou atualiza um tema. Devolve mensagem de erro ou `null`.
  String? salvarTema({
    String? id,
    required String nome,
    required String emoji,
    required Color cor,
    required String descricao,
    required String palavras,
  }) {
    final tema = Tema.fromJson({
      'nome': nome,
      'emoji': emoji,
      'cor': corParaHex(cor),
      'descricao': descricao,
      'palavras': palavras,
    }, id: id ?? _novoId());

    if (nome.trim().isEmpty) return 'Dê um nome para o tema.';
    if (tema == null) {
      final qtd = semRepetidas(lerPalavras(palavras)).length;
      return 'O tema precisa de pelo menos 3 palavras diferentes. Agora tem $qtd.';
    }

    _mudar(() {
      final i = temasCustom.indexWhere((t) => t.id == tema.id);
      if (i >= 0) {
        temasCustom[i] = tema;
      } else {
        temasCustom.insert(0, tema);
        temasSelecionados.add(tema.id); // tema novo já entra marcado
      }
    }, salvar: () {
      _salvarTemas();
      _salvarConfig();
    });
    return null;
  }

  void apagarTema(String id) => _mudar(() {
    temasCustom.removeWhere((t) => t.id == id);
    temasSelecionados.remove(id);
    _vistas.remove(id);
  }, salvar: () {
    _salvarTemas();
    _salvarConfig();
    _salvarVistas();
  });

  String exportarTemas() => const JsonEncoder.withIndent('  ').convert({
    'app': 'impostor-cc',
    'versao': 1,
    'temas': [
      for (final t in temasCustom) {...t.toJson()}..remove('id'),
    ],
  });

  /// Devolve (quantos importou, erro).
  (int, String?) importarTemas(String texto) {
    final Object? dados;
    try {
      dados = jsonDecode(texto);
    } on FormatException {
      return (0, 'Esse texto não está no formato certo. Copie de novo o texto inteiro do outro celular.');
    }
    final lista = switch (dados) {
      List<Object?> l => l,
      {'temas': List<Object?> l} => l,
      _ => null,
    };
    if (lista == null) return (0, 'Não achei nenhum tema nesse texto.');

    final novos = [for (final item in lista) ?Tema.fromJson(item, id: _novoId())];
    if (novos.isEmpty) return (0, 'Nenhum tema válido: cada um precisa de nome e pelo menos 3 palavras.');

    _mudar(() {
      temasCustom.insertAll(0, novos);
      temasSelecionados.addAll(novos.map((t) => t.id));
    }, salvar: () {
      _salvarTemas();
      _salvarConfig();
    });
    return (novos.length, null);
  }
}

/// Disponibiliza o [Jogo] para qualquer tela abaixo dele na árvore de widgets.
/// Parecido com o Context do React, mas já vem no Flutter.
class JogoScope extends InheritedNotifier<Jogo> {
  const JogoScope({super.key, required Jogo super.notifier, required super.child});

  /// Lê o jogo e reconstrói o widget quando ele mudar.
  static Jogo of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<JogoScope>()!.notifier!;

  /// Lê o jogo sem se inscrever (para usar dentro de cliques).
  static Jogo ler(BuildContext context) =>
      context.getInheritedWidgetOfExactType<JogoScope>()!.notifier!;
}
