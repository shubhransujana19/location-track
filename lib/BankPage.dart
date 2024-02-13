import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class BankPage extends StatefulWidget {
  const BankPage({Key? key}) : super(key: key);

  @override
  State<BankPage> createState() => _BankPageState();
}

class _BankPageState extends State<BankPage> {
  late Future<Map<String, String>> _bankDetailsFuture;

  late String staffCode;
  late String password;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Access context and arguments here
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    staffCode = args['staffCode'] ?? '';
    password = args['password'] ?? '';
    _bankDetailsFuture = _fetchBankDetails();
  }

  Future<Map<String, String>> _fetchBankDetails() async {
    try {
      final response = await http.post(
        Uri.parse('https://www.wmps.in/staff/gps/location.php'),
        body: jsonEncode({'staffCode': staffCode, 'password': password}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData != null && responseData['success']) {
          return {
            'bankName': responseData['staffDetails']['bankname'] ?? 'Unknown Bank',
            'ifscCode': responseData['staffDetails']['ifsc_code'] ?? '',
            'accountNumber': responseData['staffDetails']['bankacc'] ?? '',
            'accountHolderName': responseData['staffDetails']['staff_name'] ?? '',
            'panCard': responseData['staffDetails']['pan'] ?? '',
          };
        } else {
          throw Exception('Failed to fetch bank details');
        }
      } else {
        throw Exception('Failed to fetch bank details: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Failed to fetch bank details: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          // Gradient background
          backgroundColor: const Color.fromARGB(255, 65, 120, 165), // Change to your desired color
          elevation: 0.0, // Remove default shadow
          title: const Text(
            'My Bank Account',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: FutureBuilder<Map<String, String>>(
          future: _bankDetailsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              final bankDetails = snapshot.data!;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch cards
                  children: [
                    _buildDetailCard(
                      const Color.fromARGB(255, 154, 108, 192), // Light blue background
                      TextStyle(
                        color: Colors.blue[800],
                        fontWeight: FontWeight.bold,
                      ),
                      const TextStyle(fontSize: 18.0),
                      'Bank Name:',
                      bankDetails['bankName']!,
                      'bankName',
                    ),
                    _buildDetailCard(
                      const Color.fromARGB(255, 135, 204, 135), // Light green background
                      TextStyle(
                        color: Colors.green[800],
                        fontWeight: FontWeight.bold,
                      ),
                      const TextStyle(fontSize: 18.0),
                      'IFSC Code:',
                      bankDetails['ifscCode']!,
                      'ifscCode',
                    ),
                    _buildDetailCard(
                      const Color.fromARGB(255, 255, 183, 77), // Light orange background
                      TextStyle(
                        color: Colors.orange[800],
                        fontWeight: FontWeight.bold,
                      ),
                      const TextStyle(fontSize: 18.0),
                      'Account Number:',
                      bankDetails['accountNumber']!,
                      'accountNumber',
                    ),
                    _buildDetailCard(
                      const Color.fromARGB(255, 255, 138, 128), // Light red background
                      TextStyle(
                        color: Colors.red[800],
                        fontWeight: FontWeight.bold,
                      ),
                      const TextStyle(fontSize: 18.0),
                      'Account Holder Name:',
                      bankDetails['accountHolderName']!,
                      'accountHolderName',
                    ),
                    _buildDetailCard(
                      const Color.fromARGB(255, 144, 202, 249), // Light blue background
                      TextStyle(
                        color: Colors.blue[800],
                        fontWeight: FontWeight.bold,
                      ),
                      const TextStyle(fontSize: 18.0),
                      'PAN Card:',
                      bankDetails['panCard']!,
                      'panCard',
                    ),
                    // Add more detail cards here
                  ],
                ),
              );
            }
          },
        ),
      );
    
  }

  Widget _buildDetailCard(
    Color cardColor,
    TextStyle labelStyle,
    TextStyle valueStyle,
    String label,
    String value,
    String s,
  ) {
    return Card(
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.lock, color: Colors.grey),
                Text(
                  label,
                  style: labelStyle,
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _isSensitiveData(value) ? _getMaskedValue(value) : value,
                    style: valueStyle,
                  ),
                ),
                if (_isSensitiveData(value)) ... {
                  IconButton(
                    icon: const Icon(Icons.visibility_off),
                    onPressed: () {
                      // Implement authentication and reveal full data securely
                    },
                  ),
                },
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _isSensitiveData(String value) {
    return value.contains('pan') || value.contains('account');
  }

  String _getMaskedValue(String value) {
    if (value.contains('pan')) {
      return "**** **** **** ${value.substring(12)}";
    } else if (value.contains('account')) {
      return "${value.substring(0, 3)}********${value.substring(value.length - 3)}";
    } else {
      return value;
    }
  }
}
