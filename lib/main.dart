import 'package:flutter/material.dart';
import 'package:location/BankPage.dart';
import 'package:location/DocumentPage.dart';
import 'package:location/HomePage.dart';
import 'package:location/ProfilePage.dart';
import 'package:location/RecordPage.dart';
import 'package:location/SignInPage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      title: 'Flutter Demo',
      home: const SignInPage(),
      routes: {
        '/signIn':(context) => const SignInPage(),
        '/home' :(context) => const HomePage(),
        '/profile' :(context) => const ProfilePage(),
        '/bank' : (context) => const BankPage(),
        '/document' : (context) => const DocumentPage(),
        '/records' : (context) => const RecordsPage(),


      }
    );
  }
  
}




