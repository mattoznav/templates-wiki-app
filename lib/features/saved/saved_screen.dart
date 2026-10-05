import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/widgets.dart';
import '../../core/providers.dart';

class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(favouritesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Saved')),
      body: AsyncBody(
        provider: catalogProvider,
        builder: (catalog) {
          final entries = [for (final id in saved) ?catalog.speciesById[id]]..sort((a, b) => a.id.compareTo(b.id));
          if (entries.isEmpty) {
            return const EmptyState(
              icon: Icons.bookmark_outline,
              title: 'Nothing saved yet',
              message: 'Tap the bookmark on any Pokémon to keep it here. Saved entries stay on this device.',
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.78,
            ),
            itemCount: entries.length,
            itemBuilder: (_, i) => PokemonCard(entries[i]),
          );
        },
      ),
    );
  }
}
