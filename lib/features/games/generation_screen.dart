import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/widgets.dart';
import '../../core/format.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';

class GenerationScreen extends ConsumerWidget {
  const GenerationScreen({super.key, required this.number});
  final int number;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider).value;
    if (catalog == null) {
      return Scaffold(
        appBar: AppBar(),
        body: AsyncBody(provider: catalogProvider, builder: (_) => const SizedBox()),
      );
    }
    final generation = catalog.generations.firstWhere((g) => g.number == number);
    final species = catalog.species.where((s) => s.generation == number).toList();
    final legendary = species.where((s) => s.isLegendary || s.isMythical).length;
    final moves = catalog.moves.where((m) => m.generation == number).length;
    final abilities = catalog.abilities.where((a) => a.generation == number).length;
    final years = catalog.games.where((g) => g.generation == number && g.year != null).map((g) => g.year!).toList()
      ..sort();

    return Scaffold(
      appBar: AppBar(title: Text('Generation ${roman[number]}')),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(generation.region, style: display(40)),
                  const SizedBox(height: 6),
                  Text(
                    [
                      if (years.isNotEmpty)
                        years.first == years.last ? '${years.first}' : '${years.first}–${years.last}',
                      '$legendary legendary or mythical',
                    ].join(' · '),
                    style: TextStyle(color: context.palette.ink2),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      _Count(label: 'Species', value: species.length),
                      _Count(label: 'Moves', value: moves),
                      _Count(label: 'Abilities', value: abilities),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text('Pokémon introduced', style: display(22)),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.78,
              ),
              itemCount: species.length,
              itemBuilder: (_, i) => PokemonCard(species[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Caption(label),
        const SizedBox(height: 2),
        Text('$value', style: display(30, weight: FontWeight.w500)),
      ],
    ),
  );
}
