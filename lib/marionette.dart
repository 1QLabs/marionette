import 'package:interpolation/interpolation.dart';

abstract class Marionette {
  final String Function(String key) getString;
  final bool Function(String key) getBool;
  final double Function(String key) getDouble;
  final interpolation = Interpolation();

  Marionette({required this.getString, required this.getBool, required this.getDouble});

  String interpolate(String key, {required Map<String, dynamic> args}) {
    return interpolation.eval(getString(key), args);
  }
}
