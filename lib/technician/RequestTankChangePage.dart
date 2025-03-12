import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RequestTankChangePage extends StatefulWidget {
  final String tankId;

  RequestTankChangePage({required this.tankId});

  @override
  _RequestTankChangePageState createState() => _RequestTankChangePageState();
}

class _RequestTankChangePageState extends State<RequestTankChangePage> {
  final TextEditingController reasonController = TextEditingController();
  bool isLoading = true;
  bool isSubmitting = false;
  Map<String, dynamic>? tankData;
  List<String> tankTypes = [];
  String? selectedTankType;

  @override
  void initState() {
    super.initState();
    fetchTankData();
    fetchTankTypes();
    if (tankTypes.isNotEmpty) {
      selectedTankType = tankTypes.first; // เลือกค่าเริ่มต้นอัตโนมัติ
    }
  }

  /// ดึงข้อมูลถังดับเพลิงจาก Firestore
  Future<void> fetchTankData() async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('firetank_Collection')
          .where('tank_id', isEqualTo: widget.tankId)
          .get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          tankData = snapshot.docs.first.data();
          selectedTankType = tankData!['type']; // ตั้งค่าประเภทถังเริ่มต้น
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่พบข้อมูลถังดับเพลิง')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  /// ดึงข้อมูลประเภทถังจาก FE_type
  Future<void> fetchTankTypes() async {
    try {
      var snapshot =
          await FirebaseFirestore.instance.collection('FE_type').get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          tankTypes =
              snapshot.docs.map((doc) => doc['type'].toString()).toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดประเภทถัง: $e')),
      );
    }
  }

  /// ✅ ฟังก์ชันบันทึกคำขอไปยัง Firestore
  Future<void> submitRequest() async {
    if (tankData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่สามารถส่งคำขอได้ เนื่องจากไม่มีข้อมูลถัง')),
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
      DateTime requestDate = DateTime.now();
      DateTime expireDate = requestDate.add(Duration(days: 5 * 365)); // +5 ปี

      await FirebaseFirestore.instance.collection('change_requests').add({
        'tank_id': tankData!['tank_id'],
        'building': tankData!['building'],
        'floor': tankData!['floor'],
        'current_tank_type': tankData!['type'], // 🏷️ ประเภทถังเดิม
        'new_tank_type': selectedTankType, // ✅ ประเภทถังที่เลือกใหม่
        'reason': reasonController.text,
        'status': 'pending',
        'request_date': requestDate,
        'expire_date': expireDate,
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('ร้องขอเปลี่ยนถัง', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.orange,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: isLoading
            ? Center(child: CircularProgressIndicator(color: Colors.orange))
            : tankData == null
                ? Center(
                    child: Text(
                      'ไม่พบข้อมูลถังดับเพลิง',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        shadowColor: Colors.orange.withOpacity(0.5),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.fire_extinguisher,
                                      color: Colors.orange, size: 24),
                                  SizedBox(width: 8),
                                  Text('Tank ID: ${widget.tankId}',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Divider(color: Colors.orange),
                              Text('อาคาร: ${tankData!['building']}',
                                  style: TextStyle(fontSize: 16)),
                              Text('ชั้น: ${tankData!['floor']}',
                                  style: TextStyle(fontSize: 16)),
                              SizedBox(height: 8),
                              Text('ประเภทถังปัจจุบัน: ${tankData!['type']}',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              SizedBox(height: 8),
                              Text('เลือกประเภทถังใหม่:',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange)),
                              DropdownButtonFormField<String>(
                                value: selectedTankType,
                                items: tankTypes.map((type) {
                                  return DropdownMenuItem(
                                    value: type,
                                    child: Text(type),
                                  );
                                }).toList(),
                                onChanged: (newValue) {
                                  setState(() {
                                    selectedTankType = newValue;
                                  });
                                },
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text('เหตุผลในการเปลี่ยน',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange)),
                      SizedBox(height: 8),
                      TextField(
                        controller: reasonController,
                        decoration: InputDecoration(
                          hintText: 'เช่น ถังรั่ว, หมดอายุ',
                          prefixIcon: Icon(Icons.edit, color: Colors.orange),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      isSubmitting
                          ? Center(
                              child: CircularProgressIndicator(
                                  color: Colors.orange))
                          : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: submitRequest,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 5,
                                ),
                                child: Text('ส่งคำขอ',
                                    style: TextStyle(fontSize: 18)),
                              ),
                            ),
                    ],
                  ),
      ),
    );
  }
}
