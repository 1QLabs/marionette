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
