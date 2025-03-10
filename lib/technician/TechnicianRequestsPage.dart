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

  void _completeRequest(BuildContext context, Map<String, dynamic> data) async {
    String tankId = data['tank_id'] ?? 'ไม่ระบุ';
    String technicianName =
        "ช่างหนึ่ง คำนวณ"; // ค่าตัวอย่าง สามารถรับจากระบบล็อกอินได้
    String repairDetails = "สายฉีดถังดับเพลิง"; // ค่าตัวอย่าง

    FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      // ✅ 1. ค้นหาเอกสาร firetank_Collection ที่มี tank_id
      QuerySnapshot querySnapshot = await firestore
          .collection('firetank_Collection')
          .where('tank_id', isEqualTo: tankId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('ไม่พบถังดับเพลิงที่มี tank_id: $tankId'),
          backgroundColor: Colors.red,
        ));
        return;
      }

      // ✅ 2. อัปเดตสถานะ firetank_Collection
      for (var doc in querySnapshot.docs) {
        await firestore.collection('firetank_Collection').doc(doc.id).update({
          'status': 'ตรวจสอบแล้ว',
          'status_technician': 'ตรวจสอบแล้ว',
          'updated_at': FieldValue.serverTimestamp(),
        });
      }

      // ✅ 3. ค้นหา FE_updates ก่อน ถ้ามีให้อัปเดต ถ้าไม่มีให้สร้างใหม่
      QuerySnapshot feUpdateSnapshot = await firestore
          .collection('FE_updates')
          .where('tank_id', isEqualTo: tankId)
          .get();

      if (feUpdateSnapshot.docs.isNotEmpty) {
        // ถ้ามีอยู่แล้ว → อัปเดตข้อมูล
        for (var doc in feUpdateSnapshot.docs) {
          await firestore.collection('FE_updates').doc(doc.id).update({
            'status_tech': 'ซ่อมแล้ว',
            'repair_details': repairDetails,
            'repair_date': FieldValue.serverTimestamp(),
            'technician_name': technicianName,
          });
        }
      } else {
        // ถ้าไม่มี → สร้างใหม่
        await firestore.collection('FE_updates').add({
          'tank_id': tankId,
          'status_tech': 'ซ่อมแล้ว',
          'repair_details': repairDetails,
          'repair_date': FieldValue.serverTimestamp(),
          'technician_name': technicianName,
          'user_type': 'ช่างเทคนิค'
        });
      }

      // ✅ 4. ลบคำขอออกจาก technician_requests
      await firestore.collection('technician_requests').doc(requestId).delete();

      // ✅ 5. แจ้งเตือนสำเร็จ และปิดหน้า
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('อัปเดตสำเร็จ ถังดับเพลิงถูกตั้งค่าเป็น "ตรวจสอบแล้ว"'),
        backgroundColor: Colors.green,
      ));

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('เกิดข้อผิดพลาด: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
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
                        buildDetailRow(Icons.location_city, 'อาคาร', building),
                        buildDetailRow(Icons.apartment, 'ชั้น', floor),
                        buildDetailRow(Icons.person, 'ผู้ตรวจสอบ', inspector),
                        buildDetailRow(Icons.note, 'หมายเหตุ', remarks),
                        buildDetailRow(
                            Icons.assignment_turned_in, 'สถานะ', status),
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
                                                style:
                                                    TextStyle(fontSize: 16))),
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
                SizedBox(height: 20),

                // 🔥 ปุ่ม "เสร็จสิ้น" สำหรับอัปเดตสถานะและลบคำขอ
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () => _completeRequest(context, data),
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
