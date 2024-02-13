import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Variables for fetched data
  String staffCode = '';
  String password = '';
  String staffName = 'Loading...';
  String designation = '';
  String location = '';
  String staffPhoto = '';
  String photoPath = '';
  String phoneNumber = '';
  String emailAddress = '';
  int salary = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    staffCode = args['staffCode'] ?? '';
    password = args['password'] ?? '';
    fetchStaffDetails();
  }

  // Fetches staff details from API
  Future<void> fetchStaffDetails() async {
    try {
      final response = await http.post(
        Uri.parse('https://www.wmps.in/staff/gps/location.php'),
        body: jsonEncode({'staffCode': staffCode, 'password': password}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('Response Data: $responseData');

        if (responseData != null && responseData['success']) {
          setState(() {
            staffName = responseData['staffDetails']['staff_name'] ?? 'Unknown';
            designation = responseData['staffDetails']['department'] ?? '';
            location = responseData['staffDetails']['address'] ?? '';
            photoPath = responseData['staffDetails']['photo'];
            staffPhoto = 'https://www.wmps.in/staff/document/photo/$photoPath';
            phoneNumber = responseData['staffDetails']['phone'] ?? '';
            emailAddress = responseData['staffDetails']['email'] ?? '';
            salary = responseData['staffDetails']['salary'] ?? 0;
          });
        } else {
          setState(() {
            staffName = 'Failed to load data: ${responseData['message']}';
          });
        }
      } else {
        // setState(() {
        //   staffName = 'Failed to load data: ${response.statusCode}';
        // });
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (error) {
      // setState(() {
      //   staffName = 'Failed to load data: $error';
      // });
      print('Error fetching data: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200], // Subtle background
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 62, 116, 160), // Brand primary color
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white, // High contrast text
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile card with rounded corners and shadow
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.0),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromARGB(255, 224, 224, 224),
                      blurRadius: 5.0,
                      spreadRadius: 1.0,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 50.0,
                      backgroundImage: staffPhoto.isNotEmpty
                          ? NetworkImage(staffPhoto)
                          : NetworkImage('https://i.guim.co.uk/img/media/97fc02c0ed01d16b8090846535695cb1daa4d084/0_150_2000_1199/master/2000.jpg?width=465&dpr=1&s=none'), // Placeholder image
                    ),
                    const SizedBox(width: 20.0),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          staffName,
                          style: const TextStyle(
                            fontSize: 20.0,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          designation,
                          style: const TextStyle(
                            fontSize: 16.0,
                            color: Color.fromARGB(255, 117, 117, 117),
                          ),
                        ),
                      Container(
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.5), // Adjust width as needed
                        child: Text(
                          location,
                          textAlign: TextAlign.justify,
                          style: const TextStyle(
                            fontSize: 14.0,
                            color: Color.fromARGB(255, 117, 117, 117),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30.0),

              // Card for contact information with clear heading and border
              Card(
                elevation: 2.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Contact Information',
                        style: TextStyle(
                          fontSize: 18.0,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10.0),
                      Row(
                        children: [
                          const Icon(Icons.phone, color: Colors.blue),
                          const SizedBox(width: 10.0),
                          Text(
                            phoneNumber,
                            style: const TextStyle(
                              fontSize: 16.0,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10.0),
                      Row(
                        children: [
                          const Icon(Icons.email, color: Colors.blue),
                          const SizedBox(width: 10.0),
                          Text(
                            emailAddress,
                            style: const TextStyle(
                              fontSize: 16.0,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10.0),
                      Row(
                        children: [
                          const Icon(Icons.currency_rupee, color: Colors.blue),
                          const SizedBox(width: 10.0),
                          Text(
                            'Salary: ₹$salary',
                            style: const TextStyle(
                              fontSize: 16.0,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
