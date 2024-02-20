import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class RecordPage extends StatefulWidget {
  const RecordPage({Key? key}) : super(key: key);

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  List<Map<String, dynamic>> records = [];
  String staffCode = '';
  String password = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    staffCode = args['staffCode'] ?? '';
    password = args['password'] ?? '';
    fetchRecords();
  }

  Future<void> fetchRecords() async {
    try {
      final response = await http.post(
        Uri.parse('https://www.wmps.in/staff/gps/location/record-data.php'),
        body: jsonEncode({'staffCode': staffCode}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success']) {
          setState(() {
            records = List<Map<String, dynamic>>.from(responseData['records']);
          });
        } else {
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
        title: const Text('Track Records'),
      ),
      body: ListView.builder(
        itemCount: records.length,
        itemBuilder: (context, index) {
          final record = records[index];
          final List<dynamic> routeData = jsonDecode(record['trackingPath']);
          final List<LatLng> routePoints = routeData.map((data) => LatLng(data['latitude'], data['longitude'])).toList();
          final polyline = Polyline(
            polylineId: PolylineId('route_$index'),
            points: routePoints,
            color: Colors.blue,
            width: 3,
          );

          final totalDistance = record['totalDistance'] ?? 0.0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Date: ${record['currentDateAndTime']}'),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Total Distance Traveled: ${totalDistance.toStringAsFixed(2)} km'),
              ),
              SizedBox(
                height: 200,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: routePoints.isNotEmpty ? routePoints.first : LatLng(0, 0),
                    zoom: 15,
                  ),
                  polylines: {polyline},
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
