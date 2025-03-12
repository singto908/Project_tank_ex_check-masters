import 'package:flutter/material.dart';
import 'dashboardTechSection/box_1.dart'; // สำหรับกล่องข้อมูล
import 'dashboardTechSection/box_2.dart'; // สำหรับกล่องกราฟวงกลม
import 'dashboardTechSection/box_3.dart'; // สำหรับกล่องรายการอาคาร
import 'package:firecheck_setup/technician/TechnicianRequestsPage.dart';
import 'package:firecheck_setup/technician/TechnicianRequestsPage.dart';

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
              SizedBox(height: 60),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 30), // ปรับระยะห่างจากขอบล่าง
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        TechnicianRequestsPage(), // ไปที่หน้าแจ้งชำรุด
                  ),
                );
              },
              child: const Icon(Icons.refresh),
              backgroundColor: const Color.fromARGB(255, 223, 181, 11),
            ),
            SizedBox(width: 16), // ช่องว่างระหว่างปุ่ม
            FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        TechnicianRequestsPage(), // ไปที่หน้าแจ้งชำรุด
                  ),
                );
              },
              child: const Icon(Icons.report_problem),
              backgroundColor: Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}
