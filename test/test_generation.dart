#!/usr/bin/env dart

import 'dart:io';

Future<void> main(List<String> args) async {
  print('🚀 Testing Marionette CLI...\n');

  // Check if config file exists
  final configFile = File('test/remote_config.json');
  if (!await configFile.exists()) {
    print('❌ Config file not found: ${configFile.path}');
    exit(1);
  }
  print('✅ Found config file');

  // Clean up any existing generated files before starting
  final outputFile = File('test/remote_config.g.dart');
  if (await outputFile.exists()) {
    await outputFile.delete();
  }

  // Run the marionette binary
  try {
    print('🔨 Running marionette binary...');
    final result = await Process.run('dart', [
      'run',
      'bin/marionette.dart',
      '--template',
      'test/remote_config.json',
      'test',
    ]);

    if (result.exitCode != 0) {
      print('❌ Marionette binary failed with exit code ${result.exitCode}');
      print('STDERR: ${result.stderr}');
      exit(1);
    }

    print('✅ Marionette binary executed successfully');
  } catch (e) {
    print('❌ Failed to run marionette binary: $e');
    exit(1);
  }

  // Validate the output file was created
  if (!await outputFile.exists()) {
    print('❌ Generated file not found: ${outputFile.path}');
    exit(1);
  }

  // Read the generated code
  final generatedCode = await outputFile.readAsString();
  print('✅ Generated code (${generatedCode.length} characters)');

  // Run the class validation test
  try {
    print('🔍 Loading and validating generated class...');
    final result = await Process.run('dart', [
      'run',
      'test/test_generated_class.dart',
    ]);

    if (result.exitCode != 0) {
      print('❌ Generated class validation failed:');
      print('STDOUT: ${result.stdout}');
      print('STDERR: ${result.stderr}');
      exit(1);
    }

    print('✅ Generated class loaded and validated successfully');
    print('Output: ${result.stdout}');
  } catch (e) {
    print('❌ Failed to run class validation: $e');
    exit(1);
  }

  print(
    '\n🎉 Test passed! CLI successfully generated a valid, loadable class.',
  );
  print('Generated file: ${outputFile.path}');
}
