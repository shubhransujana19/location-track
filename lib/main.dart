import 'package:flutter/material.dart';
import 'package:location/HomePage.dart';
import 'package:location/SignInPage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      title: 'Flutter Demo',
      home: const SignInPage(),
      routes: {
        '/signIn':(context) => const SignInPage(),
        '/home' :(context) => HomePage(),
      },
    );
  }
  
}




