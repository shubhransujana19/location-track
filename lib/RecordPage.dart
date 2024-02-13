import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';

class RecordsPage extends StatefulWidget {
  const RecordsPage({super.key});

  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  int _selectedIndex = 2;

  String staffCode = '';
  String password = '';
    @override
    void didChangeDependencies() {
      super.didChangeDependencies();
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      staffCode = args['staffCode'] ?? '';
      password = args['password'] ?? '';
      // fetchStaffDetails();
    }


  @override
  Widget build(BuildContext context) {
    return  Scaffold(
            appBar: AppBar(
              title: const Text('All Track Records',
              style: TextStyle(
                color: Colors.white,
              ),
              ),
              backgroundColor: Color.fromARGB(200, 20, 75, 121),
            ),
            body: const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    ],
                  ),
                )
                ),
                  bottomNavigationBar: ConvexAppBar(
                  initialActiveIndex: _selectedIndex,
                  height: 50,
                  backgroundColor: const Color.fromARGB(185, 28, 84, 129),
                  style: TabStyle.flip,
                  items: const [
                    TabItem(icon: Icons.home_outlined, title: 'Home'),
                    TabItem(icon: Icons.person_outline, title: 'Profile'),
                    TabItem(icon: Icons.auto_graph_outlined, title: 'Records'),
                    TabItem(icon: Icons.settings_outlined, title: 'Settings')
                  ],
                  onTap: (int index) {
                    setState(() {
                      _selectedIndex = index; // Update the selected index
                    });

                    // Navigate to the corresponding page based on the selected index
                    switch (index) {
                      case 0:
                        Navigator.pushNamed(context, '/home',
                        arguments: {
                          'staffCode': staffCode,
                          'password': password,
                      });
                        break;
                      case 1:
                        Navigator.pushNamed(context, '/profile', 
                        arguments: {
                          'staffCode': staffCode,
                          'password': password,
                        });
                        break;
                      case 2:
                        Navigator.pushNamed(context, '/records');
                        break;
                      case 3:
                        Navigator.pushNamed(context, '/settings');
                        break;
                      default:
                        break;
                    }
                  },
                ),

    );
  }
}