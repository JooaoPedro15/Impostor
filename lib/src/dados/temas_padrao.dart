// Temas que já vêm no jogo.
// Cada linha de `palavras` segue o formato do editor: "palavra | dica para o impostor".
// A dica deve ser vaga: ajuda a blefar sem entregar a palavra.

import 'dart:ui' show Color;

import '../modelos/tema.dart';

final List<Tema> temasPadrao = [
  Tema(
    id: 'aeds',
    nome: 'Estruturas de Dados',
    emoji: '🧱',
    cor: const Color(0xFF2F6BFF),
    descricao: 'AEDS na veia: pilhas, filas, árvores e ordenação.',
    padrao: true,
    palavras: lerPalavras('''
      Pilha | Pratos
      Fila | Padaria
      Lista encadeada | Corrente
      Lista duplamente encadeada | Vai e volta
      Árvore binária | Galhos
      Árvore AVL | Equilíbrio
      Árvore rubro-negra | Cores
      Tabela hash | Gaveta
      Heap | Prioridade
      Trie | Dicionário
      Ponteiro | Seta
      Vetor | Fileira
      Matriz | Planilha
      Deque | Duas pontas
      Fila de prioridade | Pronto-socorro
      Nó | Bolinha
      Recursão | Espelho
      Busca binária | Adivinhar
      Quicksort | Rapidez
      Mergesort | Dividir
      Bubble sort | Lento
      Heapsort | Montanha
      Counting sort | Caixinhas
      Radix sort | Dígitos
      Notação Big-O | Velocidade
      Célula sentinela | Vigia
      Árvore Patricia | Prefixo
      Alocação dinâmica | Espaço
      Segmentation fault | Susto
'''),
  ),
  Tema(
    id: 'grafos',
    nome: 'Grafos',
    emoji: '🕸️',
    cor: const Color(0xFF00A6A6),
    descricao: 'Vértices, arestas e os algoritmos que caem na prova.',
    padrao: true,
    palavras: lerPalavras('''
      Vértice | Ponto
      Aresta | Linha
      Grafo direcionado | Mão única
      Grafo ponderado | Peso
      Grafo bipartido | Dois times
      Grafo completo | Todo mundo
      Grafo planar | Sem cruzar
      Árvore geradora mínima | Economia
      Dijkstra | GPS
      Busca em largura | Ondas
      Busca em profundidade | Labirinto
      Ciclo euleriano | Passeio
      Caminho hamiltoniano | Visita
      Caixeiro-viajante | Vendedor
      Coloração de grafos | Mapa
      Matriz de adjacência | Tabela
      Lista de adjacência | Vizinhos
      Grau do vértice | Popularidade
      Componente conexo | Ilha
      Isomorfismo | Gêmeos
      Clique | Panelinha
      Ordenação topológica | Pré-requisitos
      Fluxo máximo | Encanamento
      Kruskal | Floresta
      Prim | Crescer
      Laço | Volta
      Subgrafo | Pedaço
      Pontes de Königsberg | Cidade
'''),
  ),
  Tema(
    id: 'linguagens',
    nome: 'Linguagens de Programação',
    emoji: '💬',
    cor: const Color(0xFFFF7A00),
    descricao: 'Do Assembly ao Python, passando pelo bom e velho C.',
    padrao: true,
    palavras: lerPalavras('''
      Java | Café
      Python | Cobra
      C | Clássico
      C++ | Mais
      C# | Música
      JavaScript | Navegador
      TypeScript | Tipos
      Rust | Caranguejo
      Go | Google
      Kotlin | Android
      Swift | Pássaro
      Haskell | Matemática
      Assembly | Baixo nível
      SQL | Consulta
      PHP | Elefante
      Ruby | Joia
      Lua | Brasil
      COBOL | Banco
      Prolog | Lógica
      Verilog | Circuito
      R | Estatística
      Dart | Alvo
      Scratch | Blocos
      Lisp | Parênteses
      Pascal | Escola
      Fortran | Cientista
      MATLAB | Engenharia
      Bash | Terminal
'''),
  ),
  Tema(
    id: 'arquitetura',
    nome: 'Arquitetura e Sistemas Digitais',
    emoji: '🔌',
    cor: const Color(0xFF8A4FFF),
    descricao: 'Portas lógicas, flip-flops e o que roda dentro da CPU.',
    padrao: true,
    palavras: lerPalavras('''
      Processador | Cérebro
      Memória RAM | Mesa
      Memória cache | Atalho
      Registrador | Bolso
      ULA | Contas
      Clock | Ritmo
      Pipeline | Linha de montagem
      Porta lógica | Interruptor
      Porta NAND | Universal
      Flip-flop | Balanço
      Multiplexador | Seletor
      Decodificador | Tradutor
      Somador completo | Vai um
      Barramento | Ônibus
      Placa-mãe | Família
      SSD | Rápido
      HD | Disco
      Placa de vídeo | Jogos
      Transistor | Minúsculo
      Mapa de Karnaugh | Quadradinhos
      Tabela-verdade | Sim ou não
      Binário | Zeros
      Hexadecimal | Letras
      Complemento de dois | Negativo
      Interrupção | Campainha
      MIPS | Instrução
      Overclock | Turbo
      Cooler | Vento
      BIOS | Ligar
'''),
  ),
  Tema(
    id: 'so-redes',
    nome: 'Sistemas Operacionais e Redes',
    emoji: '🌐',
    cor: const Color(0xFF00B86B),
    descricao: 'Processos, threads, deadlock e o caminho de um pacote.',
    padrao: true,
    palavras: lerPalavras('''
      Processo | Programa
      Thread | Linha
      Deadlock | Engarrafamento
      Semáforo | Trânsito
      Escalonador | Agenda
      Memória virtual | Ilusão
      Paginação | Livro
      Kernel | Núcleo
      Linux | Pinguim
      Windows | Janela
      Terminal | Comandos
      Sistema de arquivos | Pastas
      Endereço IP | Endereço
      DNS | Lista telefônica
      TCP | Garantia
      UDP | Pressa
      Roteador | Caminho
      Rede sem fio | Antena
      HTTP | Site
      HTTPS | Cadeado
      Firewall | Muro
      Ping | Eco
      Modelo OSI | Camadas
      Pacote | Entrega
      Servidor | Garçom
      Nuvem | Céu
      VPN | Túnel
      Ataque DDoS | Multidão
      Senha | Segredo
'''),
  ),
  Tema(
    id: 'bd-web',
    nome: 'Banco de Dados e Web',
    emoji: '🗄️',
    cor: const Color(0xFFFF3D7F),
    descricao: 'SQL, APIs, front, back e o famoso merge conflict.',
    padrao: true,
    palavras: lerPalavras('''
      Tabela | Linhas
      Chave primária | Identidade
      Chave estrangeira | Relação
      JOIN | Juntar
      SELECT | Escolher
      Índice | Sumário
      Normalização | Organizar
      Transação | Tudo ou nada
      Rollback | Desfazer
      NoSQL | Flexível
      PostgreSQL | Elefante
      MongoDB | Documentos
      Diagrama ER | Desenho
      API | Ponte
      REST | Descanso
      JSON | Chaves
      HTML | Estrutura
      CSS | Estilo
      Front-end | Visual
      Back-end | Bastidores
      Docker | Navio
      Git | Versões
      GitHub | Gato
      Pull request | Pedido
      Merge conflict | Briga
      Deploy | Lançamento
      Cookie | Biscoito
      Cache do navegador | Lembrança
      Localhost | Casa
      React | Átomo
'''),
  ),
  Tema(
    id: 'vida-cc',
    nome: 'Vida de estudante de CC',
    emoji: '🎓',
    cor: const Color(0xFFFFC21A),
    descricao: 'Prova prática, TP de madrugada e café. Muito café.',
    padrao: true,
    palavras: lerPalavras('''
      Prova prática | Nervoso
      Trabalho prático | Prazo
      Monitoria | Ajuda
      Corretor automático | Nota
      Café | Energia
      Stack Overflow | Fórum
      Bug | Inseto
      Debug | Investigação
      Ponto e vírgula | Esquecido
      Compilar | Esperar
      Hello World | Primeiro
      Commit | Salvar
      Madrugada | Sono
      Hackathon | Maratona
      Estágio | Primeiro emprego
      LinkedIn | Currículo
      Pedir ajuda pra IA | Atalho
      Recuperação | Segunda chance
      Laboratório | Computadores
      Cantina | Fome
      TCC | Fim
      Grupo do WhatsApp | Notificação
      Cálculo | Limite
      Matemática discreta | Lógica
      Gambiarra | Improviso
      Print pra debugar | Mensagem
      Funciona na minha máquina | Desculpa
      Tela azul | Pânico
      Ctrl+C Ctrl+V | Atalho
      Fone de ouvido | Música
'''),
  ),
  Tema(
    id: 'ia-tec',
    nome: 'IA e Tecnologia',
    emoji: '🤖',
    cor: const Color(0xFF00A3E0),
    descricao: 'Redes neurais, prompts, robôs e o que vem por aí.',
    padrao: true,
    palavras: lerPalavras('''
      Inteligência artificial | Futuro
      Rede neural | Neurônio
      Machine learning | Aprender
      ChatGPT | Conversa
      Prompt | Pedido
      Dataset | Dados
      Overfitting | Decorar
      Algoritmo genético | Evolução
      Visão computacional | Olhos
      Chatbot | Atendimento
      Deepfake | Falso
      Teste de Turing | Disfarce
      Big Data | Muito
      Blockchain | Corrente
      Bitcoin | Dinheiro
      Realidade virtual | Óculos
      Realidade aumentada | Pokémon
      Computação quântica | Física
      Internet das Coisas | Geladeira
      Carro autônomo | Volante
      Robô | Metal
      Algoritmo de recomendação | Para você
      Reconhecimento facial | Rosto
      Assistente de voz | Falar
      Drone | Voar
      Impressora 3D | Camadas
      Smartwatch | Pulso
      Criptografia | Segredo
'''),
  ),
  Tema(
    id: 'icones',
    nome: 'Ícones da Computação',
    emoji: '🧑‍💻',
    cor: const Color(0xFFE14D2A),
    descricao: 'Gente que inventou o que a gente estuda.',
    padrao: true,
    palavras: lerPalavras('''
      Alan Turing | Guerra
      Ada Lovelace | Pioneira
      Grace Hopper | Marinha
      Linus Torvalds | Finlândia
      Bill Gates | Bilionário
      Steve Jobs | Maçã
      Steve Wozniak | Garagem
      Dennis Ritchie | Unix
      Edsger Dijkstra | Caminho
      Donald Knuth | Livros
      Tim Berners-Lee | Web
      John von Neumann | Arquitetura
      Margaret Hamilton | Lua
      Mark Zuckerberg | Rede social
      Guido van Rossum | Holanda
      James Gosling | Sol
      Claude Shannon | Informação
      George Boole | Verdadeiro
      Charles Babbage | Máquina
      Hedy Lamarr | Atriz
      Larry Page | Busca
      Satoshi Nakamoto | Mistério
      Katherine Johnson | NASA
      Elon Musk | Foguete
      Jensen Huang | Placa de vídeo
      Sam Altman | IA
'''),
  ),
  Tema(
    id: '40-anos',
    nome: '40 anos de computação',
    emoji: '💾',
    cor: const Color(0xFFC9A227),
    descricao: 'De 1986 a 2026: tudo que surgiu enquanto o curso existia.',
    padrao: true,
    palavras: lerPalavras('''
      Disquete | Salvar
      MS-DOS | Comandos
      Internet discada | Barulho
      Windows 95 | Iniciar
      CD-ROM | Brilho
      Pen drive | Chaveiro
      Orkut | Depoimento
      MSN Messenger | Status
      Nokia tijolão | Indestrutível
      Bug do milênio | Ano 2000
      Lan house | Campeonato
      ICQ | Florzinha
      Google | Pesquisar
      Wikipédia | Enciclopédia
      iPhone | Tela
      Android | Robô
      YouTube | Vídeo
      Netflix | Maratona
      Fita VHS | Rebobinar
      Modem | Conectar
      Mouse de bolinha | Limpar
      Monitor de tubo | Pesado
      Tamagotchi | Bichinho
      Atari | Joystick
      Super Nintendo | Cartucho
      Bluetooth | Dente
      Wi-Fi | Senha
      Aula remota | Câmera desligada
      Emoji | Carinha
      Pix | Transferência
'''),
  ),
];
