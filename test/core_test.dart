import 'package:fieldbook/core/catalog.dart';
import 'package:fieldbook/core/format.dart';
import 'package:fieldbook/core/models.dart';
import 'package:flutter_test/flutter_test.dart';

/// A cut-down answer to assets/catalog.graphql: two species, two moves, three types.
Map<String, dynamic> catalogJson() => {
  'species': [
    {
      'id': 25,
      'name': 'pikachu',
      'generation_id': 1,
      'is_legendary': false,
      'is_mythical': false,
      'names': [
        {'name': 'Pikachu', 'genus': 'Mouse Pokémon'},
      ],
      'pokemons': [
        {
          'id': 25,
          'types': [
            {
              'type': {'name': 'electric'},
            },
          ],
          'stats': [
            for (final v in [35, 55, 40, 50, 50, 90]) {'base_stat': v},
          ],
        },
      ],
    },
    {
      'id': 6,
      'name': 'charizard',
      'generation_id': 1,
      'is_legendary': false,
      'is_mythical': false,
      'names': [
        {'name': 'Charizard', 'genus': 'Flame Pokémon'},
      ],
      'pokemons': [
        {
          'id': 6,
          'types': [
            {
              'type': {'name': 'fire'},
            },
            {
              'type': {'name': 'flying'},
            },
          ],
          'stats': [
            for (final v in [78, 84, 78, 109, 85, 100]) {'base_stat': v},
          ],
        },
      ],
    },
  ],
  'moves': [
    {
      'id': 85,
      'name': 'thunderbolt',
      'power': 90,
      'accuracy': 100,
      'pp': 15,
      'priority': 0,
      'move_effect_chance': 10,
      'generation_id': 1,
      'type': {'name': 'electric'},
      'damageclass': {'name': 'special'},
      'names': [
        {'name': 'Thunderbolt'},
      ],
      'effect': {
        'texts': [
          {'short_effect': 'Has a chance to paralyze the target.'},
        ],
      },
    },
    {
      'id': 1000,
      'name': 'max-flare',
      'power': 100,
      'accuracy': null,
      'pp': 10,
      'priority': 0,
      'move_effect_chance': null,
      'generation_id': 8,
      'type': {'name': 'fire'},
      'damageclass': {'name': 'physical'},
      'names': [
        {'name': 'Max Flare'},
      ],
      'effect': null,
    },
  ],
  'types': [
    {
      'id': 10,
      'name': 'fire',
      'generation_id': 1,
      'names': [
        {'name': 'Fire'},
      ],
    },
    {
      'id': 13,
      'name': 'electric',
      'generation_id': 1,
      'names': [
        {'name': 'Electric'},
      ],
    },
    {
      'id': 3,
      'name': 'flying',
      'generation_id': 1,
      'names': [
        {'name': 'Flying'},
      ],
    },
  ],
  'efficacy': [
    {'damage_type_id': 13, 'target_type_id': 3, 'damage_factor': 200},
    {'damage_type_id': 13, 'target_type_id': 10, 'damage_factor': 100},
    {'damage_type_id': 10, 'target_type_id': 10, 'damage_factor': 50},
  ],
  'abilities': [
    {
      'id': 9,
      'name': 'static',
      'generation_id': 3,
      'names': [
        {'name': 'Static'},
      ],
      'texts': [],
    },
  ],
  'versiongroups': [
    {
      'name': 'sword-shield',
      'order': 22,
      'generation_id': 8,
      'versions': [
        {
          'name': 'sword',
          'names': [
            {'name': 'Sword'},
          ],
        },
        {
          'name': 'shield',
          'names': [
            {'name': 'Shield'},
          ],
        },
      ],
      'regions': [
        {
          'region': {'name': 'galar'},
        },
      ],
    },
    {
      'name': 'the-isle-of-armor',
      'order': 23,
      'generation_id': 8,
      'versions': [
        {
          'name': 'the-isle-of-armor-sword',
          'names': [
            {'name': 'Sword: The Isle of Armor'},
          ],
        },
        {
          'name': 'the-isle-of-armor-shield',
          'names': [
            {'name': 'Shield: The Isle of Armor'},
          ],
        },
      ],
      'regions': [],
    },
    {
      'name': 'scarlet-violet',
      'order': 27,
      'generation_id': 9,
      'versions': [
        {
          'name': 'scarlet',
          'names': [
            {'name': 'Scarlet'},
          ],
        },
        {
          'name': 'violet',
          'names': [
            {'name': 'Violet'},
          ],
        },
      ],
      'regions': [
        {
          'region': {'name': 'paldea'},
        },
      ],
    },
  ],
  'generations': [
    {
      'id': 1,
      'region': {'name': 'kanto'},
    },
  ],
};

Map<String, dynamic> pokemonJson() => {
  'id': 25,
  'name': 'pikachu',
  'height': 4,
  'weight': 60,
  'base_experience': 112,
  'types': [
    {
      'slot': 1,
      'type': {'name': 'electric'},
    },
  ],
  'stats': [
    for (final (i, s) in ['hp', 'attack', 'defense', 'special-attack', 'special-defense', 'speed'].indexed)
      {
        'base_stat': [35, 55, 40, 50, 50, 90][i],
        'stat': {'name': s},
      },
  ],
  'abilities': [
    {
      'slot': 3,
      'is_hidden': true,
      'ability': {'name': 'lightning-rod'},
    },
    {
      'slot': 1,
      'is_hidden': false,
      'ability': {'name': 'static'},
    },
  ],
  'sprites': {
    'other': {
      'official-artwork': {'front_default': 'https://example.com/25.png', 'front_shiny': null},
    },
  },
  'moves': [
    {
      'move': {'name': 'thunderbolt'},
      'version_group_details': [
        {
          'level_learned_at': 26,
          'version_group': {'name': 'sword-shield'},
          'move_learn_method': {'name': 'level-up'},
        },
        {
          'level_learned_at': 0,
          'version_group': {'name': 'scarlet-violet'},
          'move_learn_method': {'name': 'machine'},
        },
      ],
    },
    {
      'move': {'name': 'max-flare'},
      'version_group_details': [
        {
          'level_learned_at': 1,
          'version_group': {'name': 'sword-shield'},
          'move_learn_method': {'name': 'level-up'},
        },
      ],
    },
    {
      'move': {'name': 'unknown-move'},
      'version_group_details': [
        {
          'level_learned_at': 5,
          'version_group': {'name': 'sword-shield'},
          'move_learn_method': {'name': 'level-up'},
        },
      ],
    },
  ],
};

void main() {
  group('Catalog', () {
    final catalog = Catalog.fromJson(catalogJson());

    test('reads species with English names, types and stats', () {
      final pikachu = catalog.speciesById[25]!;
      expect(pikachu.name, 'Pikachu');
      expect(pikachu.genus, 'Mouse Pokémon');
      expect(pikachu.types, ['electric']);
      expect(pikachu.total, 320);
      expect(catalog.speciesBySlug['charizard']!.types, ['fire', 'flying']);
    });

    test('skips Max moves and restores the effect chance in the text', () {
      expect(catalog.moveBySlug.containsKey('max-flare'), isFalse);
      expect(catalog.moveBySlug['thunderbolt']!.effect, 'Has a 10% chance to paralyze the target.');
    });

    test('builds the type chart from efficacy rows', () {
      expect(catalog.effectiveness('electric', ['fire', 'flying']), 2);
      expect(catalog.effectiveness('fire', ['fire']), 0.5);
      expect(catalog.effectiveness('fire', ['electric']), 1);
    });

    test('names games, folding expansions into one title', () {
      expect(catalog.gameName('sword-shield'), 'Sword and Shield');
      expect(catalog.gameName('the-isle-of-armor'), 'The Isle of Armor');
      expect(catalog.games.firstWhere((g) => g.slug == 'scarlet-violet').year, 2022);
      expect(catalog.versionNames['scarlet'], 'Scarlet');
    });
  });

  group('PokemonDetail', () {
    final catalog = Catalog.fromJson(catalogJson());
    final pokemon = PokemonDetail.fromJson(pokemonJson());

    test('orders abilities by slot and converts units', () {
      expect(pokemon.abilities.map((a) => a.slug), ['static', 'lightning-rod']);
      expect(pokemon.abilities.last.hidden, isTrue);
      expect(pokemon.height, 0.4);
      expect(pokemon.weight, 6.0);
      expect(pokemon.total, 320);
    });

    test('takes the learnset from the latest game with level-up moves', () {
      final learnset = pokemon.learnset(catalog);
      // Scarlet and Violet only has a TM here, so Sword and Shield is the latest full learnset
      expect(learnset.game, 'sword-shield');
      expect(learnset.moves, hasLength(1));
      expect(learnset.moves.single.move.slug, 'thunderbolt');
      expect(learnset.moves.single.level, 26);
    });
  });

  group('describeEvolution', () {
    test('level, item and friendship conditions', () {
      expect(
        describeEvolution({
          'trigger': {'name': 'level-up'},
          'min_level': 16,
        }),
        'Level 16',
      );
      expect(
        describeEvolution({
          'trigger': {'name': 'use-item'},
          'item': {'name': 'thunder-stone'},
        }),
        'Use Thunder Stone',
      );
      expect(
        describeEvolution({
          'trigger': {'name': 'level-up'},
          'min_happiness': 160,
          'time_of_day': 'night',
        }),
        'Level up with high friendship at night',
      );
      expect(
        describeEvolution({
          'trigger': {'name': 'trade'},
          'held_item': {'name': 'kings-rock'},
        }),
        "Trade holding King's Rock",
      );
    });

    test('Alcremie collapses into one sentence', () {
      expect(
        describeEvolution({
          'trigger': {'name': 'spin'},
          'held_item': {'name': 'love-sweet'},
          'time_of_day': 'day',
        }),
        'Spin around holding a Sweet',
      );
    });
  });

  group('Variety labels', () {
    test('drop the species name from the form slug', () {
      const alola = Variety(slug: 'raichu-alola', id: 10100, isDefault: false, speciesSlug: 'raichu');
      const megaX = Variety(slug: 'charizard-mega-x', id: 10034, isDefault: false, speciesSlug: 'charizard');
      const gmax = Variety(slug: 'pikachu-gmax', id: 10199, isDefault: false, speciesSlug: 'pikachu');
      expect(alola.label, 'Alola');
      expect(megaX.label, 'Mega X');
      expect(gmax.label, 'Gigantamax');
    });
  });

  group('format', () {
    test('numbers and units', () {
      expect(dexNo(25), 'No. 0025');
      expect(formatHeight(1.7), '1.7 m · 5′07″');
      expect(multiplierLabel(0.25), '¼');
      expect(multiplierLabel(4), '4');
      expect(idFromUrl('https://pokeapi.co/api/v2/pokemon/25/'), 25);
    });
  });
}
