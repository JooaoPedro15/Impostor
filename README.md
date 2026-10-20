# Impostor CC

Jogo do impostor para jogar passando um celular de mão em mão, com temas de
Ciência da Computação (edição PUC Minas, 40 anos do curso). Feito em Flutter e
publicado como PWA: instala na tela de início do iPhone e do Android, sem loja
de apps, e funciona offline.

**Jogar:** https://jooaopedro15.github.io/Impostor/

## Como funciona

1. Escrevam os nomes dos jogadores (mínimo 3).
2. Escolham os temas.
3. Cada um arrasta a tampa do disquete para ver a palavra secreta, menos o
   impostor, que só vê o tema e uma pista vaga.
4. Todos falam uma palavra sobre o segredo, votam, e o impostor pego ainda pode
   roubar a vitória chutando a palavra.

Opções: número de impostores, dicas para o impostor, rodada surpresa (todo
mundo impostor, ou ninguém), cronômetro e temas próprios com importação e
exportação entre celulares.

## Stack

- **Flutter 3.47 / Dart 3.13**, compilado para web (CanvasKit embutido)
- `shared_preferences` para salvar jogadores e temas (localStorage na web)
- `wakelock_plus` para manter a tela acesa durante a rodada
- Service worker próprio, gerado por um script Dart depois do build

## Estrutura

```
lib/
  main.dart                   inicializa armazenamento e o app
  src/
    dados/temas_padrao.dart   10 temas, ~280 palavras com dicas
    modelos/tema.dart         Tema, Palavra, leitura/validação de JSON
    logica/regras.dart        regras puras: sorteio, Fisher–Yates, acusação
    logica/jogo.dart          estado do app (ChangeNotifier) + JogoScope
    logica/armazenamento.dart JSON no shared_preferences
    ui/estilo.dart            cores, fonte variável Anybody, tema Material
    ui/widgets/disquete.dart  disquete com tampa arrastável e texto auto-ajustável
    ui/telas/                 telas do jogo
test/                         testes de unidade das regras e do estado
tool/gerar_service_worker.dart
web/                          index.html, manifest, ícones, bootstrap
```

As regras ficam em Dart puro (`regras.dart`), sem depender de Flutter, para
poderem ser testadas isoladamente. O `Random` é injetado, então os testes usam
semente fixa.

## Rodar e testar

```bash
flutter pub get
flutter run -d chrome
flutter test
```

## Gerar a versão web (PWA)

```bash
flutter build web --release --no-web-resources-cdn
dart run tool/gerar_service_worker.dart
```

`--no-web-resources-cdn` embute o motor gráfico no app (necessário para o modo
offline). O script lista os arquivos do build, calcula um hash do conteúdo para
versionar o cache e escreve `build/web/sw.js`.

Para publicar numa subpasta (ex.: GitHub Pages em `usuario.github.io/impostor-cc/`),
use `--base-href /impostor-cc/` no build. O service worker exige HTTPS (ou
`localhost`).

## Instalar no celular

- **iPhone:** abra o link no Safari, toque em Compartilhar e depois em
  "Adicionar à Tela de Início".
- **Android:** abra no Chrome e toque em "Instalar app" (ou menu, "Adicionar à
  tela inicial").

Na primeira abertura o app baixa cerca de 10 MB. Depois abre na hora, mesmo sem
internet. Ao publicar uma versão nova, o celular atualiza na segunda abertura.
