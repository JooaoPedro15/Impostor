{{flutter_js}}
{{flutter_build_config}}

// Carrega o app SEM o service worker padrão do Flutter: nas versões atuais ele
// é só um stub que se desregistra, e apagaria o nosso (um por escopo).
// O nosso service worker é o sw.js, registrado no index.html.
_flutter.loader.load({});
