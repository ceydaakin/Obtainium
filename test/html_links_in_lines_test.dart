import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/app_sources/html.dart';

List<String> urls(String lines) =>
    getLinksInLines(lines).map((e) => e.key).toList();

void main() {
  group('getLinksInLines', () {
    test('keeps parentheses inside a URL', () {
      const url =
          'https://static.gl-inet.com/edge-app-staging/gl-inet-app-google/'
          '2.9.0/1793610269715/glinet-app_2.9.0(275)_en.apk';
      final links = getLinksInLines(url);
      expect(links.map((e) => e.key), [url]);
      expect(links.single.value, 'glinet-app_2.9.0(275)_en.apk');
    });

    test('drops a closing parenthesis that belongs to surrounding text', () {
      expect(urls('Download (https://example.com/app.apk) now'), [
        'https://example.com/app.apk',
      ]);
    });

    test('drops trailing punctuation around a closing parenthesis', () {
      expect(urls('See (https://example.com/app(1).apk).'), [
        'https://example.com/app(1).apk',
      ]);
    });

    test('keeps a balanced trailing parenthesis', () {
      expect(urls('https://example.com/wiki/App_(Android)'), [
        'https://example.com/wiki/App_(Android)',
      ]);
    });

    test('still strips trailing sentence punctuation', () {
      expect(urls('Get it at https://example.com/app.apk, or not.'), [
        'https://example.com/app.apk',
      ]);
    });
  });

  test('grabLinksCommon finds an APK URL with parentheses in JSON', () async {
    const url =
        'https://static.gl-inet.com/edge-app-staging/gl-inet-app-google/'
        '2.9.0/1793610269715/glinet-app_2.9.0(275)_en.apk';
    final links = await grabLinksCommon(
      '{"url": "$url"}',
      Uri.parse('https://edge-api.gl-inet.com/api/apps/latest/x'),
      {},
    );
    expect(links.map((e) => e.key), [url]);
  });
}
