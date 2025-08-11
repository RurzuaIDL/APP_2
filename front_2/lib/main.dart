import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:front_2/screens/home.dart';
import 'package:front_2/screens/login.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = true;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: const Color(0xFF2F6FED), 
      brightness: Brightness.light,
    );


    final textTheme = GoogleFonts.interTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.montserrat(textStyle: base.textTheme.displayLarge),
      displayMedium: GoogleFonts.montserrat(textStyle: base.textTheme.displayMedium),
      displaySmall: GoogleFonts.montserrat(textStyle: base.textTheme.displaySmall),
      headlineLarge: GoogleFonts.montserrat(textStyle: base.textTheme.headlineLarge),
      headlineMedium: GoogleFonts.montserrat(textStyle: base.textTheme.headlineMedium),
      headlineSmall: GoogleFonts.montserrat(textStyle: base.textTheme.headlineSmall),
      titleLarge: GoogleFonts.montserrat(textStyle: base.textTheme.titleLarge),
      titleMedium: GoogleFonts.montserrat(textStyle: base.textTheme.titleMedium),
      titleSmall: GoogleFonts.montserrat(textStyle: base.textTheme.titleSmall),
    );

    return MaterialApp(
      title: 'Simple Routing App',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        textTheme: textTheme,
        appBarTheme: AppBarTheme(
          titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          centerTitle: true,
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const SignInPage2(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/home') {
          return MaterialPageRoute(
            builder: (_) => const HomeScreen(),
            settings: settings,
          );
        }
        return null;
      },
    );
  }
}
