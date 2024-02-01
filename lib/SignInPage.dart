import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SignInPage extends StatefulWidget {
  const SignInPage({Key? key}) : super(key: key);

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController _staffCodeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordHidden = true;

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordHidden = !_isPasswordHidden;
    });
  }

Future<void> _login(BuildContext context) async {
  if (!mounted) return;

  final String staffCode = _staffCodeController.text.trim();
  final String password = _passwordController.text.trim();

  if (staffCode.isEmpty || password.isEmpty) {
    // Display an error message if staff code or password is empty
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Staff code and password cannot be empty'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  // Show loading indicator
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    },
  );

  final Uri url = Uri.parse('http://192.168.1.133:3000/login');
  final Map<String, String> requestBody = {'staffCode': staffCode, 'password': password};

  try {
    final http.Response response = await http.post(
      url,
      body: jsonEncode(requestBody),
      headers: {'Content-Type': 'application/json'},
    );

    if (!mounted) return;

    // Close loading indicator
    Navigator.pop(context);

    final Map<String, dynamic> responseData = json.decode(response.body);

    if (responseData['success']) {
      // Login successful
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      // Login failed, display error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(responseData['message']),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (error) {
    // Handle error and show error message in UI
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error during login: $error'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 82, 140, 248),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 55),
                const Text(
                  'Sign In',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'OpenSans',
                    fontSize: 30.0,
                    fontWeight: FontWeight.bold,
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
            color: const Color(0xFF6CA8F1),
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
              hintText: 'Enter your $labelText',
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
        onPressed: () => _login(context),
        style: ElevatedButton.styleFrom(
          elevation: 5.0,
          padding: const EdgeInsets.all(15.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
          primary: Colors.white,
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

