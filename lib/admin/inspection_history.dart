import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InspectionOverviewPage extends StatefulWidget {
  @override
  _InspectionOverviewPageState createState() => _InspectionOverviewPageState();
}

class _InspectionOverviewPageState extends State<InspectionOverviewPage> {
  String? _selectedBuilding;
  String? _selectedFloor;
  String? selectedStatus;

  List<String> _buildings = [];
  List<String> _floors = [];

  List<String> _statuses = [];

  @override
  void initState() {
    super.initState();
    fetchBuildings();
    fetchStatuses(); // ดึงสถานะจาก Firestore
  }

  /// ดึงรายชื่ออาคารจาก Firestore
  Future<void> fetchBuildings() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('firetank_Collection')
          .get();

      // ตรวจสอบว่าเอกสารมีฟิลด์ 'building' หรือไม่
      final buildings = snapshot.docs
          .where((doc) => doc
              .data()
              .containsKey('building')) // ตรวจสอบว่าเอกสารมีฟิลด์ 'building'
          .map((doc) => doc['building'] as String)
          .toSet()
          .toList();

      setState(() {
        _buildings = buildings;
      });
    } catch (e) {
      print('เกิดข้อผิดพลาดในการดึงข้อมูล: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาดในการดึงข้อมูลจาก Firestore'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  /// ดึงรายชื่อชั้นของอาคารที่เลือก
  Future<void> fetchFloors(String building) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('firetank_Collection')
        .where('building', isEqualTo: building)
        .get();

    final floors = snapshot.docs
        .map((doc) => doc['floor'].toString()) // แปลงเป็น String
        .toSet()
        .toList();

    floors.sort(
        (a, b) => int.parse(a).compareTo(int.parse(b))); // เรียงจากน้อยไปมาก

    setState(() {
      _floors = floors;
      _selectedFloor = null;
    });
  }

  /// ดึงสถานะจาก Firestore และสร้างตัวเลือกให้กรอง
  Future<void> fetchStatuses() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('firetank_Collection')
          .get();

      final statusSet = <String>{};

      for (var doc in snapshot.docs) {
        String? status = doc['status'] as String?;
        String? statusTechnician = doc['status_technician'] as String?;

        if (statusTechnician != null && statusTechnician.isNotEmpty) {
          statusSet.add(statusTechnician);
        } else if (status != null && status.isNotEmpty) {
          statusSet.add(status);
        }
      }

      setState(() {
        _statuses = statusSet.toList();
      });
    } catch (e) {
      print('เกิดข้อผิดพลาดในการดึงข้อมูลสถานะ: $e');
    }
  }

  /// กำหนดการดึงข้อมูลตามตัวกรอง
  Stream<QuerySnapshot> _getInspections() {
    Query query = FirebaseFirestore.instance.collection('firetank_Collection');

    if (_selectedBuilding != null) {
      query = query.where('building', isEqualTo: _selectedBuilding);
    }
    if (_selectedFloor != null) {
      query = query.where('floor', isEqualTo: _selectedFloor);
    }
    if (selectedStatus != null) {
      query = query.where('status_technician', isEqualTo: selectedStatus);
    }

    return query.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📊 ประวัติการตรวจสอบ')),
      body: Column(
        children: [
          // 🔍 Filter Section
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: const Text('เลือกอาคาร'),
                        value: _selectedBuilding,
                        onChanged: (value) {
                          setState(() {
                            _selectedBuilding = value;
                            _selectedFloor = null;
                            fetchFloors(value!);
                          });
                        },
                        items: _buildings
                            .map((building) => DropdownMenuItem<String>(
                                  value: building,
                                  child: Text(building),
                                ))
                            .toList(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: const Text('เลือกชั้น'),
                        value: _selectedFloor,
                        onChanged: (value) {
                          setState(() {
                            _selectedFloor = value;
                          });
                        },
                        items: _floors
                            .map((floor) => DropdownMenuItem<String>(
                                  value: floor,
                                  child: Text(floor),
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration:
                            const InputDecoration(labelText: '🔧 สถานะ'),
                        value: selectedStatus,
                        items: _statuses
                            .map((status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status),
                                ))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => selectedStatus = value),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedBuilding = null;
                          _selectedFloor = null;
                          selectedStatus = null;

                          //_selectedType = null;
                          //_searchTankId = '';
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                      child: const Text(
                        'รีเซ็ตตัวกรองทั้งหมด',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 📋 ListView of FireTanks
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getInspections(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('ไม่พบข้อมูล'));
                }

                final fireTanks = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: fireTanks.length,
                  itemBuilder: (context, index) {
                    final data =
                        fireTanks[index].data() as Map<String, dynamic>;

                    String tankId = data['tank_id'];
                    String building = data['building'] ?? 'ไม่ระบุ';
                    String floor = data['floor'] ?? 'ไม่ระบุ';
                    String statusTechnician =
                        data['status_technician'] ?? 'ไม่มีข้อมูล';
                    String status = data['status'] ?? 'ไม่มีข้อมูล';
                    String finalStatus =
                        statusTechnician.isNotEmpty ? statusTechnician : status;

                    return FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('form_checks')
                          .where('tank_id', isEqualTo: tankId)
                          .orderBy('date_checked', descending: true)
                          .orderBy('time_checked', descending: true)
                          .limit(1)
                          .get(),
                      builder: (context, formSnapshot) {
                        if (formSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (!formSnapshot.hasData ||
                            formSnapshot.data!.docs.isEmpty) {
                          return const Center(child: Text(''));
                        }

                        final latestCheck = formSnapshot.data!.docs.first.data()
                            as Map<String, dynamic>;

                        String lastCheckedBy =
                            latestCheck['inspector'] ?? 'ไม่ระบุ';
                        String userType = latestCheck['user_type'] ?? 'ไม่ระบุ';
                        String lastCheckedDate =
                            latestCheck['date_checked'] ?? 'ไม่ระบุ';

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          child: ListTile(
                            leading: Icon(Icons.fire_extinguisher,
                                color: Colors.green),
                            title: Text('ถังดับเพลิง ID: $tankId'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('📍 อาคาร: $building, ชั้น: $floor'),
                                Text(
                                    '👷‍♂️ ตรวจล่าสุดโดย: $lastCheckedBy ($userType)'),
                                Text('📅 วันที่ตรวจล่าสุด: $lastCheckedDate'),
                                Text('🔧 สถานะ: $finalStatus'),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
