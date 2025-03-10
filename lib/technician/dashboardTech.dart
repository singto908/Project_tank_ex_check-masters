import 'package:flutter/material.dart';
import 'dashboardTechSection/box_1.dart'; // สำหรับกล่องข้อมูล
import 'dashboardTechSection/box_2.dart'; // สำหรับกล่องกราฟวงกลม
import 'dashboardTechSection/box_3.dart'; // สำหรับกล่องรายการอาคาร

class DashboardTechPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Technician'),
      ),
      body: SingleChildScrollView(
        // ครอบ Column ด้วย SingleChildScrollView
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Box 1: เริ่มการตรวจใหม่, ถังทั้งหมด และการตรวจสอบ
              Box1(),

              SizedBox(height: 16),

              // Box 2: กราฟวงกลม
              Box2(),

              SizedBox(height: 16),

              // Box 3: List อาคาร
              Box3(), // ไม่ต้องใช้ Expanded แล้ว เพราะใช้ SingleChildScrollView ครอบ Column
            ],
          ),
        ),
      ),
    );
  }
}
