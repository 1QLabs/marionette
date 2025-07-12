import 'package:dart_style/dart_style.dart';
import 'package:recase/recase.dart';

import 'node.dart';

class MarionetteBuilder {
  final String _root;
  final _formatter = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  );

  // Dart reserved keywords that need to be handled
  static const _dartKeywords = {
    'abstract',
    'as',
    'assert',
    'async',
    'await',
    'break',
    'case',
    'catch',
    'class',
    'const',
    'continue',
    'covariant',
    'default',
    'deferred',
    'do',
    'dynamic',
    'else',
    'enum',
    'export',
    'extends',
    'extension',
    'external',
    'factory',
    'false',
    'final',
    'finally',
    'for',
    'function',
    'get',
    'hide',
    'if',
    'implements',
    'import',
    'in',
    'interface',
    'is',
    'library',
    'mixin',
    'new',
    'null',
    'on',
    'operator',
    'part',
    'required',
    'rethrow',
    'return',
    'set',
    'show',
    'static',
    'super',
    'switch',
    'sync',
    'this',
    'throw',
    'true',
    'try',
    'typedef',
    'var',
    'void',
    'while',
    'with',
    'yield',
  };

  MarionetteBuilder({required String root}) : _root = root;

  String get _base => 'Marionette';

  String generate(Map<String, dynamic> json) {
    final data = _unflatten(_simplify(json));
    final buffer = StringBuffer();
    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln('// This file was generated using Marionette');
    buffer.writeln();
    buffer.writeln('import \'package:marionette/marionette.dart\';');
    buffer.writeln();
    buffer.writeln('class $_root extends $_base {');
    buffer.writeln(
      '  $_root({required super.getString, required super.getBool, required super.getDouble, required super.getInt});',
    );
    buffer.writeln();
    buffer.writeln(_generateGettersOrMethods(_root, data));
    buffer.writeln('}');
    buffer.writeln(_generateClasses(_root, data));
    buffer.writeln();
    final result = buffer.toString();
    return _formatter.format(result);
  }

  Map<String, dynamic> _simplify(Map<String, dynamic> data) {
    final result = <String, dynamic>{};
    final params = data['parameters'] as Map<String, dynamic>? ?? {};
    final groups = data['parameterGroups'] as Map<String, dynamic>? ?? {};

    for (var group in groups.entries) {
      final groupParams = group.value['parameters'] as Map<String, dynamic>?;
      if (groupParams != null) {
        for (var entry in groupParams.entries) {
          params[entry.key] = entry.value;
        }
      }
    }

    for (var entry in params.entries) {
      final valueType = entry.value['valueType'] as String? ?? 'STRING';
      final defaultValue =
          entry.value['defaultValue']?['value']?.toString() ?? '';

      switch (valueType) {
        case 'STRING':
          result[entry.key] = defaultValue;
          break;
        case 'JSON':
          // JSON values are stored as strings in Remote Config
          result[entry.key] = defaultValue;
          break;
        case 'BOOLEAN':
          result[entry.key] = defaultValue.toLowerCase() == 'true';
          break;
        case 'NUMBER':
          // Try to parse as int first, then double
          final intValue = int.tryParse(defaultValue);
          if (intValue != null) {
            result[entry.key] = intValue;
          } else {
            result[entry.key] = double.tryParse(defaultValue) ?? 0.0;
          }
          break;
        default:
          // Default to string for unknown types
          result[entry.key] = defaultValue;
      }
    }

    return result;
  }

  String _generateClasses(String parent, Map<String, dynamic> json) {
    final buffer = StringBuffer();
    for (final key in json.keys) {
      final value = json[key];
      if (value is Map<String, dynamic>) {
        final name = _createClassName(parent, key);
        buffer.writeln('class $name extends $_base {');
        buffer.writeln(
          '  $name({required super.getString, required super.getBool, required super.getDouble, required super.getInt});',
        );
        buffer.writeln(_generateGettersOrMethods(name, value));
        buffer.writeln('}');
        buffer.writeln(_generateClasses(name, value));
      }
    }
    return buffer.toString();
  }

  String _generateGettersOrMethods(String parent, Map<String, dynamic> json) {
    final buffer = StringBuffer();
    for (final key in json.keys) {
      final value = json[key];
      if (value is Map<String, dynamic>) {
        buffer.writeln('  ${_generateClassGetter(parent, key)}');
      } else if (value is Node<String> && _hasTemplateParameters(value.value)) {
        buffer.writeln('  ${_generateMethod(key, value)}');
      } else if (value is Node) {
        buffer.writeln('  ${_generateGetter(key, value)}');
      }
    }
    return buffer.toString();
  }

  String _generateClassGetter(String root, String key) {
    final getterName = _sanitizeIdentifier(key.camelCase);
    return '${_createClassName(root, key)} get $getterName => ${_createClassName(root, key)}(getString: getString, getBool: getBool, getDouble: getDouble, getInt: getInt);';
  }

  String _generateGetter(String key, Node node) {
    final buffer = StringBuffer();
    final getterName = _sanitizeIdentifier(key.camelCase);

    if (node is Node<bool>) {
      buffer.writeln('bool get $getterName => getBool(\'${node.key}\');');
    } else if (node is Node<double>) {
      buffer.writeln('double get $getterName => getDouble(\'${node.key}\');');
    } else if (node is Node<int>) {
      buffer.writeln('int get $getterName => getInt(\'${node.key}\');');
    } else {
      buffer.writeln(
        'String get $getterName => getString(\'${node.key}\').replaceAll(\'\\\\n\', \'\\n\');',
      );
    }
    return buffer.toString();
  }

  String _generateMethod(String key, Node node) {
    final buffer = StringBuffer();
    final params = _getParams(node.value);
    final args = params
        .map((param) => 'required String ${_sanitizeIdentifier(param)}')
        .join(', ');
    final methodName = _sanitizeIdentifier(key.camelCase);

    buffer.writeln(
      'String $methodName({$args}) => interpolation.eval(getString(\'${node.key}\'), {',
    );
    for (final param in params) {
      final sanitizedParam = _sanitizeIdentifier(param);
      buffer.writeln('  \'$param\': $sanitizedParam,');
    }
    buffer.writeln('});');
    return buffer.toString();
  }

  bool _hasTemplateParameters(String value) {
    // Check if the value contains template parameters like {param_name}
    // but not JSON structures like {"key": "value"}
    final templateRegex = RegExp(r'{([a-zA-Z_][a-zA-Z0-9_]*)}');
    return templateRegex.hasMatch(value);
  }

  List<String> _getParams(String value) {
    // Extract template parameters like {param_name} but not JSON keys
    final matches = RegExp(r'{([a-zA-Z_][a-zA-Z0-9_]*)}').allMatches(value);
    return matches.map((match) => match.group(1)).whereType<String>().toList();
  }

  String _sanitizeIdentifier(String identifier) {
    if (_dartKeywords.contains(identifier.toLowerCase())) {
      return '${identifier}Value';
    }

    // Handle identifiers that start with numbers or are empty
    if (identifier.isEmpty || RegExp(r'^[0-9]').hasMatch(identifier)) {
      return 'param$identifier';
    }

    return identifier;
  }

  Map<String, dynamic> _unflatten(Map<String, dynamic> data) {
    final result = <String, dynamic>{};
    for (final rawKey in data.keys) {
      final value = data[rawKey];
      final key =
          rawKey.startsWith('group_')
              ? rawKey.split('_').skip(1).join('_')
              : rawKey;
      final nodeKey =
          rawKey.startsWith('group_')
              ? rawKey.split('_').skip(2).join('_')
              : rawKey;
      if (key.contains('_')) {
        final parts = key.split('_');
        final last = parts.removeLast();
        Map<String, dynamic> current = result;
        for (final part in parts) {
          if (!current.containsKey(part)) {
            current[part] = <String, dynamic>{};
          }
          current = current[part] as Map<String, dynamic>;
        }
        current[last] = _createNode(nodeKey, value);
      } else {
        result[key] = _createNode(nodeKey, value);
      }
    }
    return result;
  }

  Node _createNode(String key, dynamic value) {
    if (value is bool) {
      return Node<bool>(key, value);
    } else if (value is int) {
      return Node<int>(key, value);
    } else if (value is double) {
      return Node<double>(key, value);
    } else {
      return Node<String>(key, value);
    }
  }

  String _createClassName(String root, String key) =>
      '${ReCase(root).pascalCase}${ReCase(key).pascalCase}';

  /// Extracts default values from Remote Config JSON and returns a simplified map
  /// with parameter names as keys and their default values with proper types.
  Map<String, dynamic> extractDefaults(Map<String, dynamic> json) {
    final simplified = _simplify(json);
    final result = <String, dynamic>{};

    for (var entry in simplified.entries) {
      result[entry.key] = entry.value;
    }

    return result;
  }

  /// Generates a Dart file containing a Map<String, dynamic> with default values
  String generateDefaultsFile(String className, Map<String, dynamic> defaults) {
    final buffer = StringBuffer();
    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln('// This file was generated using Marionette');
    buffer.writeln();
    buffer.writeln(
      '/// Default values for ${className} Remote Config parameters',
    );
    buffer.writeln('const Map<String, dynamic> remoteConfigDefaults = {');

    for (var entry in defaults.entries) {
      final key = entry.key;
      final value = entry.value;

      // Convert value to proper Dart literal
      final dartValue = _convertToDartLiteral(value);
      buffer.writeln('  \'$key\': $dartValue,');
    }

    buffer.writeln('};');
    buffer.writeln();

    final result = buffer.toString();
    return _formatter.format(result);
  }

  /// Converts a value to its proper Dart literal representation
  String _convertToDartLiteral(dynamic value) {
    if (value is bool) {
      return value.toString();
    } else if (value is int) {
      return value.toString();
    } else if (value is double) {
      return value.toString();
    } else if (value is String) {
      // Escape the string for Dart string literal
      final escapedValue = value
          .replaceAll('\\', '\\\\') // Escape backslashes first
          .replaceAll('\'', '\\\'') // Escape single quotes
          .replaceAll('\n', '\\n') // Escape newlines
          .replaceAll('\r', '\\r') // Escape carriage returns
          .replaceAll('\t', '\\t'); // Escape tabs
      return '\'$escapedValue\'';
    } else {
      // Fallback to string representation
      return '\'${value.toString()}\'';
    }
  }
}
