import 'package:flutter/material.dart';
import '/backend/backend.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'flutter_flow/flutter_flow_util.dart';

class FFAppState extends ChangeNotifier {
  static FFAppState _instance = FFAppState._internal();

  factory FFAppState() {
    return _instance;
  }

  FFAppState._internal();

  static void reset() {
    _instance = FFAppState._internal();
  }

  Future initializePersistedState() async {
    prefs = await SharedPreferences.getInstance();
    _safeInit(() {
      _track = prefs.getBool('ff_track') ?? _track;
    });
  }

  void update(VoidCallback callback) {
    callback();
    notifyListeners();
  }

  late SharedPreferences prefs;

  List<String> _debug = [];
  List<String> get debug => _debug;
  set debug(List<String> value) {
    _debug = value;
  }

  void addToDebug(String value) {
    debug.add(value);
  }

  void removeFromDebug(String value) {
    debug.remove(value);
  }

  void removeAtIndexFromDebug(int index) {
    debug.removeAt(index);
  }

  void updateDebugAtIndex(
    int index,
    String Function(String) updateFn,
  ) {
    debug[index] = updateFn(_debug[index]);
  }

  void insertAtIndexInDebug(int index, String value) {
    debug.insert(index, value);
  }

  bool _track = true;
  bool get track => _track;
  set track(bool value) {
    _track = value;
    prefs.setBool('ff_track', value);
  }

  LatLng? _trackedLocation = LatLng(0.0, 0.0);
  LatLng? get trackedLocation => _trackedLocation;
  set trackedLocation(LatLng? value) {
    _trackedLocation = value;
  }
}

void _safeInit(Function() initializeField) {
  try {
    initializeField();
  } catch (_) {}
}

Future _safeInitAsync(Function() initializeField) async {
  try {
    await initializeField();
  } catch (_) {}
}
