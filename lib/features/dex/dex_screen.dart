import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../common/widgets.dart';
import '../../core/catalog.dart';
import '../../core/format.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';

enum DexSort {
  number('Number'),
  name('Name'),
  total('Base stat total'),
  hp('HP'),
  attack('Attack'),
  defense('Defense'),
  spAtk('Sp. Atk'),
  spDef('Sp. Def'),
  speed('Speed');

  const DexSort(this.label);
  final String label;
}

class DexFilter {
  const DexFilter({this.query = '', this.type, this.generation, this.sort = DexSort.number, this.special = false});

  final String query;
  final String? type;
  final int? generation;
  final DexSort sort;

  /// Only legendary and mythical Pokémon
  final bool special;

  bool get isActive => query.isNotEmpty || type != null || generation != null || sort != DexSort.number || special;

  DexFilter copyWith({
    String? query,
    String? Function()? type,
    int? Function()? generation,
    DexSort? sort,
    bool? special,
  }) => DexFilter(
    query: query ?? this.query,
    type: type != null ? type() : this.type,
    generation: generation != null ? generation() : this.generation,
    sort: sort ?? this.sort,
    special: special ?? this.special,
  );

  List<SpeciesEntry> apply(List<SpeciesEntry> all) {
    final q = query.trim().toLowerCase().replaceFirst('#', '');
    final number = int.tryParse(q);
    final list = all.where((s) {
      if (q.isNotEmpty) {
        final match = number != null ? s.id == number || '${s.id}'.startsWith(q) : s.name.toLowerCase().contains(q);
        if (!match) return false;
      }
      if (type != null && !s.types.contains(type)) return false;
      if (generation != null && s.generation != generation) return false;
      if (special && !s.isLegendary && !s.isMythical) return false;
      return true;
    }).toList();
    int byStat(int i, SpeciesEntry a, SpeciesEntry b) =>
        b.stats[i] != a.stats[i] ? b.stats[i].compareTo(a.stats[i]) : a.id.compareTo(b.id);
    switch (sort) {
      case DexSort.number:
        break;
      case DexSort.name:
        list.sort((a, b) => a.name.compareTo(b.name));
      case DexSort.total:
        list.sort((a, b) => b.total != a.total ? b.total.compareTo(a.total) : a.id.compareTo(b.id));
      default:
        final i = DexSort.values.indexOf(sort) - DexSort.hp.index;
        list.sort((a, b) => byStat(i, a, b));
    }
    return list;
  }
}

final dexFilterProvider = NotifierProvider<DexFilterNotifier, DexFilter>(DexFilterNotifier.new);

class DexFilterNotifier extends Notifier<DexFilter> {
  @override
  DexFilter build() => const DexFilter();
  void update(DexFilter filter) => state = filter;
  void reset() => state = const DexFilter();
}

class DexScreen extends ConsumerStatefulWidget {
  const DexScreen({super.key});

  @override
  ConsumerState<DexScreen> createState() => _DexScreenState();
}

class _DexScreenState extends ConsumerState<DexScreen> {
  late final _search = TextEditingController(text: ref.read(dexFilterProvider).query);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(dexFilterProvider);
    final notifier = ref.read(dexFilterProvider.notifier);
    final p = context.palette;

    return Scaffold(
      appBar: AppBar(
        title: const _Brand(),
        actions: [
          IconButton(
            tooltip: 'Random entry',
            icon: const Icon(Icons.casino_outlined),
            onPressed: () {
              final all = ref.read(catalogProvider).value?.species;
              if (all == null || all.isEmpty) return;
              final pick = all[Random().nextInt(all.length)];
              context.push('/pokemon/${pick.id}');
            },
          ),
          IconButton(
            tooltip: 'About and settings',
            icon: const Icon(Icons.tune),
            onPressed: () => context.push('/about'),
          ),
        ],
      ),
      body: AsyncBody(
        provider: catalogProvider,
        loading: 'Opening the field guide…\nThe first start downloads the catalogue.',
        builder: (catalog) {
          final results = filter.apply(catalog.species);
          return CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                  child: TextField(
                    controller: _search,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Name or number',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: filter.query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear',
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _search.clear();
                                notifier.update(filter.copyWith(query: ''));
                              },
                            ),
                    ),
                    onChanged: (v) => notifier.update(filter.copyWith(query: v)),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _FilterButton(
                        label: filter.type == null ? 'Type' : capitalize(filter.type!),
                        active: filter.type != null,
                        color: filter.type == null ? null : typeColor(filter.type!),
                        onTap: () => _pickType(context, filter),
                      ),
                      _FilterButton(
                        label: filter.generation == null ? 'Generation' : 'Gen ${roman[filter.generation!]}',
                        active: filter.generation != null,
                        onTap: () => _pickGeneration(context, filter, catalog),
                      ),
                      _FilterButton(
                        label: filter.sort == DexSort.number ? 'Sort' : filter.sort.label,
                        icon: Icons.swap_vert,
                        active: filter.sort != DexSort.number,
                        onTap: () => _pickSort(context, filter),
                      ),
                      _FilterButton(
                        label: 'Legendary',
                        icon: Icons.auto_awesome_outlined,
                        active: filter.special,
                        onTap: () => notifier.update(filter.copyWith(special: !filter.special)),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 6),
                  child: Row(
                    children: [
                      Text('${results.length} SHOWN', style: label(context)),
                      const Spacer(),
                      if (filter.isActive)
                        TextButton(
                          onPressed: () {
                            _search.clear();
                            notifier.reset();
                          },
                          child: Text('Clear filters', style: TextStyle(color: p.ink2)),
                        ),
                    ],
                  ),
                ),
              ),
              if (results.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.search_off,
                    title: 'No matches',
                    message: 'Try another name, number or filter.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  sliver: SliverGrid.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 200,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: results.length,
                    itemBuilder: (_, i) {
                      final s = results[i];
                      final stat = switch (filter.sort) {
                        DexSort.number || DexSort.name => null,
                        DexSort.total => '${s.total}',
                        _ => '${s.stats[DexSort.values.indexOf(filter.sort) - DexSort.hp.index]}',
                      };
                      return PokemonCard(s, trailing: stat);
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _pickType(BuildContext context, DexFilter filter) {
    _sheet<String?>(
      context,
      title: 'Type',
      options: [null, ...typeOrder],
      selected: filter.type,
      label: (t) => t == null ? 'All types' : capitalize(t),
      leading: (t) => t == null
          ? null
          : Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(color: typeColor(t), shape: BoxShape.circle),
            ),
      onSelect: (t) => ref.read(dexFilterProvider.notifier).update(filter.copyWith(type: () => t)),
    );
  }

  void _pickGeneration(BuildContext context, DexFilter filter, Catalog catalog) {
    _sheet<int?>(
      context,
      title: 'Generation',
      options: [null, ...catalog.generations.map((g) => g.number)],
      selected: filter.generation,
      label: (n) {
        if (n == null) return 'All generations';
        final g = catalog.generations.firstWhere((g) => g.number == n);
        return 'Generation ${roman[n]} · ${g.region}';
      },
      onSelect: (n) => ref.read(dexFilterProvider.notifier).update(filter.copyWith(generation: () => n)),
    );
  }

  void _pickSort(BuildContext context, DexFilter filter) {
    _sheet<DexSort>(
      context,
      title: 'Sort by',
      options: DexSort.values,
      selected: filter.sort,
      label: (s) => s.label,
      onSelect: (s) => ref.read(dexFilterProvider.notifier).update(filter.copyWith(sort: s)),
    );
  }

  void _sheet<T>(
    BuildContext context, {
    required String title,
    required List<T> options,
    required T selected,
    required String Function(T) label,
    required void Function(T) onSelect,
    Widget? Function(T)? leading,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: options.length > 10 ? 0.7 : 0.5,
        maxChildSize: 0.9,
        builder: (context, controller) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(title, style: display(24)),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                children: [
                  for (final o in options)
                    ListTile(
                      leading: leading?.call(o),
                      title: Text(label(o)),
                      trailing: o == selected ? const Icon(Icons.check) : null,
                      onTap: () {
                        onSelect(o);
                        Navigator.pop(context);
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 28,
          decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(5)),
          child: Icon(Icons.eco, size: 16, color: p.paper),
        ),
        const SizedBox(width: 10),
        Text('Fieldbook', style: display(24, weight: FontWeight.w700)),
      ],
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.label, required this.active, required this.onTap, this.icon, this.color});

  final String label;
  final bool active;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: active ? p.ink : p.card,
        shape: StadiumBorder(side: BorderSide(color: active ? p.ink : p.line2)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (color != null) ...[
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                ] else if (icon != null) ...[
                  Icon(icon, size: 16, color: active ? p.paper : p.ink2),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(color: active ? p.paper : p.ink, fontWeight: FontWeight.w500),
                ),
                if (icon == null && color == null || color != null) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.expand_more, size: 16, color: active ? p.paper : p.muted),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
