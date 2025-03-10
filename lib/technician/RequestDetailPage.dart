import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RequestDetailPage extends StatelessWidget {
  final String requestId;

  RequestDetailPage({required this.requestId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('รายละเอียดคำขอ', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.orange,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('technician_requests')
            .doc(requestId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: Colors.orange),
            );
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text('ไม่พบข้อมูลคำขอ',
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
            );
          }

          var data = snapshot.data!.data() as Map<String, dynamic>;
          String tankId = data['tank_id'] ?? 'ไม่ระบุ';
          String building = data['building'] ?? 'ไม่ระบุ';
          String floor = data['floor'] ?? 'ไม่ระบุ';
          String inspector = data['inspector'] ?? 'ไม่ระบุ';
          String remarks = data['remarks'] ?? 'ไม่มีหมายเหตุ';

          return Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('รหัสถัง: $tankId',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange)),
                Divider(color: Colors.orange, thickness: 2),
                Text('อาคาร: $building', style: TextStyle(fontSize: 16)),
                Text('ชั้น: $floor', style: TextStyle(fontSize: 16)),
                Text('ผู้ตรวจสอบ: $inspector', style: TextStyle(fontSize: 16)),
                Text('หมายเหตุ: $remarks', style: TextStyle(fontSize: 16)),
                SizedBox(height: 20),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      print("กดปุ่มเสร็จสิ้น");
                    },
                    icon: Icon(Icons.check_circle, color: Colors.white),
                    label: Text('เสร็จสิ้น',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
