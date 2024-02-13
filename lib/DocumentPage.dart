import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DocumentPage extends StatefulWidget {
  const DocumentPage({Key? key}) : super(key: key);

  @override
  State<DocumentPage> createState() => _DocumentPageState();
}

class _DocumentPageState extends State<DocumentPage> {
  String staffCode = '';
  String password = '';
  late Future<Map<String, String>> _documentDetailsFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Access context and arguments here
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    staffCode = args['staffCode'] ?? '';
    password = args['password'] ?? '';
    _documentDetailsFuture = _fetchDocumentDetails();
  }

  Future<Map<String, String>> _fetchDocumentDetails() async {
    try {
      final response = await http.post(
        Uri.parse('https://www.wmps.in/staff/gps/location.php'),
        body: jsonEncode({'staffCode': staffCode, 'password': password}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData != null && responseData['success']) {
          return {
            'aadhaar': responseData['staffDetails']['aadher'] ?? 'N/A',
            'voter': responseData['staffDetails']['voter'] ?? 'N/A',
            'epfno': responseData['staffDetails']['epfno'] ?? 'N/A',
            'esino': responseData['staffDetails']['esino'] ?? 'N/A',
            'panCard': responseData['staffDetails']['pan'] ?? 'N/A',
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
        title: const Text('Documents'),
        backgroundColor: const Color.fromARGB(255, 60, 121, 151),
      ),
      body: FutureBuilder<Map<String, String>>(
        future: _documentDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            return _buildDetailsList(snapshot.data!);
          } else {
            return const Center(child: Text('No data available'));
          }
        },
      ),
    );
  }

  Widget _buildDetailsList(Map<String, String> data) {
    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (context, index) {
        final label = data.keys.toList()[index];
        final value = data[label] ?? 'N/A';
        // Choose appropriate icon based on data label
        IconData icon = Icons.info_outline; // Placeholder
        if (label == 'aadhaar') {
          icon = Icons.credit_card;
        } else if (label == 'voter') {
          icon = Icons.how_to_vote;
        } else if (label == 'epfno') {
          icon = Icons.account_balance_wallet;
        } else if (label == 'esino') {
          icon = Icons.business;
        } else if (label == 'panCard') {
          icon = Icons.credit_card;
        }
        // ... customize icons for other labels
        return ListTile(
          leading: Icon(icon, size: 24.0, color: Color.fromARGB(255, 163, 111, 223)),
          title: Text(label, style: Theme.of(context).textTheme.titleMedium),
          trailing: Text(value, style: Theme.of(context).textTheme.bodyLarge),
        );
      },
    );
  }
}
