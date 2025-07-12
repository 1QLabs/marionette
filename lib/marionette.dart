import 'package:interpolation/interpolation.dart';

abstract class Marionette {
  final bool Function(String key) getBool;
  final double Function(String key) getDouble;
  final int Function(String key) getInt;
  final String Function(String key) getString;
  final interpolation = Interpolation();

  Marionette({
    required this.getBool,
    required this.getDouble,
    required this.getInt,
    required this.getString,
  });

  String interpolate(String key, {required Map<String, dynamic> args}) {
    return interpolation.eval(getString(key), args);
  }
}
