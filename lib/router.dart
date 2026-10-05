import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/abilities/ability_screen.dart';
import 'features/dex/dex_screen.dart';
import 'features/games/games_screen.dart';
import 'features/games/generation_screen.dart';
import 'features/moves/move_screen.dart';
import 'features/moves/moves_screen.dart';
import 'features/pokemon/pokemon_screen.dart';
import 'features/saved/about_screen.dart';
import 'features/saved/saved_screen.dart';
import 'features/types/type_screen.dart';
import 'features/types/types_screen.dart';

final _root = GlobalKey<NavigatorState>();

/// Five tabs (Pokédex, moves, types, games, saved). Entries open full screen above them.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _root,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _Tabs(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/', builder: (_, _) => const DexScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/moves', builder: (_, _) => const MovesScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/types', builder: (_, _) => const TypesScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/games', builder: (_, _) => const GamesScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/saved', builder: (_, _) => const SavedScreen())],
          ),
        ],
      ),
      GoRoute(
        path: '/pokemon/:id',
        parentNavigatorKey: _root,
        builder: (_, state) => PokemonScreen(id: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/moves/:slug',
        parentNavigatorKey: _root,
        builder: (_, state) => MoveScreen(slug: state.pathParameters['slug']!),
      ),
      GoRoute(
        path: '/types/:slug',
        parentNavigatorKey: _root,
        builder: (_, state) => TypeScreen(slug: state.pathParameters['slug']!),
      ),
      GoRoute(
        path: '/abilities/:slug',
        parentNavigatorKey: _root,
        builder: (_, state) => AbilityScreen(slug: state.pathParameters['slug']!),
      ),
      GoRoute(
        path: '/generations/:n',
        parentNavigatorKey: _root,
        builder: (_, state) => GenerationScreen(number: int.parse(state.pathParameters['n']!)),
      ),
      GoRoute(path: '/about', parentNavigatorKey: _root, builder: (_, _) => const AboutScreen()),
    ],
  );
});

class _Tabs extends StatelessWidget {
  const _Tabs({required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Pokédex',
          ),
          NavigationDestination(icon: Icon(Icons.bolt_outlined), selectedIcon: Icon(Icons.bolt), label: 'Moves'),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category),
            label: 'Types',
          ),
          NavigationDestination(
            icon: Icon(Icons.videogame_asset_outlined),
            selectedIcon: Icon(Icons.videogame_asset),
            label: 'Games',
          ),
          NavigationDestination(icon: Icon(Icons.bookmark_outline), selectedIcon: Icon(Icons.bookmark), label: 'Saved'),
        ],
      ),
    );
  }
}
