import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../dados/temas_padrao.dart';
import '../../logica/jogo.dart';
import '../../modelos/tema.dart';
import '../estilo.dart';
import '../widgets/comuns.dart';

class TelaMeusTemas extends StatelessWidget {
  const TelaMeusTemas({super.key});

  @override
  Widget build(BuildContext context) {
    final jogo = JogoScope.of(context);
    final meus = jogo.temasCustom;

    return Tela(
      titulo: 'Meus temas',
      corpo: [
        BotaoTecla('Criar tema', aoTocar: () => abrir(context, const TelaEditorTema())),
        const Secao('Criados por vocês'),
        if (meus.isEmpty)
          const TextoAjuda(
            'Nenhum tema criado ainda. Dá para fazer um só com nomes de professores, matérias do período ou piadas da turma.',
          )
        else
          for (final tema in meus)
            _LinhaTema(
              tema: tema,
              acoes: [
                BotaoLink('Editar', aoTocar: () => abrir(context, TelaEditorTema(base: tema))),
                BotaoLink(
                  'Apagar',
                  cor: const Color(0xFFFF8A8A),
                  aoTocar: () async {
                    final ok = await confirmar(
                      context,
                      titulo: 'Apagar "${tema.nome}"?',
                      texto: 'Isso não pode ser desfeito.',
                      acao: 'Apagar',
                    );
                    if (ok) jogo.apagarTema(tema.id);
                  },
                ),
              ],
            ),
        const Secao('Vêm com o jogo'),
        for (final tema in temasPadrao)
          _LinhaTema(
            tema: tema,
            // Rótulo curto: com "Copiar e editar", o nome do tema ficava espremido.
            acoes: [BotaoLink('Copiar', aoTocar: () => abrir(context, TelaEditorTema(base: tema)))],
          ),
        const Secao('Levar para outro celular'),
        const TextoAjuda('Os temas criados ficam salvos só neste aparelho. Exporte aqui e importe no outro celular.'),
        Row(
          children: [
            Expanded(
              child: BotaoTecla(
                'Exportar',
                tipo: TipoBotao.secundario,
                aoTocar: meus.isEmpty ? null : () => abrir(context, const TelaExportar()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: BotaoTecla(
                'Importar',
                tipo: TipoBotao.secundario,
                aoTocar: () => abrir(context, const TelaImportar()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _LinhaTema extends StatelessWidget {
  const _LinhaTema({required this.tema, required this.acoes});

  final Tema tema;
  final List<Widget> acoes;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(12, 6, 0, 6),
    decoration: BoxDecoration(
      border: Border(
        left: BorderSide(color: tema.cor, width: 5),
        bottom: const BorderSide(color: Cores.linha),
      ),
    ),
    child: Row(
      children: [
        Text(tema.emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tema.nome, style: anybody(peso: 750, largura: 95)),
              Text('${tema.palavras.length} palavras', style: anybody(tamanho: 13, cor: Cores.texto2)),
            ],
          ),
        ),
        ...acoes,
      ],
    ),
  );
}

/// Cria um tema novo, edita um tema próprio ou copia um tema padrão.
class TelaEditorTema extends StatefulWidget {
  const TelaEditorTema({super.key, this.base});

  /// Tema de partida. Se for padrão, vira uma cópia nova.
  final Tema? base;

  @override
  State<TelaEditorTema> createState() => _TelaEditorTemaState();
}

class _TelaEditorTemaState extends State<TelaEditorTema> {
  late final TextEditingController _nome;
  late final TextEditingController _emoji;
  late final TextEditingController _descricao;
  late final TextEditingController _palavras;
  late Color _cor;
  String? _erro;

  /// Só edita no lugar se for um tema próprio; tema padrão vira cópia.
  String? get _idEditado => (widget.base?.padrao ?? true) ? null : widget.base!.id;

  @override
  void initState() {
    super.initState();
    final b = widget.base;
    _nome = TextEditingController(text: b == null ? '' : (b.padrao ? '${b.nome} (cópia)' : b.nome));
    _emoji = TextEditingController(text: b?.emoji ?? '💡');
    _descricao = TextEditingController(text: b?.descricao ?? '');
    _palavras = TextEditingController(text: b == null ? '' : escreverPalavras(b.palavras));
    _cor = b?.cor ?? Cores.paleta.first;
  }

  @override
  void dispose() {
    for (final c in [_nome, _emoji, _descricao, _palavras]) {
      c.dispose();
    }
    super.dispose();
  }

  void _salvar() {
    final erro = JogoScope.ler(context).salvarTema(
      id: _idEditado,
      nome: _nome.text,
      emoji: _emoji.text,
      cor: _cor,
      descricao: _descricao.text,
      palavras: _palavras.text,
    );
    if (erro == null) {
      Navigator.of(context).pop();
    } else {
      setState(() => _erro = erro);
    }
  }

  @override
  Widget build(BuildContext context) {
    final estiloCampo = anybody(cor: Cores.tinta, peso: 600);
    return Tela(
      titulo: _idEditado == null ? 'Novo tema' : 'Editar tema',
      corpo: [
        const _Rotulo('Nome'),
        TextField(
          controller: _nome,
          maxLength: 40,
          style: estiloCampo,
          decoration: const InputDecoration(hintText: 'Ex.: Professores do ICEI', counterText: ''),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 88,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Rotulo('Emoji'),
                  TextField(
                    controller: _emoji,
                    maxLength: 8,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 26),
                    decoration: const InputDecoration(counterText: ''),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Rotulo('Cor do disquete'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final cor in Cores.paleta)
                        Semantics(
                          selected: cor == _cor,
                          label: 'Cor ${corParaHex(cor)}',
                          button: true,
                          child: GestureDetector(
                            onTap: () => setState(() => _cor = cor),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: cor,
                                borderRadius: BorderRadius.circular(8),
                                border: cor == _cor ? Border.all(color: Colors.white, width: 3) : null,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const _Rotulo('Descrição (opcional)'),
        TextField(
          controller: _descricao,
          maxLength: 80,
          style: estiloCampo,
          decoration: const InputDecoration(hintText: 'Uma frase sobre o tema', counterText: ''),
        ),
        const _Rotulo('Palavras'),
        TextField(
          controller: _palavras,
          minLines: 10,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          style: anybody(cor: Cores.tinta, peso: 550, largura: 95, altura: 1.5),
          decoration: const InputDecoration(hintText: 'Pilha | Pratos\nFila | Padaria\nRecursão'),
        ),
        const SizedBox(height: 8),
        const TextoAjuda(
          'Uma por linha. Para dar uma pista ao impostor, escreva depois de uma barra: "Pilha | Pratos". Mínimo 3 palavras.',
        ),
        if (_erro != null) Aviso(_erro!),
      ],
      rodape: [BotaoTecla('Salvar tema', aoTocar: _salvar)],
    );
  }
}

class _Rotulo extends StatelessWidget {
  const _Rotulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 6),
    child: Text(texto, style: anybody(peso: 700)),
  );
}

class TelaExportar extends StatelessWidget {
  const TelaExportar({super.key});

  @override
  Widget build(BuildContext context) {
    final texto = JogoScope.ler(context).exportarTemas();
    return Tela(
      titulo: 'Exportar temas',
      corpo: [
        const TextoAjuda(
          'Copie o texto e mande para o outro celular (WhatsApp, e-mail, notas). Lá, abra Meus temas, Importar, e cole.',
        ),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Cores.papel, borderRadius: BorderRadius.circular(12)),
          child: SelectableText(texto, style: anybody(tamanho: 13, cor: Cores.tinta, largura: 85)),
        ),
      ],
      rodape: [
        BotaoTecla(
          'Copiar texto',
          aoTocar: () async {
            await Clipboard.setData(ClipboardData(text: texto));
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Texto copiado. Agora cole no outro celular.')),
            );
          },
        ),
      ],
    );
  }
}

class TelaImportar extends StatefulWidget {
  const TelaImportar({super.key});

  @override
  State<TelaImportar> createState() => _TelaImportarState();
}

class _TelaImportarState extends State<TelaImportar> {
  final _texto = TextEditingController();
  String? _erro;

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  void _importar() {
    final (qtd, erro) = JogoScope.ler(context).importarTemas(_texto.text);
    if (erro != null) {
      setState(() => _erro = erro);
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(content: Text(qtd == 1 ? '1 tema importado.' : '$qtd temas importados.')));
  }

  @override
  Widget build(BuildContext context) => Tela(
    titulo: 'Importar temas',
    corpo: [
      const TextoAjuda('Cole aqui o texto exportado em outro celular.'),
      TextField(
        controller: _texto,
        minLines: 12,
        maxLines: null,
        keyboardType: TextInputType.multiline,
        style: anybody(tamanho: 13, cor: Cores.tinta, largura: 85),
        decoration: const InputDecoration(hintText: '{"app": "impostor-cc", ...}'),
      ),
      if (_erro != null) Aviso(_erro!),
    ],
    rodape: [BotaoTecla('Importar', aoTocar: _importar)],
  );
}
