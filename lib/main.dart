import 'package:material_ui/material_ui.dart';

import 'core/config/app_config.dart';

void main() {
  runApp(const UgymBusinessApp());
}

/// Root widget of the uGym Business mobile application.
final class UgymBusinessApp extends StatelessWidget {
  const UgymBusinessApp({super.key, this.config = const AppConfig.dev()});

  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'uGym Business',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(child: Text('uGym Business (${config.flavor.name})')),
      ),
    );
  }
}
