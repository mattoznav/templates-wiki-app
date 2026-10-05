import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../common/widgets.dart';
import '../../core/catalog.dart';
import '../../core/theme.dart';

/// One move in a list: optional level, name, type, category, power and accuracy.
class MoveRow extends StatelessWidget {
  const MoveRow({super.key, required this.move, this.leading, this.showEffect = false});

  final MoveEntry move;
  final String? leading;
  final bool showEffect;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      onTap: () => context.push('/moves/${move.slug}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            if (leading != null)
              SizedBox(
                width: 50,
                child: Text(leading!, style: mono(12.5, color: p.ink2)),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          move.name,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      CategoryMark(move.category, showLabel: false),
                    ],
                  ),
                  const SizedBox(height: 5),
                  if (showEffect && move.effect != null)
                    Text(
                      move.effect!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: p.muted),
                    )
                  else
                    TypeChip(move.type, small: true, link: false),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _Num(label: 'PWR', value: move.power?.toString() ?? '—'),
            _Num(label: 'ACC', value: move.accuracy == null ? '—' : '${move.accuracy}'),
            _Num(label: 'PP', value: move.pp?.toString() ?? '—'),
          ],
        ),
      ),
    );
  }
}

class _Num extends StatelessWidget {
  const _Num({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 42,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: mono(9, color: context.palette.muted, spacing: 0.5)),
        const SizedBox(height: 2),
        Text(value, style: mono(14)),
      ],
    ),
  );
}
