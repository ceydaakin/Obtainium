import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/providers/apps_provider_lifecycle.dart';

class _FlushRecordingFile implements File {
  _FlushRecordingFile(this._inner, this._flushes);

  final File _inner;
  final List<bool> _flushes;

  @override
  String get path => _inner.path;

  @override
  Future<File> writeAsString(
    String contents, {
    FileMode mode = FileMode.write,
    Encoding encoding = utf8,
    bool flush = false,
  }) {
    _flushes.add(flush);
    return _inner.writeAsString(
      contents,
      mode: mode,
      encoding: encoding,
      flush: flush,
    );
  }

  @override
  Future<File> rename(String newPath) => _inner.rename(newPath);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('app_json_write'));
  tearDown(() => dir.deleteSync(recursive: true));

  test(
    'flushes the temp file to disk before renaming it over the app JSON',
    () async {
      final filePath = '${dir.path}/app.json';
      final tmpPath = '$filePath.1.tmp';
      File(filePath).writeAsStringSync('{"old":true}');
      final flushes = <bool>[];

      await IOOverrides.runZoned(
        () => replaceFileContents(filePath, tmpPath, '{"new":true}'),
        createFile: (path) =>
            _FlushRecordingFile(Zone.root.run(() => File(path)), flushes),
      );

      expect(flushes, [true]);
      expect(File(filePath).readAsStringSync(), '{"new":true}');
      expect(File(tmpPath).existsSync(), isFalse);
    },
  );
}
