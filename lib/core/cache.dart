import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// A tiny JSON cache on disk: one file per key, with the time it was written.
/// Used so the app works offline for anything already seen, and so it asks
/// PokéAPI for each resource only once, as its fair use policy requests.
class DiskCache {
  DiskCache(this._dir);

  final Directory _dir;

  static Future<DiskCache> open() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/pokeapi-cache');
    await dir.create(recursive: true);
    return DiskCache(dir);
  }

  File _file(String key) => File('${_dir.path}/${key.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')}.json');

  /// The cached value and its age, or null when nothing is stored.
  Future<({Object? value, Duration age})?> read(String key) async {
    final file = _file(key);
    if (!await file.exists()) return null;
    try {
      final age = DateTime.now().difference(await file.lastModified());
      return (value: jsonDecode(await file.readAsString()), age: age);
    } on FormatException {
      await file.delete();
      return null;
    }
  }

  Future<void> write(String key, Object? value) async {
    final file = _file(key);
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(jsonEncode(value), flush: true);
    await tmp.rename(file.path);
  }

  Future<int> sizeInBytes() async {
    var total = 0;
    await for (final entity in _dir.list()) {
      if (entity is File) total += await entity.length();
    }
    return total;
  }

  Future<void> clear() async {
    await for (final entity in _dir.list()) {
      await entity.delete();
    }
  }
}
