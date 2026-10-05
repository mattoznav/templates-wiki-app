import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../common/widgets.dart';
import '../../core/catalog.dart';
import '../../core/config.dart';
import '../../core/format.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';

class GamesScreen extends ConsumerWidget {
  const GamesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Games')),
      body: AsyncBody(
        provider: catalogProvider,
        builder: (catalog) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            Text(
              'Nine generations, each with a region, new Pokémon and new mechanics.',
              style: TextStyle(color: context.palette.ink2),
            ),
            const SizedBox(height: 8),
            for (final g in catalog.generations) _Generation(generation: g, catalog: catalog),
          ],
        ),
      ),
    );
  }
}

class _Generation extends StatelessWidget {
  const _Generation({required this.generation, required this.catalog});
  final GenerationEntry generation;
  final Catalog catalog;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final games = catalog.games.where((g) => g.generation == generation.number).toList()
      ..sort(
        (a, b) => (a.year ?? 9999) != (b.year ?? 9999)
            ? (a.year ?? 9999).compareTo(b.year ?? 9999)
            : a.order.compareTo(b.order),
      );
    final partners = [0, 3, 6].map((i) => generation.firstSpecies + i).toList();

    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.push('/generations/${generation.number}'),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 52,
                    child: Text(roman[generation.number], style: mono(26, color: p.accent)),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(generation.region, style: display(26)),
                        Text('${generation.speciesCount} NEW SPECIES', style: label(context)),
                      ],
                    ),
                  ),
                  for (final id in partners)
                    SizedBox(width: 40, height: 40, child: Artwork(spriteUrl(id), pixel: true)),
                  Icon(Icons.chevron_right, color: p.muted),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          for (final g in games) _GameTile(game: g),
          Divider(height: 28, color: p.line),
        ],
      ),
    );
  }
}

class _GameTile extends StatelessWidget {
  const _GameTile({required this.game});
  final GameEntry game;

  static const kinds = {
    'original': ('Main game', Color(0xFFC9432C)),
    'remake': ('Remake', Color(0xFF5A7FE0)),
    'expansion': ('Expansion', Color(0xFF3FAE7C)),
    'spin-off': ('Spin-off', Color(0xFF9A9A88)),
    'other': ('Other', Color(0xFF9A9A88)),
  };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final kind = kinds[game.kind] ?? kinds['other']!;
    final title = game.name.startsWith('Let') || game.name.startsWith('The') ? game.name : 'Pokémon ${game.name}';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: kind.$2),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: display(16.5)),
                          const SizedBox(height: 3),
                          Text(
                            [
                              game.platform ?? 'Platform not listed',
                              if (game.regions.isNotEmpty) game.regions.join(', '),
                            ].join(' · '),
                            style: TextStyle(fontSize: 12.5, color: p.muted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(game.year?.toString() ?? '—', style: mono(13, color: p.ink2)),
                        const SizedBox(height: 3),
                        Text(kind.$1.toUpperCase(), style: mono(9.5, color: p.muted, spacing: 0.6)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
