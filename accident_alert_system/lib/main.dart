import 'package:accident_alert_system/auth/register_page.dart';
import 'package:accident_alert_system/auth/login_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    //Firebase for Web
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyA70WpmLnDPcF8CBHvNTXOq3BecxXUG9DI",
        authDomain: "accident-alert-system-30ea4.firebaseapp.com",
        projectId: "accident-alert-system-30ea4",
        messagingSenderId: "261655854283",
        appId: "1:261655854283:web:5d66231e48ca78cfe9ef4e",
        measurementId: "G-LYDLCZ5R07",
      ),
    );
  } else {
    //Firebase for Android & iOS
    await Firebase.initializeApp();
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      initialRoute: '/register',
      routes: {
        '/register': (context) => RegisterPage(),
        '/login': (context) => LoginPage(), // make sure to import this
      },
    );
  }
}
