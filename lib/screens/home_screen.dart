import 'package:flutter/material.dart';
import '../features/menu/menu_screen.dart';
import '../services/fall_detection_service.dart';
import '../features/sos/sos_confirmation_screen.dart';
import '../features/emergency_contacts/emergency_contacts_screen.dart';
import '../features/profile/profile_screen.dart';
import '../widgets/custom_bottom_navigation_bar.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late FallDetectionService _fallDetectionService;

  @override
  void initState() {
    super.initState();
    _fallDetectionService = FallDetectionService(
      onFallDetected: _handleFallDetected,
    );
    _fallDetectionService.startMonitoring();
  }

  void _handleFallDetected() {
    print("Fall detected! Triggering SOS...");
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SosConfirmationScreen()),
    ).then((value) {
      print("Returned to HomeScreen from SosConfirmationScreen");
    });
  }

  @override
  void dispose() {
    _fallDetectionService.stopMonitoring();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 100),
          Padding(
            padding: const EdgeInsets.only(left: 20.0),
            child: Text(
              "ต้องการขอความช่วยเหลือ หรือไม่?",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                try {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SosConfirmationScreen()),
                  ).then((value) {
                    print("Returned to HomeScreen from SosConfirmationScreen");
                  });
                } catch (e) {
                  print("Error navigating to SosConfirmationScreen: $e");
                }
              },
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFFE64646).withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Color(0xFFFFD8D7).withOpacity(0.7),
                              Color(0xFFFFD8D7),
                            ],
                            stops: [0.6, 1.0],
                          ),
                        ),
                      ),
                      Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Color(0xFFF68785).withOpacity(0.7),
                              Color(0xFFF68785),
                            ],
                            stops: [0.6, 1.0],
                          ),
                        ),
                      ),
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Color(0xFFE64646).withOpacity(0.8),
                              Color(0xFFE64646),
                            ],
                            stops: [0.6, 1.0],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFFE64646).withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'SOS',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2,
                              shadows: [
                                Shadow(
                                  blurRadius: 10,
                                  color: Colors.black26,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Text(
                "กดปุ่มSOS เพื่อขอความช่วยเหลือ",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          try {
            switch (index) {
              case 0:
                break;
              case 1:
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChatScreen()),
                );
                break;
              case 2:
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MenuScreen()),
                );
                break;
              case 3:
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EmergencyContactsScreen()),
                );
                break;
              case 4:
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen()),
                );
                break;
              default:
                break;
            }
          } catch (e) {
            print("Error navigating: $e");
          }
        },
      ),
    );
  }
}