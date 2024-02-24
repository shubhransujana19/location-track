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
  DateTime? selectedDate;
  LatLng initialCameraPosition = LatLng(0, 0);
  bool isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    staffCode = args['staffCode'] ?? '';
    password = args['password'] ?? '';
    // Fetch records when the page first loads
    fetchRecords(DateTime.now());
  }

  Future<void> fetchRecords(DateTime? date) async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://www.wmps.in/staff/gps/location/record-data.php'),
        body: jsonEncode({'staffCode': staffCode, 'date': date?.toString()}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success']) {
          setState(() {
            records = List<Map<String, dynamic>>.from(responseData['records']);
            if (records.isNotEmpty) {
              final List<dynamic> routeData = jsonDecode(records[0]['trackingPath']);
              final LatLng firstPoint = LatLng(routeData[0]['latitude'], routeData[0]['longitude']);
              initialCameraPosition = firstPoint;
            }
          });
        } else {
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
    } finally {
      setState(() {
        isLoading = false;
      });
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
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : records.isEmpty
              ? Center(
                  child: Text('No records found'),
                )
              : ListView.builder(
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

                    final totalDistance = double.tryParse(record['distance'] ?? '0.0') ?? 0.0;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          elevation: 2.0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Date: ${record['currentDateAndTime']}',
                                      style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.black87),
                                    ),
                                    Text(
                                      '${totalDistance.toStringAsFixed(2)} km',
                                      style: const TextStyle(fontSize: 14.0, color: Color.fromARGB(255, 117, 117, 117)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8.0),
                                SizedBox(
                                  height: 350.0,
                                  child: GoogleMap(
                                    initialCameraPosition: CameraPosition(
                                      target: initialCameraPosition,
                                      zoom: 15,
                                    ),
                                    polylines: {polyline},
                                    mapType: MapType.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
    );
  }
}
