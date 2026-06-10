import 'package:hive_flutter/hive_flutter.dart';
import '../models/kpi_history.dart';

class HistoryService {
  static const String _boxName = 'kpi_history_box';
  
  static Box<KpiHistory> get box => Hive.box<KpiHistory>(_boxName);

  static Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(KpiHistoryAdapter());
    }
    await Hive.openBox<KpiHistory>(_boxName);
  }

  static Future<void> saveSnapshot(KpiHistory history) async {
    await box.add(history);
  }

  static List<KpiHistory> getAllHistory() {
    return box.values.toList().cast<KpiHistory>();
  }

  static List<KpiHistory> getHistoryByFilter(String filter) {
    final now = DateTime.now();
    final all = getAllHistory();

    switch (filter) {
      case 'Today':
        return all.where((h) => 
          h.timestamp.year == now.year &&
          h.timestamp.month == now.month &&
          h.timestamp.day == now.day
        ).toList();
      case 'Last 7 Days':
        final sevenDaysAgo = now.subtract(const Duration(days: 7));
        return all.where((h) => h.timestamp.isAfter(sevenDaysAgo)).toList();
      case 'Last 30 Days':
        final thirtyDaysAgo = now.subtract(const Duration(days: 30));
        return all.where((h) => h.timestamp.isAfter(thirtyDaysAgo)).toList();
      case 'Critical Alerts':
        return all.where((h) => h.alertStatus == 'Critical').toList();
      case 'Warning Alerts':
        return all.where((h) => h.alertStatus == 'Warning').toList();
      default:
        return all;
    }
  }

  static Future<void> clearHistory() async {
    await box.clear();
  }

  static Future<void> deleteRecord(int index) async {
    await box.deleteAt(index);
  }

  // Statistics Calculation
  static double getAverageHealthIndex() {
    final all = getAllHistory();
    if (all.isEmpty) return 0.0;
    final total = all.fold<double>(0.0, (sum, item) => sum + item.healthIndex);
    return total / all.length;
  }

  static double getAverageOee() {
    final all = getAllHistory();
    if (all.isEmpty) return 0.0;
    final total = all.fold<double>(0.0, (sum, item) => sum + item.oee);
    return total / all.length;
  }

  static int getTotalAlerts() {
    final all = getAllHistory();
    return all.where((h) => h.alertStatus == 'Critical' || h.alertStatus == 'Warning').length;
  }

  static double getTotalDowntimeHrs() {
    // Estimating downtime from mttr and alert occurrences, or just summing where availability < threshold
    final all = getAllHistory();
    double downtime = 0.0;
    // Simple logic: if alertStatus is Critical, assume 1 hour of downtime (or sum MTTR)
    for (var h in all) {
      if (h.alertStatus == 'Critical') {
        downtime += h.mttr; // rough estimation
      }
    }
    return downtime;
  }
}
