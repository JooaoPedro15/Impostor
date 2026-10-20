// Gera build/web/sw.js depois do `flutter build web`.
//
// Uso (na pasta do projeto):
//   flutter build web --release --no-web-resources-cdn
//   dart run tool/gerar_service_worker.dart
//
// O service worker guarda os arquivos do jogo no aparelho na primeira visita,
// para o app abrir depois mesmo sem internet. A versão do cache é um hash do
// conteúdo: mudou qualquer arquivo, muda a versão e os celulares atualizam.

import 'dart:convert';
import 'dart:io';

const _pastaBuild = 'build/web';

/// Arquivos que o navegador baixa ao abrir o app no iPhone/Android.
/// Ficam de fora: símbolos de depuração, licenças e variantes do motor gráfico
/// que o Safari não usa (essas entram no cache se algum navegador pedir).
bool _vaiParaOCache(String caminho) {
  if (caminho.endsWith('.symbols') || caminho.endsWith('.map')) return false;
  const ignorados = {'.last_build_id', 'flutter_service_worker.js', 'sw.js', 'version.json', 'assets/NOTICES'};
  if (ignorados.contains(caminho)) return false;
  if (caminho.startsWith('canvaskit/')) {
    return caminho == 'canvaskit/canvaskit.js' || caminho == 'canvaskit/canvaskit.wasm';
  }
  return true;
}

/// FNV-1a de 32 bits: hash simples e rápido, bom para detectar mudança
/// (não serve para segurança).
int _fnv1a(int hash, List<int> bytes) {
  for (final b in bytes) {
    hash ^= b;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash;
}

void main() {
  final pasta = Directory(_pastaBuild);
  if (!pasta.existsSync()) {
    stderr.writeln('Pasta $_pastaBuild não existe. Rode antes: flutter build web --release --no-web-resources-cdn');
    exit(1);
  }

  final raiz = pasta.absolute.path;
  final arquivos = [
    for (final f in pasta.listSync(recursive: true).whereType<File>())
      f.absolute.path.substring(raiz.length + 1).replaceAll(r'\', '/'),
  ].where(_vaiParaOCache).toList()..sort();

  var hash = 0x811C9DC5;
  var bytesTotais = 0;
  for (final caminho in arquivos) {
    final bytes = File('$_pastaBuild/$caminho').readAsBytesSync();
    bytesTotais += bytes.length;
    hash = _fnv1a(_fnv1a(hash, utf8.encode(caminho)), bytes);
  }
  final versao = hash.toRadixString(16).padLeft(8, '0');

  final lista = const JsonEncoder.withIndent('  ').convert(['./', ...arquivos]);
  File('$_pastaBuild/sw.js').writeAsStringSync(_modelo(versao, lista));

  final mb = (bytesTotais / (1024 * 1024)).toStringAsFixed(1);
  stdout.writeln('sw.js gerado: versão $versao, ${arquivos.length} arquivos ($mb MB) no cache.');
}

String _modelo(String versao, String lista) => '''
// Gerado por tool/gerar_service_worker.dart. Não edite à mão.
const VERSAO = 'impostor-cc-$versao';
const ARQUIVOS = $lista;

// Instalação: baixa e guarda tudo de uma vez.
self.addEventListener('install', (evento) => {
  evento.waitUntil(
    caches.open(VERSAO).then((cache) => cache.addAll(ARQUIVOS)).then(() => self.skipWaiting()),
  );
});

// Ativação: apaga caches de versões antigas e assume as abas abertas.
self.addEventListener('activate', (evento) => {
  evento.waitUntil(
    caches.keys()
      .then((nomes) => Promise.all(nomes.filter((n) => n !== VERSAO).map((n) => caches.delete(n))))
      .then(() => self.clients.claim()),
  );
});

async function primeiroCache(request) {
  const salvo = await caches.match(request);
  if (salvo) return salvo;
  const resposta = await fetch(request);
  if (resposta.ok) {
    const cache = await caches.open(VERSAO);
    cache.put(request, resposta.clone());
  }
  return resposta;
}

self.addEventListener('fetch', (evento) => {
  const { request } = evento;
  if (request.method !== 'GET') return;
  const url = new URL(request.url);

  // Abrir o app: tenta a rede (pega atualização) e, sem internet, usa o cache.
  if (request.mode === 'navigate') {
    evento.respondWith(fetch(request).catch(() => caches.match('./')));
    return;
  }

  // Arquivos do app e fontes de emoji do Google: cache primeiro.
  const mesmoSite = url.origin === self.location.origin;
  const fontesGoogle = url.hostname === 'fonts.gstatic.com' || url.hostname === 'fonts.googleapis.com';
  if (mesmoSite || fontesGoogle) evento.respondWith(primeiroCache(request));
});
''';
