import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/providers/apps_provider.dart';

void main() {
  final primary = Directory('/storage/emulated/0/Android/data/app/files');

  test('selects the external cache that lives on the primary volume', () {
    final chosen = selectPrimaryExternalCache([
      Directory('/storage/6331-6435/Android/data/app/cache'),
      Directory('/storage/emulated/0/Android/data/app/cache'),
    ], primary);
    expect(chosen?.path, '/storage/emulated/0/Android/data/app/cache');
  });

  test('ignores secondary volumes', () {
    final chosen = selectPrimaryExternalCache([
      Directory('/storage/6331-6435/Android/data/app/cache'),
    ], primary);
    expect(chosen, isNull);
  });

  test('returns null when the primary root is unknown', () {
    final chosen = selectPrimaryExternalCache([
      Directory('/storage/emulated/0/Android/data/app/cache'),
    ], null);
    expect(chosen, isNull);
  });

  group('prepareCacheDirs', cacheDirFallbackTests);
}

void cacheDirFallbackTests() {
  late Directory tmp;

  setUp(() => tmp = Directory.systemTemp.createTempSync('cache_dirs_'));
  tearDown(() {
    Process.runSync('chmod', ['-R', 'u+w', tmp.path]);
    tmp.deleteSync(recursive: true);
  });

  test('uses the external cache root when it can be created', () async {
    final root = Directory('${tmp.path}/ext/cache');
    final dirs = await prepareCacheDirs(
      root,
      () async => Directory('${tmp.path}/int'),
    );
    expect(dirs.apkDir.path, root.path);
    expect(dirs.iconsCacheDir.path, '${root.path}/icons');
    expect(dirs.iconsCacheDir.existsSync(), isTrue);
  });

  test(
    'falls back to the internal cache when the external root is denied',
    () async {
      final locked = Directory('${tmp.path}/locked')..createSync();
      Process.runSync('chmod', ['555', locked.path]);
      final dirs = await prepareCacheDirs(
        Directory('${locked.path}/app/cache'),
        () async => Directory('${tmp.path}/int'),
      );
      expect(dirs.apkDir.path, '${tmp.path}/int/apks');
      expect(dirs.iconsCacheDir.path, '${tmp.path}/int/icons');
      expect(dirs.apkDir.existsSync(), isTrue);
      expect(dirs.iconsCacheDir.existsSync(), isTrue);
    },
  );

  test('uses the internal cache when there is no external root', () async {
    final dirs = await prepareCacheDirs(
      null,
      () async => Directory('${tmp.path}/int'),
    );
    expect(dirs.apkDir.path, '${tmp.path}/int/apks');
  });
}
