import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:marionette/marionette_builder.dart';
import 'package:path/path.dart' as path;
import 'package:recase/recase.dart';

const nameArg = 'name';

Future<void> main(List<String> arguments) async {
  var parser = ArgParser();
  parser.addOption(nameArg);
  parser.addFlag('help', abbr: 'h', help: 'Show usage information');
  parser.addOption(
    'template',
    help: 'Path to local template file (skips Firebase CLI fetch)',
  );
  parser.addOption(
    'version-number',
    help: 'Version number of the remote config template to fetch',
  );
  parser.addOption(
    'project',
    help: 'Firebase project ID to fetch remote config from',
  );
  parser.addFlag(
    'debug',
    help: 'Save the remote config template to output directory',
  );
  parser.addFlag('no-defaults', help: 'Skip generating the defaults JSON file');

  ArgResults args;
  try {
    args = parser.parse(arguments);
  } catch (e) {
    print('Error parsing arguments: $e');
    print('Use --help for usage information.');
    exit(1);
  }

  if (args['help'] == true) {
    print('Usage: marionette [output_directory] [options]');
    print('');
    print(
      'Generate Dart code and defaults JSON from Firebase Remote Config data.',
    );
    print('');
    print('Arguments:');
    print(
      '  output_directory    Directory to output generated files (defaults to current directory)',
    );
    print('');
    print('Options:');
    print(parser.usage);
    print('');
    print('Examples:');
    print('  # Generate both Dart code and defaults JSON');
    print('  marionette --template config.json lib/');
    print('');
    print('  # Generate only Dart code (skip defaults JSON)');
    print('  marionette --template config.json --no-defaults lib/');
    return;
  }

  final out = args.rest.isNotEmpty ? args.rest.first : '.';
  final name = args[nameArg] as String? ?? "RemoteConfig";
  final templatePath = args['template'] as String?;
  final versionNumber = args['version-number'] as String?;
  final projectId = args['project'] as String?;
  final debug = args['debug'] == true;
  final skipDefaults = args['no-defaults'] == true;

  final outPath = path.normalize(path.absolute(out));
  final outDir = Directory(outPath);

  try {
    if (!await outDir.exists()) {
      await outDir.create(recursive: true);
    }
  } catch (e) {
    print('Error creating output directory: $e');
    exit(1);
  }

  Map<String, dynamic> data;
  String? rawJsonContent;

  try {
    if (templatePath != null) {
      // Use local template file
      final result = await _loadLocalTemplate(templatePath);
      data = result['data'] as Map<String, dynamic>;
      rawJsonContent = result['rawContent'] as String?;
    } else {
      // Check for Firebase CLI and fetch remote config
      final result = await _fetchRemoteConfig(versionNumber, projectId);
      data = result['data'] as Map<String, dynamic>;
      rawJsonContent = result['rawContent'] as String?;
    }
  } catch (e) {
    print('Error loading template data: $e');
    exit(1);
  }

  try {
    final builder = MarionetteBuilder(root: name);

    // Generate Dart code
    final result = builder.generate(data);
    final dartOutputFile = File(path.join(outPath, '${name.snakeCase}.g.dart'));
    await dartOutputFile.writeAsString(result);
    print('Generated: ${dartOutputFile.path}');

    // Generate defaults JSON by default (unless disabled)
    if (!skipDefaults) {
      final defaults = builder.extractDefaults(data);
      final encoder = JsonEncoder.withIndent('  ');
      final defaultsJson = encoder.convert(defaults);

      final defaultsOutputFile = File(
        path.join(outPath, '${name.snakeCase}_defaults.g.json'),
      );
      await defaultsOutputFile.writeAsString(defaultsJson);
      print('Generated defaults: ${defaultsOutputFile.path}');
    }

    // Save debug file if requested
    if (debug && rawJsonContent != null) {
      final debugFile = File(
        path.join(outPath, '${name.snakeCase}_template.json'),
      );
      await debugFile.writeAsString(rawJsonContent);
      print('Debug template saved: ${debugFile.path}');
    }
  } catch (e) {
    print('Error generating output: $e');
    exit(1);
  }
}

Future<Map<String, dynamic>> _loadLocalTemplate(String templatePath) async {
  final templateFile = File(path.normalize(path.absolute(templatePath)));

  if (!await templateFile.exists()) {
    throw Exception('Template file not found: ${templateFile.path}');
  }

  try {
    final jsonContent = await templateFile.readAsString();
    final data = jsonDecode(jsonContent) as Map<String, dynamic>;
    return {'data': data, 'rawContent': jsonContent};
  } catch (e) {
    throw Exception('Failed to parse template file: $e');
  }
}

Future<Map<String, dynamic>> _fetchRemoteConfig(
  String? versionNumber,
  String? projectId,
) async {
  // Check if Firebase CLI is installed
  try {
    final result = await Process.run('firebase', ['--version']);
    if (result.exitCode != 0) {
      throw Exception('Firebase CLI is not installed or not in PATH');
    }
  } catch (e) {
    throw Exception('Firebase CLI is not installed or not in PATH: $e');
  }

  // Check if user is authenticated
  try {
    final result = await Process.run('firebase', ['projects:list']);
    if (result.exitCode != 0) {
      throw Exception(
        'Firebase CLI is not authenticated. Run "firebase login" first.',
      );
    }
  } catch (e) {
    throw Exception('Firebase CLI authentication check failed: $e');
  }

  // Create temporary directory
  final tempDir = await Directory.systemTemp.createTemp('marionette_');
  final tempFile = File(path.join(tempDir.path, 'remote_config.json'));

  try {
    // Fetch remote config template
    final args = ['remoteconfig:get', '--output', tempFile.path];
    if (versionNumber != null) {
      args.add('--version-number');
      args.add(versionNumber);
    }
    if (projectId != null) {
      args.add('--project');
      args.add(projectId);
    }

    final result = await Process.run('firebase', args);

    if (result.exitCode != 0) {
      throw Exception('Failed to fetch remote config: ${result.stderr}');
    }

    // Read and parse the fetched data
    final jsonContent = await tempFile.readAsString();
    final data = jsonDecode(jsonContent) as Map<String, dynamic>;

    return {'data': data, 'rawContent': jsonContent};
  } finally {
    // Clean up temporary directory
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (e) {
      // Log cleanup error but don't fail the operation
      print('Warning: Failed to cleanup temporary directory: $e');
    }
  }
}
