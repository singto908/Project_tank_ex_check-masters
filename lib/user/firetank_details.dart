import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class FireTankDetailsPage extends StatefulWidget {
  final String tankId;

  const FireTankDetailsPage({Key? key, required this.tankId}) : super(key: key);

  @override
  _FireTankDetailsPageState createState() => _FireTankDetailsPageState();
}

class _FireTankDetailsPageState extends State<FireTankDetailsPage> {
  bool isTechnicianView = false; // สลับมุมมองระหว่างผู้ใช้ทั่วไปและช่างเทคนิค
  bool isUpdating = false; // ป้องกันการกดปุ่มซ้ำ

  // ฟังก์ชันสำหรับรีเซ็ตสถานะ
  Future<void> resetStatus() async {
    setState(() {
      isUpdating = true;
    });

    try {
      // อัปเดต firetank_Collection
      await FirebaseFirestore.instance
          .collection('firetank_Collection')
          .where('tank_id', isEqualTo: widget.tankId)
          .get()
          .then((querySnapshot) {
        for (var doc in querySnapshot.docs) {
          doc.reference.update({'status': 'ปกติ'});
        }
      });

      // เพิ่มบันทึกการรีเซ็ตใน FE_updates
      await FirebaseFirestore.instance.collection('FE_updates').add({
        'tank_id': widget.tankId,
        'update_type': 'รีเซ็ตสถานะ',
        'updated_at': Timestamp.now(),
        'updated_by': 'Technician', // หรือใช้ชื่อผู้ใช้งานจริง
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('รีเซ็ตสถานะสำเร็จ')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $error')),
      );
    } finally {
      setState(() {
        isUpdating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('รายละเอียดการตรวจสอบ')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ส่วนแสดงข้อมูลถังดับเพลิง (เหมือนเดิม)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('firetank_Collection')
                    .where('tank_id', isEqualTo: widget.tankId)
                    .limit(1)
                    .get()
                    .then((querySnapshot) => querySnapshot.docs.first),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text('เกิดข้อผิดพลาด'));
                  }
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Center(
                        child: Text('ไม่พบรายละเอียดถังดับเพลิง'));
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ถังดับเพลิง ID: ${data['tank_id']}'),
                      Text('ประเภท: ${data['type']}'),
                      Text('อาคาร: ${data['building']}'),
                      Text('ชั้น: ${data['floor']}'),
                      Text('สถานะ: ${data['status']}',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // ปุ่มกดเสร็จสิ้น (Reset Status)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton(
                onPressed: isUpdating ? null : resetStatus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  minimumSize: Size(double.infinity, 50),
                ),
                child: isUpdating
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'เสร็จสิ้น (รีเซ็ตสถานะ)',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
            ),

            const SizedBox(height: 20),

            // ส่วนแสดงประวัติการตรวจสอบ (คงเดิม)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ประวัติการตรวจสอบ',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('form_checks')
                        .where('tank_id', isEqualTo: widget.tankId)
                        .orderBy('date_checked', descending: true)
                        .get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return const Center(child: Text('เกิดข้อผิดพลาด'));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                            child: Text('ไม่พบประวัติการตรวจสอบ'));
                      }

                      final formChecks = snapshot.data!.docs;

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: formChecks.length,
                        itemBuilder: (context, index) {
                          final checkData =
                              formChecks[index].data() as Map<String, dynamic>;
                          return ListTile(
                            title: Text(
                                'ตรวจสอบเมื่อ: ${checkData['date_checked']}'),
                            subtitle:
                                Text('ผู้ตรวจสอบ: ${checkData['inspector']}'),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
