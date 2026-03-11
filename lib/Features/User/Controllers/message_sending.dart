import 'dart:io';

import 'package:background_sms/background_sms.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_sms/flutter_sms.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

import '../../Emergency Contacts/emergency_contacts_controller.dart';

class messageController extends GetxController {
  static messageController get instance => Get.find();
  final emergencyContactsController = Get.put(EmergencyContactsController());

  String? _currentAddress;
  Position? _currentPosition;
  void _sendSMS(String message, List<String> recipents) async {
    // Filter out empty phone numbers
    List<String> validRecipients =
        recipents.where((r) => r.trim().isNotEmpty).toList();

    if (validRecipients.isEmpty) {
      Get.snackbar(
        "No Contacts",
        "No emergency contacts saved. Please add contacts from Profile > Emergency Contacts.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    int successCount = 0;
    for (var i = 0; i < validRecipients.length; i++) {
      try {
        await BackgroundSms.sendMessage(
          phoneNumber: validRecipients[i].trim(),
          message: message,
        );
        successCount++;
      } catch (e) {
        debugPrint("Failed to send to ${validRecipients[i]}: $e");
      }
    }

    if (successCount > 0) {
      Get.snackbar(
        "SMS Sent",
        "Distress SMS sent to $successCount contact(s) successfully!",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        "SMS Failed",
        "Could not send SMS. Make sure the app has SMS permission and you are on a real device with a SIM card.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    }
    debugPrint("SMS sent to: $validRecipients");
  }

  Future<bool> handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar("Disabled",
          'Location services are disabled. Please enable the services');
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Get.snackbar("Rejected", 'Location Permissions are denied.');
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      Get.snackbar("Rejected",
          'Location permissions are permanently denied, we cannot request permissions.');
      return false;
    }
    return true;
  }

  handleSmsPermission() async {
    if (kIsWeb) {
      debugPrint("SMS Permission skipped on Web");
      return true;
    }
    final status = await Permission.sms.request();
    if (status.isGranted) {
      debugPrint("SMS Permission Granted");
      return true;
    } else {
      debugPrint("SMS Permission Denied");
      return false;
    }
  }

  Future<Position> getCurrentPosition() async {
    // final hasSmsPermission = handleSmsPermission();

    final hasPermission = await handleLocationPermission();

    if (!hasPermission) {
      return Position(
          latitude: 0,
          longitude: 0,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0);
    }
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) {
      _currentPosition = position;
      _getAddressFromLatLng(_currentPosition!);
      return _currentPosition!;
    }).catchError((e) {
      debugPrint(e);
    });
    return Position(
        latitude: 0,
        longitude: 0,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0);
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    await placemarkFromCoordinates(
            _currentPosition!.latitude, _currentPosition!.longitude)
        .then((List<Placemark> placemarks) {
      Placemark place = placemarks[0];
      _currentAddress =
          '${place.street}, ${place.subLocality}, ${place.subAdministrativeArea}, ${place.postalCode}';
    }).catchError((e) {
      debugPrint(e);
    });
  }

  Future<void> sendLocationViaSMS(String emergencyType) async {
    await getCurrentPosition().then((pos) async {
      if (_currentPosition != null) {
        String message =
            "HELP me! There is a $emergencyType \n http://www.google.com/maps/place/${_currentPosition!.latitude},${_currentPosition!.longitude}";
        await emergencyContactsController
            .loadData()
            .then((emergencyContacts) => _sendSMS(message, emergencyContacts));
      } else {
        Get.snackbar("Location Error",
            "Could not get your location. Please enable GPS and try again.",
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    });
  }

  /// Opens email client + sends SMS to emergency contacts simultaneously,
  /// sharing the user's current GPS location with an alert message.
  Future<void> shareLocationViaEmail(String alertTitle) async {
    // Ask for SMS permission first (only on non-web)
    PermissionStatus smsPermission = PermissionStatus.granted;
    if (!kIsWeb) {
      smsPermission = await Permission.sms.request();
    }

    final hasLocation = await handleLocationPermission();
    if (!hasLocation) return;

    await getCurrentPosition().then((pos) async {
      if (_currentPosition == null) {
        Get.snackbar("Location Error",
            "Could not get your location. Please enable GPS.",
            backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }

      final lat = _currentPosition!.latitude;
      final lng = _currentPosition!.longitude;
      final mapsLink =
          "http://www.google.com/maps/place/$lat,$lng";
      final body =
          "🚨 EMERGENCY ALERT: $alertTitle\n\nI need help! My current location:\n$mapsLink\n\nPlease respond immediately.";

      // Open email app with pre-filled content
      final emailUri = Uri(
        scheme: 'mailto',
        query: Uri.encodeFull(
            'subject=🚨 EMERGENCY: $alertTitle&body=$body'),
      );

      try {
        await launchUrl(emailUri);
      } catch (e) {
        debugPrint("Could not open email: $e");
      }

      // Also send SMS to saved emergency contacts
      if (smsPermission.isGranted) {
        final smsMessage =
            "🚨 EMERGENCY! $alertTitle — My location: $mapsLink";
        await emergencyContactsController
            .loadData()
            .then((contacts) => _sendSMS(smsMessage, contacts));
      } else {
        Get.snackbar(
          "SMS not sent",
          "SMS permission denied. Location shared via email only.",
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    });
  }
}
