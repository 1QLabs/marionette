import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:marionette/marionette_builder.dart';
import 'package:path/path.dart' as path;

const inputArg = 'input';
const outputArg = 'output';
const nameArg = 'name';

Future<void> main(List<String> arguments) async {
  var parser = ArgParser();
  parser.addOption(nameArg);
  parser.addOption(inputArg);
  parser.addOption(outputArg);

  var args = parser.parse(arguments);

  final input = args[inputArg] as String?;
  final output = args[outputArg] as String?;
  final name = args[nameArg] as String?;

  if (name == null || input == null || output == null) {
    print('Usage: marionette --name <name> --input <input> --output <output>');
    return;
  }

  final inputPath = path.normalize(path.absolute(input));
  final inputFile = File(inputPath);

  if (!await inputFile.exists()) {
    throw Exception('File not found: $inputPath');
  }

  final json = await inputFile.readAsString();
  final data = jsonDecode(json) as Map<String, dynamic>;
  final builder = MarionetteBuilder(root: name);
  final result = builder.generate(data);

  final outputPath = path.normalize(path.absolute(output));
  final outputFile = File(outputPath);

  await outputFile.writeAsString(result);
}
