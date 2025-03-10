import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Box1 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'เริ่มการตรวจใหม่ในอีก 30 วัน',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            // ใช้ StreamBuilder เพื่อดึงข้อมูลจำนวนเอกสารทั้งหมดจาก Firestore
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('firetank_Collection')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Text(
                    'กำลังโหลดข้อมูล...',
                    style: TextStyle(fontSize: 14),
                  );
                }

                if (snapshot.hasError) {
                  return Text(
                    'เกิดข้อผิดพลาดในการโหลดข้อมูล',
                    style: TextStyle(fontSize: 14),
                  );
                }

                if (snapshot.hasData) {
                  final int totalTanks =
                      snapshot.data!.docs.length; // จำนวนเอกสารทั้งหมด

                  // คำนวณจำนวนถังที่มีสถานะ 'ตรวจสอบแล้ว'
                  final int checkedTanks = snapshot.data!.docs.where((doc) {
                    return doc['status_technician'] == 'ตรวจสอบแล้ว';
                  }).length;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ถังทั้งหมด: $totalTanks ถัง',
                        style: TextStyle(fontSize: 14),
                      ),
                      Text(
                        'การตรวจสอบ: $checkedTanks/$totalTanks',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  );
                }

                return Text(
                  'ไม่พบข้อมูลถัง',
                  style: TextStyle(fontSize: 14),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
