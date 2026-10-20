import 'dart:ui' show Color;

/// Uma palavra secreta e a pista vaga que o impostor pode receber.
class Palavra {
  const Palavra(this.texto, [this.dica = '']);

  final String texto;
  final String dica;
}

/// Um conjunto de palavras com nome, emoji e cor do disquete.
class Tema {
  const Tema({
    required this.id,
    required this.nome,
    required this.emoji,
    required this.cor,
    required this.palavras,
    this.descricao = '',
    this.padrao = false,
  });

  final String id;
  final String nome;
  final String emoji;
  final Color cor;
  final String descricao;
  final List<Palavra> palavras;

  /// `true` para os temas que vêm com o jogo (não podem ser apagados).
  final bool padrao;

  Map<String, Object?> toJson() => {
    'id': id,
    'nome': nome,
    'emoji': emoji,
    'cor': corParaHex(cor),
    'descricao': descricao,
    'palavras': escreverPalavras(palavras),
  };

  /// Lê um tema vindo do armazenamento ou de um texto importado.
  /// Devolve `null` se faltar o essencial (nome e 3 palavras).
  /// Tudo é limpo e cortado num tamanho máximo, porque pode vir de qualquer lugar.
  static Tema? fromJson(Object? json, {required String id}) {
    // Pattern matching do Dart 3: confere o formato e já extrai os campos.
    if (json case {'nome': String nome, 'palavras': final Object? palavrasBrutas} &&
        final Map<Object?, Object?> mapa) {
      final palavras = switch (palavrasBrutas) {
        String texto => lerPalavras(texto),
        List<Object?> lista => [
          for (final item in lista)
            if (item case {'palavra': String p, 'dica': String d})
              Palavra(p, d)
            else if (item case {'palavra': String p})
              Palavra(p)
            else if (item case String p)
              Palavra(p),
        ],
        _ => <Palavra>[],
      };
      final tema = Tema(
        id: id,
        nome: _cortar(nome, 40),
        emoji: _cortar(_texto(mapa['emoji']), 8).ifEmpty('💡'),
        cor: hexParaCor(_texto(mapa['cor'])) ?? const Color(0xFF2F6BFF),
        descricao: _cortar(_texto(mapa['descricao']), 80),
        palavras: semRepetidas(palavras),
      );
      return tema.nome.isNotEmpty && tema.palavras.length >= 3 ? tema : null;
    }
    return null;
  }
}

/// Converte o texto "palavra | dica" (uma por linha) em uma lista de [Palavra].
List<Palavra> lerPalavras(String texto) => [
  for (final linha in texto.split('\n'))
    if (linha.trim().isNotEmpty) _lerLinha(linha.trim()),
];

Palavra _lerLinha(String linha) {
  final partes = linha.split('|');
  final palavra = partes.first.trim();
  final dica = partes.skip(1).join('|').trim();
  return Palavra(palavra, dica);
}

/// Caminho inverso: lista de [Palavra] → texto para o editor.
String escreverPalavras(List<Palavra> palavras) =>
    palavras.map((p) => p.dica.isEmpty ? p.texto : '${p.texto} | ${p.dica}').join('\n');

/// Tira vazias e repetidas (sem diferenciar maiúsculas), mantendo a ordem.
List<Palavra> semRepetidas(List<Palavra> palavras) {
  final vistas = <String>{};
  return [
    for (final p in palavras)
      if (p.texto.trim().isNotEmpty && vistas.add(p.texto.trim().toLowerCase()))
        Palavra(_cortar(p.texto, 60), _cortar(p.dica, 60)),
  ];
}

String corParaHex(Color cor) =>
    '#${(cor.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

Color? hexParaCor(String? hex) {
  if (hex == null || !RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(hex)) return null;
  return Color(0xFF000000 | int.parse(hex.substring(1), radix: 16));
}

/// Campo de texto vindo de JSON: se não for String (ex.: número), vira vazio.
String _texto(Object? valor) => valor is String ? valor : '';

String _cortar(String texto, int max) {
  final limpo = texto.trim();
  return limpo.length <= max ? limpo : limpo.substring(0, max);
}

// Extension: adiciona um método novo à classe String sem herdar dela.
extension on String {
  String ifEmpty(String padrao) => isEmpty ? padrao : this;
}
