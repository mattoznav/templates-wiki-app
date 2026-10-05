import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../common/widgets.dart';
import '../../core/format.dart';
import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';

class EvolutionView extends ConsumerWidget {
  const EvolutionView({super.key, required this.species});
  final SpeciesDetail species;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chainId = species.evolutionChainId;
    if (chainId == null) {
      return EmptyState(icon: Icons.linear_scale, title: 'No evolution', message: '${species.name} does not evolve.');
    }
    return AsyncBody(
      provider: evolutionProvider(chainId),
      builder: (chain) {
        if (chain.into.isEmpty) {
          return EmptyState(
            icon: Icons.linear_scale,
            title: 'No evolution',
            message: '${species.name} does not evolve.',
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
          children: [
            Center(
              child: _Stage(node: chain, current: species.id),
            ),
          ],
        );
      },
    );
  }
}

class _Stage extends StatelessWidget {
  const _Stage({required this.node, required this.current, this.condition});

  final EvolutionNode node;
  final int current;
  final String? condition;

  @override
  Widget build(BuildContext context) {
    final children = [
      for (final child in node.into)
        _Stage(
          node: child,
          current: current,
          condition: child.conditions.isEmpty ? 'Evolves' : child.conditions.join('\nor '),
        ),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (condition != null) ...[
          Icon(Icons.arrow_downward, size: 18, color: context.palette.muted),
          const SizedBox(height: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 170),
            child: Text(
              condition!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: context.palette.ink2, height: 1.3),
            ),
          ),
          const SizedBox(height: 8),
        ],
        _Card(node: node, current: node.speciesId == current),
        if (children.length == 1) ...[const SizedBox(height: 10), children.first],
        if (children.length > 1) ...[
          const SizedBox(height: 10),
          Wrap(alignment: WrapAlignment.center, spacing: 12, runSpacing: 18, children: children),
        ],
      ],
    );
  }
}

class _Card extends ConsumerWidget {
  const _Card({required this.node, required this.current});
  final EvolutionNode node;
  final bool current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final entry = ref.watch(catalogProvider).value?.speciesById[node.speciesId];
    final color = typeColor(entry?.types.first ?? 'normal');
    return Material(
      color: tint(context, color, 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(color: current ? p.ink : p.line, width: current ? 2 : 1),
      ),
      child: InkWell(
        customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
        onTap: current ? null : () => context.pushReplacement('/pokemon/${node.speciesId}'),
        child: SizedBox(
          width: 130,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 12),
            child: Column(
              children: [
                SizedBox(height: 84, child: Artwork(entry?.artwork)),
                const SizedBox(height: 4),
                Text('#${pad(node.speciesId)}', style: mono(10.5, color: p.muted)),
                Text(
                  entry?.name ?? titleCase(node.speciesSlug),
                  style: display(15.5),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
