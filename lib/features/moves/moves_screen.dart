import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/widgets.dart';
import '../../core/format.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import 'move_row.dart';

class MovesScreen extends ConsumerStatefulWidget {
  const MovesScreen({super.key});

  @override
  ConsumerState<MovesScreen> createState() => _MovesScreenState();
}

class _MovesScreenState extends ConsumerState<MovesScreen> {
  String _query = '';
  String? _type;
  String? _category;
  String _sort = 'name';

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(title: const Text('Moves')),
      body: AsyncBody(
        provider: catalogProvider,
        builder: (catalog) {
          final q = _query.trim().toLowerCase();
          final moves = catalog.moves.where((m) {
            if (q.isNotEmpty && !m.name.toLowerCase().contains(q) && !(m.effect?.toLowerCase().contains(q) ?? false)) {
              return false;
            }
            if (_type != null && m.type != _type) return false;
            if (_category != null && m.category != _category) return false;
            return true;
          }).toList();
          int desc(int? a, int? b) => (b ?? -1).compareTo(a ?? -1);
          switch (_sort) {
            case 'power':
              moves.sort((a, b) => desc(a.power, b.power));
            case 'accuracy':
              moves.sort((a, b) => desc(a.accuracy, b.accuracy));
            case 'pp':
              moves.sort((a, b) => desc(a.pp, b.pp));
          }

          return CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Name or effect, e.g. “burn”',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _Menu<String?>(
                        label: _type == null ? 'Type' : capitalize(_type!),
                        active: _type != null,
                        options: [null, ...typeOrder],
                        optionLabel: (t) => t == null ? 'All types' : capitalize(t),
                        onSelected: (t) => setState(() => _type = t),
                      ),
                      _Menu<String?>(
                        label: _category == null ? 'Category' : capitalize(_category!),
                        active: _category != null,
                        options: const [null, 'physical', 'special', 'status'],
                        optionLabel: (c) => c == null ? 'All categories' : capitalize(c),
                        onSelected: (c) => setState(() => _category = c),
                      ),
                      _Menu<String>(
                        label: 'Sort: ${_sort == 'pp' ? 'PP' : capitalize(_sort)}',
                        active: _sort != 'name',
                        options: const ['name', 'power', 'accuracy', 'pp'],
                        optionLabel: (s) => s == 'pp' ? 'PP' : capitalize(s),
                        onSelected: (s) => setState(() => _sort = s),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text('${moves.length} MOVES', style: label(context)),
                ),
              ),
              if (moves.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.search_off,
                    title: 'No matches',
                    message: 'Try another name or filter.',
                  ),
                )
              else
                SliverList.separated(
                  itemCount: moves.length,
                  separatorBuilder: (_, _) => Divider(indent: 16, endIndent: 16, color: p.line),
                  itemBuilder: (_, i) => MoveRow(move: moves[i], showEffect: q.isNotEmpty),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Menu<T> extends StatelessWidget {
  const _Menu({
    required this.label,
    required this.active,
    required this.options,
    required this.optionLabel,
    required this.onSelected,
  });

  final String label;
  final bool active;
  final List<T> options;
  final String Function(T) optionLabel;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: PopupMenuButton<int>(
        tooltip: label,
        position: PopupMenuPosition.under,
        color: p.card,
        onSelected: (i) => onSelected(options[i]),
        itemBuilder: (_) => [
          for (var i = 0; i < options.length; i++) PopupMenuItem(value: i, child: Text(optionLabel(options[i]))),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            color: active ? p.ink : p.card,
            shape: StadiumBorder(side: BorderSide(color: active ? p.ink : p.line2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(color: active ? p.paper : p.ink, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 4),
              Icon(Icons.expand_more, size: 16, color: active ? p.paper : p.muted),
            ],
          ),
        ),
      ),
    );
  }
}
