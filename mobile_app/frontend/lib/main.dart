import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:vehnicate_frontend/app.dart';
import 'package:vehnicate_frontend/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const App());
}

