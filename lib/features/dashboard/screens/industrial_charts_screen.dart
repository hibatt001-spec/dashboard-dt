import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'dart:math' as math;
import 'industrial_simulation_panel.dart';
import 'digital_twin_motor_view.dart';
import 'industrial_kpi_grid.dart';
import 'industrial_curves_section.dart';
import '../../../main.dart';
import '../../../core/services/history_service.dart';
import 'app_translations.dart';
import 'mqtt_service.dart';

// ═══════════════════════════════════════════════════════════════
//  IndustrialChartsScreen — استقبال البيانات الحية من السيمولينك
// ═══════════════════════════════════════════════════════════════
class IndustrialChartsScreen extends StatefulWidget {
  final List<FlSpot> vibrationFftSpots;   // 👈 استقبال مصفوفة الـ FFT الحية
  final List<FlSpot> vibrationTimeSpots;  // 👈 استقبال مصفوفة الإشارة الزمنية الحية
  final bool isDarkMode;                  // 👈 تصحيح تعريف متغير الثيم الاقتصادي

  const IndustrialChartsScreen({
    super.key, 
    required this.isDarkMode,             // 👈 تصحيح الـ Constructor
    required this.vibrationFftSpots,     
    required this.vibrationTimeSpots,    
  });

  @override
  State<IndustrialChartsScreen> createState() => _IndustrialChartsScreenState();
}

class _IndustrialChartsScreenState extends State<IndustrialChartsScreen> {
  int _currentTabIndex = 0;
  String _activeAnalysisTab = 'vibration';
  String _currentSimulationMode = 'normal';
  Timer? _analysisTimer;
  double _time = 0;
  final math.Random _random = math.Random();

  // مصفوفات التيار والحرارة الافتراضية
  final List<FlSpot> _currentHarmonicSpots   = [];
  final List<FlSpot> _thermalSimulationSpots = [];

  // ألوان المخططات — ثابتة مستقلة عن الـ theme
  final Color vibColor  = const Color(0xFFFF9800);
  final Color cyan      = const Color(0xFF00C2FF);
  final Color green     = const Color(0xFF00E676);
  final Color dangerRed = const Color(0xFFFF5252);

  // ── helper ترجمة ────────────────────────────────────────────
  String _t(String key) => AppTranslations.t(key, languageNotifier.value);

  @override
  void initState() {
    super.initState();
    _initializeHighResData();
    _startLiveAnalysisSimulation();
  }

  @override
  void dispose() {
    _analysisTimer?.cancel();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════════
  //  تهيئة البيانات (للتيار والحرارة فقط حالياً)
  // ════════════════════════════════════════════════════════════
  void _initializeHighResData() {
    for (int i = 0; i < 256; i++) {
      double freq = i * 1.0;
      double amp = (freq == 50)  ? 13.7 :
                   (freq == 100) ? 0.45 :
                   (freq == 150) ? 1.85 :
                   (freq == 250) ? 0.65 : _random.nextDouble() * 0.04;
      _currentHarmonicSpots.add(FlSpot(freq, amp));
    }
    for (int i = 0; i < 60; i++) {
      _thermalSimulationSpots.add(
          FlSpot(i * 0.5, 62.0 + (i * 0.1) + _random.nextDouble() * 0.1));
    }
  }

  // ════════════════════════════════════════════════════════════
  //  محاكاة حية (مخصصة للتيار والحرارة فقط)
  // ════════════════════════════════════════════════════════════
  void _startLiveAnalysisSimulation() {
    _analysisTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!mounted) return;
      setState(() {
        _time += 0.2;
        
        for (int i = 0; i < _currentHarmonicSpots.length; i++) {
          double f = _currentHarmonicSpots[i].x;
          if (f == 50)  _currentHarmonicSpots[i] = FlSpot(f, 13.7 + math.sin(_time) * 0.15);
          if (f == 150) _currentHarmonicSpots[i] = FlSpot(f, 1.85 + math.cos(_time * 2) * 0.08);
        }
        _thermalSimulationSpots.removeAt(0);
        double nextX = _thermalSimulationSpots.last.x + 0.5;
        _thermalSimulationSpots.add(FlSpot(nextX,
            68.5 + math.sin(nextX * 0.05) * 0.4 + _random.nextDouble() * 0.05));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (context, currentLang, _) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: themeNotifier,
          builder: (context, currentMode, _) {
            final bool isDark = currentMode == ThemeMode.dark;
            final bool isRtl  = currentLang == 'ar';

            final Color bgMain   = isDark ? const Color(0xFF06142A) : const Color(0xFFF4F7FB);
            final Color cardBg   = isDark ? const Color(0xFF10203C) : Colors.white;
            final Color borderBg = isDark ? const Color(0xFF283B5A) : const Color(0xFFCBD5E1);
            final Color textMain = isDark ? const Color(0xFFF4F7FA) : const Color(0xFF1E293B);
            final Color textSub  = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

            return Directionality(
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              child: Scaffold(
                backgroundColor: bgMain,
                appBar: AppBar(
                  backgroundColor: cardBg,
                  elevation: 0,
                  title: Text(
                    _t('appbar_title'),
                    style: TextStyle(color: textMain, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                  ),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Icon(
                        Icons.lens,
                        color: _currentSimulationMode == 'normal' ? green : dangerRed,
                        size: 11,
                      ),
                    ),
                  ],
                ),
                body: SafeArea(
                  child: IndexedStack(
                    index: _currentTabIndex,
                    children: [
                      _buildDigitalTwinTab(textMain, textSub, cyan, cardBg, borderBg),
                      _buildAnalyticsLab(cardBg, borderBg, textMain, textSub),
                    ],
                  ),
                ),
                bottomNavigationBar: Container(
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: borderBg, width: 1.2)),
                  ),
                  child: BottomNavigationBar(
                    currentIndex: _currentTabIndex,
                    onTap: (i) => setState(() => _currentTabIndex = i),
                    backgroundColor: cardBg,
                    selectedItemColor: cyan,
                    unselectedItemColor: textSub.withOpacity(0.4),
                    selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.6),
                    unselectedLabelStyle: const TextStyle(fontSize: 10),
                    type: BottomNavigationBarType.fixed,
                    items: [
                      BottomNavigationBarItem(
                        icon: const Icon(Icons.precision_manufacturing_rounded),
                        label: _t('nav_digital_twin'),
                      ),
                      BottomNavigationBarItem(
                        icon: const Icon(Icons.stacked_line_chart_rounded),
                        label: _t('nav_analytics'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDigitalTwinTab(Color textMain, Color textSub, Color accentIcon, Color cardBg, Color borderBg) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_t('controls_panel'), style: TextStyle(color: textMain, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            const SizedBox(height: 6),
            IndustrialSimulationPanel(
              currentMode: _currentSimulationMode,
              onModeChanged: (mode) => setState(() {
                _currentSimulationMode = mode;
                currentSimulationModeNotifier.value = mode;
              }),
            ),
            const SizedBox(height: 14),
            Text(_t('twin_3d_title'), style: TextStyle(color: textMain, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            SizedBox(
              height: 200,
              child: DigitalTwinMotorView(
                currentMode: _currentSimulationMode,
                currentLang: languageNotifier.value,
                isDarkMode: themeNotifier.value == ThemeMode.dark,
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Icon(Icons.stacked_bar_chart_rounded, color: accentIcon, size: 14),
              const SizedBox(width: 6),
              Text(_t('telemetry_grid'), style: TextStyle(color: textSub, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            ]),
            ValueListenableBuilder<String>(
              valueListenable: languageNotifier,
              builder: (context, lang, _) => ValueListenableBuilder<ThemeMode>(
                valueListenable: themeNotifier,
                builder: (context, mode, _) => IndustrialKpiGrid(
                  currentMode: _currentSimulationMode,
                  healthIndex: HistoryService.getAverageHealthIndex(),
                  estimatedDowntime: HistoryService.getTotalDowntimeHrs(),
                  totalAlerts: HistoryService.getTotalAlerts(),
                  currentLang: lang,
                  isDarkMode: mode == ThemeMode.dark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsLab(Color cardBg, Color borderBg, Color textMain, Color textSub) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _buildTopTabsNavigator(cardBg, borderBg, textMain, textSub),
          const SizedBox(height: 12),
          Expanded(child: _buildSelectedAnalysisView(cardBg, borderBg, textMain, textSub)),
        ],
      ),
    );
  }

  Widget _buildTopTabsNavigator(Color cardBg, Color borderBg, Color textMain, Color textSub) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderBg, width: 1.5),
      ),
      child: Row(children: [
        _buildTabButton(id: 'vibration', label: _t('tab_vibration'), icon: Icons.analytics_rounded, activeColor: vibColor, textMain: textMain, textSub: textSub),
        const SizedBox(width: 6),
        _buildTabButton(id: 'current', label: _t('tab_current'), icon: Icons.electrical_services, activeColor: green, textMain: textMain, textSub: textSub),
        const SizedBox(width: 6),
        _buildTabButton(id: 'temperature', label: _t('tab_thermal'), icon: Icons.thermostat_auto_rounded, activeColor: cyan, textMain: textMain, textSub: textSub),
      ]),
    );
  }

  Widget _buildTabButton({required String id, required String label, required IconData icon, required Color activeColor, required Color textMain, required Color textSub}) {
    final bool sel = _activeAnalysisTab == id;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeAnalysisTab = id),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: sel ? activeColor.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: sel ? activeColor : Colors.transparent, width: 1.5),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: sel ? activeColor : textSub, size: 16),
            const SizedBox(width: 6),
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(color: sel ? textMain : textSub, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5))),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelectedAnalysisView(Color cardBg, Color borderBg, Color textMain, Color textSub) {
    switch (_activeAnalysisTab) {
      case 'vibration':
        final double currentVibrationValue = widget.vibrationTimeSpots.isNotEmpty 
            ? widget.vibrationTimeSpots.last.y.abs() 
            : 1.2; 

        return _buildDualLayout(
          title: _t('chart_fft_title'), subtitle: _t('chart_fft_sub'),
          cardBg: cardBg, borderBg: borderBg,
          textMain: textMain, textSub: textSub,
          mainChartsArea: Column(children: [
            Expanded(
              flex: 6,
              child: _buildFftSpectrumChart(
                borderBg: borderBg,
                textSub: textSub,
                fftSpots: widget.vibrationFftSpots,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              flex: 4,
              child: _buildTimeWaveformChart(
                borderBg: borderBg,
                textSub: textSub,
                spots: widget.vibrationTimeSpots, 
              ),
            ),
          ]),
          sidePanel: _buildPeaksTable(
            borderBg: borderBg, textMain: textMain, textSub: textSub,
            rows: [
              _buildPeakRow('45.0',  (currentVibrationValue * 1.45).toStringAsFixed(2), 'BPF (Bearing Pass Freq)', textSub),
              _buildPeakRow('90.0',  (currentVibrationValue * 0.52).toStringAsFixed(2), '2× BPF Harmonic',         textSub),
              _buildPeakRow('135.0', (currentVibrationValue * 0.21).toStringAsFixed(2), '3× BPF Harmonic',         textSub),
              _buildPeakRow('11.2',  currentVibrationValue.toStringAsFixed(2),            'Overall RMS Severity',   textSub),
            ],
          ),
        );

      case 'current':
        return _buildDualLayout(
          title: _t('chart_mcsa_title'), subtitle: _t('chart_mcsa_sub'),
          cardBg: cardBg, borderBg: borderBg,
          textMain: textMain, textSub: textSub,
          mainChartsArea: _buildBaseSingleChart(
            spots: _currentHarmonicSpots, color: green,
            borderBg: borderBg, textSub: textSub,
            minX: 0, maxX: 300, minY: 0, maxY: 15,
            xUnit: 'Hz', yUnit: 'A', verticalMarkers: [50, 150, 250],
          ),
          sidePanel: _buildPeaksTable(
            borderBg: borderBg, textMain: textMain, textSub: textSub,
            rows: [
              _buildPeakRow('50.0',  '13.72', 'Fundamental Line Freq', textSub),
              _buildPeakRow('150.0', '1.85',  '3rd Order Harmonic',    textSub),
              _buildPeakRow('250.0', '0.65',  '5th Order Harmonic',    textSub),
            ],
          ),
        );

      default: // temperature
        return _buildDualLayout(
          title: _t('chart_thermal_title'), subtitle: _t('chart_thermal_sub'),
          cardBg: cardBg, borderBg: borderBg,
          textMain: textMain, textSub: textSub,
          mainChartsArea: _buildBaseSingleChart(
            spots: _thermalSimulationSpots, color: cyan,
            borderBg: borderBg, textSub: textSub,
            minX: _thermalSimulationSpots.isNotEmpty ? _thermalSimulationSpots.first.x : 0,
            maxX: _thermalSimulationSpots.isNotEmpty ? _thermalSimulationSpots.last.x : 10,
            minY: 50, maxY: 85, xUnit: 'sec', yUnit: '°C',
            verticalMarkers: [],
          ),
          sidePanel: _buildPeaksTable(
            borderBg: borderBg, textMain: textMain, textSub: textSub,
            rows: [
              _buildPeakRow('Live Casing',   '68.5 °C', 'Stable Equilibrium', textSub),
              _buildPeakRow('Ambient',        '24.2 °C', 'Reference Sensor',   textSub),
              _buildPeakRow('Thermal Delta', '+44.3 K',  'Safe Limit',          textSub),
            ],
          ),
        );
    }
  }

  Widget _buildDualLayout({required String title, required String subtitle, required Widget mainChartsArea, required Widget sidePanel, required Color cardBg, required Color borderBg, required Color textMain, required Color textSub}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderBg, width: 1.5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: textMain, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
          Text(subtitle, style: TextStyle(color: textSub, fontSize: 9)),
          const SizedBox(height: 14),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: mainChartsArea),
                const SizedBox(width: 14),
                Expanded(flex: 1, child: sidePanel),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFftSpectrumChart({
  required Color borderBg,
  required Color textSub,
  required List<FlSpot> fftSpots,
}) {
  if (fftSpots.isEmpty) {
    return const Center(child: Text('No FFT Spectrum Data', style: TextStyle(color: Colors.white24, fontSize: 10)));
  }

  return LineChart(
    LineChartData(
      clipData: const FlClipData.all(),
      minX: 0,
      maxX: 500, // النطاق الترددي الميكانيكي الفعلي حتى 500 هرتز كما في صورتكِ
      minY: 0,
      maxY: 100, // سعة القمم الاهتزازية (Amplitude)
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        getDrawingHorizontalLine: (value) => FlLine(color: borderBg.withOpacity(0.12), strokeWidth: 1),
        getDrawingVerticalLine: (value) => FlLine(color: borderBg.withOpacity(0.12), strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 22,
            interval: 100, // خط تدريج ومؤشر كل 100 هرتز (0, 100, 200, 300, 400, 500)
            getTitlesWidget: (value, meta) {
              return Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  '${value.toStringAsFixed(0)}Hz', // العرض بالهرتز (Hz)
                  style: TextStyle(color: textSub, fontSize: 8, fontWeight: FontWeight.bold),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            getTitlesWidget: (value, meta) => Text(
              value.toStringAsFixed(0),
              style: TextStyle(color: textSub, fontSize: 8),
            ),
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: true, border: Border.all(color: borderBg.withOpacity(0.3))),
      lineBarsData: [
        LineChartBarData(
          spots: fftSpots,
          isCurved: true, // منحنى انسيابي لإظهار تضاريس القمم الترددية (Vibration Peaks)
          color: const Color(0xFFFF9F1C), // لون برتقالي مميز للـ FFT يعطي طابعاً صناعياً
          barWidth: 1.5,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: true, color: const Color(0xFFFF9F1C).withOpacity(0.05)),
        ),
      ],
    ),
  );
}

// ════════════════════════════════════════════════════════════
  // 📊 المنطق المطور: تمدد الإشارة أولاً ثم الزحف التلقائي بعد 0.5 ثانية
  // ════════════════════════════════════════════════════════════
 Widget _buildTimeWaveformChart({
  required Color borderBg,
  required Color textSub,
  required List<FlSpot> spots,
}) {
  if (spots.isEmpty) {
    return const Center(child: Text('No Live Telemetry Data', style: TextStyle(color: Colors.white24, fontSize: 10)));
  }

  // تحديد عرض المحور الأفقي الثابت (مثلاً نافذة ثابتة ومريحة بطول 1.0 ثانية كاملة)
  double minX = spots.first.x;
  double maxX = spots.last.x;
  
  if (maxX - minX < 1.0) {
    maxX = minX + 1.0;
  }

  return LineChart(
    LineChartData(
      clipData: const FlClipData.all(),
      minX: minX,
      maxX: maxX,
      minY: -5.0,
      maxY: 5.0,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        getDrawingHorizontalLine: (value) => FlLine(color: borderBg.withOpacity(0.12), strokeWidth: 1),
        getDrawingVerticalLine: (value) => FlLine(color: borderBg.withOpacity(0.12), strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 22,
            interval: 0.2, // إظهار التدريج كل 0.2 ثانية بانتظام
            getTitlesWidget: (value, meta) {
              double relativeTime = value - minX;
              if (relativeTime < 0 || relativeTime > 1.01) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  '${relativeTime.toStringAsFixed(1)}s', // يعرض 0.0s, 0.2s, 0.4s...
                  style: TextStyle(color: textSub, fontSize: 8, fontWeight: FontWeight.bold, fontFamily: 'Courier'),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            getTitlesWidget: (value, meta) => Text(
              value.toStringAsFixed(1),
              style: TextStyle(color: textSub, fontSize: 8),
            ),
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: true, border: Border.all(color: borderBg.withOpacity(0.3))),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: false, // خطوط مستقيمة عادية وحادة لتبدو كإشارة اهتزاز حقيقية من مستشعر
          color: vibColor,
          barWidth: 1.5,
          dotData: const FlDotData(show: false),
        ),
      ],
    ),
  );
}

  Widget _buildBaseSingleChart({required List<FlSpot> spots, required Color color, required Color borderBg, required Color textSub, required double minX, required double maxX, required double minY, required double maxY, required String xUnit, required String yUnit, required List<double> verticalMarkers}) {
    return LineChart(LineChartData(
      clipData: const FlClipData.all(),
      minX: minX, maxX: maxX, minY: minY, maxY: maxY,
      gridData: FlGridData(show: true,
        getDrawingHorizontalLine: (v) => FlLine(color: borderBg.withOpacity(0.3)),
        getDrawingVerticalLine:   (v) => FlLine(color: borderBg.withOpacity(0.3))),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) => Text('${v.toInt()}$xUnit', style: TextStyle(color: textSub, fontSize: 8)))),
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (v, _) => Text('${v.toStringAsFixed(1)}$yUnit', style: TextStyle(color: textSub, fontSize: 8)))),
      ),
      borderData: FlBorderData(show: true, border: Border.all(color: borderBg, width: 1.5)),
      extraLinesData: ExtraLinesData(
        verticalLines: verticalMarkers.map((mX) => VerticalLine(x: mX, color: Colors.amber.withOpacity(0.7), strokeWidth: 1.2, dashArray: [3, 3], label: VerticalLineLabel(show: true, labelResolver: (_) => '${mX.toInt()}$xUnit'))).toList(),
      ),
      lineBarsData: [LineChartBarData(
        spots: spots,
        isCurved: _activeAnalysisTab == 'temperature',
        color: color, barWidth: 2,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: true, color: color.withOpacity(0.05)),
      )],
    ));
  }

  Widget _buildPeaksTable({required Color borderBg, required Color textMain, required Color textSub, required List<DataRow> rows}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: const Color(0xFF06142A).withOpacity(0.6), borderRadius: BorderRadius.circular(12), border: Border.all(color: borderBg, width: 1.5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.gavel_rounded, color: vibColor, size: 12),
            const SizedBox(width: 6),
            Text(_t('peaks_table_title'), style: TextStyle(color: textMain, fontSize: 8.5, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          ]),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: borderBg.withOpacity(0.3)),
                child: DataTable(
                  columnSpacing: 6,
                  horizontalMargin: 2,
                  headingRowHeight: 28,
                  dataRowMinHeight: 32,
                  dataRowMaxHeight: 40,
                  columns: [
                    DataColumn(label: Text(_t('col_freq'), style: TextStyle(color: textSub, fontSize: 8.5, fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(_t('col_amp'), style: TextStyle(color: textSub, fontSize: 8.5, fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(_t('col_diag'), style: TextStyle(color: textSub, fontSize: 8.5, fontWeight: FontWeight.bold))),
                  ],
                  rows: rows,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildPeakRow(String freq, String amp, String diagnosis, Color textSub) {
    return DataRow(cells: [
      DataCell(Text(freq, style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold, fontFamily: 'Courier'))),
      DataCell(Text(amp, style: TextStyle(color: vibColor, fontSize: 9.5, fontWeight: FontWeight.w900, fontFamily: 'Courier'))),
      DataCell(Text(diagnosis, style: TextStyle(color: textSub, fontSize: 8.5, fontStyle: FontStyle.italic))),
    ]);
  }
}