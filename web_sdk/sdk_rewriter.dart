// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

final ArgParser argParser = ArgParser()
  ..addOption('output-dir')
  ..addOption('config')
  ..addMultiOption('input');

const Pattern packageLibraryName = 'library ui;';
const Pattern packagePartName = 'part of ui;';
const Pattern coreLibraryName = 'library dart.ui;';
const Pattern corePartName = 'part of dart.ui;';

// Rewrites the "package"-style web ui library into a dart:ui implementation.
// So far this only requires a replace of the library declarations.
void main(List<String> arguments) {
  final ArgResults results = argParser.parse(arguments);
  final Directory directory = Directory(results['output-dir']);
  final Set<String> privateClasses = _findPrivateClasses(File(results['config']));

  if (!directory.existsSync()) {
    directory.createSync(recursive: true);
  }
  for (String inputFilePath in results['input']) {
    final File inputFile = File(inputFilePath);
    final String fileName = path.split(inputFilePath).last;
    final File outputFile = File(path.join(directory.path, fileName))
      ..createSync();
    String source;
    if (fileName == 'ui.dart') {
      source = inputFile.readAsStringSync()
        .replaceFirst(packageLibraryName, coreLibraryName);
      outputFile.writeAsStringSync(source);
    } else {
      source = inputFile.readAsStringSync()
        .replaceFirst(packagePartName, corePartName);
    }
    for (String privateClass in privateClasses) {
      source = source.replaceAll(privateClass, '_$privateClass');
    }
    outputFile.writeAsStringSync(source);
  }
}

// Find the classes to rename with _.
Set<String> _findPrivateClasses(File configFile) {
  final YamlMap config = loadYamlNode(configFile.readAsStringSync());
  final YamlList private = config['private'];
  return Set<String>.from(private);
}
