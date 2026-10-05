import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../common/widgets.dart';
import '../../core/catalog.dart';
import '../../core/format.dart';
import '../../core/theme.dart';

/// Damage taken from each of the 18 attacking types, plus a written summary.
class MatchupsView extends StatelessWidget {
  const MatchupsView({super.key, required this.types, required this.catalog});

  final List<String> types;
  final Catalog catalog;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final rows = [for (final t in typeOrder) (type: t, m: catalog.effectiveness(t, types))];
    String list(Iterable<({String type, double m})> items) =>
        items.isEmpty ? 'Nothing' : items.map((r) => '${capitalize(r.type)} ×${multiplierLabel(r.m)}').join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, c) {
            const columns = 6;
            final w = (c.maxWidth - (columns - 1) * 6) / columns;
            return Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final r in rows)
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => context.push('/types/${r.type}'),
                    child: Container(
                      width: w,
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: r.m == 0
                            ? p.paper2
                            : r.m >= 4
                            ? Color.alphaBlend(const Color(0xFFD9483C).withValues(alpha: 0.22), p.card)
                            : tint(context, typeColor(r.type), 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: r.m >= 4 ? const Color(0xFFD9483C) : typeColor(r.type).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            r.type.substring(0, 3).toUpperCase(),
                            style: mono(10, color: Color.lerp(typeColor(r.type), p.ink, 0.4), spacing: 0.5),
                          ),
                          const SizedBox(height: 2),
                          SizedBox(
                            height: 18,
                            child: Text(
                              r.m == 1 ? '' : multiplierLabel(r.m),
                              style: mono(
                                14,
                                color: r.m > 1
                                    ? const Color(0xFFC7362B)
                                    : r.m < 1
                                    ? const Color(0xFF2F8A5F)
                                    : p.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        _Line(label: 'Weak to', text: list(rows.where((r) => r.m > 1))),
        _Line(label: 'Resists', text: list(rows.where((r) => r.m > 0 && r.m < 1))),
        if (rows.any((r) => r.m == 0))
          _Line(label: 'Immune to', text: rows.where((r) => r.m == 0).map((r) => capitalize(r.type)).join(', ')),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.text});
  final String label;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 86,
          child: Padding(padding: const EdgeInsets.only(top: 2), child: Caption(label)),
        ),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
      ],
    ),
  );
}
