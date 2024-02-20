import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({Key? key}) : super(key: key);

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController _staffCodeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordHidden = true;
  final Connectivity _connectivity = Connectivity();

  @override
  void initState() {
    super.initState();
    // Check if user credentials are stored locally
    _checkSavedCredentials();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordHidden = !_isPasswordHidden;
    });
  }

  Future<void> _checkSavedCredentials() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? storedStaffCode = prefs.getString('staffCode');
    final String? storedPassword = prefs.getString('password');

    if (storedStaffCode != null && storedPassword != null) {
      // Automatically log in with stored credentials
      _staffCodeController.text = storedStaffCode;
      _passwordController.text = storedPassword;
      _login(context);
    }
  }

  Future<void> _login(BuildContext context) async {
    final String staffCode = _staffCodeController.text.trim();
    final String password = _passwordController.text.trim();

    if (staffCode.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Staff code and password cannot be empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    final Uri url = Uri.parse('https://www.wmps.in/staff/gps/location.php');
    final Map<String, String> requestBody = {'staffCode': staffCode, 'password': password};

    try {
      final http.Response response = await http.post(
        url,
        body: jsonEncode(requestBody),
        headers: {'Content-Type': 'application/json'},
      );

      Navigator.pop(context); // Close loading indicator

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData.containsKey('success') && responseData['success']) {
          // Store credentials locally
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setString('staffCode', staffCode);
          prefs.setString('password', password);

          Navigator.pushReplacementNamed(
            context, '/home',
            arguments: {'staffCode': staffCode, 'password': password},
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message'] ?? 'Login failed'),
              backgroundColor: const Color.fromARGB(164, 244, 67, 54),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('HTTP Error: ${response.statusCode}'),
            backgroundColor: const Color.fromARGB(164, 244, 67, 54),
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error during login: $error'),
          backgroundColor: const Color.fromARGB(178, 212, 27, 14),
        ),
      );
      print('Error during login: $error');
    }
  }

  Future<void> _loginIfConnected(BuildContext context) async {
    final ConnectivityResult connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      // Device is not connected to the internet
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No internet connection. Please check your connection and try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      // Device is connected, proceed with login
      _login(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(50, 112, 172, 228),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 25),
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 100,
                  ),
                ),
                const SizedBox(height: 55),
                _buildTextField('Staff Code', _staffCodeController, Icons.person_outline),
                const SizedBox(height: 25),
                _buildTextField('Password', _passwordController, Icons.lock, suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordHidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: const Color.fromARGB(255, 224, 243, 248),
                  ),
                  onPressed: _togglePasswordVisibility,
                )),
                const SizedBox(height: 25),
                _buildLoginBtn(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String labelText, TextEditingController controller, IconData icon, {Widget? suffixIcon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'OpenSans',
          ),
        ),
        const SizedBox(height: 10.0),
        Container(
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: const Color.fromARGB(167, 22, 65, 94),
            borderRadius: BorderRadius.circular(15.0),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6.0, offset: Offset(0, 2))],
          ),
          height: 60.0,
          child: TextFormField(
            controller: controller,
            obscureText: labelText == 'Password' ? _isPasswordHidden : false,
            style: const TextStyle(color: Colors.white, fontFamily: 'OpenSans'),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.only(top: 14.0),
              prefixIcon: Icon(icon, color: Colors.white),
              hintText: ' $labelText',
              hintStyle: const TextStyle(color: Colors.white54),
              suffixIcon: suffixIcon,
            ),
            validator: (value) => value!.isEmpty ? 'Please enter your $labelText' : null,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginBtn() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 25.0),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _loginIfConnected(context),
        style: ElevatedButton.styleFrom(
          elevation: 5.0, backgroundColor: Colors.white,
          padding: const EdgeInsets.all(15.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
        ),
        child: const Text(
          'LOGIN',
          style: TextStyle(
            color: Color(0xFF527DAA),
            letterSpacing: 1.5,
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            fontFamily: 'OpenSans',
          ),
        ),
      ),
    );
  }
}
