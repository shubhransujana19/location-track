import 'package:flutter/material.dart';
import 'package:location/BankPage.dart';
import 'package:location/DocumentPage.dart';
import 'package:location/HomePage.dart';
import 'package:location/ProfilePage.dart';
import 'package:location/RecordPage.dart';
import 'package:location/SignInPage.dart';
import 'package:location/back_services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async{
    WidgetsFlutterBinding.ensureInitialized();
    
  await Permission.notification.isDenied.then(
    (value) {
      if(value){
        Permission.notification.request();
      }
  });
  await initializeService();
  await SharedPreferences.getInstance();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      title: 'Wmps',
      home: const SignInPage(),
      routes: {
        '/signIn':(context) => const SignInPage(),
        '/home' :(context) => const HomePage(),
        '/profile' :(context) => const ProfilePage(),
        '/bank' : (context) => const BankPage(),
        '/document' : (context) => const DocumentPage(),
        '/records' : (context) => const RecordPage(),

      }
    );
  }
  
}




