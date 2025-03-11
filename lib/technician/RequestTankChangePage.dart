import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RequestTankChangePage extends StatefulWidget {
  @override
  _RequestTankChangePageState createState() => _RequestTankChangePageState();
}

class _RequestTankChangePageState extends State<RequestTankChangePage> {
  final TextEditingController tankIdController = TextEditingController();
  final TextEditingController reasonController = TextEditingController();
  bool isSearching = false;
  bool isSubmitting = false;
  Map<String, dynamic>? tankData; // เก็บข้อมูลถังดับเพลิงที่ค้นพบ

  /// ฟังก์ชันค้นหา tank_id ใน Firestore
  Future<void> searchTank() async {
    if (tankIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('กรุณากรอก Tank ID')),
      );
      return;
    }

    setState(() {
      isSearching = true;
      tankData = null; // รีเซ็ตข้อมูลเก่า
    });

    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('firetank_Collection')
          .where('tank_id', isEqualTo: tankIdController.text)
          .get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          tankData = snapshot.docs.first.data() as Map<String, dynamic>;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่พบถังดับเพลิงที่มี Tank ID นี้')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }

    setState(() {
      isSearching = false;
    });
  }

  /// ฟังก์ชันส่งคำขอเปลี่ยนถัง
  Future<void> submitRequest() async {
    if (tankData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('กรุณาค้นหาและเลือกถังก่อนส่งคำขอ')),
      );
      return;
    }
    if (reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('กรุณากรอกเหตุผลในการเปลี่ยน')),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      await FirebaseFirestore.instance.collection('change_requests').add({
        'tank_id': tankData!['tank_id'],
        'building': tankData!['building'],
        'floor': tankData!['floor'],
        'type': tankData!['type'],
        'reason': reasonController.text,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ส่งคำขอเปลี่ยนถังสำเร็จ!')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }

    setState(() {
      isSubmitting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('ร้องขอเปลี่ยนถัง')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ค้นหา Tank ID',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            TextField(
              controller: tankIdController,
              decoration:
                  InputDecoration(hintText: 'กรอก Tank ID ที่ต้องการค้นหา'),
            ),
            SizedBox(height: 8),
            isSearching
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: searchTank,
                    child: Text('ค้นหา'),
                  ),
            SizedBox(height: 16),

            // แสดงข้อมูลถังดับเพลิงที่ค้นพบ
            if (tankData != null) ...[
              Card(
                margin: EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tank ID: ${tankData!['tank_id']}',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('ประเภท: ${tankData!['type']}'),
                      Text('อาคาร: ${tankData!['building']}'),
                      Text('ชั้น: ${tankData!['floor']}'),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text('เหตุผลในการเปลี่ยน',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(hintText: 'เช่น ถังรั่ว, หมดอายุ'),
              ),
              SizedBox(height: 24),
              isSubmitting
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: submitRequest,
                      child: Text('ส่งคำขอ'),
                    ),
            ],
          ],
        ),
      ),
    );
  }
}
