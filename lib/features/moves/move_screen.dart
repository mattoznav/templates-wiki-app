import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/widgets.dart';
import '../../core/format.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';

class MoveScreen extends ConsumerWidget {
  const MoveScreen({super.key, required this.slug});
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider).value;
    final move = catalog?.moveBySlug[slug];
    final p = context.palette;
    if (catalog == null || move == null) {
      return Scaffold(
        appBar: AppBar(),
        body: AsyncBody(provider: catalogProvider, builder: (_) => const SizedBox()),
      );
    }
    final color = typeColor(move.type);
    final detail = ref.watch(moveDetailProvider(slug));

    return Scaffold(
      appBar: AppBar(backgroundColor: tint(context, color, 0.14)),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            color: tint(context, color, 0.14),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(move.name, style: display(38)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    TypeChip(move.type),
                    CategoryMark(move.category),
                    Text('GENERATION ${roman[move.generation]}', style: label(context)),
                  ],
                ),
                if (move.effect != null) ...[
                  const SizedBox(height: 16),
                  Text(move.effect!, style: TextStyle(fontSize: 16, color: p.ink2, height: 1.45)),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
            child: Row(
              children: [
                _Fact(label: 'Power', value: move.power?.toString() ?? '—'),
                _Fact(label: 'Accuracy', value: move.accuracy == null ? '—' : '${move.accuracy}%'),
                _Fact(label: 'PP', value: move.pp?.toString() ?? '—'),
                _Fact(label: 'Priority', value: move.priority > 0 ? '+${move.priority}' : '${move.priority}'),
              ],
            ),
          ),
          detail.when(
            loading: () => const Padding(padding: EdgeInsets.all(40), child: LoadingView()),
            error: (e, _) => SizedBox(
              height: 260,
              child: ErrorView(error: e, onRetry: () => ref.invalidate(moveDetailProvider(slug))),
            ),
            data: (d) {
              final learners = [for (final id in d.learnedBy) ?catalog.speciesById[id]];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Panel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Caption('Target'),
                          const SizedBox(height: 4),
                          Text(d.target),
                          if (d.flavor != null) ...[
                            const SizedBox(height: 14),
                            const Caption('In-game description'),
                            const SizedBox(height: 4),
                            Text(
                              d.flavor!,
                              style: display(17, weight: FontWeight.w400, style: FontStyle.italic, color: p.ink2),
                            ),
                          ],
                          if (d.longEffect != null && d.longEffect != move.effect) ...[
                            const SizedBox(height: 14),
                            const Caption('In detail'),
                            const SizedBox(height: 4),
                            Text(d.longEffect!, style: TextStyle(color: p.ink2, height: 1.45)),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 26, 16, 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('Learned by', style: display(24)),
                        const Spacer(),
                        Text('${learners.length} SPECIES', style: label(context)),
                      ],
                    ),
                  ),
                  if (learners.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('No Pokémon learn this move in any recorded game.', style: TextStyle(color: p.muted)),
                    ),
                  for (final entry in learners) PokemonRow(entry),
                  const SizedBox(height: 32),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
      decoration: BoxDecoration(
        color: context.palette.card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: context.palette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Caption(label),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(value, style: display(24, weight: FontWeight.w500)),
          ),
        ],
      ),
    ),
  );
}
