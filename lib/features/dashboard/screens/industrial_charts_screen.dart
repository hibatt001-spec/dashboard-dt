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

// ═══════════════════════════════════════════════════════════════
//  IndustrialChartsScreen — ترجمة كاملة + ليل/نهار
// ═══════════════════════════════════════════════════════════════
class IndustrialChartsScreen extends StatefulWidget {
  // ✅ حذفنا isDarkMode — يُقرأ من themeNotifier مباشرة
  const IndustrialChartsScreen({super.key, required isDarkMode});

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

  final List<FlSpot> _fftVibrationSpots     = [];
  final List<FlSpot> _timeWaveformSpots      = [];
  final List<FlSpot> _currentHarmonicSpots   = [];
  final List<FlSpot> _thermalSimulationSpots = [];

  // ألوان المخططات — ثابتة مستقلة عن الـ theme
  final Color vibColor  = const Color(0xFFFF9800);
  final Color cyan      = const Color(0xFF00C2FF);
  final Color green     = const Color(0xFF00E676);
  final Color dangerRed = const Color(0xFFFF5252);

  // ── helper ترجمة ────────────────────────────────────────────
  String _t(String key) => AppTranslations.t(key, languageNotifier.value);

  // ── معادلات الطيف ────────────────────────────────────────────
  double _bearingPeak(double f) =>
      1.85 / (1 + math.pow((f - 45.0), 2) * 0.8);
  double _harmonics(double f) =>
      0.6  / (1 + math.pow((f - 90.0),  2) * 2) +
      0.25 / (1 + math.pow((f - 135.0), 2) * 3);

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
  //  تهيئة البيانات
  // ════════════════════════════════════════════════════════════
  void _initializeHighResData() {
    for (int i = 0; i < 512; i++) {
      double freq = i * 0.5;
      double noiseFloor = 0.02 + _random.nextDouble() * 0.015;
      _fftVibrationSpots.add(
          FlSpot(freq, noiseFloor + _bearingPeak(freq) + _harmonics(freq)));
    }
    for (int i = 0; i < 200; i++) {
      double t = i * 0.002;
      double wave = 0.4  * math.sin(2 * math.pi * 45 * t) +
                    0.15 * math.sin(2 * math.pi * 90 * t) +
                    (_random.nextDouble() - 0.5) * 0.1;
      _timeWaveformSpots.add(FlSpot(t, wave));
    }
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
  //  محاكاة حية
  // ════════════════════════════════════════════════════════════
  void _startLiveAnalysisSimulation() {
    _analysisTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!mounted) return;
      setState(() {
        _time += 0.2;
        for (int i = 0; i < _fftVibrationSpots.length; i++) {
          double f = _fftVibrationSpots[i].x;
          double mod = 1.0 + math.sin(_time + f) * 0.03;
          _fftVibrationSpots[i] = FlSpot(
              f, 0.02 + _random.nextDouble() * 0.015 +
                 (_bearingPeak(f) + _harmonics(f)) * mod);
        }
        for (int i = 0; i < _timeWaveformSpots.length; i++) {
          double t = _timeWaveformSpots[i].x;
          _timeWaveformSpots[i] = FlSpot(t,
              0.4  * math.sin(2 * math.pi * 45 * (t + _time * 0.01)) +
              0.15 * math.sin(2 * math.pi * 90 * (t + _time * 0.01)) +
              (_random.nextDouble() - 0.5) * 0.08);
        }
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

  // ════════════════════════════════════════════════════════════
  //  BUILD — مرتبط بـ languageNotifier + themeNotifier
  // ════════════════════════════════════════════════════════════
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

            // ── ألوان الـ Theme ──────────────────────────────
            final Color bgMain   = isDark ? const Color(0xFF06142A) : const Color(0xFFF4F7FB);
            final Color cardBg   = isDark ? const Color(0xFF10203C) : Colors.white;
            final Color borderBg = isDark ? const Color(0xFF283B5A) : const Color(0xFFCBD5E1);
            final Color textMain = isDark ? const Color(0xFFF4F7FA) : const Color(0xFF1E293B);
            final Color textSub  = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

            return Directionality(
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              child: Scaffold(
                backgroundColor: bgMain,

                // ── AppBar ───────────────────────────────────
                appBar: AppBar(
                  backgroundColor: cardBg,
                  elevation: 0,
                  title: Text(
                    _t('appbar_title'),
                    style: TextStyle(
                      color: textMain,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Icon(
                        Icons.lens,
                        color: _currentSimulationMode == 'normal'
                            ? green : dangerRed,
                        size: 11,
                      ),
                    ),
                  ],
                ),

                // ── Body ─────────────────────────────────────
                body: SafeArea(
                  child: IndexedStack(
                    index: _currentTabIndex,
                    children: [
                      _buildDigitalTwinTab(textMain, textSub, cyan, cardBg, borderBg),
                      _buildAnalyticsLab(cardBg, borderBg, textMain, textSub),
                    ],
                  ),
                ),

                // ── Bottom Nav ───────────────────────────────
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
                    selectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.6),
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

  // ════════════════════════════════════════════════════════════
  //  TAB 1 — Digital Twin
  // ════════════════════════════════════════════════════════════
  Widget _buildDigitalTwinTab(
    Color textMain, Color textSub, Color accentIcon,
    Color cardBg, Color borderBg,
  ) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_t('controls_panel'),
                style: TextStyle(color: textMain, fontSize: 11,
                    fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            const SizedBox(height: 6),
            IndustrialSimulationPanel(
              currentMode: _currentSimulationMode,
              onModeChanged: (mode) => setState(() {
                _currentSimulationMode = mode;
                currentSimulationModeNotifier.value = mode;
              }),
            ),
            const SizedBox(height: 14),
            Text(_t('twin_3d_title'),
                style: TextStyle(color: textMain, fontSize: 11,
                    fontWeight: FontWeight.bold, letterSpacing: 0.5)),
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
              Text(_t('telemetry_grid'),
                  style: TextStyle(color: textSub, fontSize: 10,
                      fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            ]),
            ValueListenableBuilder<String>(
              valueListenable: languageNotifier,
              builder: (context, lang, _) =>
                ValueListenableBuilder<ThemeMode>(
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

  // ════════════════════════════════════════════════════════════
  //  TAB 2 — Analytics Lab
  // ════════════════════════════════════════════════════════════
  Widget _buildAnalyticsLab(
    Color cardBg, Color borderBg, Color textMain, Color textSub,
  ) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _buildTopTabsNavigator(cardBg, borderBg, textMain, textSub),
          const SizedBox(height: 12),
          Expanded(child: _buildSelectedAnalysisView(
              cardBg, borderBg, textMain, textSub)),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  Top Tabs Navigator
  // ════════════════════════════════════════════════════════════
  Widget _buildTopTabsNavigator(
    Color cardBg, Color borderBg, Color textMain, Color textSub,
  ) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderBg, width: 1.5),
      ),
      child: Row(children: [
        _buildTabButton(id: 'vibration',   label: _t('tab_vibration'),
            icon: Icons.analytics_rounded,        activeColor: vibColor,
            textMain: textMain, textSub: textSub),
        const SizedBox(width: 6),
        _buildTabButton(id: 'current',     label: _t('tab_current'),
            icon: Icons.electrical_services,      activeColor: green,
            textMain: textMain, textSub: textSub),
        const SizedBox(width: 6),
        _buildTabButton(id: 'temperature', label: _t('tab_thermal'),
            icon: Icons.thermostat_auto_rounded,  activeColor: cyan,
            textMain: textMain, textSub: textSub),
      ]),
    );
  }

  Widget _buildTabButton({
    required String id, required String label, required IconData icon,
    required Color activeColor, required Color textMain, required Color textSub,
  }) {
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
            border: Border.all(
                color: sel ? activeColor : Colors.transparent, width: 1.5),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: sel ? activeColor : textSub, size: 16),
            const SizedBox(width: 6),
            Flexible(child: Text(label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: sel ? textMain : textSub,
                    fontSize: 10, fontWeight: FontWeight.w900,
                    letterSpacing: 0.5))),
          ]),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  Analysis Views Router
  // ════════════════════════════════════════════════════════════
  Widget _buildSelectedAnalysisView(
    Color cardBg, Color borderBg, Color textMain, Color textSub,
  ) {
    switch (_activeAnalysisTab) {

      case 'vibration':
        return _buildDualLayout(
          title: _t('chart_fft_title'), subtitle: _t('chart_fft_sub'),
          cardBg: cardBg, borderBg: borderBg,
          textMain: textMain, textSub: textSub,
          mainChartsArea: Column(children: [
            Expanded(flex: 6,
                child: _buildFFTChart(borderBg: borderBg, textSub: textSub)),
            const SizedBox(height: 12),
            Expanded(flex: 4,
                child: _buildTimeWaveformChart(borderBg: borderBg, textSub: textSub)),
          ]),
          sidePanel: _buildPeaksTable(
            borderBg: borderBg, textMain: textMain, textSub: textSub,
            rows: [
              _buildPeakRow('45.0',  '1.92', 'BPF (Bearing Pass Freq)', textSub),
              _buildPeakRow('90.0',  '0.62', '2× BPF Harmonic',         textSub),
              _buildPeakRow('135.0', '0.26', '3× BPF Harmonic',         textSub),
              _buildPeakRow('11.2',  '0.04', 'Structural Noise Floor',   textSub),
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
            minX: _thermalSimulationSpots.first.x,
            maxX: _thermalSimulationSpots.last.x,
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

  // ════════════════════════════════════════════════════════════
  //  Dual Layout
  // ════════════════════════════════════════════════════════════
  Widget _buildDualLayout({
    required String title,
    required String subtitle,
    required Widget mainChartsArea,
    required Widget sidePanel,
    required Color cardBg,
    required Color borderBg,
    required Color textMain,
    required Color textSub,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderBg, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: textMain, fontSize: 11,
              fontWeight: FontWeight.w900, letterSpacing: 1.0)),
          Text(subtitle, style: TextStyle(color: textSub, fontSize: 9)),
          const SizedBox(height: 14),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 6, child: mainChartsArea),
                const SizedBox(width: 14),
                Expanded(flex: 4, child: sidePanel),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  Charts
  // ════════════════════════════════════════════════════════════
  Widget _buildFFTChart({required Color borderBg, required Color textSub}) {
    return LineChart(LineChartData(
      minX: 0, maxX: 160, minY: 0, maxY: 2.3,
      gridData: FlGridData(show: true, drawVerticalLine: true,
        getDrawingHorizontalLine: (v) => FlLine(color: borderBg.withOpacity(0.3)),
        getDrawingVerticalLine:   (v) => FlLine(color: borderBg.withOpacity(0.3))),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
            getTitlesWidget: (v, _) => Text('${v.toInt()}Hz',
                style: TextStyle(color: textSub, fontSize: 8)))),
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (v, _) => Text('${v.toStringAsFixed(1)}mm/s',
                style: TextStyle(color: textSub, fontSize: 8)))),
      ),
      borderData: FlBorderData(show: true,
          border: Border.all(color: borderBg, width: 1.5)),
      extraLinesData: ExtraLinesData(verticalLines: [
        VerticalLine(x: 45, color: Colors.orangeAccent,
            strokeWidth: 1.5, dashArray: [4, 4],
            label: VerticalLineLabel(show: true,
                alignment: Alignment.topRight,
                labelResolver: (_) => '45Hz [BPF]')),
        VerticalLine(x: 90, color: Colors.amber,
            strokeWidth: 1.2, dashArray: [4, 4],
            label: VerticalLineLabel(show: true,
                alignment: Alignment.topRight,
                labelResolver: (_) => '90Hz [2×BPF]')),
      ]),
      lineBarsData: [LineChartBarData(
        spots: _fftVibrationSpots, isCurved: false,
        color: vibColor, barWidth: 1.5,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: true, color: vibColor.withOpacity(0.08)),
      )],
    ));
  }

  Widget _buildTimeWaveformChart({required Color borderBg, required Color textSub}) {
    return LineChart(LineChartData(
      minX: _timeWaveformSpots.first.x, maxX: _timeWaveformSpots.last.x,
      minY: -0.7, maxY: 0.7,
      gridData: FlGridData(show: true,
        getDrawingHorizontalLine: (v) => FlLine(color: borderBg.withOpacity(0.2)),
        getDrawingVerticalLine:   (v) => FlLine(color: borderBg.withOpacity(0.2))),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
            getTitlesWidget: (v, _) => Text('${(v * 1000).toInt()}ms',
                style: TextStyle(color: textSub, fontSize: 8)))),
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (v, _) => Text('${v.toStringAsFixed(2)}g',
                style: TextStyle(color: textSub, fontSize: 8)))),
      ),
      borderData: FlBorderData(show: true,
          border: Border.all(color: borderBg, width: 1.5)),
      lineBarsData: [LineChartBarData(
        spots: _timeWaveformSpots, isCurved: true,
        color: cyan.withOpacity(0.8), barWidth: 1.2,
        dotData: const FlDotData(show: false),
      )],
    ));
  }

  Widget _buildBaseSingleChart({
    required List<FlSpot> spots,
    required Color color,
    required Color borderBg,
    required Color textSub,
    required double minX, required double maxX,
    required double minY, required double maxY,
    required String xUnit, required String yUnit,
    required List<double> verticalMarkers,
  }) {
    return LineChart(LineChartData(
      minX: minX, maxX: maxX, minY: minY, maxY: maxY,
      gridData: FlGridData(show: true,
        getDrawingHorizontalLine: (v) => FlLine(color: borderBg.withOpacity(0.3)),
        getDrawingVerticalLine:   (v) => FlLine(color: borderBg.withOpacity(0.3))),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
            getTitlesWidget: (v, _) => Text('${v.toInt()}$xUnit',
                style: TextStyle(color: textSub, fontSize: 8)))),
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (v, _) => Text('${v.toStringAsFixed(1)}$yUnit',
                style: TextStyle(color: textSub, fontSize: 8)))),
      ),
      borderData: FlBorderData(show: true,
          border: Border.all(color: borderBg, width: 1.5)),
      extraLinesData: ExtraLinesData(
        verticalLines: verticalMarkers.map((mX) => VerticalLine(
          x: mX, color: Colors.amber.withOpacity(0.7),
          strokeWidth: 1.2, dashArray: [3, 3],
          label: VerticalLineLabel(show: true,
              labelResolver: (_) => '${mX.toInt()}$xUnit'),
        )).toList(),
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

  // ════════════════════════════════════════════════════════════
  //  Peaks Table
  // ════════════════════════════════════════════════════════════
  Widget _buildPeaksTable({
    required Color borderBg,
    required Color textMain,
    required Color textSub,
    required List<DataRow> rows,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF06142A).withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderBg, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.gavel_rounded, color: vibColor, size: 12),
            const SizedBox(width: 6),
            Text(_t('peaks_table_title'),
                style: TextStyle(color: textMain, fontSize: 10,
                    fontWeight: FontWeight.w900, letterSpacing: 0.8)),
          ]),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: borderBg.withOpacity(0.3)),
                child: DataTable(
                  columnSpacing: 8,
                  horizontalMargin: 2,
                  headingRowHeight: 28,
                  dataRowMinHeight: 32,
                  dataRowMaxHeight: 40,
                  columns: [
                    DataColumn(label: Text(_t('col_freq'),
                        style: TextStyle(color: textSub, fontSize: 9,
                            fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(_t('col_amp'),
                        style: TextStyle(color: textSub, fontSize: 9,
                            fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(_t('col_diag'),
                        style: TextStyle(color: textSub, fontSize: 9,
                            fontWeight: FontWeight.bold))),
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

  DataRow _buildPeakRow(
      String freq, String amp, String diagnosis, Color textSub) {
    return DataRow(cells: [
      DataCell(Text(freq, style: const TextStyle(color: Colors.white,
          fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'Courier'))),
      DataCell(Text(amp, style: TextStyle(color: vibColor,
          fontSize: 10, fontWeight: FontWeight.w900, fontFamily: 'Courier'))),
      DataCell(Text(diagnosis, style: TextStyle(color: textSub,
          fontSize: 9, fontStyle: FontStyle.italic))),
    ]);
  }
}