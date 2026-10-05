import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/widgets.dart';
import '../../core/api.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';

final _cacheSizeProvider = FutureProvider.autoDispose<int>((ref) => ref.watch(apiProvider).cacheSize());

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final mode = ref.watch(themeModeProvider);
    final size = ref.watch(_cacheSizeProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          const Caption('Appearance'),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: ThemeMode.system, label: Text('System')),
              ButtonSegment(value: ThemeMode.light, label: Text('Light')),
              ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
            ],
            selected: {mode},
            onSelectionChanged: (s) => ref.read(themeModeProvider.notifier).set(s.first),
          ),
          const SizedBox(height: 28),
          const Caption('Offline data'),
          const SizedBox(height: 8),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Everything you open is kept on this device, so it works without a connection next time. '
                  'The catalogue refreshes once a week.',
                  style: TextStyle(color: p.ink2, height: 1.45),
                ),
                const SizedBox(height: 12),
                Text(
                  size == null ? 'Measuring…' : 'Stored data: ${(size / 1024 / 1024).toStringAsFixed(1)} MB',
                  style: mono(13),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: () async {
                        await ref.read(apiProvider).catalog(refresh: true);
                        ref.invalidate(catalogProvider);
                        ref.invalidate(_cacheSizeProvider);
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(const SnackBar(content: Text('Catalogue refreshed')));
                        }
                      },
                      child: const Text('Refresh catalogue'),
                    ),
                    OutlinedButton(
                      onPressed: () async {
                        await ref.read(apiProvider).clearCache();
                        await DefaultCacheManager().emptyCache();
                        ref.invalidate(_cacheSizeProvider);
                        ref.invalidate(catalogProvider);
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(const SnackBar(content: Text('Stored data cleared')));
                        }
                      },
                      child: const Text('Clear stored data'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Caption('About'),
          const SizedBox(height: 8),
          Text('Fieldbook', style: display(28)),
          const SizedBox(height: 8),
          Text(
            'An unofficial field guide to every Pokémon. All data comes from PokéAPI (pokeapi.co), a free and open '
            'database of Pokémon game data; artwork and sprites come from its public sprites repository.',
            style: TextStyle(color: p.ink2, height: 1.5),
          ),
          const SizedBox(height: 14),
          Text(
            'Pokémon and Pokémon character names are trademarks of Nintendo, Creatures Inc. and GAME FREAK inc. '
            'This app is a fan reference and is not affiliated with or endorsed by them.',
            style: TextStyle(color: p.muted, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}
