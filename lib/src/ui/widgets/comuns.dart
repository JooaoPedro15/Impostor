import 'package:flutter/material.dart';

import '../estilo.dart';

/// Estrutura padrão das telas: fundo com malha de pontos, largura máxima de
/// celular, conteúdo rolável e rodapé fixo com o botão principal.
class Tela extends StatelessWidget {
  const Tela({
    super.key,
    required this.corpo,
    this.titulo,
    this.topo,
    this.rodape = const [],
    this.voltar = true,
  });

  final String? titulo;

  /// Substitui o cabeçalho padrão (usado nas telas da rodada).
  final Widget? topo;
  final List<Widget> corpo;
  final List<Widget> rodape;
  final bool voltar;

  @override
  Widget build(BuildContext context) {
    final podeVoltar = voltar && Navigator.of(context).canPop();
    return Scaffold(
      body: CustomPaint(
        painter: const _MalhaDePontos(),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  if (topo != null)
                    Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0), child: topo)
                  else if (titulo != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
                      child: Row(
                        children: [
                          if (podeVoltar)
                            IconButton(
                              tooltip: 'Voltar',
                              iconSize: 30,
                              onPressed: () => Navigator.of(context).maybePop(),
                              icon: const Icon(Icons.chevron_left_rounded),
                            )
                          else
                            const SizedBox(width: 12),
                          Expanded(
                            child: Semantics(
                              header: true,
                              child: Text(titulo!, style: anybody(tamanho: 30, peso: 800, largura: 112, altura: 1.05)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      children: corpo,
                    ),
                  ),
                  if (rodape.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final (i, w) in rodape.indexed) ...[if (i > 0) const SizedBox(height: 12), w],
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Malha de pontos discreta no fundo, como papel de grafos.
class _MalhaDePontos extends CustomPainter {
  const _MalhaDePontos();

  @override
  void paint(Canvas canvas, Size size) {
    final pincel = Paint()..color = Colors.white.withValues(alpha: 0.07);
    const passo = 22.0;
    for (var y = passo / 2; y < size.height; y += passo) {
      for (var x = passo / 2; x < size.width; x += passo) {
        canvas.drawCircle(Offset(x, y), 1.1, pincel);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Enum "turbinado" (enhanced enum): cada valor carrega suas próprias cores.
enum TipoBotao {
  primario(Cores.amarelo, Cores.amareloSombra, Cores.tinta),
  secundario(Cores.fundo3, Cores.sombraFundo, Cores.texto),
  perigo(Cores.vermelho, Cores.vermelhoSombra, Cores.texto);

  const TipoBotao(this.fundo, this.sombra, this.texto);

  final Color fundo;
  final Color sombra;
  final Color texto;
}

/// Botão com cara de tecla: afunda quando apertado.
class BotaoTecla extends StatefulWidget {
  const BotaoTecla(this.texto, {super.key, required this.aoTocar, this.tipo = TipoBotao.primario});

  final String texto;

  /// `null` deixa o botão desabilitado.
  final VoidCallback? aoTocar;
  final TipoBotao tipo;

  @override
  State<BotaoTecla> createState() => _BotaoTeclaState();
}

class _BotaoTeclaState extends State<BotaoTecla> {
  bool _apertado = false;
  bool _foco = false;

  void _apertar(bool valor) {
    if (widget.aoTocar != null) setState(() => _apertado = valor);
  }

  @override
  Widget build(BuildContext context) {
    final ativo = widget.aoTocar != null;
    final tipo = widget.tipo;
    return Semantics(
      button: true,
      enabled: ativo,
      child: FocusableActionDetector(
        enabled: ativo,
        mouseCursor: ativo ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onShowFocusHighlight: (v) => setState(() => _foco = v),
        actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.aoTocar?.call())},
        child: GestureDetector(
          onTapDown: (_) => _apertar(true),
          onTapUp: (_) => _apertar(false),
          onTapCancel: () => _apertar(false),
          onTap: widget.aoTocar,
          child: Opacity(
            opacity: ativo ? 1 : 0.4,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 80),
              transform: Matrix4.translationValues(0, _apertado ? 4 : 0, 0),
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tipo.fundo,
                borderRadius: BorderRadius.circular(14),
                border: _foco ? Border.all(color: Colors.white, width: 3) : null,
                boxShadow: [BoxShadow(color: tipo.sombra, offset: Offset(0, _apertado ? 1 : 5))],
              ),
              child: Text(
                widget.texto,
                textAlign: TextAlign.center,
                style: anybody(tamanho: 18, peso: 750, largura: 105, cor: tipo.texto, altura: 1.15),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BotaoLink extends StatelessWidget {
  const BotaoLink(this.texto, {super.key, required this.aoTocar, this.cor = Cores.amarelo});

  final String texto;
  final VoidCallback? aoTocar;
  final Color cor;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: aoTocar,
    style: TextButton.styleFrom(
      foregroundColor: cor,
      minimumSize: const Size(44, 44),
      padding: const EdgeInsets.symmetric(horizontal: 6),
    ),
    child: Text(
      texto,
      style: anybody(peso: 650, cor: cor).copyWith(
        decoration: TextDecoration.underline,
        decorationColor: cor,
        decorationThickness: 2,
      ),
    ),
  );
}

/// Caixa de mensagem com barra lateral colorida (erro ou sucesso).
class Aviso extends StatelessWidget {
  const Aviso(this.texto, {super.key, this.cor = Cores.vermelho});

  final String texto;
  final Color cor;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: cor, width: 4)),
      ),
      child: Text(texto, style: anybody()),
    ),
  );
}

class TextoAjuda extends StatelessWidget {
  const TextoAjuda(this.texto, {super.key, this.centro = false});

  final String texto;
  final bool centro;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Text(texto, textAlign: centro ? TextAlign.center : TextAlign.start, style: anybody(cor: Cores.texto2)),
  );
}

class Secao extends StatelessWidget {
  const Secao(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 28, bottom: 8),
    child: Semantics(header: true, child: Text(texto, style: anybody(tamanho: 17, peso: 700, cor: Cores.texto2))),
  );
}

Future<bool> confirmar(BuildContext context, {required String titulo, required String texto, required String acao}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(titulo),
      content: Text(texto),
      actions: [
        BotaoLink('Cancelar', aoTocar: () => Navigator.pop(context, false), cor: Cores.texto2),
        BotaoLink(acao, aoTocar: () => Navigator.pop(context, true), cor: Cores.vermelho),
      ],
    ),
  );
  return ok ?? false;
}

/// Navegação: abre uma tela por cima da atual.
Future<void> abrir(BuildContext context, Widget tela, {String? nome}) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => tela, settings: RouteSettings(name: nome)));

/// Troca a tela atual por outra (não dá para voltar para a anterior).
void trocar(BuildContext context, Widget tela, {String? nome}) => Navigator.of(context).pushReplacement(
  MaterialPageRoute(builder: (_) => tela, settings: RouteSettings(name: nome)),
);
