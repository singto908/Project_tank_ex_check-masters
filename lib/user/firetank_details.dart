import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // ใช้จัดรูปแบบวันที่

class FireTankDetailsPage extends StatefulWidget {
  final String tankId;

  const FireTankDetailsPage({Key? key, required this.tankId}) : super(key: key);

  @override
  _FireTankDetailsPageState createState() => _FireTankDetailsPageState();
}

class _FireTankDetailsPageState extends State<FireTankDetailsPage> {
  bool isTechnicianView = false; // สลับมุมมองระหว่างผู้ใช้ทั่วไปและช่างเทคนิค
  bool _isUpdating = false; // ป้องกันการกดซ้ำ

  Future<void> _markAsComplete() async {
    if (_isUpdating) return;

    setState(() {
      _isUpdating = true;
    });

    FirebaseFirestore firestore = FirebaseFirestore.instance;
    WriteBatch batch = firestore.batch();

    try {
      // 1️⃣ อัปเดตสถานะถังดับเพลิงเป็น "ปกติ"
      QuerySnapshot fireTankSnapshot = await firestore
          .collection('firetank_Collection')
          .where('tank_id', isEqualTo: widget.tankId)
          .where('status', isEqualTo: 'ชำรุด')
          .get();

      for (var doc in fireTankSnapshot.docs) {
        batch.update(doc.reference, {'status': 'ปกติ'});
      }

      // 2️⃣ บันทึกการอัปเดตลง `FE_updates`
      String formattedDate =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

      batch.set(firestore.collection('FE_updates').doc(), {
        'tank_id': widget.tankId,
        'updated_status': 'ปกติ',
        'updated_at': formattedDate,
        'updated_by': 'ช่างเทคนิค', // ปรับตามข้อมูลผู้ใช้จริง
      });

      // 3️⃣ ลบคำร้องที่เกี่ยวข้องจาก `technician_requests`
      QuerySnapshot requestSnapshot = await firestore
          .collection('technician_requests')
          .where('tank_id', isEqualTo: widget.tankId)
          .get();

      for (var doc in requestSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      // แจ้งเตือนว่าเสร็จสิ้น
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('รีเซ็ตสถานะสำเร็จ!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('รายละเอียดการตรวจสอบ'),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // ✅ รายละเอียดถังดับเพลิง
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
                      .doc(widget.tankId)
                      .get(),
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
                        const Text(
                          'รายละเอียดถังดับเพลิง',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 10),
                        Text('ถังดับเพลิง ID: ${data['tank_id']}'),
                        Text('ประเภท: ${data['type']}'),
                        Text('อาคาร: ${data['building']}'),
                        Text('ชั้น: ${data['floor']}'),
                        Text(
                          'สถานะ: ${data['status']}',
                          style: TextStyle(
                            color: data['status'] == 'ชำรุด'
                                ? Colors.red
                                : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // ✅ ประวัติการตรวจสอบ
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
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('form_checks')
                          .where('tank_id', isEqualTo: widget.tankId)
                          .orderBy('date_checked', descending: true)
                          .get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
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
                            final checkData = formChecks[index].data()
                                as Map<String, dynamic>;

                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      'ตรวจสอบเมื่อ: ${checkData['date_checked']}'),
                                  Text('ผู้ตรวจสอบ: ${checkData['inspector']}'),
                                  Text(
                                      'สถานะ: ${checkData['status'] ?? 'ไม่มีข้อมูล'}'),
                                ],
                              ),
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
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _isUpdating ? null : _markAsComplete, // ป้องกันการกดซ้ำ
          icon: _isUpdating
              ? CircularProgressIndicator(color: Colors.white)
              : Icon(Icons.check),
          label: Text('เสร็จสิ้น'),
          backgroundColor: Colors.green,
        ));
  }
}
