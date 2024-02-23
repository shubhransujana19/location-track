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
            'Bank Name': responseData['staffDetails']['bankname'] ?? 'Unknown Bank',
            'IFSC Code': responseData['staffDetails']['ifsc_code'] ?? '',
            'Account Number': responseData['staffDetails']['bankacc'] ?? '',
            'Account Holder Name': responseData['staffDetails']['staff_name'] ?? '',
            'PAN Card': responseData['staffDetails']['pan'] ?? '',
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
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        title: const Text(
          'My Bank Account',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white,),
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: bankDetails.entries.map((entry) {
                  return _buildDetailCard(entry.key, entry.value);
                }).toList(),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildDetailCard(String label, String value) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.white70,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
