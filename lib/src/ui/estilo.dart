import 'package:flutter/material.dart';

/// Paleta do app. `abstract final class`: só agrupa constantes, não dá para
/// instanciar nem herdar.
abstract final class Cores {
  static const fundo = Color(0xFF18206B);
  static const fundo2 = Color(0xFF222C85);
  static const fundo3 = Color(0xFF2E3A9E);
  static const sombraFundo = Color(0xFF0F1550);
  static const linha = Color(0x24FFFFFF);
  static const texto = Color(0xFFFFFFFF);
  static const texto2 = Color(0xFFBCC3F2);
  static const papel = Color(0xFFF5F7FF);
  static const tinta = Color(0xFF10163F);
  static const caneta = Color(0xFF1B2A8C);
  static const filme = Color(0xFF231E1B);
  static const filmeTexto = Color(0xFFFFF4DC);
  static const amarelo = Color(0xFFFFD23F);
  static const amareloSombra = Color(0xFFC79D00);
  static const vermelho = Color(0xFFFF4D4D);
  static const vermelhoSombra = Color(0xFFB32424);
  static const menta = Color(0xFF3DDC97);

  /// Cores de disquete: uma por tema e uma por jogador.
  static const paleta = [
    Color(0xFF2F6BFF),
    Color(0xFF00A6A6),
    Color(0xFFFF7A00),
    Color(0xFF8A4FFF),
    Color(0xFF00B86B),
    Color(0xFFFF3D7F),
    Color(0xFFFFC21A),
    Color(0xFF00A3E0),
    Color(0xFFE14D2A),
    Color(0xFFC9A227),
  ];

  static Color doJogador(int i) => paleta[i % paleta.length];

  /// Texto escuro em fundo claro, branco em fundo escuro.
  static Color tintaSobre(Color fundo) => fundo.computeLuminance() > 0.3 ? tinta : texto;
}

/// A Anybody é uma fonte variável: em vez de um arquivo por peso, um arquivo
/// só com eixos contínuos de peso (wght 100–900) e largura (wdth 50–150).
TextStyle anybody({
  double tamanho = 17,
  double peso = 500,
  double largura = 100,
  Color? cor,
  double? altura,
}) => TextStyle(
  fontFamily: 'Anybody',
  fontSize: tamanho,
  color: cor,
  height: altura,
  fontWeight: FontWeight.values[((peso / 100).round() - 1).clamp(0, 8)],
  fontVariations: [FontVariation('wght', peso), FontVariation('wdth', largura)],
);

TextStyle marcador({double tamanho = 28, Color cor = Cores.caneta}) =>
    TextStyle(fontFamily: 'PermanentMarker', fontSize: tamanho, color: cor, height: 1.1);

ThemeData temaDoApp() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: Cores.amarelo,
      onPrimary: Cores.tinta,
      secondary: Cores.menta,
      surface: Cores.fundo,
      onSurface: Cores.texto,
      error: Cores.vermelho,
    ),
    scaffoldBackgroundColor: Cores.fundo,
  );

  // Todo texto do Material (campos, diálogos) também com peso explícito,
  // senão a Anybody usaria o peso padrão do arquivo (100, bem fino).
  TextStyle? ajustar(TextStyle? s, double peso) => s?.merge(anybody(tamanho: s.fontSize ?? 17, peso: peso));
  final t = base.textTheme;

  return base.copyWith(
    textTheme: t.copyWith(
      displayLarge: ajustar(t.displayLarge, 800),
      headlineMedium: ajustar(t.headlineMedium, 800),
      titleLarge: ajustar(t.titleLarge, 700),
      titleMedium: ajustar(t.titleMedium, 650),
      bodyLarge: ajustar(t.bodyLarge, 500),
      bodyMedium: ajustar(t.bodyMedium, 500),
      labelLarge: ajustar(t.labelLarge, 650),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Cores.papel,
      hintStyle: anybody(cor: const Color(0xFF7A82AE)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Cores.amarelo, width: 3),
      ),
      errorStyle: anybody(tamanho: 14, cor: Cores.vermelho),
    ),
    textSelectionTheme: const TextSelectionThemeData(cursorColor: Cores.tinta),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Cores.tinta : Colors.white,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Cores.amarelo : Cores.fundo3,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Cores.fundo2,
      titleTextStyle: anybody(tamanho: 22, peso: 800),
      contentTextStyle: anybody(cor: Cores.texto2),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Cores.menta,
      contentTextStyle: anybody(cor: Cores.tinta, peso: 650),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
