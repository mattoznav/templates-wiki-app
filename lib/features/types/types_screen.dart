import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../common/widgets.dart';
import '../../core/catalog.dart';
import '../../core/format.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';

class TypesScreen extends ConsumerWidget {
  const TypesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Types')),
      body: AsyncBody(
        provider: catalogProvider,
        builder: (catalog) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            Text(
              'Attacks deal double damage, half damage or nothing at all depending on the type they hit.',
              style: TextStyle(color: context.palette.ink2),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: MediaQuery.sizeOf(context).width > 600 ? 3 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.3,
              children: [for (final t in catalog.types) _TypeTile(type: t, catalog: catalog)],
            ),
            const SizedBox(height: 28),
            Text('Type chart', style: display(26)),
            const SizedBox(height: 4),
            Text('Rows attack, columns defend.', style: TextStyle(color: context.palette.muted)),
            const SizedBox(height: 12),
            _Chart(catalog: catalog),
          ],
        ),
      ),
    );
  }
}

class _TypeTile extends StatelessWidget {
  const _TypeTile({required this.type, required this.catalog});
  final TypeEntry type;
  final Catalog catalog;

  @override
  Widget build(BuildContext context) {
    final c = typeColor(type.slug);
    final count = catalog.species.where((s) => s.types.contains(type.slug)).length;
    return Material(
      color: tint(context, c, 0.14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: c.withValues(alpha: 0.4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/types/${type.slug}'),
        child: Row(
          children: [
            Container(width: 6, color: c),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(type.name, style: display(19)),
                    const SizedBox(height: 2),
                    Text('$count Pokémon', style: mono(11, color: context.palette.ink2)),
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

class _Chart extends StatelessWidget {
  const _Chart({required this.catalog});
  final Catalog catalog;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    const cell = 30.0;
    Widget box(Widget child, {Color? color}) => Container(
      width: cell,
      height: cell,
      margin: const EdgeInsets.all(1.5),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color ?? p.paper2, borderRadius: BorderRadius.circular(6)),
      child: child,
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(width: 74),
              for (final d in typeOrder)
                box(
                  Text(d.substring(0, 3).toUpperCase(), style: mono(8.5, color: Colors.white)),
                  color: typeColor(d),
                ),
            ],
          ),
          for (final a in typeOrder)
            Row(
              children: [
                GestureDetector(
                  onTap: () => context.push('/types/$a'),
                  child: Container(
                    width: 70,
                    height: cell,
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.only(left: 8),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: tint(context, typeColor(a), 0.18),
                      borderRadius: BorderRadius.circular(6),
                      border: Border(left: BorderSide(color: typeColor(a), width: 3)),
                    ),
                    child: Text(capitalize(a), style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                  ),
                ),
                for (final d in typeOrder)
                  Builder(
                    builder: (context) {
                      final m = catalog.chart[a]![d]!;
                      return box(
                        Text(m == 1 ? '' : multiplierLabel(m), style: mono(12, color: Colors.white)),
                        color: switch (m) {
                          2 => const Color(0xFF3F9B5A),
                          0.5 => const Color(0xFFC8553D),
                          0 => const Color(0xFF5B5F6B),
                          _ => null,
                        },
                      );
                    },
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
