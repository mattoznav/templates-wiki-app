import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../common/widgets.dart';
import '../../core/catalog.dart';
import '../../core/format.dart';
import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import 'evolution_view.dart';
import 'learnset_view.dart';
import 'matchups_view.dart';

class PokemonScreen extends ConsumerStatefulWidget {
  const PokemonScreen({super.key, required this.id});
  final int id;

  @override
  ConsumerState<PokemonScreen> createState() => _PokemonScreenState();
}

class _PokemonScreenState extends ConsumerState<PokemonScreen> {
  int _form = 0;
  bool _shiny = false;

  @override
  Widget build(BuildContext context) {
    final catalogValue = ref.watch(catalogProvider);
    final speciesValue = ref.watch(speciesProvider(widget.id));
    final entry = catalogValue.value?.speciesById[widget.id];

    if (speciesValue.hasError || catalogValue.hasError) {
      return Scaffold(
        appBar: AppBar(),
        body: ErrorView(
          error: speciesValue.error ?? catalogValue.error!,
          onRetry: () {
            ref.invalidate(speciesProvider(widget.id));
            ref.invalidate(catalogProvider);
          },
        ),
      );
    }
    final species = speciesValue.value;
    final catalog = catalogValue.value;
    if (species == null || catalog == null) {
      return Scaffold(
        appBar: AppBar(),
        body: entry == null ? const LoadingView() : _LoadingHeader(entry: entry),
      );
    }

    final variety = species.varieties[_form.clamp(0, species.varieties.length - 1)];
    final pokemonValue = ref.watch(pokemonProvider(variety.id));
    final pokemon = pokemonValue.value;
    final types = pokemon?.types ?? entry?.types ?? const ['normal'];
    final color = typeColor(types.first);
    final p = context.palette;
    final saved = ref.watch(favouritesProvider).contains(widget.id);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, inner) => [
            SliverAppBar(
              pinned: true,
              expandedHeight: 360,
              backgroundColor: tint(context, color, 0.16),
              title: AnimatedOpacity(
                opacity: inner ? 1 : 0,
                duration: const Duration(milliseconds: 150),
                child: Text(species.name),
              ),
              actions: [
                IconButton(
                  tooltip: _shiny ? 'Show regular colours' : 'Show shiny colours',
                  isSelected: _shiny,
                  icon: const Icon(Icons.auto_awesome_outlined),
                  selectedIcon: const Icon(Icons.auto_awesome),
                  onPressed: () => setState(() => _shiny = !_shiny),
                ),
                IconButton(
                  tooltip: saved ? 'Remove from saved' : 'Save',
                  isSelected: saved,
                  icon: const Icon(Icons.bookmark_outline),
                  selectedIcon: const Icon(Icons.bookmark),
                  onPressed: () => ref.read(favouritesProvider.notifier).toggle(widget.id),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: CustomPaint(
                  painter: DotsPainter(p.ink.withValues(alpha: 0.08)),
                  child: SafeArea(
                    child: Stack(
                      children: [
                        Positioned(
                          right: -6,
                          bottom: 50,
                          child: Text(
                            pad(species.id),
                            style: mono(96, color: color.withValues(alpha: 0.18), weight: FontWeight.w500, spacing: -4),
                          ),
                        ),
                        Positioned.fill(
                          top: 48,
                          bottom: 64,
                          child: Hero(
                            tag: 'art-${species.id}',
                            child: Artwork(
                              _shiny
                                  ? (pokemon?.shinyArtwork ?? pokemon?.artwork)
                                  : (pokemon?.artwork ?? entry?.artwork),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  color: p.paper,
                  child: TabBar(
                    isScrollable: false,
                    labelColor: p.ink,
                    unselectedLabelColor: p.muted,
                    indicatorColor: color,
                    dividerColor: p.line,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                    tabs: const [
                      Tab(text: 'About'),
                      Tab(text: 'Stats'),
                      Tab(text: 'Evolution'),
                      Tab(text: 'Moves'),
                    ],
                  ),
                ),
              ),
            ),
          ],
          body: Builder(
            builder: (context) {
              if (pokemonValue.hasError) {
                return ErrorView(
                  error: pokemonValue.error!,
                  onRetry: () => ref.invalidate(pokemonProvider(variety.id)),
                );
              }
              if (pokemon == null) return const LoadingView();
              return TabBarView(
                children: [
                  _AboutTab(
                    species: species,
                    pokemon: pokemon,
                    catalog: catalog,
                    form: _form,
                    onForm: (i) => setState(() => _form = i),
                  ),
                  _StatsTab(pokemon: pokemon, catalog: catalog),
                  EvolutionView(species: species),
                  _Moves(species: species, pokemon: pokemon, catalog: catalog),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LoadingHeader extends StatelessWidget {
  const _LoadingHeader({required this.entry});
  final SpeciesEntry entry;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        height: 240,
        child: Hero(tag: 'art-${entry.id}', child: Artwork(entry.artwork)),
      ),
      const SizedBox(height: 16),
      Text(entry.name, style: display(36)),
      const SizedBox(height: 24),
      const LoadingView(),
    ],
  );
}

class _AboutTab extends StatelessWidget {
  const _AboutTab({
    required this.species,
    required this.pokemon,
    required this.catalog,
    required this.form,
    required this.onForm,
  });

  final SpeciesDetail species;
  final PokemonDetail pokemon;
  final Catalog catalog;
  final int form;
  final ValueChanged<int> onForm;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final status = species.isLegendary
        ? 'Legendary'
        : species.isMythical
        ? 'Mythical'
        : species.isBaby
        ? 'Baby'
        : null;
    final entry = catalog.speciesById[species.id];
    final prev = catalog.speciesById[species.id - 1];
    final next = catalog.speciesById[species.id + 1];
    final catchChance = (species.captureRate / 255 * 1000).round() / 10;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        Row(
          children: [
            Text('${dexNo(species.id).toUpperCase()} · GEN ${roman[entry?.generation ?? 0]}', style: label(context)),
            if (status != null) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: p.ink, borderRadius: BorderRadius.circular(999)),
                child: Text(status.toUpperCase(), style: mono(10, color: p.paper, spacing: 0.6)),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(species.name, style: display(40)),
        if (species.genus != null) ...[
          const SizedBox(height: 6),
          Text(
            species.genus!,
            style: display(18, weight: FontWeight.w400, style: FontStyle.italic, color: p.ink2),
          ),
        ],
        const SizedBox(height: 14),
        TypeRow(pokemon.types),
        if (species.varieties.length > 1) ...[
          const SizedBox(height: 20),
          Caption('${species.varieties.length} forms'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < species.varieties.length; i++)
                ChoiceChip(
                  label: Text(species.varieties[i].label),
                  selected: i == form,
                  onSelected: (_) => onForm(i),
                  labelStyle: TextStyle(color: i == form ? p.paper : p.ink, fontWeight: FontWeight.w500),
                ),
            ],
          ),
        ],
        if (species.flavor != null) ...[
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: p.card,
              border: Border(left: BorderSide(color: typeColor(pokemon.types.first), width: 3)),
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(radius)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(species.flavor!, style: TextStyle(fontSize: 15.5, height: 1.5, color: p.ink2)),
                if (species.flavorVersion != null) ...[
                  const SizedBox(height: 8),
                  Caption(
                    'Pokédex entry · ${catalog.versionNames[species.flavorVersion] ?? titleCase(species.flavorVersion!)}',
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 22),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Profile', style: display(22)),
              const SizedBox(height: 14),
              _FactGrid(
                facts: [
                  ('Height', formatHeight(pokemon.height)),
                  ('Weight', formatWeight(pokemon.weight)),
                  ('Catch rate', '${species.captureRate} ($catchChance%)'),
                  ('Base friendship', '${species.baseHappiness ?? '—'}'),
                  ('Egg groups', species.eggGroups.isEmpty ? '—' : species.eggGroups.join(', ')),
                  ('Hatch time', species.hatchCounter == null ? '—' : '${species.hatchCounter} cycles'),
                  ('Growth rate', species.growthRate),
                  ('Base experience', '${pokemon.baseExperience ?? '—'}'),
                  ('Habitat', species.habitat ?? '—'),
                  ('Colour · shape', '${species.color ?? '—'} · ${species.shape ?? '—'}'),
                ],
              ),
              const SizedBox(height: 16),
              const Caption('Abilities'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final a in pokemon.abilities)
                    ActionChip(
                      label: Text(
                        '${catalog.abilityBySlug[a.slug]?.name ?? titleCase(a.slug)}${a.hidden ? ' · hidden' : ''}',
                        style: TextStyle(color: p.ink, fontWeight: FontWeight.w500),
                      ),
                      onPressed: () => context.push('/abilities/${a.slug}'),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              const Caption('Gender'),
              const SizedBox(height: 8),
              _GenderBar(rate: species.genderRate),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            if (prev != null)
              Expanded(
                child: _Neighbour(entry: prev, label: 'Previous'),
              )
            else
              const Spacer(),
            const SizedBox(width: 10),
            if (next != null)
              Expanded(
                child: _Neighbour(entry: next, label: 'Next', alignEnd: true),
              )
            else
              const Spacer(),
          ],
        ),
      ],
    );
  }
}

class _FactGrid extends StatelessWidget {
  const _FactGrid({required this.facts});
  final List<(String, String)> facts;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = (c.maxWidth - 16) / 2;
        return Wrap(
          spacing: 16,
          runSpacing: 14,
          children: [
            for (final f in facts)
              SizedBox(
                width: w,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Caption(f.$1),
                    const SizedBox(height: 3),
                    Text(f.$2, style: const TextStyle(fontSize: 14.5)),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _GenderBar extends StatelessWidget {
  const _GenderBar({required this.rate});
  final int rate;

  @override
  Widget build(BuildContext context) {
    if (rate < 0) return const Text('Genderless');
    final female = rate / 8 * 100;
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  if (female < 100)
                    Expanded(
                      flex: (1000 - female * 10).round(),
                      child: Container(color: const Color(0xFF4B84D8)),
                    ),
                  if (female > 0)
                    Expanded(
                      flex: (female * 10).round(),
                      child: Container(color: const Color(0xFFE06AA0)),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text('${percent(100 - female)} male · ${percent(female)} female', style: const TextStyle(fontSize: 13.5)),
      ],
    );
  }
}

class _Neighbour extends StatelessWidget {
  const _Neighbour({required this.entry, required this.label, this.alignEnd = false});
  final SpeciesEntry entry;
  final String label;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final art = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: tint(context, typeColor(entry.types.first)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Artwork(entry.sprite, pixel: true),
    );
    final text = Expanded(
      child: Column(
        crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text('${label.toUpperCase()} · #${pad(entry.id)}', style: mono(9.5, color: p.muted)),
          Text(entry.name, style: display(16), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
    return Material(
      color: p.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(color: p.line),
      ),
      child: InkWell(
        customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
        onTap: () => context.pushReplacement('/pokemon/${entry.id}'),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: alignEnd ? [text, const SizedBox(width: 8), art] : [art, const SizedBox(width: 8), text],
          ),
        ),
      ),
    );
  }
}

class _StatsTab extends StatelessWidget {
  const _StatsTab({required this.pokemon, required this.catalog});
  final PokemonDetail pokemon;
  final Catalog catalog;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Base stats', style: display(22)),
              const SizedBox(height: 12),
              StatBars(stats: pokemon.stats),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Type defenses', style: display(22)),
              const SizedBox(height: 4),
              Text(
                'Damage taken from each attacking type.',
                style: TextStyle(color: context.palette.muted, fontSize: 13),
              ),
              const SizedBox(height: 14),
              MatchupsView(types: pokemon.types, catalog: catalog),
            ],
          ),
        ),
      ],
    );
  }
}

/// Forms without a learnset of their own (Mega Evolutions, most cosmetic forms)
/// show the standard form's moves.
class _Moves extends ConsumerWidget {
  const _Moves({required this.species, required this.pokemon, required this.catalog});
  final SpeciesDetail species;
  final PokemonDetail pokemon;
  final Catalog catalog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final own = pokemon.learnset(catalog);
    final standard = species.varieties.firstWhere((v) => v.isDefault, orElse: () => species.varieties.first);
    if (own.moves.isNotEmpty || standard.id == pokemon.id) return LearnsetView(learnset: own, catalog: catalog);
    return AsyncBody(
      provider: pokemonProvider(standard.id),
      builder: (main) => LearnsetView(learnset: main.learnset(catalog), catalog: catalog),
    );
  }
}
