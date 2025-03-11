import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminApproveRequestsPage extends StatefulWidget {
  @override
  _AdminApproveRequestsPageState createState() =>
      _AdminApproveRequestsPageState();
}

class _AdminApproveRequestsPageState extends State<AdminApproveRequestsPage> {
  /// ✅ ฟังก์ชันอนุมัติคำขอ → ย้ายไป `technician_change_requests`
  Future<void> approveRequest(
      String requestId, Map<String, dynamic> requestData) async {
    try {
      // 1️⃣ บันทึกข้อมูลไปที่ `technician_change_requests`
      await FirebaseFirestore.instance
          .collection('technician_chang_requests')
          .doc(requestId)
          .set({
        ...requestData, // คัดลอกข้อมูลทั้งหมด
        'status': 'approved',
        'approved_at': FieldValue.serverTimestamp(), // เวลาที่อนุมัติ
      });

      // 2️⃣ ลบคำขอออกจาก `change_requests`
      await FirebaseFirestore.instance
          .collection('change_requests')
          .doc(requestId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('✅ อนุมัติคำขอแล้ว!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('❌ เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
      );
    }
  }

  /// ❌ ฟังก์ชันปฏิเสธคำขอ → ลบจาก `change_requests`
  Future<void> rejectRequest(String requestId) async {
    try {
      // ลบเอกสารออกจาก `change_requests`
      await FirebaseFirestore.instance
          .collection('change_requests')
          .doc(requestId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('❌ ปฏิเสธคำขอเรียบร้อย!'),
            backgroundColor: Colors.red),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('❌ เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
      );
    }
  }

  /// ฟังก์ชันดึงข้อมูลคำขอจาก Firestore
  Stream<QuerySnapshot> getChangeRequests() {
    return FirebaseFirestore.instance
        .collection('change_requests')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('อนุมัติคำขอเปลี่ยนถัง',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.orange,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: getChangeRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(color: Colors.orange));
          }
          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาดในการดึงข้อมูล'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
                child: Text('ไม่มีคำขอเปลี่ยนถัง',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey)));
          }

          final requests = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              final requestId = request.id;
              final data = request.data() as Map<String, dynamic>;

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                shadowColor: Colors.orange.withOpacity(0.5),
                margin: EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.fire_extinguisher,
                              color: Colors.orange, size: 24),
                          SizedBox(width: 8),
                          Text('Tank ID: ${data['tank_id']}',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          Spacer(),
                          _getStatusIcon(data['status']),
                        ],
                      ),
                      Divider(color: Colors.orange),
                      Text('ประเภท: ${data['type']}',
                          style: TextStyle(fontSize: 16)),
                      Text('อาคาร: ${data['building']}',
                          style: TextStyle(fontSize: 16)),
                      Text('ชั้น: ${data['floor']}',
                          style: TextStyle(fontSize: 16)),
                      SizedBox(height: 8),
                      Text('เหตุผล: ${data['reason']}',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red)),
                      SizedBox(height: 12),
                      if (data['status'] == 'pending') ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () =>
                                    approveRequest(requestId, data),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text('อนุมัติ ✅',
                                    style: TextStyle(fontSize: 16)),
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => rejectRequest(requestId),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text('ปฏิเสธ ❌',
                                    style: TextStyle(fontSize: 16)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// แสดงไอคอนสถานะของคำขอ
  Widget _getStatusIcon(String status) {
    if (status == 'approved') {
      return Icon(Icons.check_circle, color: Colors.green, size: 24);
    } else if (status == 'rejected') {
      return Icon(Icons.cancel, color: Colors.red, size: 24);
    }
    return Icon(Icons.hourglass_empty, color: Colors.orange, size: 24);
  }
}
