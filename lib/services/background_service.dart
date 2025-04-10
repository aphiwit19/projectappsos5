import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'firebase_service.dart';

Future<void> initializeService() async {
  // ตรวจสอบและขอสิทธิ์ที่จำเป็น
  await _checkAndRequestPermissions();
  
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'appsos_foreground',
      initialNotificationTitle: 'แอพ SOS กำลังติดตามตำแหน่ง',
      initialNotificationContent: 'บริการกำลังเริ่มทำงาน...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );

  await service.startService();
}

// เพิ่มฟังก์ชันตรวจสอบและขอสิทธิ์เพิ่มเติม
Future<void> _checkAndRequestPermissions() async {
  // ตรวจสอบสิทธิ์การเข้าถึงตำแหน่ง
  var locationStatus = await Permission.locationWhenInUse.status;
  if (!locationStatus.isGranted) {
    locationStatus = await Permission.locationWhenInUse.request();
  }
  
  // ถ้าได้รับสิทธิ์พื้นฐานแล้ว ให้ขอสิทธิ์สำหรับการทำงานในพื้นหลัง
  if (locationStatus.isGranted) {
    var backgroundStatus = await Permission.locationAlways.status;
    if (!backgroundStatus.isGranted) {
      backgroundStatus = await Permission.locationAlways.request();
    }
    
    // สำหรับ Android 10+ ใช้ locationAlways แทน backgroundLocation
  }
  
  // ตรวจสอบว่า location service เปิดอยู่หรือไม่
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // แนะนำให้ผู้ใช้เปิด location service
    print('Location services are disabled. Please enable for background tracking.');
  }
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  try {
    if (service is AndroidServiceInstance) {
      await service.setAsForegroundService();
      await service.setForegroundNotificationInfo(
        title: "แอพ SOS กำลังติดตามตำแหน่ง",
        content: "บริการกำลังติดตามตำแหน่งของคุณ",
      );
    }

    try {
      await FirebaseService.initializeFirebase();
      FirebaseService.configureFirestore();
    } catch (e) {
      print('Failed to initialize Firebase in background service: $e');
    }

    StreamSubscription<Position>? positionStream;
    
    // ฟังก์ชันสำหรับอัพเดทตำแหน่งใน Firestore
    Future<void> updateLocation(Position position) async {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final userId = user.uid;
          final userEmail = user.email;
          
          if (userEmail != null) {
            // บันทึกตำแหน่งล่าสุดใน users collection
            await FirebaseFirestore.instance
                .collection('Users')
                .doc(userEmail)
                .collection('current_location')
                .doc('latest')
                .set({
              'latitude': position.latitude,
              'longitude': position.longitude,
              'timestamp': FieldValue.serverTimestamp(),
              'accuracy': position.accuracy,
              'speed': position.speed,
              'heading': position.heading,
              'mapLink': 'https://maps.google.com/?q=${position.latitude},${position.longitude}',
            });

            // อัพเดทข้อมูลใน SOS logs ถ้ามีการแจ้งเหตุ
            final sosLogsRef = FirebaseFirestore.instance
                .collection('Users')
                .doc(userEmail)
                .collection('sos_logs');
            
            final activeSosQuery = await sosLogsRef
                .where('status', isEqualTo: 'active')
                .get();

            for (var doc in activeSosQuery.docs) {
              await doc.reference.update({
                'location': {
                  'latitude': position.latitude,
                  'longitude': position.longitude,
                },
                'mapLink': 'https://maps.google.com/?q=${position.latitude},${position.longitude}',
                'lastUpdated': FieldValue.serverTimestamp(),
              });
            }
          }
        }
      } catch (e) {
        print('Error updating location: $e');
      }
    }

    // เริ่มการติดตามตำแหน่ง
    positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // อัพเดททุก 10 เมตร
      ),
    ).listen((Position position) {
      updateLocation(position);
    });

    // อัพเดทการแจ้งเตือนทุก 10 วินาที
    Timer.periodic(Duration(seconds: 10), (timer) async {
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          await service.setForegroundNotificationInfo(
            title: "แอพ SOS กำลังติดตามตำแหน่ง",
            content: "บริการกำลังทำงานในพื้นหลัง ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}",
          );
        }
      }
    });

    // จัดการเมื่อมีการสั่งหยุด service
    service.on('stopService').listen((event) {
      positionStream?.cancel();
      service.stopSelf();
    });
  } catch (e) {
    print('Error in background service: $e');
    if (service is AndroidServiceInstance) {
      await service.setForegroundNotificationInfo(
        title: "แอพ SOS กำลังทำงาน",
        content: "บริการกำลังทำงานในโหมดจำกัด",
      );
    }
  }
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}