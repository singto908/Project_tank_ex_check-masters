import 'package:flutter/material.dart';
import 'package:firecheck_setup/admin/dashboard.dart';

class InspectionStatusBox extends StatelessWidget {
  final int checkedCount, uncheckedCount, brokenCount, repairCount, totalTanks;
  const InspectionStatusBox({
    Key? key,
    required this.checkedCount,
    required this.uncheckedCount,
    required this.brokenCount,
    required this.repairCount,
    required this.totalTanks,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(12.0),
      decoration: boxDecorationStyle(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'การตรวจสอบผู้ใช้ทั่วไปในเดือนนี้',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$checkedCount / $totalTanks',
                style: const TextStyle(
                  fontSize: 24, // ขยายขนาดตัวเลข
                  fontWeight: FontWeight.bold, // ทำให้ตัวเข้มขึ้น
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
