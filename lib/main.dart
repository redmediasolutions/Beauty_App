import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:glowfit/firebase_options.dart';
import 'package:glowfit/services/gorouter.dart';
import 'package:glowfit/services/pnsservice.dart';
import 'package:glowfit/services/remoteconfig.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();


  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await PushNotificationService.init();

  await RemoteConfigService.init();

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
   routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
      title: 'Glad Skin',
      theme: ThemeData()
    );
  }
}
