import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ตั้งค่า'),
        backgroundColor: const Color.fromARGB(255, 92, 86, 86),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            secondary: Icon(Icons.notifications_active, color: Colors.orange),
            title: Text('เปิด/ปิด การแจ้งเตือน'),
            value: notificationsEnabled,
            onChanged: (value) {
              setState(() {
                notificationsEnabled = value;
              });
            },
          ),
        ],
      ),
    );
  }
}
