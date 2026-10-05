import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:go_router/go_router.dart';

import '../core/api.dart';
import '../core/catalog.dart';
import '../core/format.dart';
import '../core/theme.dart';

/// Coloured pill with a dot, as on the website. Tapping it opens the type.
class TypeChip extends StatelessWidget {
  const TypeChip(this.type, {super.key, this.small = false, this.link = true});

  final String type;
  final bool small;
  final bool link;

  @override
  Widget build(BuildContext context) {
    final c = typeColor(type);
    final ink = Color.lerp(c, context.palette.ink, 0.45)!;
    final chip = Container(
      height: small ? 20 : 26,
      padding: EdgeInsets.only(left: small ? 6 : 8, right: small ? 7 : 10),
      decoration: BoxDecoration(
        color: tint(context, c, 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: small ? 6 : 8,
            height: small ? 6 : 8,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
          SizedBox(width: small ? 5 : 6),
          Text(type.toUpperCase(), style: mono(small ? 9.5 : 11, color: ink, spacing: 0.6)),
        ],
      ),
    );
    if (!link) return chip;
    return Semantics(
      button: true,
      label: '${capitalize(type)} type',
      child: GestureDetector(
        onTap: () => context.push('/types/$type'),
        child: ExcludeSemantics(child: chip),
      ),
    );
  }
}

class TypeRow extends StatelessWidget {
  const TypeRow(this.types, {super.key, this.small = false, this.link = true});
  final List<String> types;
  final bool small;
  final bool link;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: small ? 4 : 6,
    runSpacing: 4,
    children: [for (final t in types) TypeChip(t, small: small, link: link)],
  );
}

/// Official artwork from PokéAPI's sprite repository, cached on the device.
class Artwork extends StatelessWidget {
  const Artwork(this.url, {super.key, this.size, this.pixel = false});

  final String? url;
  final double? size;
  final bool pixel;

  @override
  Widget build(BuildContext context) {
    final placeholder = Icon(Icons.catching_pokemon, size: (size ?? 64) * 0.4, color: context.palette.line2);
    if (url == null) {
      return SizedBox(width: size, height: size, child: Center(child: placeholder));
    }
    return CachedNetworkImage(
      imageUrl: url!,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: pixel ? FilterQuality.none : FilterQuality.medium,
      fadeInDuration: const Duration(milliseconds: 180),
      placeholder: (_, _) => Center(child: placeholder),
      errorWidget: (_, _, _) => Center(child: placeholder),
    );
  }
}

/// Dotted background, the "field notebook" texture used behind artwork.
class DotsPainter extends CustomPainter {
  DotsPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (double y = 7; y < size.height; y += 14) {
      for (double x = 7; x < size.width; x += 14) {
        canvas.drawCircle(Offset(x, y), 0.9, paint);
      }
    }
  }

  @override
  bool shouldRepaint(DotsPainter old) => old.color != color;
}

/// Grid card for a species: artwork on a tinted panel, number, name, types.
class PokemonCard extends StatelessWidget {
  const PokemonCard(this.entry, {super.key, this.trailing});

  final SpeciesEntry entry;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final c = typeColor(entry.types.first);
    return Material(
      color: p.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(color: p.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/pokemon/${entry.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: tint(context, c, 0.14),
                child: CustomPaint(
                  painter: DotsPainter(p.ink.withValues(alpha: 0.10)),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 10,
                        top: 8,
                        child: Text('#${pad(entry.id)}', style: mono(10.5, color: Color.lerp(c, p.ink2, 0.6))),
                      ),
                      if (trailing != null)
                        Positioned(
                          right: 10,
                          top: 8,
                          child: Text(trailing!, style: mono(10.5, color: p.ink2)),
                        ),
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 22, 12, 6),
                          child: Hero(tag: 'art-${entry.id}', child: Artwork(entry.artwork)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: p.line)),
              ),
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.name, style: display(15.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  TypeRow(entry.types, small: true, link: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// List row for a species: sprite, name, number, types.
class PokemonRow extends StatelessWidget {
  const PokemonRow(this.entry, {super.key, this.note});

  final SpeciesEntry entry;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ListTile(
      onTap: () => context.push('/pokemon/${entry.id}'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: tint(context, typeColor(entry.types.first)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Artwork(entry.sprite, pixel: true),
      ),
      title: Text(entry.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        note == null ? '#${pad(entry.id)}' : '#${pad(entry.id)} · $note',
        style: mono(11.5, color: p.muted),
      ),
      trailing: TypeRow(entry.types, small: true, link: false),
    );
  }
}

class StatBars extends StatelessWidget {
  const StatBars({super.key, required this.stats});
  final List<int> stats;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final total = stats.fold(0, (a, b) => a + b);
    Widget row(String name, int value, double max, Color color, {bool bold = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(
              name,
              style: TextStyle(fontSize: 13, color: bold ? p.ink : p.ink2, fontWeight: bold ? FontWeight.w600 : null),
            ),
          ),
          SizedBox(
            width: 38,
            child: Text(
              '$value',
              textAlign: TextAlign.right,
              style: mono(13, weight: bold ? FontWeight.w600 : FontWeight.w500),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: (value / max).clamp(0, 1)),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (_, v, _) =>
                    LinearProgressIndicator(value: v, minHeight: 9, backgroundColor: p.paper2, color: color),
              ),
            ),
          ),
        ],
      ),
    );
    return Column(
      children: [
        for (var i = 0; i < stats.length; i++) row(statLabels[i], stats[i], 200, statColor(stats[i])),
        Divider(color: p.line2, height: 14),
        row('Total', total, 720, p.ink, bold: true),
      ],
    );
  }
}

/// Section caption: small mono label above content.
class Caption extends StatelessWidget {
  const Caption(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(), style: label(context));
}

class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.padding = const EdgeInsets.all(18)});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: context.palette.card,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: context.palette.line),
    ),
    child: child,
  );
}

/// Category marker for moves: diamond (physical), circle (special), ring (status).
class CategoryMark extends StatelessWidget {
  const CategoryMark(this.category, {super.key, this.showLabel = true});
  final String category;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final Widget mark = switch (category) {
      'physical' => Transform.rotate(
        angle: 0.785,
        child: Container(width: 9, height: 9, color: const Color(0xFFE0703A)),
      ),
      'special' => Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(color: Color(0xFF5A7FE0), shape: BoxShape.circle),
      ),
      _ => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: p.muted, width: 2),
        ),
      ),
    };
    if (!showLabel) return mark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(width: 6),
        Text(capitalize(category), style: TextStyle(fontSize: 13, color: p.ink2)),
      ],
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message});
  final String? message;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5)),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            style: TextStyle(color: context.palette.muted),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    ),
  );
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_outlined, size: 40, color: context.palette.muted),
          const SizedBox(height: 14),
          Text(
            errorMessage(error),
            textAlign: TextAlign.center,
            style: TextStyle(color: context.palette.ink2),
          ),
          const SizedBox(height: 18),
          FilledButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}

/// Shows a provider's value, with loading and error states that offer a retry.
class AsyncBody<T> extends ConsumerWidget {
  const AsyncBody({super.key, required this.provider, required this.builder, this.loading});

  final ProviderBase<AsyncValue<T>> provider;
  final Widget Function(T value) builder;
  final String? loading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(provider);
    return value.when(
      data: builder,
      loading: () => LoadingView(message: loading),
      error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(provider)),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.message});
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: context.palette.line2),
          const SizedBox(height: 14),
          Text(title, style: display(22), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: context.palette.muted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
