import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/installers/root_installer.dart';
import 'package:obtainium/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SettingsProvider settings;
  late Directory sandbox;
  late File pmArgs;
  late File apk;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    settings = SettingsProvider();
    settings.prefs = await SharedPreferences.getInstance();
    sandbox = await Directory.systemTemp.createTemp('root_installer_test');
    pmArgs = File('${sandbox.path}/pm_args');
    apk = await File('${sandbox.path}/base.apk').writeAsString('apk');
  });

  tearDown(() async {
    await sandbox.delete(recursive: true);
  });

  Future<void> stub(String name, String body) async {
    final file = File('${sandbox.path}/bin/$name');
    await file.create(recursive: true);
    await file.writeAsString('#!/bin/sh\n$body\n');
    await Process.run('chmod', ['+x', file.path]);
  }

  Future<List<String>> installOn(
    String sdk, {
    String installerPackageName = '',
  }) async {
    final staging = '${sandbox.path}/staging';
    await stub('mktemp', 'mkdir -p "$staging" && echo "$staging"');
    await stub('am', 'echo 10');
    await stub('getprop', 'echo $sdk');
    await stub('pm', 'printf "%s\\n" "\$@" > "${pmArgs.path}"');
    final installer = RootInstaller(
      settings,
      runAsRoot: (cmd) => Process.run(
        'sh',
        ['-c', cmd],
        environment: {'PATH': '${sandbox.path}/bin:/usr/bin:/bin'},
      ),
    );
    final result = await installer.installApk(
      [apk.path],
      appId: 'com.example.app',
      installOptions: {'installerPackageName': installerPackageName},
    );
    expect(result.isSuccess, isTrue);
    return (await pmArgs.readAsString()).trim().split('\n');
  }

  test('bypasses the low target SDK block on Android 14+', () async {
    expect(await installOn('34'), [
      'install',
      '-r',
      '--bypass-low-target-sdk-block',
      '--user',
      '10',
      '${sandbox.path}/staging/obt0.apk',
    ]);
    expect(await installOn('36', installerPackageName: 'com.android.vending'), [
      'install',
      '-r',
      '--bypass-low-target-sdk-block',
      '-i',
      'com.android.vending',
      '--user',
      '10',
      '${sandbox.path}/staging/obt0.apk',
    ]);
  });

  test('omits the bypass flag where pm does not support it', () async {
    for (final sdk in ['33', '']) {
      expect(await installOn(sdk), [
        'install',
        '-r',
        '--user',
        '10',
        '${sandbox.path}/staging/obt0.apk',
      ]);
    }
  });
}
