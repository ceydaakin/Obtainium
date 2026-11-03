import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:obtainium/app_sources/fdroidrepo.dart';

const _repo = 'https://mirror.example.org/fdroid/repo';

Map<String, dynamic> _package(String name) => {
  'metadata': {
    'name': {'en-US': name},
  },
  'versions': {
    'a': {
      'added': 1792000000000,
      'file': {'name': '/$name.apk'},
      'manifest': {'versionName': '1.0', 'versionCode': 1},
    },
  },
};

final _index = jsonEncode({
  'packages': {
    'org.example.one': _package('one'),
    'org.example.two': _package('two'),
  },
});

class _CountingFDroidRepo extends FDroidRepo {
  final List<String> requested = [];
  bool fail = false;

  @override
  Future<List<String>> getSupportedAbis() async => ['arm64-v8a'];

  @override
  Future<http.Response> sourceRequest(
    String url,
    Map<String, dynamic> additionalSettings, {
    bool followRedirects = true,
    Object? postBody,
  }) async {
    requested.add(url);
    if (fail || url != '$_repo/index-v2.json') {
      return http.Response('Not found', 404);
    }
    return http.Response(
      _index,
      200,
      request: http.Request('GET', Uri.parse(url)),
    );
  }
}

void main() {
  test('apps from the same repo share one index download', () async {
    final source = _CountingFDroidRepo();
    final results = await Future.wait([
      source.getLatestAPKDetails('$_repo?appId=org.example.one', {}),
      source.getLatestAPKDetails('$_repo?appId=org.example.two', {}),
    ]);
    await source.getLatestAPKDetails('$_repo?appId=org.example.one', {});
    await source.search('', querySettings: {'url': _repo});
    expect(results.map((e) => e.apkUrls.single.value), [
      '$_repo/one.apk',
      '$_repo/two.apk',
    ]);
    expect(source.requested, ['$_repo/index-v2.json']);
  });

  test('a failed index fetch is not cached', () async {
    final source = _CountingFDroidRepo()..fail = true;
    await expectLater(
      source.getLatestAPKDetails('$_repo?appId=org.example.one', {}),
      throwsA(anything),
    );
    source.fail = false;
    final details = await source.getLatestAPKDetails(
      '$_repo?appId=org.example.one',
      {},
    );
    expect(details.apkUrls.single.value, '$_repo/one.apk');
  });
}
