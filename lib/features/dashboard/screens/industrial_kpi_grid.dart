import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'app_translations.dart'; // 🌐 استيراد ملف الترجمة المركزي الموحد

class IndustrialKpiGrid extends StatelessWidget {
  final String currentMode; // يربط القيم ديناميكياً مع أزرار الأعطال والمحاكاة
  final double healthIndex;
  final double estimatedDowntime;
  final int totalAlerts;
  final String currentLang; // 🌐 استقبال اللغة الحالية ('en' أو 'fr' أو 'ar')
  final bool isDarkMode; // 🌙 استقبال وضع المظهر (داكن أو فاتح)

  const IndustrialKpiGrid({
    super.key,
    required this.currentMode,
    required this.healthIndex,
    required this.estimatedDowntime,
    required this.totalAlerts,
    required this.currentLang,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    // 🎨 تخصيص الألوان ديناميكياً بناءً على الـ Mode Night/Day
    final Color cardBg = isDarkMode ? const Color(0xFF182338) : Colors.white;
    final Color borderBg = isDarkMode
        ? const Color(0xFF2A3A5A)
        : Colors.grey.shade300;
    final Color textMain = isDarkMode
        ? const Color(0xFFF5F7FA)
        : Colors.black87;
    final Color textSub = isDarkMode
        ? const Color(0xFFAAB6C5)
        : Colors.blueGrey.shade600;

    // ⚙️ الحسابات الديناميكية للمؤشرات بناءً على وضع المحرك (currentMode)
    double oee = 88.4;
    double mtbf = 142.0;
    double mttr = 1.8;
    double efficiency = 91.2;
    double availability = 96.5;
    double cost = 420.0;

    Color oeeColor = const Color(0xFF00E676); // أخضر مريغل

    if (currentMode == 'emergency_stop') {
      oee = 0.0;
      efficiency = 0.0;
      availability = 0.0;
      cost += 350;
      oeeColor = const Color(0xFFFF1744); // أحمر طوارئ
    } else if (currentMode == 'overload') {
      oee = 74.1;
      efficiency = 82.0;
      availability = 91.0;
      cost += 50;
      oeeColor = const Color(0xFFFFB300); // برتقالي حمل زائد
    } else if (currentMode == 'high_vibration' ||
        currentMode == 'bearing_damage') {
      oee = 58.3;
      mtbf = 48.5;
      mttr = 4.2;
      efficiency = 65.4;
      availability = 88.0;
      cost += 180;
      oeeColor = const Color(0xFFFF5252);
    } else if (currentMode == 'cooling_failure') {
      oee = 69.8;
      efficiency = 75.0;
      cost += 90;
      oeeColor = const Color(0xFFFF9800);
    }

    // 🌐 دالة محلية سهلة الاستخدام لجلب النصوص عبر المترجم المركزي الموحد
    String t(String key) => AppTranslations.t(key, currentLang);

    return GridView.count(
      crossAxisCount: 3, // تقسيم متناسق لـ 6 بطاقات في سطرين
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _buildKpiCard(
          t('oee_title'),
          'OEE',
          '$oee%',
          oeeColor,
          Icons.analytics_rounded,
          true,
          cardBg,
          borderBg,
          textMain,
          textSub,
        ),
        _buildKpiCard(
          t('mtbf_title'),
          'MTBF',
          '${mtbf.toStringAsFixed(1)} hrs',
          const Color(0xFF00C2FF),
          Icons.timer_rounded,
          false,
          cardBg,
          borderBg,
          textMain,
          textSub,
        ),
        _buildKpiCard(
          t('mttr_title'),
          'MTTR',
          '${mttr.toStringAsFixed(1)} hrs',
          const Color(0xFFFF5252),
          Icons.build_rounded,
          false,
          cardBg,
          borderBg,
          textMain,
          textSub,
        ),
        _buildKpiCard(
          t('eff_title'),
          'EFFICIENCY',
          '$efficiency%',
          const Color(0xFF9D4EDD),
          Icons.speed_rounded,
          false,
          cardBg,
          borderBg,
          textMain,
          textSub,
        ),
        _buildKpiCard(
          t('avail_title'),
          'AVAILABILITY',
          '$availability%',
          const Color(0xFFE040FB),
          Icons.event_available_rounded,
          false,
          cardBg,
          borderBg,
          textMain,
          textSub,
        ),
        _buildKpiCard(
          t('cost_title'),
          'MTN COST',
          '\$$cost',
          const Color(0xFFFF9800),
          Icons.monetization_on_rounded,
          false,
          cardBg,
          borderBg,
          textMain,
          textSub,
        ),
      ],
    );
  }

  // ─── ميثود بناء البطاقة الذكية المحدثة بالألوان الديناميكية والـ Sparkline ───
  Widget _buildKpiCard(
    String title,
    String kpiName,
    String value,
    Color kpiColor,
    IconData icon,
    bool hasGlow,
    Color cardBg,
    Color borderBg,
    Color textMain,
    Color textSub,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasGlow ? kpiColor.withOpacity(0.5) : borderBg,
          width: 1.2,
        ),
        boxShadow: hasGlow
            ? [
                BoxShadow(
                  color: kpiColor.withOpacity(0.15),
                  blurRadius: 10,
                  spreadRadius: -2,
                ),
              ]
            : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
      ),
      child: Stack(
        children: [
          // خلفية جرافيكية مصغرة (Mini-Sparkline) أسفل كل بطاقة
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 24,
              child: CustomPaint(
                painter: _SparklinePainter(color: kpiColor.withOpacity(0.25)),
              ),
            ),
          ),

          // المحتوى النصي للأشرطة
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          kpiName,
                          style: TextStyle(
                            color: kpiColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Courier',
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          title,
                          style: TextStyle(
                            color: textSub.withOpacity(0.8),
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(icon, color: textSub.withOpacity(0.4), size: 16),
                ],
              ),

              // القيمة الكبيرة لـ KPI
              Padding(
                padding: const EdgeInsets.all(0), // تم تعديلها لتوافق شروط العرض المبسط
                child: Text(
                  value,
                  style: TextStyle(
                    color: textMain,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Courier',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── رسام المنحنيات البيانية المصغرة (Sparkline) ───
class _SparklinePainter extends CustomPainter {
  final Color color;
  _SparklinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final List<double> values = [0.3, 0.5, 0.35, 0.7, 0.55, 0.85, 0.4, 0.6, 0.8];
    final double stepX = size.width / (values.length - 1);

    path.moveTo(0, size.height * (1 - values[0]));
    for (int i = 1; i < values.length; i++) {
      path.lineTo(i * stepX, size.height * (1 - values[i]));
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}