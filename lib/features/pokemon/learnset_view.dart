import 'package:flutter/material.dart';

import '../../common/widgets.dart';
import '../../core/catalog.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../moves/move_row.dart';

const _methods = {'level-up': 'Level up', 'machine': 'TM', 'egg': 'Egg', 'tutor': 'Tutor'};

class LearnsetView extends StatefulWidget {
  const LearnsetView({super.key, required this.learnset, required this.catalog});
  final Learnset learnset;
  final Catalog catalog;

  @override
  State<LearnsetView> createState() => _LearnsetViewState();
}

class _LearnsetViewState extends State<LearnsetView> {
  String _method = 'level-up';

  @override
  Widget build(BuildContext context) {
    final groups = {for (final m in _methods.keys) m: widget.learnset.moves.where((l) => l.method == m).toList()}
      ..removeWhere((_, v) => v.isEmpty);
    if (groups.isEmpty) {
      return const EmptyState(
        icon: Icons.bolt_outlined,
        title: 'No learnset',
        message: 'No moves are recorded for this form.',
      );
    }
    final method = groups.containsKey(_method) ? _method : groups.keys.first;
    final rows = [...groups[method]!];
    if (method != 'level-up') rows.sort((a, b) => a.move.name.compareTo(b.move.name));

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<String>(
                    showSelectedIcon: false,
                    segments: [
                      for (final m in groups.keys)
                        ButtonSegment(value: m, label: Text('${_methods[m]} · ${groups[m]!.length}')),
                    ],
                    selected: {method},
                    onSelectionChanged: (s) => setState(() => _method = s.first),
                  ),
                ),
                if (widget.learnset.game != null) ...[
                  const SizedBox(height: 10),
                  Caption('Learnset from ${widget.catalog.gameName(widget.learnset.game!)}'),
                ],
              ],
            ),
          ),
        ),
        SliverList.separated(
          itemCount: rows.length,
          separatorBuilder: (_, _) => Divider(indent: 16, endIndent: 16, color: context.palette.line),
          itemBuilder: (_, i) {
            final r = rows[i];
            return MoveRow(
              move: r.move,
              leading: method == 'level-up' ? (r.level == 0 ? 'Evo' : 'Lv ${r.level}') : null,
            );
          },
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}
