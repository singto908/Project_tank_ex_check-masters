import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // ใช้แปลงวันที่

class RepairUpdatesScreen extends StatelessWidget {
  const RepairUpdatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('อัปเดตการซ่อม/เปลี่ยน',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepOrange, // สีของ AppBar
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('FE_updates').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text('ไม่มีข้อมูลการอัปเดต',
                    style: TextStyle(fontSize: 16)));
          }

          var updates = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: updates.length,
            itemBuilder: (context, index) {
              var data = updates[index].data() as Map<String, dynamic>;

              return Card(
                elevation: 4, // ทำให้ Card มีเงา
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: _getStatusIcon(data['status_tech']),
                  title: Text(
                    'ถังดับเพลิง: ${data['tank_id']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('🛠 สถานะ: ${data['status_tech']}',
                          style: const TextStyle(fontSize: 14)),
                      Text('📌 รายละเอียด: ${data['repair_details']}'),
                      Text('👷 ช่าง: ${data['technician_name']}'),
                      Text(
                          '📅 วันที่: ${DateFormat('dd MMM yyyy, HH:mm').format(data['repair_date'].toDate())}'),
                    ],
                  ),
                  /*trailing:
                      const Icon(Icons.arrow_forward_ios, color: Colors.grey),*/
                ),
              );
            },
          );
        },
      ),
    );
  }

  // กำหนด Icon ตามสถานะ
  Widget _getStatusIcon(String status) {
    switch (status) {
      case 'ซ่อมแล้ว':
        return const Icon(Icons.check_circle, color: Colors.green, size: 36);
      case 'รอซ่อม':
        return const Icon(Icons.pending, color: Colors.orange, size: 36);
      case 'ต้องเปลี่ยน':
        return const Icon(Icons.error, color: Colors.red, size: 36);
      default:
        return const Icon(Icons.info, color: Colors.blue, size: 36);
    }
  }
}
