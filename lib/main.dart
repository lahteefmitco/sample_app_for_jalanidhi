import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/app/app.dart';
import 'package:sample_app_for_jalanidhi/app/app_initializer.dart';

Future<void> main() async {
  final String initialRoute = await AppInitializer.initialize();
  runApp(App(initialRoute: initialRoute));
}
