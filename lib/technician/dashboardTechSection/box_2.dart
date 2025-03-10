import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart'; // สำหรับการสร้างกราฟวงกลม

class Box2 extends StatelessWidget {
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

            if (snapshot.hasData) {
              final totalTanks = snapshot.data!.docs.length;
              int notChecked = 0;
              int checked = 0;
              int repair = 0;
              int broken = 0;

              // คำนวณจำนวนสถานะต่าง ๆ
              for (var doc in snapshot.data!.docs) {
                String status = doc['status_technician'] ?? '';
                if (status == 'ยังไม่ตรวจสอบ') {
                  notChecked++;
                } else if (status == 'ตรวจสอบแล้ว') {
                  checked++;
                } else if (status == 'ส่งซ่อม') {
                  repair++;
                } else if (status == 'ชำรุด') {
                  broken++;
                }
              }

              // คำนวณเปอร์เซ็นต์ของแต่ละสถานะ
              double notCheckedPercentage = (notChecked / totalTanks) * 100;
              double checkedPercentage = (checked / totalTanks) * 100;
              double repairPercentage = (repair / totalTanks) * 100;
              double brokenPercentage = (broken / totalTanks) * 100;

              return SizedBox(
                height: 200, // กำหนดความสูงของกราฟ
                child: PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                        color: Colors.grey, // สีเทาสำหรับยังไม่ตรวจสอบ
                        value: notCheckedPercentage,
                        title: '${notCheckedPercentage.toStringAsFixed(1)}%',
                        radius: 60,
                      ),
                      PieChartSectionData(
                        color: Colors.green, // สีเขียวสำหรับตรวจสอบแล้ว
                        value: checkedPercentage,
                        title: '${checkedPercentage.toStringAsFixed(1)}%',
                        radius: 60,
                      ),
                      PieChartSectionData(
                        color: Colors.orange, // สีส้มสำหรับส่งซ่อม
                        value: repairPercentage,
                        title: '${repairPercentage.toStringAsFixed(1)}%',
                        radius: 60,
                      ),
                      PieChartSectionData(
                        color: Colors.red, // สีแดงสำหรับชำรุด
                        value: brokenPercentage,
                        title: '${brokenPercentage.toStringAsFixed(1)}%',
                        radius: 60,
                      ),
                    ],
                  ),
                ),
              );
            }

            return Center(child: Text('ไม่พบข้อมูลถัง'));
          },
        ),
      ),
    );
  }
}
