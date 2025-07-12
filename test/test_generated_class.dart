import 'dart:io';

import 'remote_config.g.dart';

void main() {
  try {
    // Create a simple RemoteConfig instance
    final config = RemoteConfig(
      getString: (key) => 'test_string',
      getBool: (key) => true,
      getDouble: (key) => 1.0,
      getInt: (key) => 42,
    );

    print('✅ Successfully instantiated RemoteConfig class');
    print('✅ Class runtime type: ${config.runtimeType}');
    print('✅ All validation tests passed!');
  } catch (e, stackTrace) {
    print('❌ Failed to validate generated class: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}
