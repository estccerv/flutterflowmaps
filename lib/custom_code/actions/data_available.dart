// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:async';
import '../../auth/base_auth_user_provider.dart';

Future dataAvailable() async {
  // Add your function code here!
  Completer<void> completer = Completer<void>();
  BaseAuthUser? user = await currentUser;
  if (user != null) {
    await Future.delayed(const Duration(milliseconds: 1500));
  }
  completer.complete();
  return completer.future;
}
