import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../logica/jogo.dart';
import '../../logica/regras.dart';
import '../estilo.dart';
import '../widgets/comuns.dart';
import '../widgets/disquete.dart';
import 'preparacao.dart';

/// Estilo da palavra secreta no visor do disquete.
TextStyle _estiloSegredo({Color cor = Cores.filmeTexto, double largura = 100}) =>
    anybody(tamanho: 40, peso: 850, largura: largura, cor: cor, altura: 1.02);

void _desligarTelaAcesa() => WakelockPlus.disable().catchError((_) {});

/// Topo das telas da rodada: sair (com confirmação) e, opcionalmente, um texto à direita.
class _TopoRodada extends StatelessWidget {
  const _TopoRodada({this.direita});

  final String? direita;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      BotaoLink('Sair da rodada', aoTocar: () => _sair(context)),
      const Spacer(),
      if (direita != null) Text(direita!, style: anybody(cor: Cores.texto2)),
    ],
  );
}

Future<void> _sair(BuildContext context) async {
  final ok = await confirmar(
    context,
    titulo: 'Sair da rodada?',
    texto: 'A palavra desta rodada será descartada.',
    acao: 'Sair',
  );
  if (!ok || !context.mounted) return;
  _desligarTelaAcesa();
  JogoScope.ler(context).encerrarRodada();
  Navigator.of(context).popUntil(ModalRoute.withName(TelaJogadores.rota));
}

/// Impede que o "voltar" do Android ou o gesto do iPhone saia sem querer.
class _ProtegerVoltar extends StatelessWidget {
  const _ProtegerVoltar({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (saiu, _) {
      if (!saiu) _sair(context);
    },
    child: child,
  );
}

// ======================= Revelar =======================

class TelaRevelar extends StatelessWidget {
  const TelaRevelar({super.key});

  @override
  Widget build(BuildContext context) {
    final jogo = JogoScope.of(context);
    final r = jogo.rodada;
    if (r == null) return const SizedBox.shrink(); // rodada encerrada durante a transição

    final n = jogo.jogadores.length;
    final nome = jogo.jogadores[r.vez];
    final ultimo = r.vez == n - 1;

    final conteudo = r.ehImpostor(r.vez)
        ? Column(
            children: [
              Expanded(child: TextoAjustado('Você é o impostor', estilo: _estiloSegredo(cor: Cores.vermelho, largura: 88))),
              const SizedBox(height: 4),
              if (jogo.dicas) ...[
                Text('Tema: ${r.tema.nome}', style: anybody(tamanho: 14, peso: 600, cor: Cores.filmeTexto)),
                if (r.palavra.dica.isNotEmpty)
                  Text('Dica: ${r.palavra.dica}', style: anybody(tamanho: 14, peso: 600, cor: Cores.filmeTexto)),
              ] else
                Text(
                  'Descubra a palavra pelas falas dos outros.',
                  textAlign: TextAlign.center,
                  style: anybody(tamanho: 13, peso: 600, cor: Cores.filmeTexto),
                ),
            ],
          )
        : Column(
            children: [
              Text('Palavra secreta', style: anybody(tamanho: 13, peso: 600, cor: Cores.filmeTexto.withValues(alpha: 0.75))),
              const SizedBox(height: 4),
              Expanded(
                child: TextoAjustado(
                  r.palavra.texto,
                  estilo: _estiloSegredo(largura: r.palavra.texto.length > 14 ? 72 : 100),
                ),
              ),
            ],
          );

    return _ProtegerVoltar(
      child: Tela(
        topo: _TopoRodada(direita: 'Jogador ${r.vez + 1} de $n'),
        corpo: [
          const SizedBox(height: 8),
          Semantics(
            header: true,
            child: Text(
              'Vez de $nome',
              textAlign: TextAlign.center,
              style: anybody(tamanho: 32, peso: 800, largura: 112),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Só $nome pode olhar. Arraste a tampa de metal para o lado e solte para esconder.',
            textAlign: TextAlign.center,
            style: anybody(cor: Cores.texto2),
          ),
          const SizedBox(height: 20),
          Disquete(
            key: ValueKey(r.vez), // novo jogador = disquete novo, com a tampa fechada
            cor: Cores.doJogador(r.vez),
            etiqueta: nome,
            conteudo: conteudo,
            interativo: true,
            aoVer: jogo.marcarVisto,
          ),
        ],
        rodape: [
          BotaoTecla(
            ultimo ? 'Já vi, ir para a conversa' : 'Já vi, passar para ${jogo.jogadores[r.vez + 1]}',
            aoTocar: r.visto
                ? () {
                    if (!jogo.proximoJogador()) trocar(context, const TelaConversa());
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

// ======================= Conversa =======================

class TelaConversa extends StatefulWidget {
  const TelaConversa({super.key});

  @override
  State<TelaConversa> createState() => _TelaConversaState();
}

class _TelaConversaState extends State<TelaConversa> {
  Timer? _timer;
  late int _total;
  late int _restante;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _total = JogoScope.ler(context).tempo;
    _restante = _timer == null ? _total : _restante;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool get _rodando => _timer?.isActive ?? false;

  void _alternar() {
    if (_rodando) {
      setState(() => _timer?.cancel());
      return;
    }
    if (_restante == 0) _restante = _total;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _restante--);
      if (_restante <= 0) {
        t.cancel();
        HapticFeedback.vibrate(); // no navegador vira navigator.vibrate (Android)
      }
    });
    setState(() {});
  }

  String get _rotuloBotao => switch ((_rodando, _restante)) {
    (true, _) => 'Pausar',
    (false, 0) => 'Recomeçar',
    (false, final r) when r < _total => 'Continuar',
    _ => 'Iniciar tempo',
  };

  @override
  Widget build(BuildContext context) {
    final jogo = JogoScope.of(context);
    final r = jogo.rodada;
    if (r == null) return const SizedBox.shrink();
    final comeca = jogo.jogadores[r.quemComeca];
    final acabou = _total > 0 && _restante == 0;

    return _ProtegerVoltar(
      child: Tela(
        topo: const _TopoRodada(),
        corpo: [
          const SizedBox(height: 8),
          Semantics(
            header: true,
            child: Text('Hora de falar', textAlign: TextAlign.center, style: anybody(tamanho: 32, peso: 800, largura: 112)),
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Cada um diz uma palavra ou frase sobre o segredo, sem entregar. Quem começa é '),
                TextSpan(text: comeca, style: anybody(peso: 800, cor: Cores.texto)),
                const TextSpan(text: ', depois segue a ordem da lista.'),
              ],
            ),
            textAlign: TextAlign.center,
            style: anybody(cor: Cores.texto2),
          ),
          if (_total > 0) ...[
            const SizedBox(height: 24),
            Center(
              child: SizedBox.square(
                dimension: math.min(MediaQuery.sizeOf(context).width * 0.62, 230),
                child: CustomPaint(
                  painter: _Anel(fracao: _restante / _total),
                  child: Center(
                    child: Text(
                      '${_restante ~/ 60}:${(_restante % 60).toString().padLeft(2, '0')}',
                      style: anybody(tamanho: 54, peso: 850, largura: 120, cor: acabou ? Cores.vermelho : Cores.texto)
                          .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                    ),
                  ),
                ),
              ),
            ),
            if (acabou)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text('Acabou o tempo!', textAlign: TextAlign.center, style: anybody(peso: 750, cor: Cores.vermelho)),
              ),
            const SizedBox(height: 20),
            Center(
              child: SizedBox(
                width: 220,
                child: BotaoTecla(_rotuloBotao, tipo: TipoBotao.secundario, aoTocar: _alternar),
              ),
            ),
          ],
        ],
        rodape: [BotaoTecla('Ir para a votação', aoTocar: () => trocar(context, const TelaVotacao()))],
      ),
    );
  }
}

/// Anel do cronômetro: o arco amarelo diminui conforme o tempo passa.
class _Anel extends CustomPainter {
  const _Anel({required this.fracao});

  final double fracao;

  @override
  void paint(Canvas canvas, Size size) {
    final espessura = size.width * 0.13;
    final rect = Offset(espessura / 2, espessura / 2) & Size(size.width - espessura, size.height - espessura);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = espessura
      ..color = Cores.fundo2;
    canvas.drawArc(rect, 0, math.pi * 2, false, base);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * fracao, false, base..color = Cores.amarelo);
  }

  @override
  bool shouldRepaint(covariant _Anel antigo) => antigo.fracao != fracao;
}

// ======================= Votação =======================

class TelaVotacao extends StatefulWidget {
  const TelaVotacao({super.key});

  @override
  State<TelaVotacao> createState() => _TelaVotacaoState();
}

class _TelaVotacaoState extends State<TelaVotacao> {
  int? _selecionado;
  String? _aviso;

  void _acusar() {
    final jogo = JogoScope.ler(context);
    final i = _selecionado!;
    final nome = jogo.jogadores[i];
    // switch exaustivo: se um dia criarmos outro tipo de resultado, isto deixa de compilar.
    switch (jogo.acusarJogador(i)) {
      case AindaFaltam(:final quantos):
        setState(() {
          _selecionado = null;
          _aviso = 'Acertaram! $nome estava fingindo. ${quantos == 1 ? 'Ainda falta 1.' : 'Ainda faltam $quantos.'}';
        });
      case UltimaChance():
        trocar(context, const TelaUltimaChance());
      case Terminou():
        _irParaResultado(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final jogo = JogoScope.of(context);
    final r = jogo.rodada;
    if (r == null) return const SizedBox.shrink();
    final sel = _selecionado;

    return _ProtegerVoltar(
      child: Tela(
        topo: const _TopoRodada(),
        corpo: [
          const SizedBox(height: 8),
          Semantics(
            header: true,
            child: Text(
              jogo.impostores > 1 ? 'Quem são os impostores?' : 'Quem é o impostor?',
              style: anybody(tamanho: 32, peso: 800, largura: 112, altura: 1.05),
            ),
          ),
          const SizedBox(height: 8),
          const TextoAjuda('Votem em voz alta. Depois toquem em quem foi mais votado.'),
          if (_aviso != null) Aviso(_aviso!, cor: Cores.menta),
          for (final (i, nome) in jogo.jogadores.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _BotaoVoto(
                nome: nome,
                cor: Cores.doJogador(i),
                selecionado: sel == i,
                pego: r.acusados.contains(i),
                aoTocar: () => setState(() => _selecionado = sel == i ? null : i),
              ),
            ),
        ],
        rodape: [
          if (sel != null)
            BotaoTecla('Acusar ${jogo.jogadores[sel]}', tipo: TipoBotao.perigo, aoTocar: _acusar)
          else
            Text('Toque em um nome para acusar.', textAlign: TextAlign.center, style: anybody(cor: Cores.texto2)),
          if (jogo.surpresa && r.acusados.isEmpty)
            BotaoTecla(
              'Achamos que não tem impostor',
              tipo: TipoBotao.secundario,
              aoTocar: () {
                jogo.apostarNinguemTemImpostor();
                _irParaResultado(context);
              },
            ),
        ],
      ),
    );
  }
}

class _BotaoVoto extends StatelessWidget {
  const _BotaoVoto({
    required this.nome,
    required this.cor,
    required this.selecionado,
    required this.pego,
    required this.aoTocar,
  });

  final String nome;
  final Color cor;
  final bool selecionado;
  final bool pego;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selecionado,
    child: Material(
      color: selecionado ? Cores.vermelho.withValues(alpha: 0.2) : Cores.fundo2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: selecionado ? Cores.vermelho : Cores.linha, width: 2),
      ),
      child: InkWell(
        customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onTap: pego ? null : aoTocar,
        child: Opacity(
          opacity: pego ? 0.55 : 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(3)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    nome,
                    style: anybody(tamanho: 19, peso: 700).copyWith(
                      decoration: pego ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                if (pego)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(color: Cores.menta, borderRadius: BorderRadius.circular(20)),
                    child: Text('pego', style: anybody(tamanho: 13, peso: 700, cor: Cores.tinta)),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

void _irParaResultado(BuildContext context) {
  _desligarTelaAcesa();
  trocar(context, const TelaResultado());
}

// ======================= Última chance =======================

class TelaUltimaChance extends StatelessWidget {
  const TelaUltimaChance({super.key});

  @override
  Widget build(BuildContext context) {
    final jogo = JogoScope.of(context);
    final varios = (jogo.rodada?.impostores.length ?? 1) > 1;

    void responder(bool acertou) {
      jogo.registrarChute(acertou: acertou);
      _irParaResultado(context);
    }

    return _ProtegerVoltar(
      child: Tela(
        topo: const _TopoRodada(),
        corpo: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.15),
          Semantics(
            header: true,
            child: Text('Última chance', textAlign: TextAlign.center, style: anybody(tamanho: 36, peso: 850, largura: 115)),
          ),
          const SizedBox(height: 12),
          TextoAjuda(
            varios
                ? 'Os impostores ainda podem roubar a vitória: digam em voz alta qual era a palavra secreta.'
                : 'O impostor ainda pode roubar a vitória: diga em voz alta qual era a palavra secreta.',
            centro: true,
          ),
        ],
        rodape: [
          BotaoTecla('Acertou a palavra', tipo: TipoBotao.perigo, aoTocar: () => responder(true)),
          BotaoTecla('Errou', tipo: TipoBotao.secundario, aoTocar: () => responder(false)),
        ],
      ),
    );
  }
}

// ======================= Resultado =======================

class TelaResultado extends StatelessWidget {
  const TelaResultado({super.key});

  @override
  Widget build(BuildContext context) {
    final jogo = JogoScope.of(context);
    final r = jogo.rodada;
    if (r == null || r.fim == null) return const SizedBox.shrink();

    final varios = r.impostores.length > 1;
    final nomesImpostores = [for (final i in r.impostores) jogo.jogadores[i]];
    final culpado = r.culpado == null ? '' : jogo.jogadores[r.culpado!];
    final impostorVenceu = varios ? 'Impostores venceram!' : 'Impostor venceu!';

    // switch expression devolvendo um record com 3 campos
    final (titulo, texto, cor) = switch (r.fim!) {
      FimDeJogo.jogadoresVenceram => (
        'Jogadores venceram!',
        varios ? 'Pegaram todos e o chute final errou.' : 'Pegaram quem estava fingindo e o chute final errou.',
        Cores.menta,
      ),
      FimDeJogo.impostorAdivinhou => (impostorVenceu, 'Foi pego, mas acertou a palavra secreta.', Cores.vermelho),
      FimDeJogo.impostorEscapou => (impostorVenceu, '$culpado sabia a palavra. Acusaram a pessoa errada.', Cores.vermelho),
      FimDeJogo.ninguemErrado => (impostorVenceu, 'Tinha impostor, sim.', Cores.vermelho),
      FimDeJogo.ninguemCerto => (
        'Jogadores venceram!',
        'Rodada surpresa: não tinha nenhum impostor, e vocês perceberam.',
        Cores.menta,
      ),
      FimDeJogo.ninguemAcusou => (
        'Não tinha impostor!',
        'Rodada surpresa: todo mundo sabia a palavra. $culpado levou a culpa à toa.',
        Cores.amarelo,
      ),
      FimDeJogo.todosImpostores => (
        'Todos eram impostores!',
        'Rodada surpresa: ninguém sabia a palavra. Todo mundo estava fingindo.',
        Cores.amarelo,
      ),
    };

    final quem = switch (r.surpresa) {
      Surpresa.ninguemImpostor => 'Ninguém era impostor.',
      Surpresa.todosImpostores => 'Todo mundo era impostor.',
      null => '${varios ? 'Impostores' : 'Impostor'}: ${nomesImpostores.join(', ')}',
    };

    void voltarParaJogadores() {
      jogo.encerrarRodada();
      Navigator.of(context).popUntil(ModalRoute.withName(TelaJogadores.rota));
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (saiu, _) {
        if (!saiu) voltarParaJogadores();
      },
      child: Tela(
        corpo: [
          const SizedBox(height: 24),
          // Título grande sem quebrar palavra no meio: o TextoAjustado acha
          // (por busca binária) o maior tamanho que cabe em até ~2 linhas.
          Semantics(
            header: true,
            child: SizedBox(
              height: 112,
              child: TextoAjustado(
                titulo,
                estilo: anybody(tamanho: 44, peso: 900, largura: 125, cor: cor, altura: 0.98),
                maximo: 52,
                minimo: 24,
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextoAjuda(texto, centro: true),
          Disquete(
            cor: r.tema.cor,
            etiqueta: 'Palavra secreta',
            modo: ModoTampa.abrir,
            conteudo: Column(
              children: [
                Text(r.tema.nome, style: anybody(tamanho: 13, peso: 600, cor: Cores.filmeTexto.withValues(alpha: 0.75))),
                const SizedBox(height: 4),
                Expanded(
                  child: TextoAjustado(
                    r.palavra.texto,
                    estilo: _estiloSegredo(largura: r.palavra.texto.length > 14 ? 72 : 100),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(quem, textAlign: TextAlign.center, style: anybody(peso: 700)),
        ],
        rodape: [
          BotaoTecla(
            'Jogar de novo',
            aoTocar: () {
              jogo.novaRodada();
              WakelockPlus.enable().catchError((_) {});
              trocar(context, const TelaRevelar());
            },
          ),
          BotaoTecla('Mudar jogadores ou temas', tipo: TipoBotao.secundario, aoTocar: voltarParaJogadores),
        ],
      ),
    );
  }
}
