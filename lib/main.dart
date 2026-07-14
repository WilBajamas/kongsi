import 'package:flutter/material.dart';
import 'package:kongsi/core/config/app_config.dart';

void main() {
  runApp(
    MainApp(
      config: AppConfig.fromEnvironment(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({required this.config, super.key});

  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Hello World! (${config.flavor.name})'),
        ),
      ),
    );
  }
}
