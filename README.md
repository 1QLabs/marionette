# Marionette

A Dart code generation library that creates type-safe classes from Firebase Remote Config default files. Marionette transforms Firebase Remote Config JSON schemas into clean, hierarchical Dart classes with getters and interpolation support, providing compile-time safety for your Firebase Remote Config parameters and defaults.

## Features

- **Type-safe Firebase Remote Config access**: Generate Dart classes with strongly-typed getters for Remote Config parameters (strings, booleans, numbers)
- **Hierarchical structure**: Organize Remote Config parameters into nested groups with corresponding class hierarchies
- **String interpolation**: Built-in support for parameterized Remote Config strings with runtime value substitution
- **Command-line interface**: Easy-to-use CLI tool for code generation from Firebase Remote Config schemas
- **Clean code output**: Generates well-formatted, readable Dart code with proper class structure

## Usage

### Command Line

```bash
dart run marionette --name FirebaseRemoteConfig --input firebase_remote_config.json --output lib/generated/remote_config.dart
```

### Input JSON Format

Marionette accepts JSON files exported from Firebase Remote Config with `parameters` and `parameterGroups`:

```json
{
  "parameters": {
    "app_name": {
      "valueType": "STRING",
      "defaultValue": {"value": "My App"}
    },
    "debug_mode": {
      "valueType": "BOOLEAN",
      "defaultValue": {"value": "true"}
    }
  },
  "parameterGroups": {
    "ui": {
      "parameters": {
        "welcome_message": {
          "valueType": "STRING",
          "defaultValue": {"value": "Welcome, {username}!"}
        }
      }
    }
  }
}
```

### Generated Code

The above Firebase Remote Config schema generates a class hierarchy like:

```dart
class FirebaseRemoteConfig extends Marionette {
  String get appName => getString('app_name');
  bool get debugMode => getBool('debug_mode');
  FirebaseRemoteConfigUi get ui => FirebaseRemoteConfigUi(...);
}

class FirebaseRemoteConfigUi extends Marionette {
  String welcomeMessage({required String username}) =>
    interpolation.eval(getString('welcome_message'), {'username': username});
}
```

## Use Cases

- **Firebase Remote Config defaults**: Generate type-safe classes for Firebase Remote Config parameter defaults
- **Feature flag management**: Create strongly-typed interfaces for Firebase Remote Config feature toggles
- **A/B testing with Firebase**: Manage Firebase Remote Config experiment parameters with compile-time safety
- **Remote localization**: Handle internationalization strings delivered via Firebase Remote Config
- **Dynamic app behavior**: Type-safe access to Firebase Remote Config controlled app settings and content
