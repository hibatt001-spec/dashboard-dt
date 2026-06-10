import 'package:hive/hive.dart';

part 'kpi_history.g.dart';

@HiveType(typeId: 0)
class KpiHistory extends HiveObject {
  @HiveField(0)
  final DateTime timestamp;

  @HiveField(1)
  final double temperature;

  @HiveField(2)
  final double vibration;

  @HiveField(3)
  final double current;

  @HiveField(4)
  final double healthIndex;

  @HiveField(5)
  final double rul;

  @HiveField(6)
  final double oee;

  @HiveField(7)
  final double availability;

  @HiveField(8)
  final double efficiency;

  @HiveField(9)
  final double mtbf;

  @HiveField(10)
  final double mttr;

  @HiveField(11)
  final double maintenanceCost;

  @HiveField(12)
  final String alertStatus; // "Normal", "Warning", "Critical"

  @HiveField(13)
  final String mode;

  KpiHistory({
    required this.timestamp,
    required this.temperature,
    required this.vibration,
    required this.current,
    required this.healthIndex,
    required this.rul,
    required this.oee,
    required this.availability,
    required this.efficiency,
    required this.mtbf,
    required this.mttr,
    required this.maintenanceCost,
    required this.alertStatus,
    required this.mode,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'temperature': temperature,
      'vibration': vibration,
      'current': current,
      'healthIndex': healthIndex,
      'rul': rul,
      'oee': oee,
      'availability': availability,
      'efficiency': efficiency,
      'mtbf': mtbf,
      'mttr': mttr,
      'maintenanceCost': maintenanceCost,
      'alertStatus': alertStatus,
      'mode': mode,
    };
  }
}
