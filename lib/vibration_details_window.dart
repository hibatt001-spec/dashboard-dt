import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class VibrationDetailsWindow extends StatefulWidget {
  final double currentValue;
  final String title;
  final String currentLang;
  final VoidCallback? onClose; // 👈 جعلناها اختيارية بنضافة علامة الاستفهام ؟

  const VibrationDetailsWindow({
    super.key,
    required this.currentValue,
    required this.currentLang,
    required this.title,
    this.onClose, // 👈 إزالة كلمة required لتفادي المشاكل عند التنقل بين الصفحات
  });

  @override
  State<VibrationDetailsWindow> createState() => _VibrationDetailsWindowState();
}

class _VibrationDetailsWindowState extends State<VibrationDetailsWindow> {
  final Map<String, Map<String, String>> localizedTexts = {
    'ar': {
      'vibr_signal': 'إشارة الاهتزاز في الوقت الحقيقي (Time Domain)',
      'fft_analysis': 'تحليل تردد الإشارة (FFT Spectrum - Edge Impulse)',
      'rms_val': 'قيمة الـ RMS الحالية',
      'peak_val': 'أعلى ذروة (Peak)',
    },
    'fr': {
      'vibr_signal': 'Signal de Vibration (Time Domain)',
      'fft_analysis': 'Analyse Fréquentielle (FFT Spectrum - Edge Impulse)',
      'rms_val': 'Valeur RMS Actuelle',
      'peak_val': 'Valeur Pic (Peak)',
    },
    'en': {
      'vibr_signal': 'Vibration Signal (Time Domain)',
      'fft_analysis': 'Frequency Analysis (FFT Spectrum - Edge Impulse)',
      'rms_val': 'Current RMS Value',
      'peak_val': 'Peak Value',
    }
  };

  String _t(String key) {
    return localizedTexts[widget.currentLang]?[key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    bool isRtl = widget.currentLang == 'ar';

    // استخدام Scaffold هنا يضمن ظهور الصفحة بشكل صحيح ومريح عند استخدام Navigator.push
    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D1220),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D1220),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            widget.title,
            style: const TextStyle(
              color: Color(0xFFE0F7FA),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: widget.onClose != null 
              ? [IconButton(icon: const Icon(Icons.close), onPressed: widget.onClose)]
              : null,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildMiniStatCard(
                        title: _t('rms_val'),
                        value: '${widget.currentValue.toStringAsFixed(2)} mm/s',
                        color: const Color(0xFF7C4DFF),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMiniStatCard(
                        title: _t('peak_val'),
                        value: '${(widget.currentValue * 1.414).toStringAsFixed(2)} mm/s',
                        color: const Color(0xFFFF6D00),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _t('vibr_signal'),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildChartWrapper(_buildTimeDomainChart()),

                        const SizedBox(height: 24),

                        Text(
                          _t('fft_analysis'),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildChartWrapper(_buildFFTChart()),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStatCard({required String title, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF141B30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildChartWrapper(Widget chart) {
    return Container(
      height: 180,
      width: double.infinity,
      padding: const EdgeInsets.only(right: 20, left: 5, top: 15, bottom: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E2A45), width: 1),
      ),
      child: chart,
    );
  }

  Widget _buildTimeDomainChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => const FlLine(color: Color(0xFF1E2A45), strokeWidth: 0.6),
        ),
        titlesData: const FlTitlesData(
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: _leftTitleWidgets,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              const FlSpot(0, 1.5),
              const FlSpot(1, 2.8),
              const FlSpot(2, 1.2),
              FlSpot(3, widget.currentValue),
              const FlSpot(4, 3.5),
              const FlSpot(5, 2.0),
              const FlSpot(6, 4.2),
            ],
            isCurved: true,
            color: const Color(0xFF7C4DFF),
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: const Color(0xFF7C4DFF).withOpacity(0.05)),
          ),
        ],
      ),
    );
  }

  Widget _buildFFTChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => const FlLine(color: Color(0xFF1E2A45), strokeWidth: 0.6),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 18,
              getTitlesWidget: (value, meta) {
                if (value % 20 == 0 && value > 0) {
                  return Text('${value.toInt()}Hz', style: const TextStyle(color: Colors.white30, fontSize: 8));
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: _leftTitleWidgets,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              const FlSpot(10, 0.4),
              const FlSpot(20, 0.2),
              const FlSpot(35, 1.1),
              const FlSpot(50, 4.5),
              const FlSpot(65, 0.3),
              const FlSpot(80, 2.1),
              const FlSpot(100, 0.5),
            ],
            isCurved: false,
            color: const Color(0xFF00E5FF),
            barWidth: 2,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: true, color: const Color(0xFF00E5FF).withOpacity(0.05)),
          ),
        ],
      ),
    );
  }

  static Widget _leftTitleWidgets(double value, TitleMeta meta) {
    return Text(
      value.toStringAsFixed(1),
      style: const TextStyle(color: Colors.white30, fontSize: 8),
      textAlign: TextAlign.center,
    );
  }
}