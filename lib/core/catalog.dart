import 'config.dart';
import 'format.dart';

/// Everything the lists need, loaded with a single GraphQL query
/// (assets/catalog.graphql) and kept on disk.
class Catalog {
  Catalog({
    required this.species,
    required this.moves,
    required this.types,
    required this.abilities,
    required this.games,
    required this.generations,
    required this.chart,
    required this.versionNames,
  }) : speciesById = {for (final s in species) s.id: s},
       speciesBySlug = {for (final s in species) s.slug: s},
       moveBySlug = {for (final m in moves) m.slug: m},
       abilityBySlug = {for (final a in abilities) a.slug: a},
       typeBySlug = {for (final t in types) t.slug: t},
       gameOrder = {for (final g in games) g.slug: g.order};

  final List<SpeciesEntry> species;
  final List<MoveEntry> moves;
  final List<TypeEntry> types;
  final List<AbilityEntry> abilities;
  final List<GameEntry> games;
  final List<GenerationEntry> generations;

  /// chart[attacker][defender] = damage multiplier
  final Map<String, Map<String, double>> chart;

  /// Version slug ("lets-go-pikachu") to English name ("Let's Go, Pikachu!")
  final Map<String, String> versionNames;

  final Map<int, SpeciesEntry> speciesById;
  final Map<String, SpeciesEntry> speciesBySlug;
  final Map<String, MoveEntry> moveBySlug;
  final Map<String, AbilityEntry> abilityBySlug;
  final Map<String, TypeEntry> typeBySlug;
  final Map<String, int> gameOrder;

  /// Damage multiplier of an [attacker] move against a Pokémon of [defenders] types.
  double effectiveness(String attacker, List<String> defenders) =>
      defenders.fold(1.0, (m, d) => m * (chart[attacker]?[d] ?? 1));

  String gameName(String slug) {
    for (final g in games) {
      if (g.slug == slug) return g.name;
    }
    return titleCase(slug);
  }

  factory Catalog.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> list(String key) =>
        (json[key] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    String? firstName(Map<String, dynamic> item, [String key = 'names', String field = 'name']) {
      final names = item[key] as List?;
      return names == null || names.isEmpty ? null : (names.first as Map)[field] as String?;
    }

    final types =
        list('types')
            .where((t) => typeOrder.contains(t['name']))
            .map(
              (t) => TypeEntry(
                slug: t['name'] as String,
                name: firstName(t) ?? titleCase(t['name'] as String),
                generation: t['generation_id'] as int,
              ),
            )
            .toList()
          ..sort((a, b) => typeOrder.indexOf(a.slug).compareTo(typeOrder.indexOf(b.slug)));

    final typeById = {for (final t in list('types')) t['id'] as int: t['name'] as String};
    final chart = {
      for (final a in typeOrder) a: {for (final d in typeOrder) d: 1.0},
    };
    for (final e in list('efficacy')) {
      final a = typeById[e['damage_type_id']];
      final d = typeById[e['target_type_id']];
      if (a != null && d != null) chart[a]![d] = (e['damage_factor'] as int) / 100;
    }

    final species = list('species').map((s) {
      final pokemon = (s['pokemons'] as List).isEmpty
          ? null
          : Map<String, dynamic>.from((s['pokemons'] as List).first as Map);
      final stats = pokemon == null
          ? List.filled(6, 0)
          : (pokemon['stats'] as List).map((x) => (x as Map)['base_stat'] as int).toList();
      return SpeciesEntry(
        id: s['id'] as int,
        slug: s['name'] as String,
        name: firstName(s) ?? titleCase(s['name'] as String),
        genus: firstName(s, 'names', 'genus'),
        generation: s['generation_id'] as int,
        types: pokemon == null
            ? const ['normal']
            : (pokemon['types'] as List).map((t) => (t as Map)['type']['name'] as String).toList(),
        stats: stats,
        isLegendary: s['is_legendary'] as bool,
        isMythical: s['is_mythical'] as bool,
      );
    }).toList();

    final moves = list('moves')
        .where((m) {
          final name = m['name'] as String;
          return !name.startsWith('max-') && !name.startsWith('g-max-') && typeOrder.contains(m['type']?['name']);
        })
        .map((m) {
          final chance = m['move_effect_chance'] as int?;
          final texts = (m['effect']?['texts'] as List?) ?? const [];
          var effect = texts.isEmpty ? null : cleanText((texts.first as Map)['short_effect'] as String);
          if (effect != null) {
            effect = effect.replaceAll(r'$effect_chance', '${chance ?? ''}');
            // Some newer texts say "has a chance" and keep the number only in move_effect_chance
            if (chance != null && !effect.contains('%')) {
              effect = effect.replaceFirst(RegExp(r'\ba chance\b', caseSensitive: false), 'a $chance% chance');
            }
          }
          return MoveEntry(
            id: m['id'] as int,
            slug: m['name'] as String,
            name: firstName(m) ?? titleCase(m['name'] as String),
            type: m['type']['name'] as String,
            category: (m['damageclass']?['name'] as String?) ?? 'status',
            power: m['power'] as int?,
            accuracy: m['accuracy'] as int?,
            pp: m['pp'] as int?,
            priority: (m['priority'] as int?) ?? 0,
            generation: (m['generation_id'] as int?) ?? 0,
            effect: effect,
          );
        })
        .toList();
    // Z-Moves come in a physical and a special version with the same name
    final nameCounts = <String, int>{};
    for (final m in moves) {
      nameCounts[m.name] = (nameCounts[m.name] ?? 0) + 1;
    }
    for (var i = 0; i < moves.length; i++) {
      final m = moves[i];
      if (nameCounts[m.name]! > 1) moves[i] = m.withName('${m.name} (${capitalize(m.category)})');
    }
    moves.sort((a, b) => a.name.compareTo(b.name));

    final abilities = list('abilities').map((a) {
      final texts = a['texts'] as List;
      return AbilityEntry(
        slug: a['name'] as String,
        name: firstName(a) ?? titleCase(a['name'] as String),
        generation: (a['generation_id'] as int?) ?? 0,
        effect: texts.isEmpty ? null : cleanText((texts.first as Map)['short_effect'] as String),
      );
    }).toList()..sort((a, b) => a.name.compareTo(b.name));

    final versionNames = <String, String>{};
    final games = list('versiongroups').map((g) {
      final versions = (g['versions'] as List).map((v) => Map<String, dynamic>.from(v as Map)).toList();
      final names = <String>[];
      for (final v in versions) {
        final name = firstName(v) ?? titleCase(v['name'] as String);
        versionNames[v['name'] as String] = name;
        names.add(name);
      }
      final facts = gameFacts[g['name']];
      return GameEntry(
        slug: g['name'] as String,
        name: gameDisplayName(names),
        generation: g['generation_id'] as int,
        order: g['order'] as int,
        regions: (g['regions'] as List).map((r) => titleCase((r as Map)['region']['name'] as String)).toList(),
        year: facts?.$1,
        platform: facts?.$2,
        kind: facts?.$3 ?? 'other',
      );
    }).toList();

    final counts = <int, int>{};
    final first = <int, int>{};
    for (final s in species) {
      counts[s.generation] = (counts[s.generation] ?? 0) + 1;
      first[s.generation] = first[s.generation] == null || s.id < first[s.generation]! ? s.id : first[s.generation]!;
    }
    final generations = list('generations')
        .map(
          (g) => GenerationEntry(
            number: g['id'] as int,
            region: titleCase(g['region']['name'] as String),
            speciesCount: counts[g['id']] ?? 0,
            firstSpecies: first[g['id']] ?? 1,
          ),
        )
        .toList();

    return Catalog(
      species: species,
      moves: moves,
      types: types,
      abilities: abilities,
      games: games,
      generations: generations,
      chart: chart,
      versionNames: versionNames,
    );
  }
}

/// Expansions are listed once per base game ("Sword: The Isle of Armor"), so keep the shared part.
String gameDisplayName(List<String> versions) {
  final suffixes = versions.map((n) => n.contains(': ') ? n.split(': ')[1] : '').toSet();
  if (versions.length > 1 && suffixes.length == 1 && suffixes.first.isNotEmpty) return suffixes.first;
  return versions.join(' and ');
}

/// Release year, platform and kind of each game: PokéAPI does not carry them.
const gameFacts = <String, (int, String, String)>{
  'red-green-japan': (1996, 'Game Boy', 'original'),
  'blue-japan': (1996, 'Game Boy', 'original'),
  'red-blue': (1998, 'Game Boy', 'original'),
  'yellow': (1998, 'Game Boy', 'original'),
  'gold-silver': (1999, 'Game Boy Color', 'original'),
  'crystal': (2000, 'Game Boy Color', 'original'),
  'ruby-sapphire': (2002, 'Game Boy Advance', 'original'),
  'emerald': (2004, 'Game Boy Advance', 'original'),
  'colosseum': (2003, 'GameCube', 'spin-off'),
  'xd': (2005, 'GameCube', 'spin-off'),
  'firered-leafgreen': (2004, 'Game Boy Advance', 'remake'),
  'diamond-pearl': (2006, 'Nintendo DS', 'original'),
  'platinum': (2008, 'Nintendo DS', 'original'),
  'heartgold-soulsilver': (2009, 'Nintendo DS', 'remake'),
  'black-white': (2010, 'Nintendo DS', 'original'),
  'black-2-white-2': (2012, 'Nintendo DS', 'original'),
  'x-y': (2013, 'Nintendo 3DS', 'original'),
  'omega-ruby-alpha-sapphire': (2014, 'Nintendo 3DS', 'remake'),
  'sun-moon': (2016, 'Nintendo 3DS', 'original'),
  'ultra-sun-ultra-moon': (2017, 'Nintendo 3DS', 'original'),
  'lets-go-pikachu-lets-go-eevee': (2018, 'Nintendo Switch', 'remake'),
  'sword-shield': (2019, 'Nintendo Switch', 'original'),
  'the-isle-of-armor': (2020, 'Nintendo Switch', 'expansion'),
  'the-crown-tundra': (2020, 'Nintendo Switch', 'expansion'),
  'brilliant-diamond-shining-pearl': (2021, 'Nintendo Switch', 'remake'),
  'legends-arceus': (2022, 'Nintendo Switch', 'original'),
  'scarlet-violet': (2022, 'Nintendo Switch', 'original'),
  'the-teal-mask': (2023, 'Nintendo Switch', 'expansion'),
  'the-indigo-disk': (2023, 'Nintendo Switch', 'expansion'),
  'legends-za': (2025, 'Nintendo Switch', 'original'),
  'mega-dimension': (2025, 'Nintendo Switch', 'expansion'),
};

class SpeciesEntry {
  const SpeciesEntry({
    required this.id,
    required this.slug,
    required this.name,
    required this.genus,
    required this.generation,
    required this.types,
    required this.stats,
    required this.isLegendary,
    required this.isMythical,
  });

  final int id;
  final String slug;
  final String name;
  final String? genus;
  final int generation;
  final List<String> types;
  final List<int> stats;
  final bool isLegendary;
  final bool isMythical;

  int get total => stats.fold(0, (a, b) => a + b);
  String get artwork => artworkUrl(id);
  String get sprite => spriteUrl(id);
}

class MoveEntry {
  const MoveEntry({
    required this.id,
    required this.slug,
    required this.name,
    required this.type,
    required this.category,
    required this.power,
    required this.accuracy,
    required this.pp,
    required this.priority,
    required this.generation,
    required this.effect,
  });

  final int id;
  final String slug;
  final String name;
  final String type;

  /// physical, special or status
  final String category;
  final int? power;
  final int? accuracy;
  final int? pp;
  final int priority;
  final int generation;
  final String? effect;

  MoveEntry withName(String name) => MoveEntry(
    id: id,
    slug: slug,
    name: name,
    type: type,
    category: category,
    power: power,
    accuracy: accuracy,
    pp: pp,
    priority: priority,
    generation: generation,
    effect: effect,
  );
}

class TypeEntry {
  const TypeEntry({required this.slug, required this.name, required this.generation});
  final String slug;
  final String name;
  final int generation;
}

class AbilityEntry {
  const AbilityEntry({required this.slug, required this.name, required this.generation, required this.effect});
  final String slug;
  final String name;
  final int generation;
  final String? effect;
}

class GameEntry {
  const GameEntry({
    required this.slug,
    required this.name,
    required this.generation,
    required this.order,
    required this.regions,
    required this.year,
    required this.platform,
    required this.kind,
  });

  final String slug;
  final String name;
  final int generation;
  final int order;
  final List<String> regions;
  final int? year;
  final String? platform;

  /// original, remake, expansion, spin-off or other
  final String kind;
}

class GenerationEntry {
  const GenerationEntry({
    required this.number,
    required this.region,
    required this.speciesCount,
    required this.firstSpecies,
  });

  final int number;
  final String region;
  final int speciesCount;
  final int firstSpecies;
}
