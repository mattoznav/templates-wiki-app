# Wiki template: App

"Fieldbook" for iOS and Android: every Pokémon with stats, forms, type defenses, evolution chains and learnsets, plus moves, abilities, types and games. Works offline for everything already opened.

Flutter, Riverpod, go_router and Dio. No backend: the app talks to [PokéAPI](https://pokeapi.co/) directly. Part of the [`templates-wiki`](https://github.com/mattoznav/templates-wiki) template, inside the [`templates`](https://github.com/mattoznav/templates) collection.

## Requirements

- Flutter 3.44 or newer (Dart 3.12)
- For iOS: macOS with Xcode and CocoaPods
- For Android: Android Studio with an emulator or a device
- An internet connection the first time the app opens

No API key or account is needed.

## Quick start

Start an iOS simulator or an Android emulator, then:

```bash
flutter pub get
flutter run
```

The first start downloads the catalogue (about 700 KB) and shows the Pokédex. Checks:

```bash
flutter analyze
flutter test
```

To use a self-hosted PokéAPI:

```bash
flutter run --dart-define=POKEAPI_URL=https://pokeapi.example.com/api/v2 --dart-define=POKEAPI_GRAPHQL_URL=https://pokeapi.example.com/graphql/v1beta2
```

## Screens

| Tab or screen | What it does |
| --- | --- |
| Pokédex | All 1,025 species: search by name or number, filter by type, generation and legendary status, sort by any base stat, random entry |
| Pokémon | Artwork (with shiny), Pokédex entry, profile, abilities, gender ratio, every form, base stats, type defenses, evolution chain, learnset by method |
| Moves | All moves, searchable by name or effect, filterable by type and category, sortable by power, accuracy and PP |
| Move | Power, accuracy, PP, priority, target, descriptions, every Pokémon that learns it |
| Types | The 18 types and the full type chart; each type shows its matchups, Pokémon and moves |
| Ability | What it does and which Pokémon have it, as a regular or hidden ability |
| Games | Every game by generation, with year, platform and kind; each generation lists the Pokémon it introduced |
| Saved | Pokémon bookmarked on this device |
| About | Light, dark or system theme, stored data size, refresh or clear the cache, credits |

## How the data is loaded

| Data | Source | Kept on the device for |
| --- | --- | --- |
| Catalogue: every species with types and stats, every move, type, type matchup, ability and game | One GraphQL query, [`assets/catalog.graphql`](assets/catalog.graphql) | 7 days |
| Species, Pokémon form, evolution chain, move and ability details | PokéAPI REST, one request per resource | 30 days |
| Artwork and sprites | PokéAPI's sprite repository on GitHub | Image cache |

Every response is written to a small JSON cache in the app's support folder (`lib/core/cache.dart`). When the network fails, the last saved copy is used, so anything opened before works offline. This also follows PokéAPI's fair use policy, which asks clients to cache what they request.

Lists come from the GraphQL catalogue because REST would need one request per Pokémon or move just to show their types and power. Details come from REST because each screen needs only a few resources.

## Structure

```
lib/
  main.dart              app start, theme, providers
  router.dart            tabs and routes
  core/
    api.dart             PokéAPI client (REST and GraphQL) with the disk cache
    cache.dart           JSON cache on disk
    catalog.dart         catalogue model and parsing, release years of each game
    models.dart          species, forms, learnsets, evolution chains, moves, abilities
    providers.dart       Riverpod providers, saved Pokémon, theme setting
    theme.dart           colours (the same as the website), type colours, fonts
    format.dart          small formatting helpers
  common/widgets.dart    type chips, cards, rows, stat bars, loading and error states
  features/              one folder per tab or screen
test/core_test.dart      parsing, learnsets, evolution text, labels
```

## Customising

- Colours, type colours and fonts are in `lib/core/theme.dart`; they match the website's design tokens.
- Release years, platforms and the kind of each game are in `gameFacts` in `lib/core/catalog.dart`.
- Cache lifetimes and endpoints are in `lib/core/config.dart`.
- Change the bundle identifier (`com.example.wiki.fieldbook`) and the app name before publishing.

## Credits and trademarks

Data from [PokéAPI](https://pokeapi.co/). Artwork and sprites are loaded at runtime from [PokeAPI/sprites](https://github.com/PokeAPI/sprites) and are not included in this repository. Fonts (Fraunces, IBM Plex Sans, IBM Plex Mono, SIL Open Font License) are loaded with `google_fonts`.

Pokémon and Pokémon character names are trademarks of Nintendo, Creatures Inc. and GAME FREAK inc. This template is an unofficial fan reference and is not affiliated with or endorsed by them.

## License

The code is released under the [MIT License](LICENSE). It covers the code only: data from PokéAPI, the artwork loaded from its repositories and the Pokémon trademarks are not covered.
