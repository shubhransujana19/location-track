import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // for launching phone calls

class ContactPage extends StatelessWidget {
  const ContactPage({Key? key}) : super(key: key);

  void _callSupport() async {
    final phoneNumber = '7407895189'; // Replace with your actual phone number
    final url = 'tel:$phoneNumber';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch phone call';
    }
  }

  void _sendEmail() async {
    final url = 'mailto:info@wmps.in?subject=Customer Support';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      // Handle error
      print('Could not launch email client');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Contact Us',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.0, // Remove default shadow
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Image.asset(
                'assets/images/logo.png',
                // fit: BoxFit.fitWidth,
                height: 10,
              ),
            ),
            const SizedBox(height: 10.0),
            ElevatedButton.icon(
              onPressed: _callSupport,
              icon: const Icon(Icons.phone, size: 24.0),
              label: const Text(
                'Call Us',
                style: TextStyle(fontSize: 20.0),
              ),
              style: ElevatedButton.styleFrom(
                primary: Colors.blue,
                onPrimary: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
            ),
            const SizedBox(height: 20.0),
            ElevatedButton.icon(
              onPressed: _sendEmail,
              icon: const Icon(Icons.email, size: 24.0),
              label: const Text(
                'Send Email',
                style: TextStyle(fontSize: 20.0),
              ),
              style: ElevatedButton.styleFrom(
                primary: Colors.green,
                onPrimary: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
            ),
            const SizedBox(height: 20.0),
            TextButton(
              onPressed: () {
                // Implement FAQ or Help Center link
              },
              child: const Text(
                'Visit our FAQ & Help Center',
                style: TextStyle(
                  fontSize: 18.0,
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
