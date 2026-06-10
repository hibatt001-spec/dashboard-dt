import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:async';
import 'dart:math' as math;

// نموذج بيانات التنبيه الصناعي
class IndustrialAlert {
  final String id;
  final String assetName;
  final String parameter;
  final String message;
  final double currentValue;
  final double thresholdValue;
  final String unit;
  final DateTime timestamp;
  final String severity; // 'CRITICAL' (Red), 'WARNING' (Orange), 'INFO' (Yellow/Cyan)
  bool isAcknowledged;

  IndustrialAlert({
    required this.id,
    required this.assetName,
    required this.parameter,
    required this.message,
    required this.currentValue,
    required this.thresholdValue,
    required this.unit,
    required this.timestamp,
    required this.severity,
    this.isAcknowledged = false,
  });
}

class IndustrialAlertsPanel extends StatefulWidget {
  const IndustrialAlertsPanel({super.key});

  @override
  State<IndustrialAlertsPanel> createState() => _IndustrialAlertsPanelState();
}

class _IndustrialAlertsPanelState extends State<IndustrialAlertsPanel>
    with SingleTickerProviderStateMixin {
  final List<IndustrialAlert> _alertsLog = [];
  String _severityFilter = 'ALL'; // ALL, CRITICAL, WARNING, INFO

  // أنيميشن الوميض للمخاطر الحرجة (Blinking Danger Animation)
  late AnimationController _blinkController;
  Timer? _alertSimulationTimer;
  final math.Random _random = math.Random();

  // ─── الألوان الصناعية القياسية (تظل ثابتة لأنها تعبر عن دلالات أمان دولية) ───
  final Color colorCritical = const Color(0xFFFF3333); // الأحمر الناري للمخاطر
  final Color colorWarning = const Color(0xFFFF9100);  // البرتقالي الصناعي للتحذيرات
  final Color colorInfo = const Color(0xFFFFEA00);     // الأصفر التنبيهي للمتغيرات الخفيفة
  final Color colorNormal = const Color(0xFF00E676);   // الأخضر المستقر للتشغيل الطبيعي

  @override
  void initState() {
    super.initState();

    // إعداد أنيميشن الوميض ليعمل باستمرار وبنعومة (Looping Pulse)
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _blinkController.reverse();
        } else if (status == AnimationStatus.dismissed) {
          _blinkController.forward();
        }
      });
    _blinkController.forward();

    _generateInitialAlerts();
    _startRealTimeAlertStream();
  }

  @override
  void dispose() {
    _blinkController.dispose();
    _alertSimulationTimer?.cancel();
    super.dispose();
  }

  void _generateInitialAlerts() {
    _alertsLog.addAll([
      IndustrialAlert(
        id: 'AL-0941',
        assetName: 'SEW-EURODRIVE FA 107',
        parameter: 'VIBRATION (FFT SPECTRUM)',
        message: 'Abnormal vibration peak amplitude detected at 45Hz [BPF Fault Candidate]',
        currentValue: 3.82,
        thresholdValue: 2.50,
        unit: 'mm/s',
        timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
        severity: 'CRITICAL',
      ),
      IndustrialAlert(
        id: 'AL-0938',
        assetName: 'SEW-EURODRIVE FA 107',
        parameter: 'CASING TEMPERATURE',
        message: 'Infrared sensor MLX90614 reported dynamic thermal rise exceeding nominal gradient',
        currentValue: 74.5,
        thresholdValue: 65.0,
        unit: '°C',
        timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
        severity: 'WARNING',
      ),
      IndustrialAlert(
        id: 'AL-0932',
        assetName: 'LINE DATA ACQUISITION',
        parameter: 'ESP32 ETH UTP CAT6',
        message: 'Packet transmission jitter detected on physical layer link',
        currentValue: 14.2,
        thresholdValue: 5.0,
        unit: 'ms',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        severity: 'INFO',
      ),
    ]);
  }

  void _startRealTimeAlertStream() {
    _alertSimulationTimer = Timer.periodic(const Duration(seconds: 14), (timer) {
      if (!mounted) return;

      int dice = _random.nextInt(3);
      IndustrialAlert newAlert;

      if (dice == 0) {
        newAlert = IndustrialAlert(
          id: 'AL-${_random.nextInt(900) + 100}',
          assetName: 'SEW-EURODRIVE FA 107',
          parameter: 'THREE-PHASE CURRENT',
          message: 'Phase unbalance detected. Absorbed current analysis suggests temporary overcurrent.',
          currentValue: 17.4,
          thresholdValue: 15.0,
          unit: 'A',
          timestamp: DateTime.now(),
          severity: 'CRITICAL',
        );
      } else if (dice == 1) {
        newAlert = IndustrialAlert(
          id: 'AL-${_random.nextInt(900) + 100}',
          assetName: 'MPU6050 SENSOR MODULE',
          parameter: 'ACCELEROMETER LOG',
          message: 'High-frequency micro-shocks captured outside typical asset envelope.',
          currentValue: 1.15,
          thresholdValue: 0.80,
          unit: 'g',
          timestamp: DateTime.now(),
          severity: 'WARNING',
         );
      } else {
        newAlert = IndustrialAlert(
          id: 'AL-${_random.nextInt(900) + 100}',
          assetName: 'THERMAL CORE NODE',
          parameter: 'AMBIENT REFERENCE',
          message: 'Control room baseline temperature variation detected.',
          currentValue: 28.1,
          thresholdValue: 26.0,
          unit: '°C',
          timestamp: DateTime.now(),
          severity: 'INFO',
        );
      }

      setState(() {
        _alertsLog.insert(0, newAlert);
        if (_alertsLog.length > 50) _alertsLog.removeLast();
      });
    });
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'CRITICAL':
        return colorCritical;
      case 'WARNING':
        return colorWarning;
      case 'INFO':
        return colorInfo;
      default:
        return Theme.of(context).hintColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🎨 جلب متغيرات الألوان ديناميكياً بناءً على الثيم المختار للتطبيق
    final Color bgControlRoom = Theme.of(context).scaffoldBackgroundColor;
    final Color cardAlertBg = Theme.of(context).cardColor;
    final Color panelBorder = Theme.of(context).dividerColor.withOpacity(0.15);
    final Color textPrimary = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
    final Color textMuted = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;

    List<IndustrialAlert> filteredAlerts = _alertsLog.where((alert) {
      if (_severityFilter == 'ALL') return true;
      return alert.severity == _severityFilter;
    }).toList();

    int criticalCount = _alertsLog
        .where((a) => a.severity == 'CRITICAL' && !a.isAcknowledged)
        .length;
    int warningCount = _alertsLog
        .where((a) => a.severity == 'WARNING' && !a.isAcknowledged)
        .length;

    return Scaffold(
      backgroundColor: bgControlRoom,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildControlRoomHeader(criticalCount, warningCount, textPrimary, textMuted),
            const SizedBox(height: 24),
            _buildSeverityFilterBar(cardAlertBg, panelBorder, textPrimary, textMuted),
            const SizedBox(height: 16),
            Expanded(
              child: filteredAlerts.isEmpty
                  ? _buildEmptySystemState(cardAlertBg, panelBorder, textPrimary, textMuted)
                  : ListView.builder(
                      itemCount: filteredAlerts.length,
                      itemBuilder: (context, index) {
                        return _buildAlertNotificationCard(
                          filteredAlerts[index],
                          cardAlertBg,
                          panelBorder,
                          textPrimary,
                          textMuted,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 1. تصميم الهيدر العلوي لغرف المراقبة الصناعية ────────────────────────────
  Widget _buildControlRoomHeader(int criticals, int warnings, Color textPrimary, Color textMuted) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AnimatedBuilder(
                    animation: _blinkController,
                    builder: (context, child) {
                      return Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: criticals > 0
                              ? colorCritical.withOpacity(_blinkController.value)
                              : colorNormal,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: criticals > 0 ? colorCritical : colorNormal,
                              blurRadius: criticals > 0 ? 10 * _blinkController.value : 6,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'ANOMALY DETECTION & LIVE ENGINE ALERTS',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        fontFamily: 'Courier',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Real-time automated diagnostic pipeline monitoring system',
                style: TextStyle(color: textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Row(
          children: [
            _buildStatusCounterBadge('CRITICAL', criticals, colorCritical, textPrimary, textMuted),
            const SizedBox(width: 12),
            _buildStatusCounterBadge('WARNINGS', warnings, colorWarning, textPrimary, textMuted),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusCounterBadge(String label, int count, Color badgeColor, Color textPrimary, Color textMuted) {
    final Color panelBorder = Theme.of(context).dividerColor.withOpacity(0.15);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: count > 0 ? badgeColor.withOpacity(0.12) : panelBorder.withOpacity(0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: count > 0 ? badgeColor : panelBorder,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: textMuted,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '$count',
            style: TextStyle(
              color: count > 0 ? badgeColor : textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              fontFamily: 'Courier',
            ),
          ),
        ],
      ),
    );
  }

  // ─── 2. شريط الفلترة والأزرار الصناعية لتصفية الأحداث ─────────────────────────
  Widget _buildSeverityFilterBar(Color cardAlertBg, Color panelBorder, Color textPrimary, Color textMuted) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterButton('ALL SYSTEM EVENTS', 'ALL', textPrimary, cardAlertBg, panelBorder, textPrimary, textMuted),
          const SizedBox(width: 10),
          _buildFilterButton('CRITICAL ONLY', 'CRITICAL', colorCritical, cardAlertBg, panelBorder, textPrimary, textMuted),
          const SizedBox(width: 10),
          _buildFilterButton('WARNING LABELS', 'WARNING', colorWarning, cardAlertBg, panelBorder, textPrimary, textMuted),
          const SizedBox(width: 10),
          _buildFilterButton('SYSTEM INFO', 'INFO', colorInfo, cardAlertBg, panelBorder, textPrimary, textMuted),
        ],
      ),
    );
  }

  Widget _buildFilterButton(
    String text,
    String targetFilter,
    Color activeIndicatorColor,
    Color cardAlertBg,
    Color panelBorder,
    Color textPrimary,
    Color textMuted,
  ) {
    bool isSelected = _severityFilter == targetFilter;
    return InkWell(
      onTap: () => setState(() => _severityFilter = targetFilter),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeIndicatorColor.withOpacity(0.1) : cardAlertBg.withOpacity(0.4),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? activeIndicatorColor : panelBorder,
            width: 1.2,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? textPrimary : textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  // ─── 3. كرت التنبيه الصناعي الذكي (Notification Card Template) ────────────────
  Widget _buildAlertNotificationCard(IndustrialAlert alert, Color cardAlertBg, Color panelBorder, Color textPrimary, Color textMuted) {
    Color severityColor = _getSeverityColor(alert.severity);
    bool isCritical = alert.severity == 'CRITICAL';

    return AnimatedBuilder(
      animation: _blinkController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: cardAlertBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: (isCritical && !alert.isAcknowledged)
                  ? severityColor.withOpacity(_blinkController.value)
                  : severityColor.withOpacity(0.4),
              width: (isCritical && !alert.isAcknowledged) ? 2.0 : 1.2,
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 6,
                  decoration: BoxDecoration(
                    color: severityColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      bottomLeft: Radius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: panelBorder,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      alert.id,
                                      style: TextStyle(
                                        color: textPrimary,
                                        fontSize: 10,
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      alert.assetName,
                                      style: TextStyle(
                                        color: textPrimary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('•', style: TextStyle(color: panelBorder)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      alert.parameter,
                                      style: TextStyle(
                                        color: severityColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.1,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${alert.timestamp.hour.toString().padLeft(2, '0')}:${alert.timestamp.minute.toString().padLeft(2, '0')}:${alert.timestamp.second.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                color: textMuted,
                                fontSize: 11,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          alert.message,
                          style: TextStyle(
                            color: textPrimary.withOpacity(0.9),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildValueMetricTracker('CURRENT VALUE', '${alert.currentValue} ${alert.unit}', textPrimary, textMuted),
                            const SizedBox(width: 24),
                            _buildValueMetricTracker('CRITICAL THRESHOLD', '> ${alert.thresholdValue} ${alert.unit}', severityColor, textMuted),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Center(
                    child: OutlinedButton.icon(
                      onPressed: alert.isAcknowledged
                          ? null
                          : () => setState(() => alert.isAcknowledged = true),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: alert.isAcknowledged ? Colors.transparent : panelBorder,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        backgroundColor: alert.isAcknowledged ? panelBorder.withOpacity(0.2) : Colors.transparent,
                      ),
                      icon: Icon(
                        alert.isAcknowledged ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        size: 14,
                        color: alert.isAcknowledged ? colorNormal : textMuted,
                      ),
                      label: Text(
                        alert.isAcknowledged ? 'ACKED' : 'ACKNOWLEDGE',
                        style: TextStyle(
                          color: alert.isAcknowledged ? colorNormal.withOpacity(0.8) : textPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildValueMetricTracker(String label, String value, Color valueColor, Color textMuted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textMuted,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  // ─── 4. واجهة خلو النظام من أي شذوذ ──────────────────
  Widget _buildEmptySystemState(Color cardAlertBg, Color panelBorder, Color textPrimary, Color textMuted) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: cardAlertBg.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: panelBorder.withOpacity(0.5), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              FontAwesomeIcons.shieldHalved,
              size: 48,
              color: colorNormal.withOpacity(0.7),
            ),
            const SizedBox(height: 18),
            const Text(
              'ALL SYSTEMS OPERATIONAL',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                fontFamily: 'Courier',
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'No active anomalies or telemetry violations captured across monitored assets.',
              textAlign: TextAlign.center,
              style: TextStyle(color: textMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}