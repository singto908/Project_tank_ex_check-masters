import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminReportPage extends StatefulWidget {
  @override
  _AdminReportPageState createState() => _AdminReportPageState();
}

class _AdminReportPageState extends State<AdminReportPage> {
  Set<String> uniqueTankIds = Set<String>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายการแจ้งชำรุด'),
        backgroundColor: Colors.redAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('firetank_Collection')
            .where('status', whereIn: ['ชำรุด', 'แจ้งซ่อมแล้ว']).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('ไม่มีข้อมูลการชำรุด'));
          }

          final damagedExtinguishers = snapshot.data!.docs;

          return ListView.builder(
            itemCount: damagedExtinguishers.length,
            itemBuilder: (context, index) {
              var data =
                  damagedExtinguishers[index].data() as Map<String, dynamic>;
              String tankId = data['tank_id'];

              if (uniqueTankIds.contains(tankId)) {
                return SizedBox.shrink();
              }
              uniqueTankIds.add(tankId);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                color: data['status'] == 'แจ้งซ่อมแล้ว'
                    ? Colors.green[100]
                    : Colors.white,
                child: ListTile(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ถัง #${data['tank_id']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.red), // ❌ ปุ่ม X
                        onPressed: () => _removeTechnicianRequest(data),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          '📍 อาคาร: ${data['building']} ชั้น ${data['floor']}'),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('form_checks')
                            .where('tank_id', isEqualTo: data['tank_id'])
                            .limit(1)
                            .snapshots(),
                        builder: (context, formSnapshot) {
                          if (formSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }
                          if (formSnapshot.hasError) {
                            return const Text('เกิดข้อผิดพลาดในการโหลดข้อมูล');
                          }
                          if (!formSnapshot.hasData ||
                              formSnapshot.data!.docs.isEmpty) {
                            return const Text('ไม่มีข้อมูลการตรวจสอบ');
                          }

                          var formData = formSnapshot.data!.docs.first.data()
                              as Map<String, dynamic>;

                          Map<String, dynamic> equipmentStatus =
                              formData['equipment_status'] ?? {};
                          var damagedParts = equipmentStatus.entries
                              .where((entry) => entry.value == 'ชำรุด')
                              .map((entry) => entry.key)
                              .toList();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('🔧 ประเภทถัง: ${data['type']}'),
                              damagedParts.isNotEmpty
                                  ? Text(
                                      '🔧 ส่วนที่ชำรุด: ${damagedParts.join(", ")}')
                                  : Text('✅ ไม่มีส่วนที่ชำรุด'),
                              Text(
                                  '💬 หมายเหตุ: ${formData['remarks'] ?? 'ไม่มีข้อมูล'}'),
                              Text(
                                  '📅 การตรวจสอบเมื่อ: ${_formatDate(formData['date_checked'])}'),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                      '📝 ผู้ตรวจสอบ: ${formData['inspector']}'),
                                  ElevatedButton(
                                    onPressed: data['status'] == 'แจ้งซ่อมแล้ว'
                                        ? null
                                        : () {
                                            _assignTechnician(data);
                                          },
                                    child: Text(
                                      data['status'] == 'แจ้งซ่อมแล้ว'
                                          ? 'แจ้งแล้ว'
                                          : 'แจ้งชำรุดหาช่าง',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          data['status'] == 'แจ้งซ่อมแล้ว'
                                              ? Colors.green
                                              : Colors.redAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
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

  String _formatDate(dynamic date) {
    if (date is Timestamp) {
      return DateFormat('yyyy-MM-dd').format(date.toDate());
    } else if (date is String) {
      try {
        return DateFormat('yyyy-MM-dd').format(DateTime.parse(date));
      } catch (e) {
        return '-';
      }
    }
    return '-';
  }

  void _assignTechnician(Map<String, dynamic> data) async {
    try {
      String tankId = data['tank_id']?.toString() ?? "ไม่ทราบ";
      String inspector =
          data['inspector']?.toString() ?? "ไม่ระบุ"; // ✅ ป้องกัน null

      // ✅ ดึงข้อมูล `firetank_Collection` เพื่ออัปเดตสถานะ
      QuerySnapshot firetankQuery = await FirebaseFirestore.instance
          .collection('firetank_Collection')
          .where('tank_id', isEqualTo: tankId)
          .limit(1)
          .get();

      if (firetankQuery.docs.isEmpty) {
        throw 'ไม่พบถังดับเพลิง #$tankId';
      }

      // ✅ ได้ Document ID ที่แท้จริงของ `firetank_Collection`
      String docId = firetankQuery.docs.first.id;

      // ✅ ดึง `equipment_status` จาก `form_checks`
      Map<String, dynamic> damagedParts = {};
      QuerySnapshot formQuery = await FirebaseFirestore.instance
          .collection('form_checks')
          .where('tank_id', isEqualTo: tankId)
          .limit(1)
          .get();

      if (formQuery.docs.isNotEmpty) {
        Map<String, dynamic> formData =
            formQuery.docs.first.data() as Map<String, dynamic>;
        Map<String, dynamic> equipmentStatus =
            (formData['equipment_status'] as Map<String, dynamic>?) ?? {};
        damagedParts = equipmentStatus.entries
            .where(
                (entry) => entry.value == 'ชำรุด') // ✅ คัดเฉพาะที่เป็น "ชำรุด"
            .fold<Map<String, dynamic>>({}, (map, entry) {
          map[entry.key] = entry.value;
          return map;
        });
      }

      // ✅ ดึง `user_type` จาก `users` collection
      String userType = "ผู้ดูแลระบบ"; // ค่าเริ่มต้น
      QuerySnapshot userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('name', isEqualTo: inspector)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        userType =
            userQuery.docs.first.get('user_type')?.toString() ?? "ไม่ทราบ";
      }

      // ✅ บันทึกข้อมูลไปยัง `technician_requests`
      await FirebaseFirestore.instance
          .collection('technician_requests')
          .doc(tankId)
          .set({
        'tank_id': tankId,
        'building': data['building']?.toString() ?? "ไม่ทราบ",
        'floor': data['floor']?.toString() ?? "ไม่ระบุ",
        'type': data['type']?.toString() ?? "ไม่ระบุ",
        'remarks': data['remarks']?.toString() ?? "ไม่มีหมายเหตุ",
        'status': 'แจ้งซ่อมแล้ว',
        'inspector': inspector,
        'user_type': userType, // ✅ ป้องกัน null
        'damaged_parts': damagedParts, // ✅ บันทึกเฉพาะที่เป็น "ชำรุด"
        'timestamp': FieldValue.serverTimestamp(),
      });

      // ✅ อัปเดต `firetank_Collection` เปลี่ยนสถานะเป็น "แจ้งซ่อมแล้ว"
      await FirebaseFirestore.instance
          .collection('firetank_Collection')
          .doc(docId)
          .update({'status': 'แจ้งซ่อมแล้ว'});

      // ✅ แจ้งเตือนว่าทำรายการสำเร็จ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'แจ้งซ่อมสำเร็จ! ส่วนที่ชำรุด: ${damagedParts.keys.join(", ")}'),
        ),
      );

      // ✅ รีโหลดหน้า `AdminReportPage`
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => AdminReportPage()));
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $error')),
      );
    }
  }

  void _removeTechnicianRequest(Map<String, dynamic> data) async {
    try {
      String tankId = data['tank_id'];

      // ✅ ลบข้อมูลจาก `technician_requests`
      await FirebaseFirestore.instance
          .collection('technician_requests')
          .doc(tankId)
          .delete();

      // ✅ อัปเดต `firetank_Collection` กลับเป็น "ชำรุด"
      await FirebaseFirestore.instance
          .collection('firetank_Collection')
          .where('tank_id', isEqualTo: tankId)
          .limit(1)
          .get()
          .then((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          snapshot.docs.first.reference.update({'status': 'ชำรุด'});
        }
      });

      // ✅ รีโหลดหน้า
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => AdminReportPage()));
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $error')),
      );
    }
  }
}
