import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../estilo.dart';

/// Como a tampa de metal se comporta ao aparecer na tela.
enum ModoTampa {
  /// Fechada, esperando o jogador arrastar.
  fechada,

  /// Abre um pouco e fecha uma vez (tela inicial).
  espiar,

  /// Abre sozinha e fica aberta (resultado).
  abrir,
}

/// Disquete 3,5" desenhado com widgets. A palavra secreta fica no "visor",
/// coberto pela tampa de metal. Arrastar a tampa para o lado revela o conteúdo;
/// soltar faz ela voltar sozinha.
class Disquete extends StatefulWidget {
  const Disquete({
    super.key,
    required this.cor,
    required this.etiqueta,
    required this.conteudo,
    this.interativo = false,
    this.modo = ModoTampa.fechada,
    this.aoVer,
  });

  final Color cor;
  final String etiqueta;
  final Widget conteudo;
  final bool interativo;
  final ModoTampa modo;

  /// Chamado uma vez, quando a tampa abre o suficiente para ler.
  final VoidCallback? aoVer;

  @override
  State<Disquete> createState() => _DisqueteState();
}

class _DisqueteState extends State<Disquete> with SingleTickerProviderStateMixin {
  /// Posição da tampa: 0 = fechada, 1 = totalmente aberta.
  late final AnimationController _tampa = AnimationController(vsync: this);
  bool _avisou = false;

  static const _limiarVisto = 0.6;

  @override
  void initState() {
    super.initState();
    // Espera o primeiro frame para poder ler as preferências de acessibilidade.
    WidgetsBinding.instance.addPostFrameCallback((_) => _animacaoInicial());
  }

  Future<void> _animacaoInicial() async {
    if (!mounted) return;
    final semAnimacao = MediaQuery.disableAnimationsOf(context);
    switch (widget.modo) {
      case ModoTampa.fechada:
        break;
      case ModoTampa.espiar:
        if (semAnimacao) return;
        await Future<void>.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        await _tampa.animateTo(0.62, duration: const Duration(milliseconds: 650), curve: Curves.easeInOut);
        await Future<void>.delayed(const Duration(milliseconds: 550));
        if (!mounted) return;
        await _tampa.animateTo(0, duration: const Duration(milliseconds: 650), curve: Curves.easeInOut);
      case ModoTampa.abrir:
        if (semAnimacao) {
          _tampa.value = 1;
          return;
        }
        await Future<void>.delayed(const Duration(milliseconds: 350));
        if (!mounted) return;
        await _tampa.animateTo(1, duration: const Duration(milliseconds: 900), curve: Curves.easeInOutCubic);
    }
  }

  @override
  void dispose() {
    _tampa.dispose();
    super.dispose();
  }

  void _mover(double fracao) {
    _tampa.value = fracao.clamp(0, 1);
    if (!_avisou && _tampa.value >= _limiarVisto) {
      _avisou = true;
      HapticFeedback.selectionClick();
      widget.aoVer?.call();
    }
  }

  void _fechar() => _tampa.animateTo(0, duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic);

  void _abrirInteira() {
    _tampa.stop();
    _mover(1);
  }

  /// Teclado: segurar Espaço ou Enter abre; soltar fecha.
  KeyEventResult _tecla(FocusNode _, KeyEvent evento) {
    final tecla = evento.logicalKey;
    if (tecla != LogicalKeyboardKey.space && tecla != LogicalKeyboardKey.enter) return KeyEventResult.ignored;
    if (evento is KeyDownEvent) _abrirInteira();
    if (evento is KeyUpEvent) _fechar();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final tela = MediaQuery.sizeOf(context);
    final largura = math.min(math.min(tela.width * 0.84, 340.0), tela.height * 0.46);
    final altura = largura * 94 / 90; // proporção real do disquete: 90 × 94 mm

    final visorLargura = largura * 0.70;
    final visorAltura = altura * 0.50;

    Widget tampa = AnimatedBuilder(
      animation: _tampa,
      builder: (context, filho) =>
          Transform.translate(offset: Offset(_tampa.value * visorLargura, 0), child: filho),
      child: _Tampa(mostrarDica: widget.interativo),
    );

    if (widget.interativo) {
      tampa = Semantics(
        button: true,
        label: 'Tampa do disquete. Arraste para o lado, ou segure, para ver o segredo.',
        onLongPress: _abrirInteira,
        child: Focus(
          onKeyEvent: _tecla,
          child: MouseRegion(
            cursor: SystemMouseCursors.grab,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (_) => _tampa.stop(),
              onHorizontalDragUpdate: (d) => _mover(_tampa.value + d.primaryDelta! / visorLargura),
              onHorizontalDragEnd: (_) => _fechar(),
              onHorizontalDragCancel: _fechar,
              onLongPressStart: (_) => _abrirInteira(),
              onLongPressEnd: (_) => _fechar(),
              child: tampa,
            ),
          ),
        ),
      );
    }

    final faixa = Color.lerp(widget.cor, Colors.black, 0.22)!;
    final quadradinho = largura * 0.065;

    return Center(
      child: SizedBox(
        width: largura,
        height: altura + 10,
        child: Stack(
          children: [
            // Sombra "chapada", deslocada para baixo
            Positioned(
              top: 10,
              width: largura,
              height: altura,
              child: ClipPath(clipper: const _Chanfro(), child: const ColoredBox(color: Color(0x73080C32))),
            ),
            Positioned(
              top: 0,
              width: largura,
              height: altura,
              child: ClipPath(
                clipper: const _Chanfro(),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color.lerp(widget.cor, Colors.white, 0.22)!, widget.cor],
                      stops: const [0, 0.38],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Visor com o segredo, coberto pela tampa
                      Positioned(
                        left: largura * 0.15,
                        top: 0,
                        width: visorLargura,
                        height: visorAltura,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(6)),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              _Filme(child: widget.conteudo),
                              tampa,
                            ],
                          ),
                        ),
                      ),
                      // Etiqueta de papel com o nome escrito à caneta
                      Positioned(
                        left: largura * 0.08,
                        right: largura * 0.08,
                        top: altura * 0.56,
                        bottom: 0,
                        child: _Etiqueta(texto: widget.etiqueta, faixa: faixa, largura: largura),
                      ),
                      // Trava de proteção e furo de alta densidade
                      Positioned(
                        left: largura * 0.035,
                        bottom: altura * 0.04,
                        child: _Quadradinho(lado: quadradinho, trava: true),
                      ),
                      Positioned(
                        right: largura * 0.035,
                        bottom: altura * 0.04,
                        child: _Quadradinho(lado: quadradinho),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Recorta o canto superior direito, como no disquete de verdade.
class _Chanfro extends CustomClipper<Path> {
  const _Chanfro();

  @override
  Path getClip(Size s) => Path()
    ..moveTo(0, 0)
    ..lineTo(s.width * 0.93, 0)
    ..lineTo(s.width, s.height * 0.05)
    ..lineTo(s.width, s.height)
    ..lineTo(0, s.height)
    ..close();

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// O disco magnético escuro, com trilhas circulares.
class _Filme extends StatelessWidget {
  const _Filme({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: const _Trilhas(),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: DefaultTextStyle.merge(
        style: anybody(cor: Cores.filmeTexto),
        textAlign: TextAlign.center,
        child: Center(child: child),
      ),
    ),
  );
}

class _Trilhas extends CustomPainter {
  const _Trilhas();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Cores.filme);
    final pincel = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.045);
    final centro = size.center(Offset.zero);
    final raioMax = size.longestSide;
    for (var r = 3.0; r < raioMax; r += 5) {
      canvas.drawCircle(centro, r, pincel);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Tampa extends StatelessWidget {
  const _Tampa({required this.mostrarDica});

  final bool mostrarDica;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) => DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF8F97A5),
            Color(0xFFE4E8EE),
            Color(0xFFBFC6D1),
            Color(0xFFEEF1F5),
            Color(0xFFC5CBD5),
            Color(0xFF9AA2B0),
          ],
          stops: [0, 0.14, 0.36, 0.58, 0.80, 1],
        ),
      ),
      child: Stack(
        children: [
          // Furo da tampa, por onde se vê o disco
          Positioned(
            left: c.maxWidth * 0.60,
            top: c.maxHeight * 0.16,
            width: c.maxWidth * 0.20,
            height: c.maxHeight * 0.58,
            child: DecoratedBox(
              decoration: BoxDecoration(color: Cores.filme, borderRadius: BorderRadius.circular(3)),
            ),
          ),
          if (mostrarDica)
            Positioned(
              left: c.maxWidth * 0.09,
              top: 0,
              bottom: 0,
              child: Row(
                children: [
                  CustomPaint(size: const Size(16, 26), painter: const _Sulcos()),
                  const SizedBox(width: 6),
                  Text('arraste', style: anybody(tamanho: 13, peso: 700, cor: const Color(0xFF4A5262))),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

/// Sulcos para o dedo na tampa.
class _Sulcos extends CustomPainter {
  const _Sulcos();

  @override
  void paint(Canvas canvas, Size size) {
    final pincel = Paint()..color = const Color(0x8C3C4454);
    for (var x = 0.0; x < size.width; x += 5) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 2, size.height), pincel);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta({required this.texto, required this.faixa, required this.largura});

  final String texto;
  final Color faixa;
  final double largura;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
    child: CustomPaint(
      painter: _Pautas(faixa: faixa, espaco: largura * 0.078),
      child: Padding(
        padding: EdgeInsets.fromLTRB(largura * 0.06, largura * 0.11, largura * 0.06, largura * 0.03),
        child: Center(
          child: Transform.rotate(
            angle: -2.5 * math.pi / 180,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(texto, maxLines: 1, style: marcador(tamanho: largura * 0.09)),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Papel pautado com a faixa colorida no topo.
class _Pautas extends CustomPainter {
  const _Pautas({required this.faixa, required this.espaco});

  final Color faixa;
  final double espaco;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Cores.papel);
    final alturaFaixa = size.height * 0.14;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, alturaFaixa), Paint()..color = faixa);
    final linha = Paint()..color = const Color(0x382F6BFF);
    for (var y = alturaFaixa + espaco; y < size.height; y += espaco) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), linha);
    }
  }

  @override
  bool shouldRepaint(covariant _Pautas antigo) => antigo.faixa != faixa || antigo.espaco != espaco;
}

class _Quadradinho extends StatelessWidget {
  const _Quadradinho({required this.lado, this.trava = false});

  final double lado;
  final bool trava;

  @override
  Widget build(BuildContext context) => Container(
    width: lado,
    height: lado,
    decoration: BoxDecoration(color: const Color(0x52000000), borderRadius: BorderRadius.circular(2)),
    alignment: Alignment.bottomCenter,
    child: trava ? Container(height: lado * 0.45, color: const Color(0x40FFFFFF)) : null,
  );
}

/// Texto que escolhe o maior tamanho de fonte em que cabe no espaço.
///
/// Usa busca binária: testa o tamanho do meio, e conforme cabe ou não,
/// descarta metade do intervalo. ~8 medições em vez de testar todos os tamanhos.
class TextoAjustado extends StatelessWidget {
  const TextoAjustado(this.texto, {super.key, required this.estilo, this.maximo = 72, this.minimo = 12});

  final String texto;
  final TextStyle estilo;
  final double maximo;
  final double minimo;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final tamanho = _melhorTamanho(c.maxWidth, c.maxHeight);
      return Text(
        texto,
        textAlign: TextAlign.center,
        textScaler: TextScaler.noScaling, // o tamanho já foi calculado para caber
        style: estilo.copyWith(fontSize: tamanho),
      );
    },
  );

  double _melhorTamanho(double largura, double altura) {
    var baixo = minimo;
    var alto = maximo;
    while (alto - baixo > 0.5) {
      final meio = (baixo + alto) / 2;
      if (_cabe(meio, largura, altura)) {
        baixo = meio;
      } else {
        alto = meio;
      }
    }
    return baixo;
  }

  bool _cabe(double tamanho, double largura, double altura) {
    final estiloTeste = estilo.copyWith(fontSize: tamanho);
    final bloco = TextPainter(
      text: TextSpan(text: texto, style: estiloTeste),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: largura);
    final cabeAltura = bloco.height <= altura;
    bloco.dispose();
    if (!cabeAltura) return false;

    // Nenhuma palavra pode ser quebrada no meio.
    for (final palavra in texto.split(' ')) {
      final p = TextPainter(text: TextSpan(text: palavra, style: estiloTeste), textDirection: TextDirection.ltr)
        ..layout();
      final cabe = p.width <= largura;
      p.dispose();
      if (!cabe) return false;
    }
    return true;
  }
}
