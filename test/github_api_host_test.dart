import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/app_sources/github.dart';

GitHub overriddenTo(String host) => GitHub(hostChanged: true)..hosts = [host];

void main() {
  test('uses api.github.com for github.com', () async {
    expect(
      await GitHub().convertStandardUrlToAPIUrl(
        'https://github.com/owner/repo',
        {},
      ),
      'https://api.github.com/repos/owner/repo',
    );
  });

  test('uses /api/v3 for a GitHub Enterprise Server host', () async {
    expect(
      await overriddenTo(
        'git.example.com',
      ).convertStandardUrlToAPIUrl('https://git.example.com/owner/repo', {}),
      'https://git.example.com/api/v3/repos/owner/repo',
    );
  });

  test('keeps the api subdomain for GHE.com hosts', () async {
    expect(
      await overriddenTo(
        'octocorp.ghe.com',
      ).convertStandardUrlToAPIUrl('https://octocorp.ghe.com/owner/repo', {}),
      'https://api.octocorp.ghe.com/repos/owner/repo',
    );
  });

  test('treats an override to github.com as github.com', () async {
    final source = overriddenTo('github.com')
      ..hostIdenticalDespiteAnyChange = true;
    expect(
      await source.convertStandardUrlToAPIUrl(
        'https://github.com/owner/repo',
        {},
      ),
      'https://api.github.com/repos/owner/repo',
    );
  });
}
