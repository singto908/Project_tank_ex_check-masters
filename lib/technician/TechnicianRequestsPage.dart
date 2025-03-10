import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TechnicianRequestsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('คำขอของช่างเทคนิค', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.orange, // สีส้ม
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('technician_requests')
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(color: Colors.orange));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
                child: Text('ไม่มีคำขอของช่างเทคนิค',
                    style: TextStyle(fontSize: 16, color: Colors.grey)));
          }

          return ListView.builder(
            padding: EdgeInsets.all(8),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;

              String tankId = data.containsKey('tank_id')
                  ? data['tank_id']
                  : 'ไม่พบรหัสถัง';
              String status =
                  data.containsKey('status') ? data['status'] : 'ไม่พบสถานะ';
              String building =
                  data.containsKey('building') ? data['building'] : 'ไม่ระบุ';

              return Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 3,
                color: Colors.white,
                child: ListTile(
                  contentPadding: EdgeInsets.all(12),
                  leading: Icon(Icons.fire_extinguisher,
                      color: Colors.orange, size: 30),
                  title: Text('รหัสถัง: $tankId',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: Text('อาคาร: $building \nสถานะ: $status',
                      style: TextStyle(color: Colors.black87)),
                  trailing: Icon(Icons.arrow_forward_ios, color: Colors.orange),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            RequestDetailPage(requestId: doc.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      backgroundColor: Colors.white,
    );
  }
}

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
      body: FutureBuilder(
        future: FirebaseFirestore.instance
            .collection('technician_requests')
            .doc(requestId)
            .get(),
        builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(color: Colors.orange));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
                child: Text('ไม่พบข้อมูลคำขอ',
                    style: TextStyle(fontSize: 16, color: Colors.grey)));
          }

          var data = snapshot.data!.data() as Map<String, dynamic>;

          String tankId = data['tank_id'] ?? 'ไม่ระบุ';
          String status = data['status'] ?? 'ไม่ระบุ';
          String building = data['building'] ?? 'ไม่ระบุ';
          String floor = data['floor'] ?? 'ไม่ระบุ';
          String inspector = data['inspector'] ?? 'ไม่ระบุ';
          String remarks = data['remarks'] ?? 'ไม่มีหมายเหตุ';

          Map<String, dynamic>? damagedParts =
              data['damaged_parts'] as Map<String, dynamic>?;

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              color: Colors.white,
              child: Padding(
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
                    SizedBox(height: 8),
                    buildDetailRow(Icons.location_city, 'อาคาร', building),
                    buildDetailRow(Icons.apartment, 'ชั้น', floor),
                    buildDetailRow(Icons.person, 'ผู้ตรวจสอบ', inspector),
                    buildDetailRow(Icons.note, 'หมายเหตุ', remarks),
                    buildDetailRow(Icons.assignment_turned_in, 'สถานะ', status),
                    SizedBox(height: 16),
                    Text('🔧 ส่วนที่เสียหาย',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent)),
                    Divider(color: Colors.redAccent, thickness: 1),
                    damagedParts != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: damagedParts.entries.map((entry) {
                              return Padding(
                                padding: EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Icon(Icons.warning_amber,
                                        color: Colors.redAccent, size: 20),
                                    SizedBox(width: 8),
                                    Expanded(
                                        child: Text(
                                            '${entry.key}: ${entry.value}',
                                            style: TextStyle(fontSize: 16))),
                                  ],
                                ),
                              );
                            }).toList(),
                          )
                        : Text('ไม่มีข้อมูล',
                            style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      backgroundColor: Colors.white,
    );
  }

  Widget buildDetailRow(IconData icon, String title, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.orange, size: 24),
          SizedBox(width: 8),
          Text('$title: ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Expanded(child: Text(value, style: TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}
