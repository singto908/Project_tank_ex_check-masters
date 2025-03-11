import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RequestTankChangePage extends StatefulWidget {
  @override
  _RequestTankChangePageState createState() => _RequestTankChangePageState();
}

class _RequestTankChangePageState extends State<RequestTankChangePage> {
  final TextEditingController locationController = TextEditingController();
  final TextEditingController reasonController = TextEditingController();
  bool isSubmitting = false;

  Future<void> submitRequest() async {
    if (locationController.text.isEmpty || reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วน')),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      await FirebaseFirestore.instance.collection('change_requests').add({
        'location': locationController.text,
        'reason': reasonController.text,
        'status': 'pending', // สถานะเริ่มต้น
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ส่งคำขอเปลี่ยนถังสำเร็จ!')),
      );

      Navigator.pop(context); // ปิดหน้านี้หลังส่งข้อมูลสำเร็จ
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
            Text('ตำแหน่งที่ตั้งถัง',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            TextField(
                controller: locationController,
                decoration:
                    InputDecoration(hintText: 'เช่น ชั้น 3 หน้าห้องประชุม')),
            SizedBox(height: 16),
            Text('เหตุผลในการเปลี่ยน',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            TextField(
                controller: reasonController,
                decoration: InputDecoration(hintText: 'เช่น ถังรั่ว, หมดอายุ')),
            SizedBox(height: 24),
            isSubmitting
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: submitRequest,
                    child: Text('ส่งคำขอ'),
                  ),
          ],
        ),
      ),
    );
  }
}
