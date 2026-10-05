import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api.dart';
import 'catalog.dart';
import 'models.dart';

/// The whole catalogue. Parsed in a background isolate: it holds about 2,300 entries.
final catalogProvider = FutureProvider<Catalog>((ref) async {
  final json = await ref.watch(apiProvider).catalog();
  return compute(Catalog.fromJson, json);
});

final speciesProvider = FutureProvider.family<SpeciesDetail, int>((ref, id) async {
  return SpeciesDetail.fromJson(await ref.watch(apiProvider).resource('pokemon-species/$id'));
});

final pokemonProvider = FutureProvider.family<PokemonDetail, int>((ref, id) async {
  return PokemonDetail.fromJson(await ref.watch(apiProvider).resource('pokemon/$id'));
});

final evolutionProvider = FutureProvider.family<EvolutionNode, int>((ref, id) async {
  final json = await ref.watch(apiProvider).resource('evolution-chain/$id');
  return EvolutionNode.fromJson(json['chain'] as Map);
});

final moveDetailProvider = FutureProvider.family<MoveDetail, String>((ref, slug) async {
  final catalog = await ref.watch(catalogProvider.future);
  return MoveDetail.fromJson(await ref.watch(apiProvider).resource('move/$slug'), catalog);
});

final abilityDetailProvider = FutureProvider.family<AbilityDetail, String>((ref, slug) async {
  final catalog = await ref.watch(catalogProvider.future);
  return AbilityDetail.fromJson(await ref.watch(apiProvider).resource('ability/$slug'), catalog);
});

/// Saved Pokémon, by species id, kept on the device.
final favouritesProvider = NotifierProvider<Favourites, Set<int>>(Favourites.new);

class Favourites extends Notifier<Set<int>> {
  static const _key = 'favourites';

  @override
  Set<int> build() {
    final saved = ref.watch(sharedPreferencesProvider).getStringList(_key) ?? const [];
    return saved.map(int.parse).toSet();
  }

  void toggle(int id) {
    state = state.contains(id) ? ({...state}..remove(id)) : {...state, id};
    ref.read(sharedPreferencesProvider).setStringList(_key, state.map((e) => '$e').toList());
  }
}

/// Light, dark or follow the system. Kept on the device.
final themeModeProvider = NotifierProvider<ThemeModeSetting, ThemeMode>(ThemeModeSetting.new);

class ThemeModeSetting extends Notifier<ThemeMode> {
  static const _key = 'theme';

  @override
  ThemeMode build() {
    final saved = ref.watch(sharedPreferencesProvider).getString(_key);
    return ThemeMode.values.firstWhere((m) => m.name == saved, orElse: () => ThemeMode.system);
  }

  void set(ThemeMode mode) {
    state = mode;
    ref.read(sharedPreferencesProvider).setString(_key, mode.name);
  }
}
