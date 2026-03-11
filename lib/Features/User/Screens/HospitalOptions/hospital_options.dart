import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../Common Widgets/constants.dart';
import '../../Controllers/message_sending.dart';
import '../map_screen.dart';

class HospitalOptions extends StatelessWidget {
  const HospitalOptions({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final smsController = Get.put(messageController());
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(color),
        centerTitle: true,
        automaticallyImplyLeading: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(40),
          ),
        ),
        bottom: PreferredSize(
            preferredSize: Size.fromHeight(Get.height * 0.1),
            child: Container(
              padding: const EdgeInsets.only(bottom: 15),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image(
                          image: const AssetImage(
                              "assets/logos/emergencyAppLogo.png"),
                          height: Get.height * 0.08),
                    ],
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Hospital Options",
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            )),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // MAP CARD
            Card(
              child: ListTile(
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(15.0)),
                ),
                tileColor: Color(color),
                leading: const Icon(Icons.map, color: Colors.yellowAccent),
                title: const Text('Hospital Map Display',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text('Find the nearest hospital on the map',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Get.to(() => const MapScreen(
                        searchQuery: 'hospital',
                        title: 'Nearest Hospitals',
                      ));
                },
              ),
            ),
            // CALL CARD
            Card(
              child: ListTile(
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(15.0)),
                ),
                tileColor: Color(color),
                leading: const Icon(Icons.call, color: Colors.yellowAccent),
                title: const Text('Call Hospital Helpline',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text('Directly call the hospital helpline',
                    style: TextStyle(color: Colors.white)),
                onTap: () async {
                  if (await Permission.phone.request().isGranted) {
                    final url = Uri.parse("tel:1122");
                    await launchUrl(url);
                  } else {
                    Get.snackbar("Permission Denied",
                        "Phone call permission is required.");
                  }
                },
              ),
            ),
            // DISTRESS SMS CARD
            Card(
              child: ListTile(
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(15.0)),
                ),
                tileColor: const Color(0xfff85757),
                leading: const Icon(Icons.message, color: Colors.white),
                title: const Text('Send Distress Message',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text(
                    'Send a distress message to emergency contacts',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  smsController.sendLocationViaSMS(
                      "Medical Emergency\nSend Ambulance at");
                },
              ),
            ),
            // SHARE LOCATION CARD
            Card(
              child: ListTile(
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(15.0)),
                ),
                tileColor: Colors.green.shade700,
                leading:
                    const Icon(Icons.share_location, color: Colors.white),
                title: const Text('Share My Location',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text(
                    'Share your current location via email & SMS alert',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  smsController.shareLocationViaEmail(
                      "Medical Emergency – Hospital Help Needed");
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
