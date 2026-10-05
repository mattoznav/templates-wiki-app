import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/widgets.dart';
import '../../core/format.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../moves/move_row.dart';

class TypeScreen extends ConsumerWidget {
  const TypeScreen({super.key, required this.slug});
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider).value;
    final type = catalog?.typeBySlug[slug];
    if (catalog == null || type == null) {
      return Scaffold(
        appBar: AppBar(),
        body: AsyncBody(provider: catalogProvider, builder: (_) => const SizedBox()),
      );
    }
    final c = typeColor(slug);
    final p = context.palette;
    List<String> attack(double m) => typeOrder.where((d) => catalog.chart[slug]![d] == m).toList();
    List<String> defend(double m) => typeOrder.where((a) => catalog.chart[a]![slug] == m).toList();
    final pokemon = catalog.species.where((s) => s.types.contains(slug)).toList();
    final moves = catalog.moves.where((m) => m.type == slug).toList();

    Widget relation(String label, List<String> types) => Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Caption(label),
          const SizedBox(height: 6),
          types.isEmpty ? Text('Nothing', style: TextStyle(color: p.muted)) : TypeRow(types),
        ],
      ),
    );

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: tint(context, c, 0.16),
          title: Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(color: c, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Text(type.name),
            ],
          ),
          bottom: TabBar(
            labelColor: p.ink,
            unselectedLabelColor: p.muted,
            indicatorColor: c,
            dividerColor: p.line,
            tabs: [
              const Tab(text: 'Matchups'),
              Tab(text: 'Pokémon · ${pokemon.length}'),
              Tab(text: 'Moves · ${moves.length}'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Introduced in Generation ${roman[type.generation]}.', style: TextStyle(color: p.ink2)),
                const SizedBox(height: 14),
                Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Attacking', style: display(22)),
                      relation('Super effective against', attack(2)),
                      relation('Not very effective against', attack(0.5)),
                      relation('No effect on', attack(0)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Defending', style: display(22)),
                      relation('Weak to', defend(2)),
                      relation('Resists', defend(0.5)),
                      relation('Immune to', defend(0)),
                    ],
                  ),
                ),
              ],
            ),
            ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: pokemon.length,
              itemBuilder: (_, i) => PokemonRow(pokemon[i]),
            ),
            ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: moves.length,
              separatorBuilder: (_, _) => Divider(indent: 16, endIndent: 16, color: p.line),
              itemBuilder: (_, i) => MoveRow(move: moves[i], showEffect: true),
            ),
          ],
        ),
      ),
    );
  }
}
