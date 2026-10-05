const typeOrder = [
  'normal',
  'fire',
  'water',
  'electric',
  'grass',
  'ice',
  'fighting',
  'poison',
  'ground',
  'flying',
  'psychic',
  'bug',
  'rock',
  'ghost',
  'dragon',
  'dark',
  'steel',
  'fairy',
];

const statLabels = ['HP', 'Attack', 'Defense', 'Sp. Atk', 'Sp. Def', 'Speed'];

const roman = ['', 'I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X'];

String titleCase(String slug) =>
    slug.split('-').where((w) => w.isNotEmpty).map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');

String capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

String pad(int id) => id.toString().padLeft(4, '0');
String dexNo(int id) => 'No. ${pad(id)}';

String formatHeight(double m) {
  final inches = (m * 39.3701).round();
  return '${m.toStringAsFixed(1)} m · ${inches ~/ 12}′${(inches % 12).toString().padLeft(2, '0')}″';
}

String formatWeight(double kg) => '${kg.toStringAsFixed(1)} kg · ${(kg * 2.20462).toStringAsFixed(1)} lb';

String percent(double n) => n == n.roundToDouble() ? '${n.round()}%' : '${n.toStringAsFixed(1)}%';

String multiplierLabel(double m) => switch (m) {
  0 => '0',
  0.25 => '¼',
  0.5 => '½',
  _ => m == m.roundToDouble() ? '${m.round()}' : '$m',
};

/// The last path segment of a PokéAPI url, as a number: `.../pokemon/25/` -> 25.
int idFromUrl(String url) => int.parse(url.split('/').where((s) => s.isNotEmpty).last);

String cleanText(String text) =>
    text.replaceAll(RegExp(r'[\f\n\r­]+'), ' ').replaceAll(RegExp(r'\s+'), ' ').replaceAll('POKéMON', 'Pokémon').trim();

/// English entry from a PokéAPI list of localised objects.
String? english(List<dynamic>? entries, [String key = 'name']) {
  for (final e in entries ?? const []) {
    if ((e as Map)['language']?['name'] == 'en') return e[key] as String?;
  }
  return null;
}
