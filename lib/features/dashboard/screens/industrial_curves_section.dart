import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'app_translations.dart'; // 🌐 استيراد ملف الترجمة المركزي الموحد

class IndustrialCurvesSection extends StatefulWidget {
  final String currentMode; // يربط المنحنيات مع أزرار التحكم في الأعطال
  final String currentLang; // 🌐 استقبال اللغة الحالية ('en' أو 'fr' أو 'ar')

  const IndustrialCurvesSection({
    super.key, 
    required this.currentMode,
    required this.currentLang,
  });

  @override
  State<IndustrialCurvesSection> createState() =>
      _IndustrialCurvesSectionState();
}

class _IndustrialCurvesSectionState extends State<IndustrialCurvesSection> {
  String _activeTab = 'vibration';
  Timer? _analysisTimer;
  double _time = 0;
  final math.Random _random = math.Random();

  final List<FlSpot> _fftVibrationSpots = [];
  final List<FlSpot> _timeWaveformSpots = [];
  final List<FlSpot> _currentHarmonicSpots = [];
  final List<FlSpot> _thermalSimulationSpots = [];

  final Color bgDark = const Color(0xFF0B1020);
  final Color cardBg = const Color(0xFF182338);
  final Color borderBg = const Color(0xFF2A3A5A);
  final Color textMain = const Color(0xFFF5F7FA);
  final Color textSub = const Color(0xFFAAB6C5);

  final Color vibColor = const Color(0xFFFF9800);
  final Color cyan = const Color(0xFF00C2FF);
  final Color green = const Color(0xFF00E676);

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

  double _bearingPeak(double f) {
    double faultMultiplier =
        (widget.currentMode == 'high_vibration' ||
                widget.currentMode == 'bearing_damage')
            ? 4.5
            : 1.0;
    return (1.85 * faultMultiplier) / (1 + math.pow((f - 45.0), 2) * 0.8);
  }

  double _harmonics(double f) =>
      0.6 / (1 + math.pow((f - 90.0), 2) * 2) +
      0.25 / (1 + math.pow((f - 135.0), 2) * 3);

  void _initializeHighResData() {
    for (int i = 0; i < 512; i++) {
      double freq = i * 0.5;
      double noiseFloor = 0.02 + _random.nextDouble() * 0.015;
      double amp = noiseFloor + _bearingPeak(freq) + _harmonics(freq);
      _fftVibrationSpots.add(FlSpot(freq, amp));
    }

    for (int i = 0; i < 200; i++) {
      double t = i * 0.002;
      double wave =
          0.4 * math.sin(2 * math.pi * 45 * t) +
          0.15 * math.sin(2 * math.pi * 90 * t) +
          (_random.nextDouble() - 0.5) * 0.1;
      _timeWaveformSpots.add(FlSpot(t, wave));
    }

    for (int i = 0; i < 256; i++) {
      double freq = i * 1.0;
      double currentAmp = (freq == 50)
          ? 13.7
          : ((freq == 100)
              ? 0.45
              : ((freq == 150)
                  ? 1.85
                  : ((freq == 250)
                      ? 0.65
                      : (_random.nextDouble() * 0.04))));
      _currentHarmonicSpots.add(FlSpot(freq, currentAmp));
    }

    for (int i = 0; i < 60; i++) {
      _thermalSimulationSpots.add(
        FlSpot(i * 0.5, 62.0 + (i * 0.1) + _random.nextDouble() * 0.1),
      );
    }
  }

  void _startLiveAnalysisSimulation() {
    _analysisTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!mounted) return;
      setState(() {
        _time += 0.2;

        for (int i = 0; i < _fftVibrationSpots.length; i++) {
          double f = _fftVibrationSpots[i].x;
          double noiseFloor = 0.02 + _random.nextDouble() * 0.015;
          double dynamicMod = 1.0 + (math.sin(_time + f) * 0.03);
          double amp =
              noiseFloor + (_bearingPeak(f) + _harmonics(f)) * dynamicMod;
          _fftVibrationSpots[i] = FlSpot(f, amp);
        }

        for (int i = 0; i < _timeWaveformSpots.length; i++) {
          double t = _timeWaveformSpots[i].x;
          double waveMultiplier = (widget.currentMode == 'high_vibration') ? 2.8 : 1.0;
          double wave =
              waveMultiplier *
                  (0.4 * math.sin(2 * math.pi * 45 * (t + _time * 0.01)) +
                      0.15 * math.sin(2 * math.pi * 90 * (t + _time * 0.01))) +
              (_random.nextDouble() - 0.5) * 0.08;
          _timeWaveformSpots[i] = FlSpot(t, wave);
        }

        for (int i = 0; i < _currentHarmonicSpots.length; i++) {
          double f = _currentHarmonicSpots[i].x;
          double loadFactor = (widget.currentMode == 'overload') ? 1.4 : 1.0;
          if (f == 50) {
            _currentHarmonicSpots[i] = FlSpot(
              f,
              (13.7 * loadFactor) + math.sin(_time) * 0.15,
            );
          } else if (f == 150) {
            _currentHarmonicSpots[i] = FlSpot(
              f,
              (1.85 * loadFactor) + math.cos(_time * 2) * 0.08,
            );
          }
        }

        _thermalSimulationSpots.removeAt(0);
        double nextX = _thermalSimulationSpots.last.x + 0.5;
        double baseTemp = (widget.currentMode == 'cooling_failure') ? 82.5 : 65.0;
        double nextTemp =
            baseTemp +
            math.sin(nextX * 0.05) * 0.4 +
            _random.nextDouble() * 0.05;
        _thermalSimulationSpots.add(FlSpot(nextX, nextTemp));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // تحديد الاتجاه العام بناءً على اللغة المحددة
    final bool isRtl = widget.currentLang == 'ar';

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        color: bgDark,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopTabsNavigator(),
            const SizedBox(height: 14),
            Expanded(child: _buildSelectedAnalysisView()),
          ],
        ),
      ),
    );
  }

  Widget _buildTopTabsNavigator() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderBg, width: 1.2),
      ),
      child: Row(
        children: [
          _buildTabButton(
            id: 'vibration',
            label: widget.currentLang == 'ar' ? 'الاهتزاز (FFT)' : (widget.currentLang == 'fr' ? 'VIBRATION (FFT)' : 'VIBRATION (FFT)'),
            icon: Icons.analytics_rounded,
            activeColor: vibColor,
          ),
          const SizedBox(width: 6),
          _buildTabButton(
            id: 'current',
            label: widget.currentLang == 'ar' ? 'التيار (MCSA)' : (widget.currentLang == 'fr' ? 'COURANT (MCSA)' : 'CURRENT (MCSA)'),
            icon: Icons.electrical_services,
            activeColor: green,
          ),
          const SizedBox(width: 6),
          _buildTabButton(
            id: 'temperature',
            label: widget.currentLang == 'ar' ? 'السجل الحراري' : (widget.currentLang == 'fr' ? 'LOG THERMIQUE' : 'THERMAL LOG'),
            icon: Icons.thermostat_auto_rounded,
            activeColor: cyan,
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String id,
    required String label,
    required IconData icon,
    required Color activeColor,
  }) {
    bool isSelected = _activeTab == id;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeTab = id),
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? activeColor : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? activeColor : textSub, size: 14),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? textMain : textSub,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedAnalysisView() {
    // دالة اختصار لجلب التراجم من الملف المركزي الموحد
    String t(String key) => AppTranslations.t(key, widget.currentLang);

    if (_activeTab == 'vibration') {
      return _buildDualLayout(
        title: widget.currentLang == 'ar' ? 'محلل الاهتزازات - طيف FFT عالي الدقة' : 'VIBRATION ANALYSER - HIGH RESOLUTION FFT SPECTRUM',
        subtitle: widget.currentLang == 'ar' ? 'تشخيص متزامن لطيف التردد والموجة الزمنية.' : 'Simultaneous Spectrum and Time Waveform diagnostics.',
        mainChartsArea: Column(
          children: [
            Expanded(flex: 6, child: _buildFFTChart()),
            const SizedBox(height: 10),
            Expanded(flex: 4, child: _buildTimeWaveformChart()),
          ],
        ),
        sidePanel: _buildPeaksTable([
          _buildPeakRow(
            '45.0',
            (widget.currentMode == 'high_vibration' || widget.currentMode == 'bearing_damage') ? '8.32' : '1.92',
            'BPF (Bearing Pass Freq)',
          ),
          _buildPeakRow('90.0', '0.62', widget.currentLang == 'ar' ? 'التوافقية الثانية لـ BPF' : '2× BPF Harmonic'),
          _buildPeakRow('135.0', '0.26', widget.currentLang == 'ar' ? 'التوافقية الثالثة لـ BPF' : '3× BPF Harmonic'),
        ]),
      );
    } else if (_activeTab == 'current') {
      return _buildDualLayout(
        title: widget.currentLang == 'ar' ? 'تحليل بصمة تيار المحرك (MCSA)' : 'MOTOR CURRENT SIGNATURE ANALYSIS (MCSA)',
        subtitle: widget.currentLang == 'ar' ? 'التقاط النطاقات الجانبية التوافقية لتشخيص حالة قضبان الدوار.' : 'Harmonic sidebands capture to diagnose rotor bars status.',
        mainChartsArea: _buildBaseSingleChart(
          _currentHarmonicSpots,
          green,
          0,
          300,
          0,
          22,
          'Hz',
          'A',
          [50, 150, 250],
        ),
        sidePanel: _buildPeaksTable([
          _buildPeakRow(
            '50.0',
            (widget.currentMode == 'overload') ? '19.20' : '13.72',
            widget.currentLang == 'ar' ? 'تردد الخط الأساسي' : 'Fundamental Line Freq',
          ),
          _buildPeakRow('150.0', '1.85', widget.currentLang == 'ar' ? 'التوافقية الدرجة الثالثة' : '3rd Order Harmonic'),
          _buildPeakRow('250.0', '0.65', widget.currentLang == 'ar' ? 'التوافقية الدرجة الخامسة' : '5th Order Harmonic'),
        ]),
      );
    } else {
      double liveTemp = (widget.currentMode == 'cooling_failure') ? 83.4 : 68.5;
      return _buildDualLayout(
        title: widget.currentLang == 'ar' ? 'النموذج الحراري التنبئي ومعدل الارتفاع' : 'PREDICTIVE THERMAL MODEL & RISE RATE',
        subtitle: widget.currentLang == 'ar' ? 'سجل ديناميكي لتغير درجة الحرارة تحت الحمل الميكانيكي.' : 'Dynamic temperature variance log under mechanical load.',
        mainChartsArea: _buildBaseSingleChart(
          _thermalSimulationSpots,
          cyan,
          _thermalSimulationSpots.first.x,
          _thermalSimulationSpots.last.x,
          40,
          95,
          's',
          '°C',
          [],
        ),
        sidePanel: _buildPeaksTable([
          _buildPeakRow(
            widget.currentLang == 'ar' ? 'القلب الحي' : 'Live Core',
            '$liveTemp °C',
            (widget.currentMode == 'cooling_failure')
                ? (widget.currentLang == 'ar' ? 'ارتفاع حرج' : 'CRITICAL HIGH')
                : (widget.currentLang == 'ar' ? 'توازن مستقر' : 'Stable Equilibrium'),
          ),
          _buildPeakRow(widget.currentLang == 'ar' ? 'المحيط' : 'Ambient', '24.2 °C', widget.currentLang == 'ar' ? 'المستشعر المرجعي' : 'Reference Sensor'),
        ]),
      );
    }
  }

  Widget _buildDualLayout({
    required String title,
    required String subtitle,
    required Widget mainChartsArea,
    required Widget sidePanel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: textMain,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(color: textSub.withOpacity(0.6), fontSize: 9),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 7, child: mainChartsArea),
              const SizedBox(width: 12),
              Expanded(flex: 3, child: sidePanel),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFFTChart() {
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: 160,
        minY: 0,
        maxY: (widget.currentMode == 'high_vibration' || widget.currentMode == 'bearing_damage') ? 9.0 : 2.5,
        gridData: FlGridData(
          show: true,
          getDrawingHorizontalLine: (v) => FlLine(color: borderBg.withOpacity(0.2)),
          getDrawingVerticalLine: (v) => FlLine(color: borderBg.withOpacity(0.2)),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) => Text(
                '${v.toInt()}Hz',
                style: TextStyle(color: textSub, fontSize: 8),
              ),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 35,
              getTitlesWidget: (v, _) => Text(
                v.toStringAsFixed(1),
                style: TextStyle(color: textSub, fontSize: 8),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: borderBg, width: 1.0),
        ),
        lineBarsData: [
          LineChartBarData(
            isCurved: false,
            color: vibColor,
            barWidth: 1.2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: vibColor.withOpacity(0.05),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeWaveformChart() {
    return LineChart(
      LineChartData(
        minX: _timeWaveformSpots.first.x,
        maxX: _timeWaveformSpots.last.x,
        minY: (widget.currentMode == 'high_vibration') ? -2.0 : -0.7,
        maxY: (widget.currentMode == 'high_vibration') ? 2.0 : 0.7,
        gridData: FlGridData(
          show: true,
          getDrawingHorizontalLine: (v) => FlLine(color: borderBg.withOpacity(0.15)),
          getDrawingVerticalLine: (v) => FlLine(color: borderBg.withOpacity(0.15)),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) => Text(
                '${(v * 1000).toInt()}ms',
                style: TextStyle(color: textSub, fontSize: 8),
              ),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 35,
              getTitlesWidget: (v, _) => Text(
                '${v.toStringAsFixed(1)}g',
                style: TextStyle(color: textSub, fontSize: 8),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: borderBg, width: 1.0),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: _timeWaveformSpots,
            isCurved: true,
            color: cyan.withOpacity(0.8),
            barWidth: 1.0,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _buildBaseSingleChart(
    List<FlSpot> spots,
    Color color,
    double minX,
    double maxX,
    double minY,
    double maxY,
    String xUnit,
    String yUnit,
    List<double> verticalMarkers,
  ) {
    return LineChart(
      LineChartData(
        minX: minX,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          getDrawingHorizontalLine: (v) => FlLine(color: borderBg.withOpacity(0.2)),
          getDrawingVerticalLine: (v) => FlLine(color: borderBg.withOpacity(0.2)),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) => Text(
                '${v.toInt()}$xUnit',
                style: TextStyle(color: textSub, fontSize: 8),
              ),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 35,
              getTitlesWidget: (v, _) => Text(
                '${v.toStringAsFixed(0)}$yUnit',
                style: TextStyle(color: textSub, fontSize: 8),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: borderBg, width: 1.0),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: _activeTab == 'temperature',
            color: color,
            barWidth: 1.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withOpacity(0.04),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeaksTable(List<DataRow> rows) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bgDark.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderBg, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.currentLang == 'ar' ? 'رصد القمم الترددية' : 'PEAK DETECTION',
            style: TextStyle(
              color: textMain,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: SingleChildScrollView(
              child: DataTable(
                columnSpacing: 6,
                horizontalMargin: 2,
                headingRowHeight: 24,
                dataRowMinHeight: 28,
                dataRowMaxHeight: 34,
                columns: [
                  DataColumn(
                    label: Text(
                      widget.currentLang == 'ar' ? 'هرتز' : 'Hz',
                      style: TextStyle(color: textSub, fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      widget.currentLang == 'ar' ? 'السعة' : 'Amp',
                      style: TextStyle(color: textSub, fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      widget.currentLang == 'ar' ? 'التشخيص' : 'Diagnosis',
                      style: TextStyle(color: textSub, fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                rows: rows,
              ),
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildPeakRow(String freq, String amp, String diagnosis) {
    return DataRow(
      cells: [
        DataCell(
          Text(
            freq,
            style: const TextStyle(color: Colors.white, fontSize: 9, fontFamily: 'Courier'),
          ),
        ),
        DataCell(
          Text(
            amp,
            style: TextStyle(color: vibColor, fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'Courier'),
          ),
        ),
        DataCell(
          Text(
            diagnosis,
            style: TextStyle(color: textSub, fontSize: 8, fontStyle: FontStyle.italic),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}