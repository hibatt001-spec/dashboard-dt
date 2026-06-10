import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/models/kpi_history.dart';
import '../../../core/services/history_service.dart';
import '../../../core/services/export_service.dart';
import '../../../main.dart';
import 'app_translations.dart';

class HistoryScreen extends StatefulWidget {
  final bool isDarkMode; // استقبال حالة الثيم ليتناسق مع الـ Day/Night Mode مريغل

  const HistoryScreen({
    super.key,
    required this.isDarkMode,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _currentFilter = 'all';
  
  final List<String> _filters = [
    'all',
    'today',
    'last_7_days',
    'last_30_days',
    'critical_alerts',
    'warning_alerts',
  ];

  @override
  Widget build(BuildContext context) {
    // 🎨 إعداد لوحة الألوان لتتغير ديناميكياً حسب الـ Mode (Jour / Nuit)
    final Color bgDark = widget.isDarkMode ? const Color(0xFF0C1322) : const Color(0xFFF8FAFC);
    final Color cardBg = widget.isDarkMode ? const Color(0xFF131C32) : Colors.white;
    final Color borderColor = widget.isDarkMode ? const Color(0xFF1E2D4A) : const Color(0xFFE2E8F0);
    final Color textMain = widget.isDarkMode ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B);
    final Color textSub = widget.isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final Color neonNominal = const Color(0xFF00E5FF);
    final Color neonWarning = const Color(0xFFFFEA00);
    final Color neonCritical = const Color(0xFFFF1744);

    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (context, currentLang, _) {
        String t(String key) => AppTranslations.t(key, currentLang);

        return Scaffold(
          backgroundColor: bgDark,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(t, cardBg, textMain, textSub),
                  const SizedBox(height: 24),
                  _buildStatsRow(t, cardBg, borderColor, textMain, textSub, neonNominal, neonWarning, neonCritical),
                  const SizedBox(height: 24),
                  _buildFilterAndExportRow(t, cardBg, borderColor, textMain, textSub, neonNominal),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _buildHistoryTable(t, cardBg, borderColor, textMain, textSub, neonNominal, neonWarning, neonCritical),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── شريط العنوان العلوي وزر مسح السجل بالكامل ───────────────────────────
  Widget _buildHeader(String Function(String) t, Color cardBg, Color textMain, Color textSub) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(
              Icons.history_toggle_off_rounded,
              color: Color(0xFF00E5FF),
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              t('kpi_history_logs'),
              style: TextStyle(
                color: textMain,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.delete_sweep_rounded, size: 18),
          label: Text(t('clear_history')),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent.withOpacity(0.1),
            foregroundColor: Colors.redAccent,
            elevation: 0,
            side: const BorderSide(color: Colors.redAccent, width: 1.2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: cardBg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                title: Text(
                  t('clear_confirm_title'),
                  style: TextStyle(color: textMain, fontWeight: FontWeight.bold),
                ),
                content: Text(
                  t('clear_confirm_content'),
                  style: TextStyle(color: textSub),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(t('cancel')),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(
                      t('clear_history'),
                      style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              await HistoryService.clearHistory();
              setState(() {}); // إعادة بناء الحسابات العلوية فوراً بعد الحذف المريغل
            }
          },
        ),
      ],
    );
  }

  // ─── كروت الإحصائيات الحية للمتوسطات والتنبيهات ───────────────────────────
  Widget _buildStatsRow(
    String Function(String) t, Color cardBg, Color borderColor, Color textMain, Color textSub,
    Color neonNominal, Color neonWarning, Color neonCritical
  ) {
    return ValueListenableBuilder(
      valueListenable: HistoryService.box.listenable(),
      builder: (context, Box<KpiHistory> box, _) {
        final avgHealth = HistoryService.getAverageHealthIndex();
        final avgOee = HistoryService.getAverageOee();
        final alerts = HistoryService.getTotalAlerts();
        final downtime = HistoryService.getTotalDowntimeHrs();

        return Row(
          children: [
            Expanded(child: _buildStatCard(t('avg_health'), '${avgHealth.toStringAsFixed(1)}%', Icons.favorite, neonNominal, cardBg, borderColor, textMain, textSub)),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard(t('avg_oee'), '${avgOee.toStringAsFixed(1)}%', Icons.analytics, const Color(0xFF00E676), cardBg, borderColor, textMain, textSub)),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard(t('total_alerts'), '$alerts', Icons.warning_amber_rounded, neonWarning, cardBg, borderColor, textMain, textSub)),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard(t('est_downtime'), '${downtime.toStringAsFixed(1)} h', Icons.timer_off_rounded, neonCritical, cardBg, borderColor, textMain, textSub)),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    String title, String value, IconData icon, Color color,
    Color cardBg, Color borderColor, Color textMain, Color textSub
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(widget.isDarkMode ? 0.05 : 0.02),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: textSub, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(color: textMain, fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── شريط الفلترة وتصدير التقارير (PDF/CSV) ───────────────────────────────────
  Widget _buildFilterAndExportRow(String Function(String) t, Color cardBg, Color borderColor, Color textMain, Color textSub, Color neonNominal) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _currentFilter,
              dropdownColor: cardBg,
              icon: Icon(Icons.filter_list, color: textSub),
              style: TextStyle(color: textMain, fontWeight: FontWeight.bold, fontSize: 13),
              items: _filters.map((filterKey) {
                return DropdownMenuItem(
                  value: filterKey,
                  child: Text(t(filterKey)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _currentFilter = val);
              },
            ),
          ),
        ),
        Row(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf, size: 18),
              label: Text(t('export_pdf')),
              style: ElevatedButton.styleFrom(
                backgroundColor: cardBg,
                foregroundColor: const Color(0xFFE040FB),
                elevation: 0,
                side: BorderSide(color: const Color(0xFFE040FB).withOpacity(0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final records = HistoryService.getHistoryByFilter(_mapFilterForService(_currentFilter));
                final path = await ExportService.exportToPDF(records);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF: $path')));
              },
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.table_chart, size: 18),
              label: Text(t('export_csv')),
              style: ElevatedButton.styleFrom(
                backgroundColor: cardBg,
                foregroundColor: neonNominal,
                elevation: 0,
                side: BorderSide(color: neonNominal.withOpacity(0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final records = HistoryService.getHistoryByFilter(_mapFilterForService(_currentFilter));
                final path = await ExportService.exportToCSV(records);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('CSV: $path')));
              },
            ),
          ],
        ),
      ],
    );
  }

  // ─── جدول السجلات الصناعية المتكامل ───────────────────────────────────────────
  Widget _buildHistoryTable(
    String Function(String) t, Color cardBg, Color borderColor, Color textMain, Color textSub,
    Color neonNominal, Color neonWarning, Color neonCritical
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: ValueListenableBuilder(
        valueListenable: HistoryService.box.listenable(),
        builder: (context, Box<KpiHistory> box, _) {
          final records = HistoryService.getHistoryByFilter(_mapFilterForService(_currentFilter));

          if (records.isEmpty) {
            return Center(
              child: Text(
                '${t("no_data_found")} "${t(_currentFilter)}"',
                style: TextStyle(color: textSub, letterSpacing: 1.1, fontSize: 14),
              ),
            );
          }

          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  headingTextStyle: TextStyle(color: neonNominal, fontWeight: FontWeight.bold, fontSize: 12),
                  dataTextStyle: TextStyle(color: textMain, fontSize: 13),
                  columnSpacing: 28,
                  headingRowColor: MaterialStateProperty.all(borderColor.withOpacity(0.2)),
                  columns: [
                    DataColumn(label: Text(t('timestamp'))),
                    DataColumn(label: Text(t('temp_c'))),
                    DataColumn(label: Text(t('vib_rms'))),
                    DataColumn(label: Text(t('current_a'))),
                    DataColumn(label: Text(t('health'))),
                    DataColumn(label: Text(t('oee_percent'))),
                    DataColumn(label: Text(t('mode'))),
                    DataColumn(label: Text(t('status'))),
                    DataColumn(label: Text(t('actions'))),
                  ],
                  rows: List.generate(records.length, (index) {
                    final record = records[index];
                    final statusKey = record.alertStatus.toLowerCase().trim();
                    final modeKey = record.mode.toLowerCase().trim();

                    final isCritical = statusKey == 'critical';
                    final isWarning = statusKey == 'warning';

                    return DataRow(
                      cells: [
                        DataCell(Text(DateFormat('MM-dd HH:mm:ss').format(record.timestamp))),
                        DataCell(Text('${record.temperature.toStringAsFixed(1)} °C')),
                        DataCell(Text('${record.vibration.toStringAsFixed(2)} mm/s')),
                        DataCell(Text('${record.current.toStringAsFixed(2)} A')),
                        DataCell(Text('${record.healthIndex.toStringAsFixed(1)} %')),
                        DataCell(Text('${record.oee.toStringAsFixed(1)} %')),
                        DataCell(Text(t(modeKey), style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isCritical ? neonCritical.withOpacity(0.15) : (isWarning ? neonWarning.withOpacity(0.15) : const Color(0xFF00E676).withOpacity(0.15)),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: isCritical ? neonCritical : (isWarning ? neonWarning : const Color(0xFF00E676)), width: 1),
                            ),
                            child: Text(
                              t(statusKey),
                              style: TextStyle(color: isCritical ? neonCritical : (isWarning ? neonWarning : const Color(0xFF00E676)), fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                            onPressed: () {
                              HistoryService.deleteRecord(record.key);
                              setState(() {}); // مريغلة لتحديث متوسطات الكروت العلوية فوراً
                            },
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _mapFilterForService(String filter) {
    switch (filter) {
      case 'all': return 'All';
      case 'today': return 'Today';
      case 'last_7_days': return 'Last 7 Days';
      case 'last_30_days': return 'Last 30 Days';
      case 'critical_alerts': return 'Critical Alerts';
      case 'warning_alerts': return 'Warning Alerts';
      default: return 'All';
    }
  }
}