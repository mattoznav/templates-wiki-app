import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/widgets.dart';
import '../../core/format.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';

class AbilityScreen extends ConsumerWidget {
  const AbilityScreen({super.key, required this.slug});
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider).value;
    final ability = catalog?.abilityBySlug[slug];
    final p = context.palette;
    final detail = ref.watch(abilityDetailProvider(slug));

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 32),
        children: [
          _Pad(
            Text(
              'ABILITY${ability != null ? ' · GENERATION ${roman[ability.generation]}' : ''}',
              style: label(context),
            ),
          ),
          const SizedBox(height: 8),
          _Pad(Text(ability?.name ?? titleCase(slug), style: display(38))),
          if (ability?.effect != null) ...[
            const SizedBox(height: 14),
            _Pad(Text(ability!.effect!, style: TextStyle(fontSize: 16, color: p.ink2, height: 1.45))),
          ],
          const SizedBox(height: 20),
          detail.when(
            loading: () => const Padding(padding: EdgeInsets.all(40), child: LoadingView()),
            error: (e, _) => SizedBox(
              height: 260,
              child: ErrorView(error: e, onRetry: () => ref.invalidate(abilityDetailProvider(slug))),
            ),
            data: (d) {
              final regular = d.pokemon.where((x) => !x.hidden).toList();
              final hidden = d.pokemon.where((x) => x.hidden).toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (d.longEffect != null || d.flavor != null)
                    _Pad(
                      Panel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (d.longEffect != null && d.longEffect != ability?.effect) ...[
                              const Caption('In detail'),
                              const SizedBox(height: 4),
                              Text(d.longEffect!, style: TextStyle(color: p.ink2, height: 1.45)),
                              const SizedBox(height: 14),
                            ],
                            if (d.flavor != null) ...[
                              const Caption('In-game description'),
                              const SizedBox(height: 4),
                              Text(
                                d.flavor!,
                                style: display(17, weight: FontWeight.w400, style: FontStyle.italic, color: p.ink2),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  if (regular.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _Pad(Text('Pokémon with ${ability?.name ?? 'it'}', style: display(22))),
                    const SizedBox(height: 4),
                    for (final x in regular)
                      if (catalog?.speciesById[x.speciesId] case final e?) PokemonRow(e),
                  ],
                  if (hidden.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _Pad(Text('As a hidden ability', style: display(22))),
                    const SizedBox(height: 4),
                    for (final x in hidden)
                      if (catalog?.speciesById[x.speciesId] case final e?) PokemonRow(e, note: 'hidden'),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Pad extends StatelessWidget {
  const _Pad(this.child);
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: child);
}
