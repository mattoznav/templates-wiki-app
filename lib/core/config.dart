/// Endpoints. Both can be pointed at a self-hosted PokéAPI with --dart-define.
const restUrl = String.fromEnvironment('POKEAPI_URL', defaultValue: 'https://pokeapi.co/api/v2');
const graphqlUrl = String.fromEnvironment('POKEAPI_GRAPHQL_URL', defaultValue: 'https://graphql.pokeapi.co/v1beta2');

/// How long cached responses are trusted before the app asks PokéAPI again.
/// Game data changes only when new games come out, so these can be long.
const catalogMaxAge = Duration(days: 7);
const detailMaxAge = Duration(days: 30);

String artworkUrl(int id) =>
    'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';

String shinyArtworkUrl(int id) =>
    'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/shiny/$id.png';

String spriteUrl(int id) => 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$id.png';
