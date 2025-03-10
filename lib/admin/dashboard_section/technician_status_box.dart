import 'package:flutter/material.dart';
import 'inspection_status_box.dart';

class TechnicianStatusBox extends StatelessWidget {
  final int checkedCount, uncheckedCount, brokenCount, repairCount, totalTanks;
  const TechnicianStatusBox({
    Key? key,
    required this.checkedCount,
    required this.uncheckedCount,
    required this.brokenCount,
    required this.repairCount,
    required this.totalTanks,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InspectionStatusBox(
      checkedCount: checkedCount,
      uncheckedCount: uncheckedCount,
      brokenCount: brokenCount,
      repairCount: repairCount,
      totalTanks: totalTanks,
    );
  }
}
