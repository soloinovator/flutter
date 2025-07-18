// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/version.dart';
import 'package:flutter_tools/src/vscode/vscode.dart';

import '../../src/common.dart';
import '../../src/fake_process_manager.dart';

void main() {
  testWithoutContext('VsCodeInstallLocation equality', () {
    const installLocation1 = VsCodeInstallLocation('abc', 'zyx', edition: '123');
    const installLocation2 = VsCodeInstallLocation('abc', 'zyx', edition: '123');
    const installLocation3 = VsCodeInstallLocation('cba', 'zyx', edition: '123');
    const installLocation4 = VsCodeInstallLocation('abc', 'xyz', edition: '123');
    const installLocation5 = VsCodeInstallLocation('abc', 'xyz', edition: '321');

    expect(installLocation1, installLocation2);
    expect(installLocation1.hashCode, installLocation2.hashCode);
    expect(installLocation1, isNot(installLocation3));
    expect(installLocation1.hashCode, isNot(installLocation3.hashCode));
    expect(installLocation1, isNot(installLocation4));
    expect(installLocation1.hashCode, isNot(installLocation4.hashCode));
    expect(installLocation1, isNot(installLocation5));
    expect(installLocation1.hashCode, isNot(installLocation5.hashCode));
  });

  testWithoutContext('VsCode.fromDirectory does not crash when packages.json is malformed', () {
    final fileSystem = MemoryFileSystem.test();
    // Create invalid JSON file.
    fileSystem.file(fileSystem.path.join('', 'Resources', 'app', 'package.json'))
      ..createSync(recursive: true)
      ..writeAsStringSync('{');

    final vsCode = VsCode.fromDirectory(
      '',
      '',
      fileSystem: fileSystem,
      platform: const LocalPlatform(),
    );

    expect(vsCode.version, null);
  });

  testWithoutContext('VsCode.fromDirectory finds packages.json on Linux', () {
    // Regression test for https://github.com/flutter/flutter/issues/169812
    final fileSystem = MemoryFileSystem.test();
    // Installations on Linux appear to use $VSCODE_INSTALL/resources/app/package.json rather than
    // $VSCODE_INSTALL/Resources/app/package.json.
    fileSystem.file(fileSystem.path.join('', 'resources', 'app', 'package.json'))
      ..createSync(recursive: true)
      ..writeAsStringSync('{"version":"1.2.3"}');

    final vsCode = VsCode.fromDirectory('', '', fileSystem: fileSystem, platform: FakePlatform());

    expect(vsCode.version, Version(1, 2, 3));
  });

  testWithoutContext('can locate VS Code installed via Snap', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    const home = '/home/me';
    final Platform platform = FakePlatform(environment: <String, String>{'HOME': home});

    fileSystem
        .directory(fileSystem.path.join('/snap/code/current/usr/share/code', '.vscode'))
        .createSync(recursive: true);
    fileSystem
        .directory(
          fileSystem.path.join(
            '/snap/code-insiders/current/usr/share/code-insiders',
            '.vscode-insiders',
          ),
        )
        .createSync(recursive: true);

    final processManager = FakeProcessManager.list(<FakeCommand>[]);

    final List<VsCode> installed = VsCode.allInstalled(fileSystem, platform, processManager);
    expect(installed.length, 2);
  });

  testWithoutContext('can locate VS Code installed via Flatpak', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    const home = '/home/me';
    final Platform platform = FakePlatform(environment: <String, String>{'HOME': home});

    fileSystem
        .directory(
          fileSystem.path.join(
            '/var/lib/flatpak/app/com.visualstudio.code/x86_64/stable/active/files/extra/vscode',
            '.var/app/com.visualstudio.code/data/vscode',
          ),
        )
        .createSync(recursive: true);

    fileSystem
        .directory(
          fileSystem.path.join(
            '/var/lib/flatpak/app/com.visualstudio.code.insiders/x86_64/beta/active/files/extra/vscode-insiders',
            '.var/app/com.visualstudio.code.insiders/data/vscode-insiders',
          ),
        )
        .createSync(recursive: true);

    final processManager = FakeProcessManager.list(<FakeCommand>[]);

    final List<VsCode> installed = VsCode.allInstalled(fileSystem, platform, processManager);
    expect(installed.length, 2);
  });

  testWithoutContext('can locate installations on macOS', () {
    final FileSystem fileSystem = MemoryFileSystem.test();
    const home = '/home/me';
    final Platform platform = FakePlatform(
      operatingSystem: 'macos',
      environment: <String, String>{'HOME': home},
    );

    final String randomLocation = fileSystem.path.join('/', 'random', 'Visual Studio Code.app');
    fileSystem
        .directory(fileSystem.path.join(randomLocation, 'Contents'))
        .createSync(recursive: true);

    final String randomInsidersLocation = fileSystem.path.join(
      '/',
      'random',
      'Visual Studio Code - Insiders.app',
    );
    fileSystem
        .directory(fileSystem.path.join(randomInsidersLocation, 'Contents'))
        .createSync(recursive: true);

    fileSystem
        .directory(fileSystem.path.join('/', 'Applications', 'Visual Studio Code.app', 'Contents'))
        .createSync(recursive: true);
    fileSystem
        .directory(
          fileSystem.path.join(
            '/',
            'Applications',
            'Visual Studio Code - Insiders.app',
            'Contents',
          ),
        )
        .createSync(recursive: true);
    fileSystem
        .directory(fileSystem.path.join(home, 'Applications', 'Visual Studio Code.app', 'Contents'))
        .createSync(recursive: true);
    fileSystem
        .directory(
          fileSystem.path.join(
            home,
            'Applications',
            'Visual Studio Code - Insiders.app',
            'Contents',
          ),
        )
        .createSync(recursive: true);

    final processManager = FakeProcessManager.list(<FakeCommand>[
      FakeCommand(
        command: const <String>['mdfind', 'kMDItemCFBundleIdentifier="com.microsoft.VSCode"'],
        stdout: randomLocation,
      ),
      FakeCommand(
        command: const <String>[
          'mdfind',
          'kMDItemCFBundleIdentifier="com.microsoft.VSCodeInsiders"',
        ],
        stdout: randomInsidersLocation,
      ),
    ]);

    final List<VsCode> installed = VsCode.allInstalled(fileSystem, platform, processManager);
    expect(installed.length, 6);
    expect(processManager, hasNoRemainingExpectations);
  });
}
