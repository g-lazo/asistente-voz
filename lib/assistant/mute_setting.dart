import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether the assistant keeps quiet; remembered between launches.
class MuteSetting extends ValueNotifier<bool> {
  MuteSetting(this._prefs) : super(_prefs.getBool(_key) ?? false);

  static const _key = 'assistant_muted';

  final SharedPreferences _prefs;

  Future<void> toggle() async {
    value = !value;
    await _prefs.setBool(_key, value);
  }
}
