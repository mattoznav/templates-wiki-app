import 'catalog.dart';
import 'config.dart';
import 'format.dart';

/// `pokemon-species/<id>`: what is shared by every form of a Pokémon.
class SpeciesDetail {
  SpeciesDetail({
    required this.id,
    required this.slug,
    required this.name,
    required this.genus,
    required this.flavor,
    required this.flavorVersion,
    required this.genderRate,
    required this.captureRate,
    required this.baseHappiness,
    required this.hatchCounter,
    required this.growthRate,
    required this.eggGroups,
    required this.habitat,
    required this.color,
    required this.shape,
    required this.evolutionChainId,
    required this.varieties,
    required this.isLegendary,
    required this.isMythical,
    required this.isBaby,
  });

  final int id;
  final String slug;
  final String name;
  final String? genus;
  final String? flavor;
  final String? flavorVersion;

  /// Chance of being female in eighths, or -1 when genderless.
  final int genderRate;
  final int captureRate;
  final int? baseHappiness;
  final int? hatchCounter;
  final String growthRate;
  final List<String> eggGroups;
  final String? habitat;
  final String? color;
  final String? shape;
  final int? evolutionChainId;
  final List<Variety> varieties;
  final bool isLegendary;
  final bool isMythical;
  final bool isBaby;

  factory SpeciesDetail.fromJson(Map<String, dynamic> json) {
    // Legends: Arceus entries are written as in-world notes, so prefer any other game
    final flavors = (json['flavor_text_entries'] as List)
        .cast<Map>()
        .where((e) => e['language']['name'] == 'en')
        .toList();
    final regular = flavors.where((e) => e['version']['name'] != 'legends-arceus').toList();
    final flavor = (regular.isNotEmpty ? regular : flavors).lastOrNull;
    final slug = json['name'] as String;
    return SpeciesDetail(
      id: json['id'] as int,
      slug: slug,
      name: english(json['names'] as List?) ?? titleCase(slug),
      genus: english(json['genera'] as List?, 'genus'),
      flavor: flavor == null ? null : cleanText(flavor['flavor_text'] as String),
      flavorVersion: flavor?['version']['name'] as String?,
      genderRate: json['gender_rate'] as int,
      captureRate: json['capture_rate'] as int,
      baseHappiness: json['base_happiness'] as int?,
      hatchCounter: json['hatch_counter'] as int?,
      growthRate: titleCase(json['growth_rate']['name'] as String),
      eggGroups: (json['egg_groups'] as List)
          .map((g) => (g as Map)['name'] == 'no-eggs' ? 'Undiscovered' : titleCase(g['name'] as String))
          .toList(),
      habitat: json['habitat'] == null ? null : titleCase(json['habitat']['name'] as String),
      color: json['color'] == null ? null : titleCase(json['color']['name'] as String),
      shape: json['shape'] == null ? null : titleCase(json['shape']['name'] as String),
      evolutionChainId: json['evolution_chain'] == null ? null : idFromUrl(json['evolution_chain']['url'] as String),
      varieties: (json['varieties'] as List)
          .map(
            (v) => Variety(
              slug: (v as Map)['pokemon']['name'] as String,
              id: idFromUrl(v['pokemon']['url'] as String),
              isDefault: v['is_default'] as bool,
              speciesSlug: slug,
            ),
          )
          .toList(),
      isLegendary: json['is_legendary'] as bool,
      isMythical: json['is_mythical'] as bool,
      isBaby: json['is_baby'] as bool,
    );
  }
}

class Variety {
  const Variety({required this.slug, required this.id, required this.isDefault, required this.speciesSlug});

  final String slug;
  final int id;
  final bool isDefault;
  final String speciesSlug;

  /// "raichu-alola" -> "Alola", "charizard-mega-x" -> "Mega X"
  String get label {
    if (isDefault) return 'Standard';
    final rest = slug.startsWith('$speciesSlug-') ? slug.substring(speciesSlug.length + 1) : slug;
    return titleCase(rest).replaceFirst('Gmax', 'Gigantamax');
  }
}

/// `pokemon/<id>`: one form, with its own types, stats, abilities and moves.
class PokemonDetail {
  PokemonDetail({
    required this.id,
    required this.slug,
    required this.types,
    required this.stats,
    required this.abilities,
    required this.height,
    required this.weight,
    required this.baseExperience,
    required this.artwork,
    required this.shinyArtwork,
    required this.rawMoves,
  });

  final int id;
  final String slug;
  final List<String> types;
  final List<int> stats;
  final List<({String slug, bool hidden})> abilities;
  final double height;
  final double weight;
  final int? baseExperience;
  final String? artwork;
  final String? shinyArtwork;
  final List<Map> rawMoves;

  int get total => stats.fold(0, (a, b) => a + b);

  factory PokemonDetail.fromJson(Map<String, dynamic> json) {
    const statOrder = ['hp', 'attack', 'defense', 'special-attack', 'special-defense', 'speed'];
    final stats = (json['stats'] as List).cast<Map>();
    final types = (json['types'] as List).cast<Map>().toList()
      ..sort((a, b) => (a['slot'] as int).compareTo(b['slot'] as int));
    final abilities = (json['abilities'] as List).cast<Map>().toList()
      ..sort((a, b) => (a['slot'] as int).compareTo(b['slot'] as int));
    final art = json['sprites']?['other']?['official-artwork'] as Map?;
    final id = json['id'] as int;
    return PokemonDetail(
      id: id,
      slug: json['name'] as String,
      types: types.map((t) => t['type']['name'] as String).toList(),
      stats: statOrder
          .map(
            (s) => stats.firstWhere((x) => x['stat']['name'] == s, orElse: () => {'base_stat': 0})['base_stat'] as int,
          )
          .toList(),
      abilities: abilities.map((a) => (slug: a['ability']['name'] as String, hidden: a['is_hidden'] as bool)).toList(),
      height: (json['height'] as int) / 10,
      weight: (json['weight'] as int) / 10,
      baseExperience: json['base_experience'] as int?,
      artwork: art?['front_default'] as String? ?? (id <= 1025 ? artworkUrl(id) : null),
      shinyArtwork: art?['front_shiny'] as String?,
      rawMoves: (json['moves'] as List).cast<Map>(),
    );
  }

  /// Moves in the most recent game where this form has a level-up learnset.
  Learnset learnset(Catalog catalog) {
    final counts = <String, int>{};
    for (final m in rawMoves) {
      for (final d in (m['version_group_details'] as List).cast<Map>()) {
        if (d['move_learn_method']['name'] != 'level-up') continue;
        final g = d['version_group']['name'] as String;
        counts[g] = (counts[g] ?? 0) + 1;
      }
    }
    final candidates = counts.entries.where((e) => e.value >= 2).map((e) => e.key).toList()
      ..sort((a, b) => (catalog.gameOrder[b] ?? 0).compareTo(catalog.gameOrder[a] ?? 0));
    if (candidates.isEmpty) return const Learnset(game: null, moves: []);
    final game = candidates.first;

    final moves = <LearnedMove>[];
    for (final m in rawMoves) {
      final info = catalog.moveBySlug[m['move']['name']];
      if (info == null) continue;
      final seen = <String>{};
      for (final d in (m['version_group_details'] as List).cast<Map>()) {
        if (d['version_group']['name'] != game) continue;
        final method = d['move_learn_method']['name'] as String;
        if (!const ['level-up', 'machine', 'egg', 'tutor'].contains(method)) continue;
        final level = d['level_learned_at'] as int;
        if (!seen.add('$method:$level')) continue;
        moves.add(LearnedMove(move: info, method: method, level: method == 'level-up' ? level : null));
      }
    }
    moves.sort(
      (a, b) => (a.level ?? 0).compareTo(b.level ?? 0) != 0
          ? (a.level ?? 0).compareTo(b.level ?? 0)
          : a.move.name.compareTo(b.move.name),
    );
    return Learnset(game: game, moves: moves);
  }
}

class Learnset {
  const Learnset({required this.game, required this.moves});
  final String? game;
  final List<LearnedMove> moves;
}

class LearnedMove {
  const LearnedMove({required this.move, required this.method, required this.level});
  final MoveEntry move;

  /// level-up, machine, egg or tutor
  final String method;
  final int? level;
}

/// One step of an evolution chain.
class EvolutionNode {
  EvolutionNode({required this.speciesSlug, required this.speciesId, required this.conditions, required this.into});

  final String speciesSlug;
  final int speciesId;
  final List<String> conditions;
  final List<EvolutionNode> into;

  factory EvolutionNode.fromJson(Map json) {
    final conditions = <String>{for (final d in (json['evolution_details'] as List).cast<Map>()) describeEvolution(d)}
      ..removeWhere((c) => c.isEmpty);
    return EvolutionNode(
      speciesSlug: json['species']['name'] as String,
      speciesId: idFromUrl(json['species']['url'] as String),
      conditions: conditions.toList(),
      into: (json['evolves_to'] as List).map((c) => EvolutionNode.fromJson(c as Map)).toList(),
    );
  }

  /// The chain as rows of stages, for a simple vertical layout.
  int get depth => into.isEmpty ? 1 : 1 + into.map((c) => c.depth).reduce((a, b) => a > b ? a : b);
}

const _itemNames = {
  'kings-rock': "King's Rock",
  'up-grade': 'Up-Grade',
  'dubious-disc': 'Dubious Disc',
  'scroll-of-darkness': 'Scroll of Darkness',
  'scroll-of-waters': 'Scroll of Waters',
};

String _item(Map ref) => _itemNames[ref['name']] ?? titleCase(ref['name'] as String);

/// A readable sentence for one set of evolution conditions.
String describeEvolution(Map d) {
  final parts = <String>[];
  final trigger = d['trigger']?['name'] as String?;
  switch (trigger) {
    case 'level-up':
      parts.add(d['min_level'] != null ? 'Level ${d['min_level']}' : 'Level up');
    case 'use-item':
      if (d['item'] != null) parts.add('Use ${_item(d['item'] as Map)}');
    case 'trade':
      parts.add('Trade');
    case 'shed':
      parts.add('Level 20 with a free party slot and a Poké Ball');
    case 'spin':
      return 'Spin around holding a Sweet';
    case 'tower-of-darkness':
      parts.add('Train in the Tower of Darkness');
    case 'tower-of-waters':
      parts.add('Train in the Tower of Waters');
    case 'three-critical-hits':
      parts.add('Land three critical hits in one battle');
    case 'take-damage':
      parts.add('Take ${d['min_damage_taken'] ?? 49}+ damage, then walk under a stone bridge');
    case 'agile-style-move':
      parts.add('Use ${titleCase((d['used_move']?['name'] as String?) ?? 'move')} 20 times in agile style');
    case 'strong-style-move':
      parts.add('Use ${titleCase((d['used_move']?['name'] as String?) ?? 'move')} 20 times in strong style');
    case 'recoil-damage':
      parts.add('Take 294 recoil damage without fainting');
    case 'use-move':
      parts.add(
        'Use ${titleCase((d['used_move']?['name'] as String?) ?? 'a move')} ${d['min_move_count'] ?? 20} times',
      );
    case 'gimmighoul-coins':
      parts.add('Collect 999 Gimmighoul Coins');
    case 'other':
      parts.add('Special condition');
    case null:
      break;
    default:
      parts.add(titleCase(trigger));
  }
  if (d['held_item'] != null) parts.add('holding ${_item(d['held_item'] as Map)}');
  if (d['min_happiness'] != null) parts.add('with high friendship');
  if (d['min_affection'] != null) parts.add('with high affection');
  if (d['min_beauty'] != null) parts.add('with high beauty');
  if (d['known_move'] != null) parts.add('knowing ${titleCase(d['known_move']['name'] as String)}');
  if (d['known_move_type'] != null) {
    parts.add('knowing a ${titleCase(d['known_move_type']['name'] as String)}-type move');
  }
  final time = d['time_of_day'] as String? ?? '';
  if (time == 'full-moon') {
    parts.add('under a full moon');
  } else if (time.isNotEmpty) {
    parts.add('at ${time == 'day' ? 'daytime' : time}');
  }
  if (d['gender'] == 1) parts.add('(female)');
  if (d['gender'] == 2) parts.add('(male)');
  if (d['location'] != null) parts.add('at ${titleCase(d['location']['name'] as String)}');
  if (d['needs_overworld_rain'] == true) parts.add('while raining');
  if (d['turn_upside_down'] == true) parts.add('holding the console upside down');
  if (d['party_species'] != null) parts.add('with ${titleCase(d['party_species']['name'] as String)} in the party');
  if (d['party_type'] != null) parts.add('with a ${titleCase(d['party_type']['name'] as String)}-type in the party');
  if (d['trade_species'] != null) parts.add('for ${titleCase(d['trade_species']['name'] as String)}');
  if (d['relative_physical_stats'] == 1) parts.add('(Attack > Defense)');
  if (d['relative_physical_stats'] == -1) parts.add('(Attack < Defense)');
  if (d['relative_physical_stats'] == 0) parts.add('(Attack = Defense)');
  if (d['min_steps'] != null) parts.add('after ${d['min_steps']} steps');
  return parts.join(' ');
}

/// `move/<name>`: the parts of a move that the catalogue does not carry.
class MoveDetail {
  MoveDetail({required this.flavor, required this.target, required this.longEffect, required this.learnedBy});

  final String? flavor;
  final String target;
  final String? longEffect;

  /// Species ids (alternate forms are folded into their species).
  final List<int> learnedBy;

  factory MoveDetail.fromJson(Map<String, dynamic> json, Catalog catalog) {
    final flavors = (json['flavor_text_entries'] as List).cast<Map>().where((e) => e['language']['name'] == 'en');
    final effect = (json['effect_entries'] as List).cast<Map>().where((e) => e['language']['name'] == 'en').firstOrNull;
    final chance = json['effect_chance'];
    final ids = <int>{};
    for (final p in (json['learned_by_pokemon'] as List).cast<Map>()) {
      final id = idFromUrl(p['url'] as String);
      if (catalog.speciesById.containsKey(id)) {
        ids.add(id);
      } else {
        // Forms use ids above 10000; match them to their species by name
        final base = (p['name'] as String).split('-').first;
        final species = catalog.speciesBySlug[base];
        if (species != null) ids.add(species.id);
      }
    }
    return MoveDetail(
      flavor: flavors.isEmpty ? null : cleanText(flavors.last['flavor_text'] as String),
      target: titleCase(json['target']['name'] as String).replaceAll('Pokemon', 'Pokémon'),
      longEffect: effect == null
          ? null
          : cleanText((effect['effect'] as String).replaceAll(r'$effect_chance', '${chance ?? ''}')),
      learnedBy: ids.toList()..sort(),
    );
  }
}

/// `ability/<name>`: full description and who has it.
class AbilityDetail {
  AbilityDetail({required this.longEffect, required this.flavor, required this.pokemon});

  final String? longEffect;
  final String? flavor;
  final List<({int speciesId, bool hidden})> pokemon;

  factory AbilityDetail.fromJson(Map<String, dynamic> json, Catalog catalog) {
    final flavors = (json['flavor_text_entries'] as List).cast<Map>().where((e) => e['language']['name'] == 'en');
    final effect = (json['effect_entries'] as List).cast<Map>().where((e) => e['language']['name'] == 'en').firstOrNull;
    final seen = <int>{};
    final pokemon = <({int speciesId, bool hidden})>[];
    for (final p in (json['pokemon'] as List).cast<Map>()) {
      final id = idFromUrl(p['pokemon']['url'] as String);
      if (!catalog.speciesById.containsKey(id) || !seen.add(id)) continue;
      pokemon.add((speciesId: id, hidden: p['is_hidden'] as bool));
    }
    pokemon.sort((a, b) => a.speciesId.compareTo(b.speciesId));
    return AbilityDetail(
      longEffect: effect == null ? null : cleanText(effect['effect'] as String),
      flavor: flavors.isEmpty ? null : cleanText(flavors.last['flavor_text'] as String),
      pokemon: pokemon,
    );
  }
}
