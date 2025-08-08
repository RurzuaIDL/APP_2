import 'package:flutter/material.dart';
import 'package:front_2/screens/home.dart';
import 'package:front_2/screens/login.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Routing App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true), // enables Badge if on a new SDK
      initialRoute: '/login',
      routes: {
        '/login': (context) => const SignInPage2(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/home') {
          // Pass optional args safely
          return MaterialPageRoute(
            builder: (_) => const HomeScreen(),
            settings: settings, // keep args accessible in HomeScreen
          );
        }
        return null;
      },
    );
  }
}
