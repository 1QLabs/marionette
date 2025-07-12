import 'package:dart_style/dart_style.dart';
import 'package:recase/recase.dart';

class Parameter {
  final String valueType;
  Parameter(this.valueType);
}

class StringParameter extends Parameter {
  final String value;
  StringParameter(this.value) : super('STRING');
}

class BoolParameter extends Parameter {
  final bool value;
  BoolParameter(this.value) : super('BOOLEAN');
}

class MarionetteBuilder {
  final String _root;
  final _formatter = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  );

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
      '  $_root({required super.getString, required super.getBool, required super.getDouble});',
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
      final groupParams = group.value['parameters'] as Map<String, dynamic>;
      for (var entry in groupParams.entries) {
        params[entry.key] = entry.value;
      }
    }

    for (var entry in params.entries) {
      final valueType = entry.value['valueType'] as String;
      switch (valueType) {
        case 'STRING':
        case 'JSON':
          result[entry.key] = entry.value['defaultValue']['value'].toString();
          break;
        case 'BOOLEAN':
          result[entry.key] = entry.value['defaultValue']['value'] == 'true';
          break;
        case 'NUMBER':
          result[entry.key] =
              double.tryParse(entry.value['defaultValue']['value']) ?? 0;
          break;
        default:
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
          '  $name({required super.getString, required super.getBool, required super.getDouble,});',
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
      } else if (value is Node<String> && value.value.contains('{')) {
        buffer.writeln('  ${_generateMethod(key, value)}');
      } else if (value is Node) {
        buffer.writeln('  ${_generateGetter(key, value)}');
      }
    }
    return buffer.toString();
  }

  String _generateClassGetter(String root, String key) {
    return '${_createClassName(root, key)} get ${key.camelCase} => ${_createClassName(root, key)}(getString: getString, getBool: getBool, getDouble: getDouble,);';
  }

  String _generateGetter(String key, Node node) {
    final buffer = StringBuffer();
    if (node is Node<bool>) {
      buffer.writeln('bool get ${key.camelCase} => getBool(\'${node.key}\');');
    } else if (node is Node<double>) {
      buffer.writeln(
        'double get ${key.camelCase} => getDouble(\'${node.key}\');',
      );
    } else {
      buffer.writeln(
        'String get ${key.camelCase} => getString(\'${node.key}\').replaceAll(\'\\\\n\', \'\\n\');',
      );
    }
    return buffer.toString();
  }

  String _generateMethod(String key, Node node) {
    final buffer = StringBuffer();
    final params = _getParams(node.value);
    final args = params.map((param) => 'required String $param').join(', ');
    buffer.writeln(
      'String $key({$args}) => interpolation.eval(getString(\'${node.key}\'), {',
    );
    for (final param in params) {
      buffer.writeln('  \'$param\': $param,');
    }
    buffer.writeln('});');
    return buffer.toString();
  }

  List<String> _getParams(String value) {
    final matches = RegExp(r'{([^}]+)}').allMatches(value);
    return matches.map((match) => match.group(1)).whereType<String>().toList();
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
    } else if (value is double) {
      return Node<double>(key, value);
    } else {
      return Node<String>(key, value);
    }
  }

  String _createClassName(String root, String key) =>
      '${ReCase(root).pascalCase}${ReCase(key).pascalCase}';
}

class Node<T> {
  final String key;
  final T value;
  Node(this.key, this.value);
  toJson() => {'key': key, 'value': value};
}
