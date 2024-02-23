import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RecordPage extends StatefulWidget {
  const RecordPage({Key? key}) : super(key: key);

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  List<Map<String, dynamic>> records = [];
  String staffCode = '';
  String password = '';
  DateTime? selectedDate;

  GoogleMapController? mapController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    staffCode = args['staffCode'] ?? '';
    password = args['password'] ?? '';
  }

  Future<void> fetchRecords(DateTime? date) async {
    try {
      final response = await http.post(
        Uri.parse('https://www.wmps.in/staff/gps/location/record-data.php'),
        body: jsonEncode({'staffCode': staffCode, 'date': date?.toString()}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success']) {
          setState(() {
            records =
                List<Map<String, dynamic>>.from(responseData['records']);
          });
        } else {
          // No records found, clear existing records
          setState(() {
            records = [];
          });
          print('No records found: ${responseData['message']}');
        }
      } else {
        print('Failed to fetch records. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching records: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Track Records',
          style: TextStyle(color: Colors.blue, fontSize: 18.0),
        ),
        backgroundColor: Colors.grey[200],
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2015, 8),
                lastDate: DateTime.now(),
              );
              if (picked != null && picked != selectedDate) {
                setState(() {
                  selectedDate = picked;
                });
                fetchRecords(selectedDate);
              }
            },
          ),
        ],
      ),
      body: records.isEmpty
          ? const Center(
              child: Text('No records found'),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 200.0,
                  child: GoogleMap(
                    onMapCreated: (controller) {
                      setState(() {
                        mapController = controller;
                      });
                    },
                    initialCameraPosition: const CameraPosition(
                      target: LatLng(0, 0),
                      zoom: 15,
                    ),
                    markers: _buildMarkers(),
                  ),
                ),
                const SizedBox(height: 8.0),
                Expanded(
                  child: ListView.builder(
                    itemCount: records.length,
                    itemBuilder: (context, index) {
                      final record = records[index];
                      return ListTile(
                        title: Text('Location ${index + 1}: ${record['location']}'),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Set<Marker> _buildMarkers() {
    if (records.isNotEmpty && mapController != null) {
      return records.map((record) {
        final LatLng location = LatLng(
          record['latitude'] as double,
          record['longitude'] as double,
        );
        return Marker(
          markerId: MarkerId(location.toString()),
          position: location,
          infoWindow: InfoWindow(
            title: record['location'] as String,
          ),
        );
      }).toSet();
    }
    return {};
  }
}
