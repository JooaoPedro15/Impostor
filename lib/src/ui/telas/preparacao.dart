import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../logica/jogo.dart';
import '../../logica/regras.dart';
import '../../modelos/tema.dart';
import '../estilo.dart';
import '../widgets/comuns.dart';
import 'rodada.dart';
import 'temas.dart';

class TelaJogadores extends StatefulWidget {
  const TelaJogadores({super.key});

  static const rota = '/jogadores';

  @override
  State<TelaJogadores> createState() => _TelaJogadoresState();
}

class _TelaJogadoresState extends State<TelaJogadores> {
  final _nome = TextEditingController();
  final _foco = FocusNode();
  String? _erro;

  @override
  void dispose() {
    _nome.dispose();
    _foco.dispose();
    super.dispose();
  }

  void _adicionar() {
    final erro = JogoScope.ler(context).adicionarJogador(_nome.text);
    setState(() => _erro = erro);
    if (erro == null) _nome.clear();
    _foco.requestFocus(); // teclado continua aberto para o próximo nome
  }

  @override
  Widget build(BuildContext context) {
    final jogo = JogoScope.of(context);
    final n = jogo.jogadores.length;
    final faltam = minJogadores - n;
    final cheio = n >= maxJogadores;

    return Tela(
      titulo: 'Jogadores',
      corpo: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _nome,
                focusNode: _foco,
                enabled: !cheio,
                maxLength: 20,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                // onEditingComplete substitui o padrão do "done" (que tira o foco
                // e fecha o teclado): assim dá para digitar vários nomes seguidos.
                onEditingComplete: _adicionar,
                style: anybody(cor: Cores.tinta, peso: 600),
                decoration: const InputDecoration(hintText: 'Nome do jogador', counterText: ''),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 136,
              child: BotaoTecla('Adicionar', aoTocar: cheio ? null : _adicionar),
            ),
          ],
        ),
        if (_erro != null) Aviso(_erro!),
        const SizedBox(height: 8),
        if (n == 0)
          const _CaixaVazia('Escreva o nome de cada pessoa. A ordem da lista é a ordem em que o celular vai passar.')
        else
          for (final (i, nome) in jogo.jogadores.indexed)
            _LinhaJogador(
              nome: nome,
              cor: Cores.doJogador(i),
              aoRemover: () => jogo.removerJogador(i),
            ),
        if (n >= 2)
          Align(
            alignment: Alignment.centerLeft,
            child: BotaoLink('Sortear ordem', aoTocar: jogo.sortearOrdem),
          ),

        const Secao('Regras da rodada'),
        _Campo(
          titulo: 'Impostores',
          descricao: jogo.impostoresAutomatico ? 'Automático pelo número de jogadores.' : null,
          acaoDescricao: jogo.impostoresAutomatico ? null : BotaoLink('Voltar ao automático', aoTocar: jogo.impostoresAuto),
          controle: _Contador(
            valor: jogo.impostores,
            aoDiminuir: n >= minJogadores && jogo.impostores > 1 ? () => jogo.mudarImpostores(-1) : null,
            aoAumentar: n >= minJogadores && jogo.impostores < maxImpostores(n) ? () => jogo.mudarImpostores(1) : null,
          ),
        ),
        _Campo(
          titulo: 'Dicas para o impostor',
          descricao: 'Quem é impostor vê o tema e uma pista vaga.',
          controle: Switch(value: jogo.dicas, onChanged: (_) => jogo.alternarDicas()),
        ),
        _Campo(
          titulo: 'Rodada surpresa',
          descricao: 'Às vezes todo mundo é impostor. Às vezes ninguém é.',
          controle: Switch(value: jogo.surpresa, onChanged: (_) => jogo.alternarSurpresa()),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tempo para falar', style: anybody(peso: 700)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final segundos in const [0, 60, 120, 180, 300])
                    ChoiceChip(
                      label: Text(segundos == 0 ? 'Sem tempo' : '${segundos ~/ 60} min'),
                      selected: jogo.tempo == segundos,
                      onSelected: (_) => jogo.mudarTempo(segundos),
                      showCheckmark: false,
                      labelStyle: anybody(
                        peso: 650,
                        cor: jogo.tempo == segundos ? Cores.tinta : Cores.texto,
                      ),
                      selectedColor: Cores.amarelo,
                      backgroundColor: Colors.transparent,
                      side: BorderSide(color: jogo.tempo == segundos ? Cores.amarelo : Cores.linha, width: 2),
                      shape: const StadiumBorder(),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
      rodape: [
        if (faltam > 0)
          Text(
            faltam == 1 ? 'Falta 1 jogador para começar.' : 'Faltam $faltam jogadores para começar.',
            textAlign: TextAlign.center,
            style: anybody(cor: Cores.texto2),
          ),
        BotaoTecla(
          'Escolher temas',
          aoTocar: faltam > 0 ? null : () => abrir(context, const TelaEscolherTemas()),
        ),
      ],
    );
  }
}

class _LinhaJogador extends StatelessWidget {
  const _LinhaJogador({required this.nome, required this.cor, required this.aoRemover});

  final String nome;
  final Color cor;
  final VoidCallback aoRemover;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.only(left: 14),
    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Cores.linha))),
    child: Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(nome, style: anybody(tamanho: 18, peso: 650))),
        IconButton(
          tooltip: 'Remover $nome',
          onPressed: aoRemover,
          icon: const Icon(Icons.close_rounded, color: Cores.texto2),
        ),
      ],
    ),
  );
}

class _CaixaVazia extends StatelessWidget {
  const _CaixaVazia(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    margin: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Cores.linha, width: 2),
    ),
    child: Text(texto, style: anybody(cor: Cores.texto2)),
  );
}

class _Campo extends StatelessWidget {
  const _Campo({required this.titulo, required this.controle, this.descricao, this.acaoDescricao});

  final String titulo;
  final String? descricao;
  final Widget? acaoDescricao;
  final Widget controle;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Cores.linha))),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: anybody(peso: 700)),
              if (descricao != null) Text(descricao!, style: anybody(tamanho: 15, cor: Cores.texto2)),
              ?acaoDescricao,
            ],
          ),
        ),
        const SizedBox(width: 16),
        controle,
      ],
    ),
  );
}

class _Contador extends StatelessWidget {
  const _Contador({required this.valor, required this.aoDiminuir, required this.aoAumentar});

  final int valor;
  final VoidCallback? aoDiminuir;
  final VoidCallback? aoAumentar;

  @override
  Widget build(BuildContext context) {
    ButtonStyle estilo() => IconButton.styleFrom(
      backgroundColor: Cores.fundo3,
      disabledBackgroundColor: Cores.fundo3.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(tooltip: 'Menos impostores', style: estilo(), onPressed: aoDiminuir, icon: const Icon(Icons.remove)),
        SizedBox(
          width: 36,
          child: Text('$valor', textAlign: TextAlign.center, style: anybody(tamanho: 22, peso: 800)),
        ),
        IconButton(tooltip: 'Mais impostores', style: estilo(), onPressed: aoAumentar, icon: const Icon(Icons.add)),
      ],
    );
  }
}

class TelaEscolherTemas extends StatelessWidget {
  const TelaEscolherTemas({super.key});

  @override
  Widget build(BuildContext context) {
    final jogo = JogoScope.of(context);
    return Tela(
      titulo: 'Temas da rodada',
      corpo: [
        const TextoAjuda('A palavra secreta sai de um dos temas marcados.'),
        Wrap(
          spacing: 8,
          children: [
            BotaoLink('Marcar todos', aoTocar: jogo.marcarTodos),
            BotaoLink('Desmarcar todos', aoTocar: jogo.desmarcarTodos),
            BotaoLink('Criar tema', aoTocar: () => abrir(context, const TelaEditorTema())),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, c) {
            final largura = (c.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final tema in jogo.todosTemas)
                  SizedBox(
                    width: largura,
                    child: _TemaTile(
                      tema: tema,
                      marcado: jogo.temasSelecionados.contains(tema.id),
                      aoTocar: () => jogo.alternarTema(tema.id),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
      rodape: [
        BotaoTecla(
          'Começar rodada',
          aoTocar: jogo.podeComecar
              ? () {
                  jogo.novaRodada();
                  WakelockPlus.enable().catchError((_) {}); // tela acesa durante a rodada
                  abrir(context, const TelaRevelar());
                }
              : null,
        ),
      ],
    );
  }
}

class _TemaTile extends StatelessWidget {
  const _TemaTile({required this.tema, required this.marcado, required this.aoTocar});

  final Tema tema;
  final bool marcado;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final corTexto = marcado ? Cores.tintaSobre(tema.cor) : Cores.texto;
    return Semantics(
      checked: marcado,
      button: true,
      child: ClipPath(
        clipper: const _CantoCortado(),
        child: Material(
          color: marcado ? tema.cor : Cores.fundo2,
          child: InkWell(
            onTap: aoTocar,
            child: Container(
              constraints: const BoxConstraints(minHeight: 132),
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
              decoration: BoxDecoration(
                border: Border.all(color: tema.cor.withValues(alpha: marcado ? 1 : 0.55), width: 2),
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tema.emoji, style: const TextStyle(fontSize: 28)),
                      const SizedBox(height: 6),
                      Text(tema.nome, style: anybody(peso: 800, largura: 92, cor: corTexto, altura: 1.1)),
                      const SizedBox(height: 6),
                      Text(
                        tema.padrao ? '${tema.palavras.length} palavras' : '${tema.palavras.length} palavras, de vocês',
                        style: anybody(tamanho: 13, cor: corTexto.withValues(alpha: 0.8)),
                      ),
                    ],
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Icon(
                      marcado ? Icons.check_circle_rounded : Icons.circle_outlined,
                      color: corTexto.withValues(alpha: marcado ? 1 : 0.5),
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

/// Mesmo canto cortado do disquete, para os cartões de tema.
class _CantoCortado extends CustomClipper<Path> {
  const _CantoCortado();

  @override
  Path getClip(Size s) => Path()
    ..moveTo(0, 0)
    ..lineTo(s.width - 18, 0)
    ..lineTo(s.width, 18)
    ..lineTo(s.width, s.height)
    ..lineTo(0, s.height)
    ..close();

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
