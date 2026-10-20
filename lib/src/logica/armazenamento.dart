import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Guarda dados como JSON no aparelho.
/// Na web, o shared_preferences usa o localStorage do navegador.
class Armazenamento {
  Armazenamento(this._prefs);

  final SharedPreferences _prefs;

  static Future<Armazenamento> abrir() async => Armazenamento(await SharedPreferences.getInstance());

  /// Devolve `null` se não existir ou se o conteúdo estiver corrompido.
  Object? ler(String chave) {
    final texto = _prefs.getString(chave);
    if (texto == null) return null;
    try {
      return jsonDecode(texto);
    } on FormatException {
      return null;
    }
  }

  Future<void> gravar(String chave, Object? valor) => _prefs.setString(chave, jsonEncode(valor));
}
