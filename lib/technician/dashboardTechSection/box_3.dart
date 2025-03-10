import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Box3 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('firetank_Collection')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล'));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text('ไม่มีข้อมูล'));
            }

            // สร้างแผนที่เพื่อเก็บข้อมูลจำนวนสถานะ 'ตรวจสอบแล้ว' ในแต่ละอาคาร
            Map<String, Map<String, int>> buildingsStatus = {};

            for (var doc in snapshot.data!.docs) {
              String building = doc['building'] ?? '';
              String status = doc['status_technician'] ?? '';

              // หากไม่มีข้อมูลของอาคารนี้ ให้สร้างแผนที่ใหม่
              if (!buildingsStatus.containsKey(building)) {
                buildingsStatus[building] = {'checked': 0, 'total': 0};
              }

              // เพิ่มจำนวนถังในอาคารนี้
              buildingsStatus[building]!['total'] =
                  buildingsStatus[building]!['total']! + 1;

              // ถ้าสถานะเป็น 'ตรวจสอบแล้ว' ให้เพิ่มจำนวน
              if (status == 'ตรวจสอบแล้ว') {
                buildingsStatus[building]!['checked'] =
                    buildingsStatus[building]!['checked']! + 1;
              }
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'อาคารที่ตรวจสอบแล้ว',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                // ตรวจสอบว่า buildingsStatus มีข้อมูลหรือไม่
                buildingsStatus.isEmpty
                    ? Center(child: Text('ไม่มีอาคารที่มีข้อมูล'))
                    : ListView(
                        shrinkWrap: true,
                        children: buildingsStatus.entries.map((entry) {
                          String buildingName = entry.key;
                          int checked = entry.value['checked']!;
                          int total = entry.value['total']!;

                          return _buildingCard(buildingName, checked, total);
                        }).toList(),
                      ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildingCard(String buildingName, int checked, int total) {
    double percentage = total > 0 ? (checked / total) * 100 : 0;

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(buildingName, style: TextStyle(fontSize: 14)),
            Text(
              '$checked/$total ถัง (${percentage.toStringAsFixed(1)}%)',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
